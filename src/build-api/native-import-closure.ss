;;; -*- Gerbil -*-
;;; Project declared entry modules through Gerbil's native import model.
;;; std/make remains the sole build planner and executor.

(import :gerbil/expander
        (only-in :std/misc/path path-default-extension path-expand)
        (only-in :std/srfi/13 string-prefix?)
        (only-in "./package-build"
                 asp-gerbil-scheme-package-build-package-name))

(export asp-gerbil-scheme-native-import-closure)

(def (import-context value)
  (cond
   ((or (module-context? value) (prelude-context? value)) value)
   ((module-import? value) (import-context (module-import-source value)))
   ((module-export? value) (import-context (module-export-context value)))
   ((import-set? value) (import-context (import-set-source value)))
   (else #f)))

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
(def (asp-gerbil-scheme-native-import-closure root entries)
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
