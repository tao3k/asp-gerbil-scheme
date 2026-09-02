;;; Gerbil package source closures expand declared entry modules into one
;;; deterministic internal import/include order. Package identity comes only
;;; from gerbil.pkg; this owner has no downstream project or component catalog.

(import :gerbil/expander
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/srfi/1 filter-map fold)
        (only-in :std/srfi/13 string-index string-prefix? string-suffix?)
        (only-in :std/sugar
                 hash
                 hash-get
                 hash-key?
                 hash-put!
                 hash-remove!)
        (only-in :asp-gerbil-scheme/src/parser/imports module-import-facts-from-form)
        (only-in :asp-gerbil-scheme/src/parser/model module-import-fact-module)
        (only-in :asp-gerbil-scheme/src/build-api/package-build
                 asp-gerbil-scheme-package-build-package-name))

(export asp-gerbil-scheme-source-dependency-order)

;; : (-> ModuleReference ModuleReference)
(def (module-ref-without-fragment module-ref)
  (let (fragment-index (string-index module-ref #\#))
    (if fragment-index
      (substring module-ref 0 fragment-index)
      module-ref)))

;; : (-> SourcePath SourcePath)
(def (source-path-with-extension path)
  (if (string-suffix? ".ss" path)
    path
    (string-append path ".ss")))

;; : (-> PackageRoot AbsolutePath SourcePath)
(def (root-relative-path root path)
  (let* ((absolute-root (path-normalize root))
         (absolute-path (path-normalize path))
         (root-prefix (if (string-suffix? "/" absolute-root)
                        absolute-root
                        (string-append absolute-root "/"))))
    (if (string-prefix? root-prefix absolute-path)
      (substring absolute-path
                 (string-length root-prefix)
                 (string-length absolute-path))
      (error "ASP_GERBIL_SCHEME component dependency escapes the package root"
             absolute-path absolute-root))))

;; : (-> PackageRoot SourcePath ModuleReference Boolean SourcePath)
(def (relative-source-path root importer module-ref
                           add-extension?: (add-extension? #t))
  (let* ((module-path (module-ref-without-fragment module-ref))
         (resolved-path
          (path-expand (if add-extension?
                         (source-path-with-extension module-path)
                         module-path)
                       (path-directory (path-expand importer root)))))
    (root-relative-path root resolved-path)))

;; : (-> PackageRoot ModulePrefix)
(def (package-module-prefix root)
  (let (package-name (asp-gerbil-scheme-package-build-package-name root))
    (unless (and (string? package-name) (> (string-length package-name) 0))
      (error "Gerbil package closure requires package: in gerbil.pkg" root))
    (string-append ":" package-name "/")))

;;; Boundary: imports qualified by the package-local gerbil.pkg identity and
;;; relative imports enter the closure; external package modules remain Gerbil
;;; package dependencies.
;; : (-> ModulePrefix PackageRoot SourcePath ModuleReference (Maybe SourcePath))
(def (internal-module-source-file package-prefix root importer module-ref)
  (let (module-path (module-ref-without-fragment module-ref))
    (cond
     ((string-prefix? package-prefix module-path)
      (source-path-with-extension
       (substring module-path
                  (string-length package-prefix)
                  (string-length module-path))))
     ((string-prefix? ":" module-path) #f)
     (else (relative-source-path root importer module-path)))))

;; : (forall (form) (-> PackageRoot SourcePath form (List SourcePath)))
;; : (-> PackageRoot SourcePath Syntax (List SourcePath))
(def (include-source-files root importer form)
  (let (datum (syntax->datum form))
    (if (and (pair? datum) (eq? (car datum) 'include))
      (map (lambda (path)
             (unless (string? path)
               (error "unsupported non-string Gerbil include" importer path))
             (relative-source-path root importer path add-extension?: #f))
           (cdr datum))
      '())))

;; : (forall (form) (-> ModulePrefix PackageRoot SourcePath form (List SourcePath)))
;; : (-> ModulePrefix PackageRoot SourcePath Syntax (List SourcePath))
(def (source-form-dependencies package-prefix root source form)
  (cond
   ((and (stx-pair? form) (eq? (stx-e (stx-car form)) 'import))
    (filter-map
     (lambda (fact)
       (internal-module-source-file
        package-prefix root source (module-import-fact-module fact)))
     (module-import-facts-from-form source form)))
   ((and (stx-pair? form) (eq? (stx-e (stx-car form)) 'include))
    (include-source-files root source form))
   (else '())))

;; : (-> ModulePrefix PackageRoot SourcePath (List SourcePath))
(def (source-dependencies package-prefix root source)
  (call-with-input-file
   (path-expand source root)
   (lambda (port)
     (let loop ((dependencies '()))
       (let (form (read-syntax port))
         (if (eof-object? form)
           dependencies
           (loop (fold cons dependencies
                       (source-form-dependencies
                        package-prefix root source form)))))))))

;;; Invariant: a source is emitted once, every dependency is visited first, and
;;; a back-edge is rejected with its cycle path instead of being silently cut.
;;; Optimization boundary: traversal-local tables preserve a value-oriented
;;; public API while making closure discovery O(V+E) and reading shared imports
;;; only once.
;; : (forall (path) (-> path (List path) (List path)))
;; : (-> PackageRoot (List SourcePath) (List SourcePath))
(def (asp-gerbil-scheme-source-dependency-order root entries)
  (let ((package-prefix (package-module-prefix root))
        (visited (make-hash-table))
        (visiting (make-hash-table))
        (dependency-cache (make-hash-table))
        (ordered '()))
    (def (cached-source-dependencies source)
      (if (hash-key? dependency-cache source)
        (hash-get dependency-cache source)
        (let (dependencies
              (source-dependencies package-prefix root source))
          (hash-put! dependency-cache source dependencies)
          dependencies)))
    (def (visit source stack)
      (cond
       ((hash-key? visited source) (void))
       ((hash-key? visiting source)
        (error "cyclic Gerbil package source dependency"
               (reverse (cons source stack))))
       (else
        (unless (file-exists? (path-expand source root))
          (error "missing Gerbil package source dependency" source stack))
        (hash-put! visiting source #t)
        (for-each (lambda (dependency)
                    (visit dependency (cons source stack)))
                  (cached-source-dependencies source))
        (hash-remove! visiting source)
        (hash-put! visited source #t)
        (set! ordered (cons source ordered)))))
    (for-each (lambda (entry) (visit entry '())) entries)
    (reverse ordered)))
