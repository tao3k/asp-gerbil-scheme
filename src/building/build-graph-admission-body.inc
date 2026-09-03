;;; Bootstrap-safe Build Graph admission.
;;;
;;; This file is included by the source-loaded build script, so it must depend
;;; only on Gerbil/std bindings already imported by build-script-body.inc.  A
;;; fresh package must be able to run `build.ss clean` before any ASP module has
;;; been compiled into GERBIL_PATH.

(def (framework-build-graph-module-stem module)
  (let (length (string-length module))
    (if (and (>= length 3)
             (string-suffix? ".ss" module))
      (substring module 0 (- length 3))
      module)))

(def (framework-build-graph-module-path module)
  (if (string-suffix? ".ss" module)
    module
    (string-append module ".ss")))

(def (framework-build-graph-source-path source-directory module)
  (path-expand (framework-build-graph-module-path module) source-directory))

(def (framework-build-graph-output-path prefix module)
  (path-expand
   (string-append prefix "/"
                  (framework-build-graph-module-stem module)
                  ".ssi")
   (path-expand "lib" (or (getenv "GERBIL_PATH") ".gerbil"))))

(def (framework-build-graph-file-seconds path)
  (time->seconds (file-info-last-modification-time (file-info path))))

(def (framework-build-graph-header-form? form)
  (and (pair? form)
       (memq (car form)
             '(import export include package: namespace declare prelude:))))

(def (framework-build-graph-read-header-forms path)
  (call-with-input-file path
    (lambda (port)
      (let loop ((forms []))
        (let (form (read port))
          (cond
           ((eof-object? form) (reverse forms))
           ((and (pair? form) (memq (car form) '(import export include)))
            (loop (cons form forms)))
           ((framework-build-graph-header-form? form) (loop forms))
           (else (reverse forms))))))))

(def (framework-build-graph-import-reference source-directory prefix owner reference)
  (let* ((name (cond ((symbol? reference) (symbol->string reference))
                     ((string? reference) reference)
                     (else #f)))
         (package-prefix (string-append ":" prefix "/")))
    (cond
     ((not name) #f)
     ((string-prefix? package-prefix name)
      (framework-build-graph-module-path
       (substring name
                  (string-length package-prefix)
                  (string-length name))))
     ((string-prefix? "." name)
      (let* ((root (path-normalize source-directory))
             (directory (path-expand (path-directory owner) root))
             (absolute
              (path-normalize
               (path-expand (framework-build-graph-module-path name)
                            directory))))
        (framework-build-graph-module-path
         (substring absolute
                    (+ (string-length root)
                       (if (string-suffix? "/" root) 0 1))
                    (string-length absolute)))))
     (else #f))))

(def (framework-build-graph-import-references source-directory prefix owner datum)
  (if (pair? datum)
    (apply append
           (map (lambda (item)
                  (framework-build-graph-import-references
                   source-directory prefix owner item))
                datum))
    (let (module
          (framework-build-graph-import-reference
           source-directory prefix owner datum))
      (if module [module] []))))

(def (framework-build-graph-dependencies source-directory prefix modules module)
  (let (forms
        (framework-build-graph-read-header-forms
         (framework-build-graph-source-path source-directory module)))
    (filter
     (lambda (dependency) (member dependency modules))
     (apply append
            (map (lambda (form)
                   (if (and (pair? form)
                            (memq (car form) '(import export)))
                     (framework-build-graph-import-references
                      source-directory prefix module (cdr form))
                     []))
                 forms)))))

(def (framework-build-graph-includes source-directory module)
  (let* ((source-path
          (framework-build-graph-source-path source-directory module))
         (source-parent (path-directory source-path)))
    (filter-map
     (lambda (form)
       (and (pair? form)
            (eq? (car form) 'include)
            (pair? (cdr form))
            (string? (cadr form))
            (path-normalize (path-expand (cadr form) source-parent))))
     (framework-build-graph-read-header-forms source-path))))

(def (framework-build-graph-artifact-current?
      source-directory prefix module dependencies (dependencies-current? #t))
  (let ((source (framework-build-graph-source-path source-directory module))
        (output (framework-build-graph-output-path prefix module))
        (includes (framework-build-graph-includes source-directory module)))
    (and (file-exists? source)
         (file-exists? output)
         (<= (framework-build-graph-file-seconds source)
             (framework-build-graph-file-seconds output))
         (andmap
          (lambda (include)
            (and (file-exists? include)
                 (<= (framework-build-graph-file-seconds include)
                     (framework-build-graph-file-seconds output))))
          includes)
         (or (not dependencies-current?)
             (andmap
              (lambda (dependency)
                (let (dependency-output
                      (framework-build-graph-output-path prefix dependency))
                  (and (file-exists? dependency-output)
                       (<= (framework-build-graph-file-seconds dependency-output)
                           (framework-build-graph-file-seconds output)))))
              dependencies)))))

(def (framework-build-graph-affected modules stale dependencies-of)
  (let loop ((affected stale))
    (let (dependents
          (filter
           (lambda (module)
             (and (not (member module affected))
                  (ormap (lambda (dependency)
                           (member dependency affected))
                         (dependencies-of module))))
           modules))
      (if (null? dependents)
        (filter (lambda (module) (member module affected)) modules)
        (loop (append affected dependents))))))

(def (framework-build-graph-affected-specs source-directory prefix specs)
  (let* ((modules (map framework-build-graph-module-path specs))
         (dependencies
          (map (lambda (module)
                 (cons module
                       (framework-build-graph-dependencies
                        source-directory prefix modules module)))
               modules))
         (dependencies-of
          (lambda (module) (cdr (assoc module dependencies))))
         (stale
          (filter
           (lambda (module)
             (not (framework-build-graph-artifact-current?
                   source-directory prefix module (dependencies-of module))))
           modules)))
    (framework-build-graph-affected modules stale dependencies-of)))
