;;; -*- Gerbil -*-
;;; Project declared entry modules through Gerbil's native import model.
;;; std/make remains the sole build planner and executor.

(import :gerbil/expander
        (only-in :std/misc/path path-default-extension path-expand)
        (only-in :std/srfi/13 string-prefix?)
        (only-in "./package-build"
                 asp-gerbil-scheme-package-build-package-name))

(export asp-gerbil-scheme-native-import-closure
        asp-gerbil-scheme-prepared-native-import-closure
        asp-gerbil-scheme-resident-import-footprints
        call-with-asp-gerbil-scheme-prepared-source-graph)

;;; Dynamic capability installed only by the Testing prepared-source slot.
;;; It separates build-time closure projection from resident-context
;;; observation and makes accidental re-entry into the cold projection API a
;;; typed lifecycle failure instead of a silent performance regression.
(def current-asp-gerbil-scheme-prepared-source-graph?
  (make-parameter #f))

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
         (visited (make-hash-table-eq))
         (ordered '()))
    ;; PackageSpec is evaluated before std/make enters its own `make` body.
    ;; Mirror the upstream source-root acquisition step so qualified sibling
    ;; imports resolve on a genuinely clean package with no installed outputs.
    (add-load-path! root)
    (def (visit imported)
      (alet (context (import-context imported))
        (unless (hash-get visited context)
          (hash-put! visited context #t)
          (alet (source (local-module-source context package-prefix))
            ;; External package contexts are already represented by gxpkg and
            ;; must not expand this package's native build target set.
            (when (and source (file-exists? (path-expand source root)))
              (for-each visit (module-context-import context))
              (set! ordered (cons source ordered)))))))
    (for-each
     (lambda (entry)
       (visit (import-module (path-default-extension entry ".ss") #f #f)))
     entries)
    (reverse ordered)))

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

(def (resident-direct-import-contexts context)
  (reverse
   (foldl
    (lambda (imported contexts)
      (alet (direct (import-context imported))
        (if (or (not (expander-context-id direct))
                (memq direct contexts))
          contexts
          (cons direct contexts))))
    []
    (module-context-import context))))

(def (resident-context-closure-ids root-context)
  (let ((visited (make-hash-table-eq))
        (ordered []))
    (def (visit imported)
      (alet (context (import-context imported))
        (unless (hash-get visited context)
          (hash-put! visited context #t)
          (alet (id (expander-context-id context))
            (when id (set! ordered (cons id ordered))))
          (for-each visit (module-context-import context)))))
    (visit root-context)
    (reverse ordered)))

;;; Project direct-import footprints exclusively from Gerbil's resident module
;;; registry.  No source is parsed or imported here; an absent context is a
;;; lifecycle error instead of a fallback to cold expansion.
;; : (-> Path (List (Pair ModuleId (List ModuleId))))
(def (asp-gerbil-scheme-resident-import-footprints entry)
  (map (lambda (context)
         (cons (expander-context-id context)
               (resident-context-closure-ids context)))
       (resident-direct-import-contexts (prepared-module-context entry))))

;; : (-> Path (List Path) (List Path))
(def (project-prepared-native-import-closure root entries)
  (let* ((package-name
          (or (asp-gerbil-scheme-package-build-package-name root)
              (error "prepared native import closure requires package: in gerbil.pkg"
                     root)))
         (package-prefix (string-append package-name "/"))
         (visited (make-hash-table-eq))
         (ordered '()))
    (def (visit imported)
      (alet (context (import-context imported))
        (unless (hash-get visited context)
          (hash-put! visited context #t)
          (alet (source (local-module-source context package-prefix))
            (when (and source (file-exists? (path-expand source root)))
              (for-each visit (module-context-import context))
              (set! ordered (cons source ordered)))))))
    (for-each (lambda (entry) (visit (prepared-module-context entry))) entries)
    (reverse ordered)))

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
