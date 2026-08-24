;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns the search command dispatcher and compact owner views.
;;; - Evidence packet rendering lives in :commands/search-evidence.
;;; - shared Rust owns workspace search planning, ranking, and budgets.
;;; - unsupported or incomplete routes fail before project collection.
;;; Search command adapter.

(import :gslph/src/commands/guide
        :gslph/src/commands/search-evidence
        :gslph/src/commands/search-extension
        :gslph/src/commands/search-owner-items
        (only-in :gslph/src/commands/search-prime-light
                 emit-prime-light
                 source-path-class)
        :gslph/src/commands/search-proof
        :gslph/src/parser/facade
        :gslph/src/parser/query
        :gslph/src/protocol/json
        :gslph/src/support/args
        :gslph/src/support/io
        (only-in :std/srfi/1 take)
        (only-in :std/srfi/13 string-join)
        (only-in :std/sugar cut filter match ormap))

(export search-main
        language-evidence-view?
        language-evidence-index-free-view?
        language-evidence-authority
        language-evidence-next)
;; search-main
;;   : (-> (List String) Integer)
;;   | doc m%
;;       `search-main args` dispatches a search view and returns a process-style
;;       status code for the harness CLI.
;;
;;       # Examples
;;
;;       ```scheme
;;       (search-main '("prime" "--workspace" "."))
;;       ;; => 0
;;       ```
;;     %
(def (search-main args)
  (match args
    ([] (error "search requires a view"))
    ([view . rest]
     (dispatch-search-view view rest))))
;; : (-> SearchView Args Integer )
(def (dispatch-search-view view rest)
  (if (equal? view "guide")
    (begin (print-guide) 0)
    (dispatch-search-runtime-view view rest)))
;; : (-> SearchView Args Integer )
(def (dispatch-search-runtime-view view rest)
  (let* ((root (project-root rest))
         (args (drop-project-root rest))
         (json? (flag? "--json" args)))
    (or (emit-index-free-search view root args json?)
        (emit-indexed-search
         view
         (search-index-for-view view root args)
         args
         json?))))
;; : (-> SearchView Root Args Boolean MaybeStatus )
(def +dependency-topology-unresolved-version+ "unresolved")
(def +dependency-topology-hex-digits+ "0123456789abcdef")

(def (dependency-topology-byte->hex byte)
  (string
   (string-ref +dependency-topology-hex-digits+ (quotient byte 16))
   (string-ref +dependency-topology-hex-digits+ (modulo byte 16))))

(def (dependency-topology-fingerprint dependencies manifest-path)
  (string-append
   "sha256:"
   (apply
    string-append
    (map dependency-topology-byte->hex
         (u8vector->list
          (sha256
           (apply
            string-append
            (map (lambda (dependency)
                   (string-append
                    dependency
                    "|"
                    +dependency-topology-unresolved-version+
                    "|"
                    manifest-path
                    "\n"))
                 dependencies))))))))

(def (dependency-topology-nodes dependency manifest-path)
  (list
   (hash
    (id (string-append "dependency:" dependency))
    (kind "dependency")
    (value dependency)
    (path manifest-path)
    (fields
     (hash
      (dependencyName dependency)
      (manifestPath manifest-path))))
   (hash
    (id (string-append "dependency-version:" dependency))
    (kind "dependency-version")
    (value +dependency-topology-unresolved-version+)
    (fields
     (hash
      (version +dependency-topology-unresolved-version+))))))

(def (dependency-topology-edge dependency)
  (hash
   (source (string-append "dependency:" dependency))
   (target (string-append "dependency-version:" dependency))
   (relation "version_locked")))

