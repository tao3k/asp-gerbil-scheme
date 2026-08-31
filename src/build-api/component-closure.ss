;;; Component closures are ASP_GERBIL_SCHEME-owned build metadata: declared public entry
;;; modules expand to a deterministic, checked internal import/include graph.
;;; Downstream build systems consume the receipt and never reimplement parsing.

(import :gerbil/expander
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 filter-map fold)
        (only-in :std/srfi/13 string-index string-prefix? string-suffix?)
        (only-in :std/sugar
                 hash
                 hash-get
                 hash-key?
                 hash-put!
                 hash-remove!)
        (only-in :std/text/json write-json)
        (only-in :asp-gerbil-scheme/src/parser/imports module-import-facts-from-form)
        (only-in :asp-gerbil-scheme/src/parser/model module-import-fact-module)
        (only-in :asp-gerbil-scheme/src/build-api/source-coverage
                 asp-gerbil-scheme-source-coverage-files))

(export asp-gerbil-scheme-component-names
        asp-gerbil-scheme-component-entry-files
        asp-gerbil-scheme-source-dependency-order
        asp-gerbil-scheme-component-source-files
        asp-gerbil-scheme-component-receipt
        write-asp-gerbil-scheme-component-receipt)

(def +asp-gerbil-scheme-package-module-prefix+ ":asp-gerbil-scheme/")
(def +asp-gerbil-scheme-component-support-files+
  '("build.ss" "gerbil.pkg" "src/building/build-script-body.inc"))
(def +asp-gerbil-scheme-component-entry-files+
  '((poo-flow
     "src/build-api/framework.ss"
     "src/build-api/source-coverage.ss"
     "src/building/observability.ss"
     "src/building/std-builder.ss"
     "src/extensions/poo-object-validation.ss"
     "src/policy/gxtest.ss"
     "src/testing/build.ss")))

;; : (-> (U Symbol String) ComponentName)
(def (component-name->symbol name)
  (cond
   ((symbol? name) name)
   ((string? name) (string->symbol name))
   (else (error "invalid ASP_GERBIL_SCHEME component name" name))))

;; : (-> (List ComponentName))
(def (asp-gerbil-scheme-component-names)
  (map car +asp-gerbil-scheme-component-entry-files+))

;; : (-> ComponentName (List SourcePath))
(def (asp-gerbil-scheme-component-entry-files name)
  (let* ((component (component-name->symbol name))
         (entry (assq component +asp-gerbil-scheme-component-entry-files+)))
    (or (and entry (cdr entry))
        (error "unknown ASP_GERBIL_SCHEME component" component))))

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

;;; Boundary: package-qualified ASP_GERBIL_SCHEME and relative imports enter the component
;;; graph; external modules remain declared Gerbil package dependencies.
;; : (-> PackageRoot SourcePath ModuleReference (Maybe SourcePath))
(def (asp-gerbil-scheme-internal-module-source-file root importer module-ref)
  (let (module-path (module-ref-without-fragment module-ref))
    (cond
     ((string-prefix? +asp-gerbil-scheme-package-module-prefix+ module-path)
      (source-path-with-extension
       (substring module-path
                  (string-length +asp-gerbil-scheme-package-module-prefix+)
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

;; : (forall (form) (-> PackageRoot SourcePath form (List SourcePath)))
;; : (-> PackageRoot SourcePath Syntax (List SourcePath))
(def (source-form-dependencies root source form)
  (cond
   ((and (stx-pair? form) (eq? (stx-e (stx-car form)) 'import))
    (filter-map
     (lambda (fact)
       (asp-gerbil-scheme-internal-module-source-file
        root source (module-import-fact-module fact)))
     (module-import-facts-from-form source form)))
   ((and (stx-pair? form) (eq? (stx-e (stx-car form)) 'include))
    (include-source-files root source form))
   (else '())))

;; : (-> PackageRoot SourcePath (List SourcePath))
(def (source-dependencies root source)
  (call-with-input-file
   (path-expand source root)
   (lambda (port)
     (let loop ((dependencies '()))
       (let (form (read-syntax port))
         (if (eof-object? form)
           dependencies
           (loop (fold cons dependencies
                       (source-form-dependencies root source form)))))))))

;;; Invariant: a source is emitted once, every dependency is visited first, and
;;; a back-edge is rejected with its cycle path instead of being silently cut.
;;; Optimization boundary: traversal-local tables preserve a value-oriented
;;; public API while making closure discovery O(V+E) and reading shared imports
;;; only once.
;; : (forall (path) (-> path (List path) (List path)))
;; : (-> PackageRoot (List SourcePath) (List SourcePath))
(def (asp-gerbil-scheme-source-dependency-order root entries)
  (let ((visited (make-hash-table))
        (visiting (make-hash-table))
        (dependency-cache (make-hash-table))
        (ordered '()))
    (def (cached-source-dependencies source)
      (if (hash-key? dependency-cache source)
        (hash-get dependency-cache source)
        (let (dependencies (source-dependencies root source))
          (hash-put! dependency-cache source dependencies)
          dependencies)))
    (def (visit source stack)
      (cond
       ((hash-key? visited source) (void))
       ((hash-key? visiting source)
        (error "cyclic ASP_GERBIL_SCHEME component source dependency"
               (reverse (cons source stack))))
       (else
        (unless (file-exists? (path-expand source root))
          (error "missing ASP_GERBIL_SCHEME component source dependency" source stack))
        (hash-put! visiting source #t)
        (for-each (lambda (dependency)
                    (visit dependency (cons source stack)))
                  (cached-source-dependencies source))
        (hash-remove! visiting source)
        (hash-put! visited source #t)
        (set! ordered (cons source ordered)))))
    (for-each (lambda (entry) (visit entry '())) entries)
    (reverse ordered)))

;; : (-> ComponentName PackageRoot (List SourcePath))
(def (asp-gerbil-scheme-component-source-files name root: (root (current-directory)))
  (sort (asp-gerbil-scheme-source-dependency-order root (asp-gerbil-scheme-component-entry-files name))
        string<?))

;;; Intent: the sorted receipt is the deterministic analysis boundary consumed
;;; by downstream build systems; declared entry roots remain separately visible.
;; : (-> ComponentName PackageRoot ComponentClosureReceipt)
(def (asp-gerbil-scheme-component-receipt name root: (root (current-directory)))
  (let* ((component (component-name->symbol name))
         (entries (asp-gerbil-scheme-component-entry-files component))
         (sources (asp-gerbil-scheme-component-source-files component root: root))
         (module-sources
          (filter (lambda (path) (string-suffix? ".ss" path)) sources))
         (full-sources (asp-gerbil-scheme-source-coverage-files root))
         (strict-subset? (< (length module-sources) (length full-sources))))
    (unless strict-subset?
      (error "ASP_GERBIL_SCHEME component closure is not a strict package subset"
             component (length module-sources) (length full-sources)))
    (hash
     (schema "asp-gerbil-scheme.component-source-closure.v1")
     (outcome "valid")
     (component (symbol->string component))
     (entryFiles entries)
     (sourceFiles sources)
     (sourceCount (length sources))
     (fullSourceCount (length full-sources))
     (strictSubset strict-subset?)
     (supportFiles +asp-gerbil-scheme-component-support-files+))))

;; : (-> ComponentName PackageRoot Void)
(def (write-asp-gerbil-scheme-component-receipt name root: (root (current-directory)))
  (write-json (asp-gerbil-scheme-component-receipt name root: root))
  (newline))
