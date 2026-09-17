;;; -*- Gerbil -*-
;;; Optional resident-registry projection for Testing source admission.
;;;
;;; This owner is intentionally outside the native PackageSpec startup path:
;;; ordinary std/make planning must not pay to load testing-only detection.

(import :gerbil/expander
        (only-in :std/misc/path path-default-extension))

(export asp-gerbil-scheme-resident-import-footprints)

(def (resident-import-context value)
  (cond
   ((or (module-context? value) (prelude-context? value)) value)
   ((module-import? value)
    (resident-import-context (module-import-source value)))
   ((module-export? value)
    (resident-import-context (module-export-context value)))
   ((import-set? value)
    (resident-import-context (import-set-source value)))
   (else #f)))

(def (resident-module-context entry)
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
      (alet (direct (resident-import-context imported))
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
      (alet (context (resident-import-context imported))
        (unless (hash-get visited context)
          (hash-put! visited context #t)
          (alet (id (expander-context-id context))
            (when id (set! ordered (cons id ordered))))
          (for-each visit (module-context-import context)))))
    (visit root-context)
    (reverse ordered)))

;;; Read only contexts already installed by the native test harness.  Absence
;;; is a lifecycle error; this owner never calls import-module or reads source.
(def (asp-gerbil-scheme-resident-import-footprints entry)
  (map (lambda (context)
         (cons (expander-context-id context)
               (resident-context-closure-ids context)))
       (resident-direct-import-contexts (resident-module-context entry))))