(def (dependency-topology-packet index)
  (let* ((package (project-index-package index))
         (dependencies
          (if package
            (project-package-dependencies package)
            '()))
         (manifest-path
          (if package
            (project-package-path package)
            "gerbil.pkg")))
    (hash
     (packetKind "dependency-topology")
     (fingerprint
      (dependency-topology-fingerprint dependencies manifest-path))
     (graph
      (hash
       (nodes
        (apply append
               (map (lambda (dependency)
                      (dependency-topology-nodes dependency manifest-path))
                    dependencies)))
       (edges (map dependency-topology-edge dependencies)))))))

(def (emit-dependency-topology-search root json?)
  (unless json?
    (error "search dependency-topology requires --json"))
  (write-json-line
   (dependency-topology-packet
    (collect-project-package-only root)))
  0)

(def (emit-index-free-search view root args json?)
  (cond
   ((equal? view "compare") (emit-compare-search args json?))
   ((equal? view "proof") (emit-type-proof-search args json?))
   ((equal? view "dependency-topology")
    (emit-dependency-topology-search root json?))
   ((language-evidence-index-free-view? view)
    (emit-language-evidence-search root view args json?))
   ((language-pattern-package-only-search? view args)
    (emit-pattern-search (collect-project-package-only root) args json?))
    ((and (equal? view "prime")
          (prime-seeds-view? args))
     (if json?
       (begin
         (write-json-line
          (search-prime-packet-json
           (collect-project-package-only root)))
         0)
       (emit-prime-light root)))
   ((equal? view "extension")
    (emit-extension-search (collect-project-package-only root) args json?))
   (else #f)))
;; : (-> SearchView Root Args ProjectIndex )
(def (search-index-for-view view root args)
  (cond
   ((equal? view "owner")
    (owner-search-index root args))
   ((rust-owned-search-view? view)
    (error "whole-workspace search is Rust-owned; use asp search/query" view))
   (else
    (error "unsupported search view" view))))
;; : (-> SearchView Boolean )
(def (rust-owned-search-view? view)
  (or (equal? view "workspace")
      (equal? view "prime")
      (equal? view "symbol")
      (equal? view "import")
      (equal? view "structural")
      (equal? view "extension")
      (equal? view "pattern")
      (language-evidence-view? view)
      (equal? view "lexical")
      (equal? view "pipe")
      (equal? view "ingest")))
;; : (-> SearchView ProjectIndex Args Boolean Integer )
(def (emit-indexed-search view index args json?)
  (if (equal? view "owner")
    (emit-owner-search index args json?)
    (error "Scheme indexed search only supports explicit owners" view)))
;; : (-> String (List String) ProjectIndex )
(def (owner-search-index root args)
  (if (explicit-owner-search-path? root args)
    (collect-project-package-only root)
    (error "owner search requires an explicit Gerbil source path")))

;; : (-> String (List String) Boolean )
(def (explicit-owner-search-path? root args)
  (let* ((positionals (positional-args args))
         (owner (and (pair? positionals) (car positionals)))
         (path (and owner (path-expand owner (path-normalize root)))))
    (and path
         (gerbil-source-path? path)
         (file-exists? path))))

;; : (-> Args Boolean )
(def (prime-seeds-view? args)
  (or (equal? (option "--view" args) "seeds")
      (member "seeds" args)))
;;; Boundary:
;;; - resolve-owner-file owns owner path fallback semantics.
;;; - Keep indexed owners first; parse explicit files only when they are Gerbil sources.
;; : (-> ProjectIndex String SourceFile )
(def (resolve-owner-file index owner)
  (or (find-owner index owner)
      (resolve-explicit-owner-file index owner)))
;; : (-> ProjectIndex String MaybeSourceFile )
(def (resolve-explicit-owner-file index owner)
  (let* ((root (project-index-root index))
         (path (path-expand owner root)))
    (and (gerbil-source-path? path)
         (file-exists? path)
         (parse-source-file root path))))
;; emit-owner-search
;;   : (-> ProjectIndex (List String) Boolean Integer)
;;   | doc m%
;;       `emit-owner-search index args json?` resolves an owner path and emits
;;       either owner details, owner item matches, or owner JSON.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-owner-search index '("src/parser/support.ss") #f)
;;       ;; => 0
;;       ```
;;     %
(def (emit-owner-search index args json?)
  (let* ((positionals (positional-args args))
         (owner (and (pair? positionals) (car positionals))))
    (unless owner (error "search owner requires a path"))
    (let (file (resolve-owner-file index owner))
      (unless file (error "owner not found" owner))
      (if (and (pair? (cdr positionals)) (equal? (cadr positionals) "items"))
        (let* ((query (option "--query" args))
               (terms (owner-item-query-terms query))
               (limit (owner-items-limit args))
               (definition-matches
                (matching-definitions (source-file-definitions file) terms))
               (syntax-limit (max 0 (- limit (length definition-matches))))
               (syntax-matches (matching-owner-syntax-facts file terms syntax-limit)))
          (cond
           ((flag? "--code" args)
            (for-each (lambda (defn)
                        (display (read-definition-code (project-index-root index) defn)))
                      definition-matches))
           ((flag? "--names-only" args)
            (for-each (lambda (defn) (displayln (definition-name defn)))
                      (take definition-matches
                            (min limit (length definition-matches))))
            (for-each (lambda (fact) (displayln (hash-get fact 'name)))
                      syntax-matches))
           (else (emit-owner-items file definition-matches syntax-matches limit))))
        (if json?
          (write-json-line (source-file-json file))
          (emit-owner file))))
    0))

;; : (-> Args Integer )
(def (owner-items-limit args)
  (let* ((value (option "--limit" args))
         (parsed (and value (string->number value))))
    (cond
     ((not value) 80)
     ((and (integer? parsed) (>= parsed 0)) parsed)
     (else (error "invalid owner-items --limit" value)))))
;; emit-owner
;;   : (-> SourceFile Unit)
;;   | doc m%
;;       `emit-owner file` prints compact owner metadata, imports, definitions,
;;       and the next command hint for a source file.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-owner file)
;;       ;; => (void)
;;       ```
;;     %
(def (emit-owner file)
  (displayln "[gerbil-owner] path=" (source-file-path file)
             " package=" (or (source-file-package file) "-")
             " sourceClass=" (source-path-class (source-file-path file))
             " defs=" (length (source-file-definitions file))
             " imports=" (length (source-file-imports file))
             " exports=" (length (source-file-exports file)))
  (when (source-file-prelude file)
    (displayln "|prelude " (source-file-prelude file)))
  (when (source-file-namespace file)
    (displayln "|namespace " (source-file-namespace file)))
  (unless (null? (source-file-imports file))
    (displayln "|imports " (string-join (source-file-imports file) ",")))
  (for-each
   (lambda (defn)
     (displayln "|item kind=" (definition-kind defn)
                " name=" (definition-name defn)
                " selector=" (definition-selector defn)))
   (let (definitions (source-file-definitions file))
     (take definitions (min 30 (length definitions)))))
  (displayln "nextCommand=asp gerbil-scheme search owner "
             (source-file-path file)
             " items --query '<symbol>' --workspace . --view seeds"))
(import :std/crypto/digest)
