;;; -*- Gerbil -*-
;;; Lightweight prime-seeds renderer for the Gerbil search command.

(import :gerbil/gambit
        :gslph/src/constants
        :gslph/src/commands/search-prime-light-list
        (only-in :std/misc/path directory-files path-expand path-normalize)
        (only-in :std/srfi/13
                 string-contains
                 string-index
                 string-index-right
                 string-join
                 string-prefix?
                 string-suffix?))

(export search-prime-light-main
        emit-prime-light
        read-project-package
        project-package-path
        project-package-name
        project-package-manager
        project-package-source-scope-policy
        source-scope-policy-roots
        source-scope-policy-runtime-roots
        source-scope-policy-exclude-directories
        project-root
        drop-project-root
        flag?
        source-path-class
        take-up-to
        relative-owner-path
        workspace-source-roots
        workspace-runtime-roots
        workspace-exclude-directories)

;; : Integer
(def +prime-light-preview-limit+ 12)

;; : String
(def +semantic-language-protocol-id+
  "agent.semantic-protocols.semantic-language")

;; : (List String)
(def +source-extensions+ '(".ss" ".ssi" ".scm" ".sld" ".inc"))
;; : (List String)
(def +config-files+ '("gerbil.pkg" "build.ss"))
;; : (List String)
;; : (List String)
(def +boolean-flags+
  '("--json" "--code" "--names-only" "--changed" "--full" "--more"
    "--artifact"))
;; : (List String)
(def +value-options+
  '("--term" "--query" "--selector" "--workspace" "--from-hook" "--view" "--package"
    "--owner"
    "--iterations" "--max-total-ms" "--max-interface-ms" "--whitelist"
    "--topic" "--intent" "--role" "--level" "--rule" "--finding" "--limit"))

;;; Light package model:
;;; - Keep release launcher dependencies local to this file.
;;; - Full parser/policy modules still own deep semantic facts; prime light only
;;;   needs package identity, dependencies, and source-scope hints.
;; : (-> String (U String #f) (List String) String MaybeSourceScopePolicy ProjectPackage)
(def (make-project-package path name dependencies manager source-scope-policy)
  [path name dependencies manager source-scope-policy])

;; : (-> ProjectPackage String)
(def (project-package-path package)
  (list-ref package 0))

;; : (-> ProjectPackage (U String #f))
(def (project-package-name package)
  (list-ref package 1))

;; : (-> ProjectPackage (List String))
(def (project-package-dependencies package)
  (list-ref package 2))

;; : (-> ProjectPackage String)
(def (project-package-manager package)
  (list-ref package 3))

;; : (-> ProjectPackage MaybeSourceScopePolicy)
(def (project-package-source-scope-policy package)
  (list-ref package 4))

;; : (-> (List String) (List String) (List String) (U String #f) SourceScopePolicy)
(def (make-source-scope-policy roots runtime-roots exclude-directories explanation)
  [roots runtime-roots exclude-directories explanation])

;; : (-> SourceScopePolicy (List String))
(def (source-scope-policy-roots policy)
  (list-ref policy 0))

;; : (-> SourceScopePolicy (List String))
(def (source-scope-policy-runtime-roots policy)
  (list-ref policy 1))

;; : (-> SourceScopePolicy (List String))
(def (source-scope-policy-exclude-directories policy)
  (list-ref policy 2))

;; : (-> SourceScopePolicy (U String #f))
(def (source-scope-policy-explanation policy)
  (list-ref policy 3))

;; : (-> String ParsedData)
(def (read-project-package root)
  (let* ((package-form (read-package-form root))
         (build-scope (read-build-source-scope-policy root)))
    (cond
     (package-form
      (make-project-package "gerbil.pkg"
                            (datum->string (safe-cadr package-form))
                            (package-dependencies package-form)
                            "gxpkg"
                            (or (package-source-scope-policy package-form)
                                build-scope)))
     (build-scope
      (make-project-package "build.ss"
                            #f
                            '()
                            "gxpkg"
                            build-scope))
     (else #f))))

;;; Package reader boundary:
;;; - Protect the lightweight launcher from malformed or absent package files.
;;; - The sequence search returns only the first package form for scope seeding.
;; : (-> String ParsedData)
(def (read-package-form root)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand "gerbil.pkg" root))
            (forms (read-package-forms path)))
       (find package-form? forms)))))

;; : (-> String MaybeSourceScopePolicy)
(def (read-build-source-scope-policy root)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand "build.ss" root))
            (forms (read-package-forms path))
            (targets (build-script-targets forms))
            (runtime-roots (build-target-source-roots targets)))
       (and (pair? runtime-roots)
            (make-source-scope-policy
             '()
             runtime-roots
             '()
             "Inferred from build.ss defbuild-script targets."))))))

