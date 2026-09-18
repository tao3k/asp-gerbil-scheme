;;; -*- Gerbil -*-
;;; Project declared entry modules through Gerbil's native import model.
;;; std/make remains the sole build planner and executor.

(import (only-in :gerbil/expander/module
                 __module-registry
                 core-resolve-module-path
                 import-module
                 import-set? import-set-source
                 module-export? module-export-context
                 module-import? module-import-source)
        (only-in :gerbil/expander/common
                 expander-context-id
                 module-context? module-context-import
                 prelude-context?)
        (only-in :std/iter for in-input-port)
        (only-in :std/misc/dag walk-dag)
        (only-in :std/misc/hash hash-ensure-ref)
        (only-in :std/misc/list with-list-builder)
        (only-in :std/misc/path
                 path-default-extension path-expand path-strip-extension)
        (only-in :std/sort stable-sort)
        (only-in :std/srfi/1 find)
        (only-in :std/srfi/13 string-prefix?)
        (only-in "./package-build"
                 asp-gerbil-scheme-package-build-package-name))

(export asp-gerbil-scheme-native-import-closure
        asp-gerbil-scheme-prepared-native-import-closure
        call-with-asp-gerbil-scheme-prepared-source-graph)

;;; Dynamic capability installed only by the Testing prepared-source slot.
;;; It separates build-time closure projection from resident-context
;;; observation and makes accidental re-entry into the cold projection API a
;;; typed lifecycle failure instead of a silent performance regression.
;; : (-> Boolean Parameter)
(def current-asp-gerbil-scheme-prepared-source-graph?
  (make-parameter #f))

;; : (-> Thunk Result)
(def (call-with-asp-gerbil-scheme-prepared-source-graph thunk)
  (parameterize
      ((current-asp-gerbil-scheme-prepared-source-graph? #t))
    (thunk)))

;; : (-> ImportBinding (Maybe ExpanderContext))
(def (import-context value)
  (cond
   ((or (module-context? value) (prelude-context? value)) value)
   ((module-import? value) (import-context (module-import-source value)))
   ((module-export? value) (import-context (module-export-context value)))
   ((import-set? value) (import-context (import-set-source value)))
   (else #f)))

;; : (-> ExpanderContext String (Maybe Path))
(def (local-module-source context package-prefix)
  (let* ((id (expander-context-id context))
         (name (and id (symbol->string id))))
    (and name
         (string-prefix? package-prefix name)
         (path-default-extension
          (substring name (string-length package-prefix) (string-length name))
          ".ss"))))

;; Project an already native Gerbil context DAG to package-local sources.
;; `walk-dag` owns cycle detection and the visited index; the source index
;; ensures both arrow selection and post-order collection share one stat.
;; : (-> Path String (List ExpanderContext) (List Path))
(def (project-native-context-closure root package-prefix contexts)
  (let (source-index (make-hash-table-eq))
    (def (project-source context)
      (hash-ensure-ref
       source-index context
       (lambda ()
         (alet (source (local-module-source context package-prefix))
           (and (file-exists? (path-expand source root)) source)))))
    (with-list-builder (collect)
      (walk-dag
       (lambda (visit) (for-each visit contexts))
       arrows:
       (lambda (context)
         (if (project-source context)
           (module-context-import context)
           []))
       arrow-target: import-context
       synthetic-attribute:
       (lambda (context _imports _attributes)
         (alet (source (project-source context))
           (collect source)))))))

;; The installed interface contains Gerbil's normalized import declarations.
;; This adapter only projects their module identity; std `walk-dag` below owns
;; graph traversal, cycle detection, and visited indexing.
;; : (-> ImportSpec (Pair Phase ModuleId))
(def (compiled-import-module value)
  (match value
    ((? symbol?) [0 . value])
    (['spec: [(? symbol? module) . _] . _] [0 . module])
    (['phi: (? integer? phase) (? symbol? module) . _] [phase . module])
    (_ (error "unsupported compiled interface import" value))))

;; : (-> Path (List Symbol))
(def (compiled-interface-imports path)
  (let (imports
        (with-list-builder (collect)
          (def (walk datum)
            (when (pair? datum)
              (if (eq? (car datum) '%#import)
                (for-each
                 (lambda (spec)
                   (collect (compiled-import-module spec)))
                 (cdr datum))
                (for-each walk datum))))
          (call-with-input-file path
            (lambda (port)
              (for (datum (in-input-port port))
                (walk datum))))))
    (map cdr
         (stable-sort imports
                      (lambda (left right)
                        (> (car left) (car right)))))))

;; : (-> String (List Path) (Maybe Path))
(def (installed-library-root package-name entries)
  (find
   (lambda (root)
     (andmap
      (lambda (entry)
        (file-exists?
         (path-expand
          (string-append package-name "/"
                         (path-strip-extension entry) ".ssi")
          root)))
      entries))
   (load-path)))

;; Project the authoritative installed interfaces only while every package
;; source is no newer than its corresponding .ssi. A single stale or missing
;; interface rejects the whole path and preserves native source expansion as
;; the fail-closed fallback.
;; : (-> Path String (List Path) (Maybe (List Path)))
(def (project-compiled-interface-closure root package-name entries)
  (alet (library-root (installed-library-root package-name entries))
    (let ((package-prefix (string-append ":" package-name "/"))
          (source-info-index (make-hash-table))
          (interface-info-index (make-hash-table))
          (current? #t))
      (def (module-source module)
        (let (name (symbol->string module))
          (and (string-prefix? package-prefix name)
               (path-default-extension
                (substring name
                           (string-length package-prefix)
                           (string-length name))
                ".ss"))))
      (def (interface-path source)
        (path-expand
         (string-append package-name "/"
                        (path-strip-extension source) ".ssi")
         library-root))
      (def (file-info/indexed index path)
        (hash-ensure-ref
         index path
         (lambda ()
           (with-catch (lambda (_) #f) (lambda () (file-info path))))))
      (def (module-current? source interface)
        (let ((source-info
               (file-info/indexed
                source-info-index (path-expand source root)))
              (interface-info
               (file-info/indexed interface-info-index interface)))
          (and source-info interface-info
               (<= (time->seconds
                    (file-info-last-modification-time source-info))
                   (time->seconds
                    (file-info-last-modification-time interface-info))))))
      (let (projected
            (with-list-builder (collect)
              (walk-dag
               (lambda (visit)
                 (for-each
                  (lambda (entry)
                    (visit
                     (string->symbol
                      (string-append package-prefix
                                     (path-strip-extension entry)))))
                  entries))
               arrows:
               (lambda (module)
                 (cond
                  ((module-source module)
                   => (lambda (source)
                        (let (interface (interface-path source))
                          (if (module-current? source interface)
                            (compiled-interface-imports interface)
                            (begin (set! current? #f) [])))))
                  (else [])))
               synthetic-attribute:
               (lambda (module _imports _attributes)
                 (alet (source (module-source module))
                   (when current? (collect source)))))))
        (and current? projected)))))

;; Visit each native module context once.  Importing only the declared roots
;; lets Gerbil resolve wrappers, phases, preludes, and relative paths itself;
;; the projection neither reparses source nor imports every catalog member.
;; : (-> Path (List Path) (List Path))
(def (project-native-import-closure root entries)
  (let* ((package-name
          (or (asp-gerbil-scheme-package-build-package-name root)
              (error "native import closure requires package: in gerbil.pkg"
                     root)))
         (package-prefix (string-append package-name "/"))
         (compiled
          (with-catch
           (lambda (_) #f)
           (lambda ()
             (project-compiled-interface-closure
              root package-name entries)))))
    ;; PackageSpec is evaluated before std/make enters its own `make` body.
    ;; Mirror the upstream source-root acquisition step so qualified sibling
    ;; imports resolve on a genuinely clean package with no installed outputs.
    (add-load-path! root)
    (or compiled
        (project-native-context-closure
         root package-prefix
         (map
          (lambda (entry)
            ;; import-module already consults Gerbil's authoritative module
            ;; registry before expanding source; do not duplicate that lookup here.
            (import-module (path-default-extension entry ".ss") #f #f))
          entries)))))

;; Read a context already installed by the native test harness.  Unlike
;; import-module, this lookup cannot expand or evaluate an unprepared module.
;; : (-> Path ExpanderContext)
(def (prepared-module-context entry)
  (let* ((source (path-default-extension entry ".ss"))
         (resolved (core-resolve-module-path source))
         (context (hash-get __module-registry resolved)))
    (or context
        (error "prepared source is absent from the native module registry"
               entry resolved))))

;; : (-> Path (List Path) (List Path))
(def (project-prepared-native-import-closure root entries)
  (let* ((package-name
          (or (asp-gerbil-scheme-package-build-package-name root)
              (error "prepared native import closure requires package: in gerbil.pkg"
                     root)))
         (package-prefix (string-append package-name "/")))
    (project-native-context-closure
     root package-prefix (map prepared-module-context entries))))

;; : (-> Path (List Path) (List Path))
(def (asp-gerbil-scheme-native-import-closure root entries)
  (when (current-asp-gerbil-scheme-prepared-source-graph?)
    (error "build-time native import closure is forbidden during prepared source admission"
           root entries))
  (project-native-import-closure root entries))

;; : (-> Path (List Path) (List Path))
(def (asp-gerbil-scheme-prepared-native-import-closure root entries)
  (unless (current-asp-gerbil-scheme-prepared-source-graph?)
    (error "prepared native import closure requires the source-admission slot"
           root entries))
  ;; gxtest has already imported every declared root before it invokes suites.
  ;; Read those resident contexts directly; an absent root is a lifecycle
  ;; error and must never fall through to import-module.
  (project-prepared-native-import-closure root entries))