;; read-package-forms
;;   : (-> String (List Datum))
;;   | doc m%
;;       `read-package-forms` reads every datum from a package metadata file
;;       under one port scope.
;;
;;       # Examples
;;
;;       ```scheme
;;       (read-package-forms "gerbil.pkg")
;;       ;; => (package-forms ...)
;;       ```
;;     %
;;; Port boundary:
;;; - The helper owns the reader EOF boundary for one open input port.
;;; - Consing each datum onto the recursive tail preserves source order.
(def (read-package-forms path)
  (call-with-input-file path
    read-package-forms/from-port))

;; : (-> InputPort (List Datum))
(def (read-package-forms/from-port port)
  (let ((next (read port)))
    (if (eof-object? next)
      '()
      (cons next (read-package-forms/from-port port)))))

;; : (-> Datum Boolean)
(def (package-form? datum)
  (and (pair? datum) (eq? (car datum) 'package:)))

;;; Dependency projection:
;;; - `depend:` values are optional package metadata.
;;; - The filter-map keeps only string-like dependency entries.
;; : (-> Datum (List String))
(def (package-dependencies datum)
  (let ((deps (package-field-value datum 'depend:)))
    (if deps
      (unique (filter-map datum->string (datum-list-items deps)))
      '())))

;; : (-> Datum MaybeSourceScopePolicy)
(def (package-source-scope-policy datum)
  (let ((policy (package-field-value datum 'policy:)))
    (and policy
         (let ((entry (policy-source-scope-entry policy)))
           (and entry
                (make-source-scope-policy
                 (or (policy-string-list-field entry 'roots:)
                     (policy-string-list-field entry 'source-roots:)
                     (policy-string-list-field entry 'source-root:)
                     '())
                 (or (policy-string-list-field entry 'runtime-roots:)
                     (policy-string-list-field entry 'runtime-root:)
                     '())
                 (or (policy-string-list-field entry 'exclude-directories:)
                     (policy-string-list-field entry 'excluded-directories:)
                     (policy-string-list-field entry 'ignore-directories:)
                     '())
                 (policy-string-field entry 'explanation:)))))))

;; : (-> Policy MaybeSourceScopeEntry)
(def (policy-source-scope-entry policy)
  (if (source-scope-policy-form? policy)
    policy
    (find source-scope-policy-form? (datum-list-items policy))))

;; : (-> Datum Boolean)
(def (source-scope-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(source-scope source-policy project-resolution))))

;; package-field-value
;;   : (-> Datum Symbol Datum)
;;   | doc m%
;;       `package-field-value` returns the value after a package metadata field
;;       symbol, or `#f` when the field is absent.
;;
;;       # Examples
;;
;;       ```scheme
;;       (package-field-value '(package: x depend: (a)) 'depend:)
;;       ;; => (a)
;;       ```
;;     %
;;; Field scan boundary:
;;; - Package forms are flat keyword/value lists.
;;; - The helper advances one cell at a time so malformed tails fail closed.
(def (package-field-value datum field)
  (package-field-value/rest (if (pair? datum) (cdr datum) '()) field))

;; : (-> (List Datum) Symbol Datum)
(def (package-field-value/rest rest field)
  (cond
   ((null? rest) #f)
   ((and (eq? (car rest) field)
         (pair? (cdr rest)))
    (cadr rest))
   (else (package-field-value/rest (cdr rest) field))))

;; : (-> Datum Symbol (List String))
(def (policy-string-list-field entry field)
  (let ((value (package-field-value entry field)))
    (and value (datum-string-list value))))

;; : (-> Datum Symbol (U String #f))
(def (policy-string-field entry field)
  (datum->string (package-field-value entry field)))

;;; String-list projection:
;;; - Accept either a list-like metadata field or one scalar value.
;;; - Unique filtering prevents duplicate source roots from widening scans.
;; : (-> Datum (List String))
(def (datum-string-list value)
  (cond
   ((not value) #f)
   ((pair? value) (unique (filter-map datum->string (datum-list-items value))))
   (else (let ((string-value (datum->string value)))
           (if string-value [string-value] '())))))

;;; Build-script target projection:
;;; - Only the first `defbuild-script` form contributes light source roots.
;;; - Full build semantics stay with Gerbil's build system.
;; : (-> (List Datum) (List String))
(def (build-script-targets forms)
  (let ((form (find build-script-form? forms)))
    (if form
      (build-script-target-value (safe-cadr form))
      '())))

;; : (-> Datum Boolean)
(def (build-script-form? datum)
  (and (pair? datum) (eq? (car datum) 'defbuild-script)))

;;; Target coercion boundary:
;;; - `defbuild-script` may use quoted, scalar, or list-shaped targets.
;;; - filter-map keeps only values that can become source-root strings.
;; : (-> Datum (List String))
(def (build-script-target-value datum)
  (cond
   ((not datum) '())
   ((quoted-datum? datum) (build-script-target-value (safe-cadr datum)))
   ((or (string? datum) (symbol? datum)) [(datum->string datum)])
   (else (filter-map datum->string (datum-list-items datum)))))

;; : (-> Datum Boolean)
(def (quoted-datum? datum)
  (and (pair? datum) (eq? (car datum) 'quote)))

;;; Source-root projection:
;;; - Build targets are converted to unique root prefixes before file walking.
;;; - This keeps repeated targets from expanding the preview scope twice.
;; : (-> (List String) (List String))
(def (build-target-source-roots targets)
  (unique (filter-map build-target-source-root targets)))

;; : (-> String (U String #f))
(def (build-target-source-root target)
  (let ((slash (and target (string-index target #\/))))
    (cond
     ((not target) #f)
     ((not slash) ".")
     ((fx= slash 0) ".")
     (else (substring target 0 slash)))))

;; : (-> String (List String) Boolean)
(def (flag? flag args)
  (member flag args))

;; : (-> String (List String) (U #f String))
(def (option flag args)
  (cond
   ((null? args) #f)
   ((and (pair? (cdr args)) (equal? (car args) flag))
    (cadr args))
   (else (option flag (cdr args)))))

;; positional-args
;;   : (-> (List String) (List String))
;;   | doc m%
;;       `positional-args` returns non-option arguments while preserving their
;;       command-line order.
;;
;;       # Examples
;;
;;       ```scheme
;;       (positional-args '("--workspace" "." "src"))
;;       ;; => ("src")
;;       ```
;;     %
;;; Argument scan boundary:
;;; - Value options consume their following argument without counting it as
;;;   positional.
;;; - Boolean and unknown long flags are skipped so workspace paths remain last.
(def (positional-args args)
  (reverse (positional-args/reversed args '())))

;; : (-> (List String) (List String) (List String))
(def (positional-args/reversed rest out)
  (cond
   ((null? rest) out)
   ((member (car rest) +value-options+)
    (positional-args/reversed
     (if (pair? (cdr rest)) (cddr rest) (cdr rest))
     out))
   ((or (member (car rest) +boolean-flags+)
        (string-prefix? "--" (car rest)))
    (positional-args/reversed (cdr rest) out))
   (else
    (positional-args/reversed (cdr rest) (cons (car rest) out)))))

;; : (-> (List String) ProjectRoot)
(def (project-root args)
  (or (option "--workspace" args)
      (let ((pos (positional-args args)))
        (if (and (pair? pos) (file-directory? (last-item pos)))
          (last-item pos)
          "."))))

;; : (-> (List String) DropProjectRoot)
(def (drop-project-root args)
  (let* ((pos (positional-args args))
         (root? (and (pair? pos) (file-directory? (last-item pos))))
         (root-index (and root? (length pos))))
    (if root?
      (drop-positional-index args root-index)
      args)))

;; drop-positional-index
;;   : (-> (List String) Integer (List String))
;;   | doc m%
;;       `drop-positional-index` removes one positional argument by 1-based
;;       positional index while preserving options and skipped option values.
;;
;;       # Examples
;;
;;       ```scheme
;;       (drop-positional-index '("--full" "." "src") 1)
;;       ;; => ("--full" "src")
;;       ```
;;     %
;;; Drop boundary:
;;; - Option values stay attached to their flags while positional indexes are
;;;   counted over non-option arguments only.
;;; - This keeps workspace root normalization from rewriting command options.
(def (drop-positional-index args target-index)
  (drop-positional-index/walk args '() 0 target-index))

;;; Positional-drop scan:
;;; - The helper owns all branches that preserve option/value attachment while
;;;   counting only non-option arguments toward the target positional index.
;;; - Keeping the index and output accumulator explicit makes the workspace-root
;;;   removal boundary visible without reintroducing mutable recursive closures.
;; : (-> (List String) (List String) Integer Integer (List String))
(def (drop-positional-index/walk rest out index target-index)
  (cond
   ((null? rest) (reverse out))
   ((and (member (car rest) +value-options+)
         (pair? (cdr rest)))
    (drop-positional-index/walk
     (cddr rest)
     (cons (cadr rest) (cons (car rest) out))
     index
     target-index))
   ((member (car rest) +value-options+)
    (drop-positional-index/walk
     (cdr rest)
     (cons (car rest) out)
     index
     target-index))
   ((or (member (car rest) +boolean-flags+)
        (string-prefix? "--" (car rest)))
    (drop-positional-index/walk
     (cdr rest)
     (cons (car rest) out)
     index
     target-index))
   (else
    (let ((next-index (fx1+ index)))
      (if (fx= next-index target-index)
        (drop-positional-index/walk (cdr rest) out next-index target-index)
        (drop-positional-index/walk
         (cdr rest)
         (cons (car rest) out)
         next-index
         target-index))))))

;;; Filesystem probe boundary:
;;; - Missing or inaccessible paths are ordinary negative checks in CLI parsing.
;;; - Exceptions must not escape while detecting a trailing workspace argument.
;; : (-> String Boolean)
(def (file-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

;;; Preview assembly boundary:
;;; - Config files are emitted before source previews.
;;; - The source walk receives only the remaining preview budget.
;; : (-> Root Integer ProjectPackage (List Path))
(def (collect-source-files-preview root limit _package)
  (take-up-to (root-config-files root) limit))

;;; Config preview boundary:
;;; - Package config files are checked in stable order before source traversal.
;;; - Existing files are returned as absolute paths for later normalization.
;; : (-> Root (List Path))
(def (root-config-files root)
  (filter-list
   (lambda (path)
     (file-exists? (path-expand path root)))
   (map (lambda (path) (path-expand path root))
        +config-files+)))

;;; Directory walk boundary:
;;; - The walker shares one mutable budget across nested directories.
;;; - It returns paths in deterministic traversal order for stable prime output.
;; : (-> Root (List String) (List String) Integer (List Path))

;;; Source directory probe:
;;; - Directory lookup failures mean the scan root is unavailable.
;;; - The caller decides whether a missing root is acceptable.
;; : (-> String Boolean)

;; : (-> Root Path String (List String) Boolean)

;;; Source extension predicate:
;;; - The light launcher recognizes only Gerbil-family source suffixes.
;;; - any short-circuits once a configured extension matches.
;; : (-> Path Boolean)
(def (gerbil-source-path? path)
  (any (lambda (extension)
         (string-suffix? extension path))
       +source-extensions+))

;;; Source-class projection:
;;; - Class labels are agent-facing routing hints, not parser facts.
;;; - More specific generated/test/build cases win before generic source.
;; : (-> SourcePath SourceClass)
(def (source-path-class path)
  (cond
   ((equal? path "gerbil.pkg")
    "config")
   ((equal? path "build.ss")
    "package-build")
   ((and (or (string-prefix? "src/build-api/" path)
             (string-prefix? "src/testing/" path))
         (string-suffix? ".ss" path))
    "build-runtime")
   ((or (string-prefix? "t/snapshots/" path)
        (string-contains path "/snapshots/"))
    "snapshot-output")
   ((or (string-prefix? "t/scenarios/" path)
        (string-contains path "/scenarios/"))
    "policy-scenario")
   ((or (string-prefix? "t/fixtures/" path)
        (string-contains path "/fixtures/"))
    "fixture")
   ((or (string-prefix? "t/" path)
        (string-contains path "/t/"))
    "test")
   ((or (string-contains path "/generated/")
        (string-contains path ".generated."))
    "generated")
   ((or (string-prefix? "src/check-fast/" path)
        (equal? path "src/search-fast/gerbil-scheme-search-extension.ss")
        (equal? path "src/search-fast/gerbil-scheme-search-pattern.ss"))
    "native-fast-runtime")
   ((or (string-prefix? "src/" path)
        (string-prefix? "bin/" path))
    "runtime-source")
   (else "source")))

;;; Boundary:
;;; - This command path is intentionally package/source-scope only.
;;; - ASP owns dependency source indexing, route topology, symbol indexes, and
;;;   reasoning-tree state built from this provider-owned workspace map.
;; : (-> Args Integer )
(def (search-prime-light-main args)
  (if (and (pair? args) (equal? (car args) "prime"))
    (let ((tail (cdr args)))
      (let ((root (path-normalize (project-root tail))))
        (let ((normalized-args (drop-project-root tail)))
          (let ((json? (flag? "--json" normalized-args)))
            (if json?
              (error "search prime light does not render json")
              (emit-prime-light root))))))
    (error "search-prime-light requires prime view")))

;;; Boundary:
;;; - The seed packet exposes durable navigation facts only.
;;; - It must not parse source forms or produce graph-derived rank.
;; : (-> Root Integer )
(def (emit-prime-light root)
  (let* ((root (path-normalize root))
         (package (read-project-package root))
         (files (source-files-light root package)))
    (displayln "[gerbil-search-prime] root=" root
               " filePreview=" (length files)
               " definitions=skipped"
               " analysis=structure"
               " nativeSyntaxFacts=skipped"
               " topology=asp-owned")
    (displayln "|language id=" +language-id+ " provider=" +provider-id+
               " parser=package-manager")
    (emit-package-line-light package)
    (displayln "|factScope sourceForms=skipped graphRank=asp-owned sourceIndex=asp-owned")
    (for-each
     (lambda (path)
       (let ((owner (relative-owner-path root path)))
         (displayln "owner:path(" owner ")"
                    " package=" (or (and package (project-package-name package)) "-")
                    " sourceClass=" (source-path-class owner)
                    " defs=skipped"
                    " imports=skipped"
                    " next=owner:" owner)))
     (take files (min +prime-light-preview-limit+ (length files))))
    (displayln "recommendedNext=asp gerbil-scheme search lexical --query '<term>' --workspace . --view seeds")
    (displayln "nextCommand=asp gerbil-scheme search lexical --query '<term>' --workspace . --view seeds"))
  0)

;; : (-> Root MaybePackage (List Path) )
(def (source-files-light root package)
  (if package
    (collect-source-files-preview root +prime-light-preview-limit+ package)
    '()))

;; : (-> MaybeSourceScopePolicy (List String) )
(def (workspace-source-roots policy)
  (let ((roots (and policy (source-scope-policy-roots policy))))
    (if (and roots (pair? roots)) roots ["."])))

;; : (-> MaybeSourceScopePolicy (List String) )
(def (workspace-runtime-roots policy)
  (let ((roots (and policy (source-scope-policy-runtime-roots policy))))
    (if roots roots '())))

;; : (-> MaybeSourceScopePolicy (List String) )
(def (workspace-exclude-directories policy)
  (let ((dirs (and policy (source-scope-policy-exclude-directories policy))))
    (if dirs dirs '())))

;; : (-> MaybePackage Unit )
(def (emit-package-line-light package)
  (when package
    (displayln "|package name=" (or (project-package-name package) "-")
               " path=" (project-package-path package)
               " packageManager=" (project-package-manager package)
               " dependencies=" (string-join (project-package-dependencies package) ","))))

;; : (-> Root Path Path )
(def (relative-owner-path root path)
  (let* ((root* (strip-trailing-path-separator (path-normalize root)))
         (path* (path-normalize path))
         (prefix (string-append root* "/")))
    (if (string-prefix? prefix path*)
      (substring path* (string-length prefix) (string-length path*))
      path*)))

;;; Path normalization boundary:
;;; - Remove only trailing separators after path-normalize has run.
;;; - Relative owner projection depends on this stable root prefix.
;; : (-> Path Path )
(def (strip-trailing-path-separator path)
  (let ((last-path-char
         (string-index-right path
                             (lambda (char)
                               (not (char=? char #\/))))))
    (if (and last-path-char
             (< (fx1+ last-path-char) (string-length path)))
      (substring path 0 (fx1+ last-path-char))
      path)))
