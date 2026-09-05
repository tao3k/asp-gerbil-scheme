;;; -*- Gerbil -*-
;;; Lightweight parser surface for owner-items.

(import :gerbil/expander
        :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/parser/definition-syntax definitions-from-form)
        :asp-gerbil-scheme/src/parser/exports
        :asp-gerbil-scheme/src/parser/model
        (only-in :asp-gerbil-scheme/src/parser/package
                 agent-policy-disabled-rules
                 package-agent-policy
                 package-dependencies
                 package-form?
                 package-macro-governance-policy
                 package-source-scope-policy
                 package-test-directory-policy
                 read-package-forms
                 source-scope-policy-exclude-directories
                 source-scope-policy-roots
                 source-scope-policy-runtime-roots
                 test-directory-policy-allowed-directories)
        :asp-gerbil-scheme/src/parser/selectors
        :asp-gerbil-scheme/src/parser/support
        :asp-gerbil-scheme/src/parser/syntax
        (only-in :std/misc/list unique)
        (only-in :std/misc/ports open-output-string read-file-lines)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 find take)
        (only-in :std/srfi/13
                 string-contains
                 string-join
                 string-prefix?
                 string-trim)
        (only-in :std/sugar cut filter hash ormap))

(export owner-items-source-path?
        parse-owner-items-source-file
        owner-items-syntax-fact-json
        source-file::t
        source-file-path
        source-file-line-count
        source-file-package
        source-file-prelude
        source-file-namespace
        source-file-imports
        source-file-exports
        source-file-includes
        source-file-definitions
        source-file-calls
        source-file-forms
        source-file-module-imports
        source-file-module-exports
        source-file-parse-error
        definition-name
        definition-kind
        definition-path
        definition-start
        definition-end
        definition-formals
        definition-arity
        definition-selector)

;; (List FileExtension)
(def +owner-items-source-extensions+ '(".ss" ".ssi" ".scm" ".sld"))
;; (List ConfigFileName)
(def +owner-items-config-files+ '("gerbil.pkg" "build.ss"))
;; Exact-owner Scheme parsing is intentionally bounded. Shared Rust owns bulk
;; and oversized-source indexing.
(def +owner-items-max-source-bytes+ (* 1024 1024))
(def +owner-items-max-source-lines+ 50000)

;; : (-> Path Boolean )
(def (owner-items-source-path? path)
  (or (member (path-extension path) +owner-items-source-extensions+)
      (member (path-strip-directory path) +owner-items-config-files+)))

;;; Parse boundary:
;;; - Owner-items needs a lightweight SourceFile without the full project walk.
;;; - Native forms, definitions, calls, imports, and top-forms are collected in
;;;   one pass so CLI owner browsing stays cheap and parser-owned.
;; : (-> ProjectRoot OwnerPath [MaybeLimit] [Terms] SourceFile )
(def (parse-owner-items-source-file root path . maybe-limit/terms)
  (let* ((fullpath (source-full-path root path))
         (relpath (relative-path root fullpath))
         (line-count (owner-source-line-count fullpath))
         (read-result (owner-read-native-forms fullpath))
         (forms (vector-ref read-result 0))
         (parse-error (vector-ref read-result 1))
         (initial-package (vector-ref read-result 2))
         (initial-prelude (vector-ref read-result 3))
         (initial-namespace (vector-ref read-result 4))
         (call-budget (if (pair? maybe-limit/terms) 0 #f))
         (call-terms (if (and (pair? maybe-limit/terms)
                              (pair? (cdr maybe-limit/terms)))
                       (cadr maybe-limit/terms)
                       '())))
    (let ((rest forms)
          (package initial-package)
          (prelude initial-prelude)
          (namespace initial-namespace)
          (imports '())
          (exports '())
          (includes '())
          (definitions '())
          (calls '())
          (top-forms '())
          (module-imports '())
          (module-exports '()))
      (while (pair? rest)
        (let* ((form (car rest))
               (datum (syntax->datum form))
               (head (form-datum-head datum))
               (metadata-value (form-metadata-value datum (cdr rest)))
               (next-rest (form-next-rest datum rest))
               (top-form (top-form-from relpath form datum))
               (form-calls
                (if (owner-call-collection-open? call-budget)
                  (owner-filtered-calls-from-form relpath form datum
                                                  call-terms call-budget)
                  '()))
               (next-calls (append form-calls calls)))
          (set! top-forms (cons top-form top-forms))
          (when call-budget
            (set! call-budget (max 0 (- call-budget (length form-calls)))))
          (cond
           ((eq? head 'package:)
            (set! package (datum->string metadata-value)))
           ((eq? head 'prelude:)
            (set! prelude (datum->string metadata-value)))
           ((eq? head 'namespace:)
            (set! namespace (datum->string metadata-value)))
           ((eq? head 'import)
            (set! imports (append (module-refs datum) imports))
            (set! module-imports
              (append (module-import-facts-from-form relpath form)
                      module-imports)))
           ((eq? head 'export)
            (set! exports (append (export-symbols datum) exports))
            (set! module-exports
              (append (module-export-facts-from-form relpath form)
                      module-exports)))
           ((eq? head 'include)
            (set! includes (append (string-datums datum) includes)))
           ((member head +definition-heads+)
            (set! definitions
              (append (definitions-from-form relpath form datum) definitions))
            (set! calls next-calls))
           (else
            (set! calls next-calls)))
          (set! rest next-rest)))
      (make-source-file relpath line-count package prelude namespace
                        (unique imports)
                        (unique exports)
                        (unique includes)
                        (reverse definitions)
                        (reverse calls)
                        (reverse top-forms)
                        (reverse module-imports)
                        (reverse module-exports)
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        parse-error))))

;; : (-> MaybeInteger Boolean )
(def (owner-call-collection-open? call-budget)
  (or (not call-budget) (> call-budget 0)))

;; : (-> Relpath Form Datum Terms MaybeInteger (List CallFact) )
(def (owner-filtered-calls-from-form relpath form datum terms call-budget)
  (let (calls (calls-from-form relpath form datum))
    (cond
     ((null? terms) (owner-take calls call-budget))
     (else (owner-filtered-calls/limit calls terms call-budget [])))))

;; : (-> (List CallFact) Terms MaybeInteger (List CallFact) (List CallFact) )
(def (owner-filtered-calls/limit calls terms call-budget out)
  (cond
   ((or (null? calls)
        (and call-budget (<= call-budget 0)))
    (reverse out))
   ((owner-call-fact-matches-any-term? (car calls) terms)
    (owner-filtered-calls/limit
     (cdr calls) terms
     (and call-budget (- call-budget 1))
     (cons (car calls) out)))
   (else
    (owner-filtered-calls/limit (cdr calls) terms call-budget out))))

;; : (-> (List Dyn) MaybeInteger (List Dyn) )
(def (owner-take values maybe-limit)
  (if maybe-limit
    (take values (min maybe-limit (length values)))
    values))

;;; Call-term filter boundary:
;;; - Use ormap/cut so owner item browsing stays a bounded predicate pass.
;;; - Terms are agent query tokens, not source selectors or regexes.
;; : (-> CallFact Terms Boolean )
(def (owner-call-fact-matches-any-term? fact terms)
  (ormap (cut owner-call-fact-matches-term? fact <>) terms))

;;; Call-field boundary:
;;; - Match only callee, caller, and parser-owned argument strings.
;;; - Filtering non-strings keeps mixed syntax facts from becoming ad hoc text.
;; : (-> CallFact Term Boolean )
(def (owner-call-fact-matches-term? fact term)
  (ormap (cut string-contains <> term)
         (filter string?
                 (append [(call-fact-callee fact)
                          (or (call-fact-caller fact) "")]
                         (call-fact-arguments fact)))))

;;; Syntax projection:
;;; - Owner-items exposes imports, exports, calls, and top forms in one stream.
;;; - Stable sorting below keeps agent-visible output deterministic.
;; : (-> SourceFile (List SyntaxFactJson) )
(def (owner-items-syntax-fact-json file . maybe-root)
  (stable-owner-items-syntax-facts
   (append
    (owner-package-fact-jsons file maybe-root)
    (map owner-module-import-fact-json (source-file-module-imports file))
    (map owner-module-export-fact-json (source-file-module-exports file))
    (map owner-call-fact-json (source-file-calls file))
    (map owner-top-form-fact-json (source-file-forms file)))))

;;; Package config boundary:
;;; - gerbil.pkg is not a Gerbil module, but it is an owner with package facts.
;;; - Use parser/package helpers so owner-items does not invent a second
;;;   package metadata parser.
;; : (-> SourceFile (List Root) (List SyntaxFactJson) )
(def (owner-package-fact-jsons file maybe-root)
  (let (root (and (pair? maybe-root) (car maybe-root)))
    (if (and root
             (equal? (path-strip-directory (source-file-path file))
                     "gerbil.pkg"))
      (with-catch
       (lambda (_) '())
       (lambda ()
         (let* ((package-path (path-expand (source-file-path file) root))
                (form (find package-form? (read-package-forms package-path))))
           (if form
             [(owner-package-fact-json file form)]
             '()))))
      '())))

;;; Package item projection:
;;; - One package item is enough for owner browsing and query routing.
;;; - Field-level values stay in queryKeys/fields so future renderers can split
;;;   them without changing parser ownership.
;; : (-> SourceFile PackageForm SyntaxFactJson )
(def (owner-package-fact-json file form)
  (let* ((path (source-file-path file))
         (name (or (source-file-package file)
                   (owner-package-form-name form)
                   "package"))
         (dependencies (package-dependencies form))
         (query-keys
          (unique
           (filter string?
                   (append [path
                            "gerbil.pkg"
                            "package"
                            "package:"
                            name
                            "depend:"
                            "policy:"]
                           dependencies
                           (owner-package-policy-query-keys form))))))
    (hash (id (owner-syntax-fact-id "package" path name 1))
          (kind "package")
          (source "native-parser")
          (languageKind "package-form")
          (name name)
          (ownerPath path)
          (location (owner-fact-location-json path 1 1))
          (queryKeys query-keys)
          (fields (hash (role "package")
                        (dependencies (string-join dependencies ","))
                        (sourceRoots
                         (string-join
                          (owner-package-source-roots form) ","))
                        (runtimeRoots
                         (string-join
                          (owner-package-runtime-roots form) ","))
                        (excludeDirectories
                         (string-join
                          (owner-package-exclude-directories form) ","))
                        (agentDisabledRules
                         (string-join
                          (owner-package-agent-disabled-rules form) ",")))))))

;; : (-> Boolean (List String) (List String) )
(def (owner-package-policy-key-group enabled? keys)
  (if enabled? keys '()))
;; : (-> PackageForm (List String) )
(def (owner-package-policy-query-key-groups form)
  [(owner-package-policy-key-group
    (package-test-directory-policy form)
    ["test-directory" "test-directories" "allowed-test-directories"])
   (owner-package-policy-key-group
    (package-macro-governance-policy form)
    ["macro-governance" "allow-generated"])
   (owner-package-policy-key-group
    (package-source-scope-policy form)
    ["source-scope" "source-roots" "runtime-roots" "exclude-directories"])
   (owner-package-policy-key-group
    (package-agent-policy form)
    ["agent-policy" "disabled-rules"])])
;; : (-> PackageForm (List String) )
(def (owner-package-policy-query-keys form)
  (apply append
         (append
          (owner-package-policy-query-key-groups form)
          [(owner-package-test-directories form)
           (owner-package-source-roots form)
           (owner-package-runtime-roots form)
           (owner-package-exclude-directories form)
           (owner-package-agent-disabled-rules form)])))

;; : (-> PackageForm MaybeString )
(def (owner-package-form-name form)
  (let (name (and (pair? (cdr form)) (cadr form)))
    (cond
     ((symbol? name) (symbol->string name))
     ((string? name) name)
     (else #f))))

;; : (-> PackageForm (List String) )
(def (owner-package-test-directories form)
  (let (policy (package-test-directory-policy form))
    (if policy
      (test-directory-policy-allowed-directories policy)
      '())))

;; : (-> PackageForm (List String) )
(def (owner-package-source-roots form)
  (let (policy (package-source-scope-policy form))
    (if policy
      (source-scope-policy-roots policy)
      '())))

;; : (-> PackageForm (List String) )
(def (owner-package-runtime-roots form)
  (let (policy (package-source-scope-policy form))
    (if policy
      (source-scope-policy-runtime-roots policy)
      '())))

;; : (-> PackageForm (List String) )
(def (owner-package-exclude-directories form)
  (let (policy (package-source-scope-policy form))
    (if policy
      (source-scope-policy-exclude-directories policy)
      '())))

;; : (-> PackageForm (List String) )
(def (owner-package-agent-disabled-rules form)
  (let (policy (package-agent-policy form))
    (if policy
      (agent-policy-disabled-rules policy)
      '())))

;;; Stability boundary:
;;; - Syntax facts may be gathered from several parser surfaces.
;;; - Sorting by synthetic id prevents output churn when collection order moves.
;; : (-> (List SyntaxFactJson) (List SyntaxFactJson) )
(def (stable-owner-items-syntax-facts facts)
  (sort facts
        (lambda (a b)
          (string<? (hash-get a 'id) (hash-get b 'id)))))

;; : (-> ModuleImportFact SyntaxFactJson )
(def (owner-module-import-fact-json fact)
  (hash (id (owner-syntax-fact-id "import"
                                   (module-import-fact-path fact)
                                   (module-import-fact-module fact)
                                   (module-import-fact-start fact)))
        (kind "import")
        (source "native-parser")
        (languageKind "module-import")
        (name (module-import-fact-module fact))
        (ownerPath (module-import-fact-path fact))
        (location (owner-fact-location-json (module-import-fact-path fact)
                                            (module-import-fact-start fact)
                                            (module-import-fact-end fact)))
        (queryKeys (unique [(module-import-fact-module fact)
                            (module-import-fact-modifier fact)
                            (module-import-fact-phase fact)
                            (module-import-fact-path fact)]))
        (fields (hash (role "")
                      (phase (module-import-fact-phase fact))
                      (modifier (module-import-fact-modifier fact))
                      (symbols (module-import-fact-symbols fact))
                      (alias (or (module-import-fact-alias fact) ""))))))

;; : (-> ModuleExportFact SyntaxFactJson )
(def (owner-module-export-fact-json fact)
  (hash (id (owner-syntax-fact-id "export"
                                  (module-export-fact-path fact)
                                  (module-export-fact-name fact)
                                  (module-export-fact-start fact)))
        (kind "export")
        (source "native-parser")
        (languageKind "module-export")
        (name (module-export-fact-name fact))
        (ownerPath (module-export-fact-path fact))
        (location (owner-fact-location-json (module-export-fact-path fact)
                                            (module-export-fact-start fact)
                                            (module-export-fact-end fact)))
        (queryKeys (unique [(module-export-fact-name fact)
                            (module-export-fact-modifier fact)
                            (or (module-export-fact-alias fact) "")
                            (or (module-export-fact-module fact) "")
                            (module-export-fact-path fact)]))
        (fields (hash (role "")
                      (modifier (module-export-fact-modifier fact))
                      (symbols (module-export-fact-symbols fact))
                      (alias (or (module-export-fact-alias fact) ""))
                      (module (or (module-export-fact-module fact) ""))))))

;; : (-> CallFact SyntaxFactJson )
(def (owner-call-fact-json fact)
  (hash (id (owner-syntax-fact-id "call"
                                  (call-fact-path fact)
                                  (call-fact-callee fact)
                                  (call-fact-start fact)))
        (kind "call")
        (source "native-parser")
        (languageKind "call")
        (name (call-fact-callee fact))
        (ownerPath (call-fact-path fact))
        (location (owner-fact-location-json (call-fact-path fact)
                                            (call-fact-start fact)
                                            (call-fact-end fact)))
        (queryKeys (unique [(call-fact-callee fact)
                            (or (call-fact-caller fact) "")
                            (call-fact-path fact)]))
        (fields (hash (role "")
                      (caller (or (call-fact-caller fact) ""))
                      (arity (call-fact-arity fact))
                      (arguments (call-fact-arguments fact))))))

;; : (-> TopForm SyntaxFactJson )
(def (owner-top-form-fact-json fact)
  (let ((name (owner-top-form-head-name fact))
        (kind (owner-top-form-kind-name fact)))
    (hash (id (owner-syntax-fact-id "top-form"
                                    (top-form-path fact)
                                    name
                                    (top-form-start fact)))
          (kind "top-form")
          (source "native-parser")
          (languageKind kind)
          (name name)
          (ownerPath (top-form-path fact))
          (location (owner-fact-location-json (top-form-path fact)
                                              (top-form-start fact)
                                              (top-form-end fact)))
          (queryKeys (unique [name
                              kind
                              (top-form-path fact)]))
          (fields (hash (role kind))))))

;; : (-> TopForm String )
(def (owner-top-form-head-name fact)
  (let (head (top-form-head fact))
    (if (string? head) head "form")))

;; : (-> TopForm String )
(def (owner-top-form-kind-name fact)
  (let (kind (top-form-kind fact))
    (if (string? kind) kind "form")))

;; : (-> Kind Path Name Start String )
(def (owner-syntax-fact-id kind path name start)
  (string-append kind ":" path ":" name ":" (number->string start)))

;; : (-> Path Start End Json )
(def (owner-fact-location-json path start end)
  (hash (path path)
        (lineRange (string-append (number->string start)
                                  "-"
                                  (number->string end)))))

;;; Size boundary:
;;; - Scan once with constant memory before native form materialization.
;;; - Reject oversized owners instead of retaining both a line list and forms.
;; : (-> SourcePath Integer )
(def (owner-source-line-count path)
  (let (bytes (file-info-size (file-info path)))
    (when (> bytes +owner-items-max-source-bytes+)
      (error "owner source exceeds Scheme parse budget; use asp search/query"
             path bytes))
    (call-with-input-file path
      (lambda (port)
        (let (lines 1)
          (let loop ()
            (let (char (read-char port))
              (if (eof-object? char)
                lines
                (begin
                  (when (char=? char #\newline)
                    (set! lines (+ lines 1)))
                  (when (> lines +owner-items-max-source-lines+)
                    (error "owner source exceeds Scheme parse line budget; use asp search/query"
                           path lines))
                  (loop))))))))))

;;; Read strategy:
;;; - Prefer core-read-module for ordinary Gerbil modules.
;;; - Fall back to syntax reading for #lang, custom preludes, config, and errors.
;; : (-> SourcePath OwnerReadResult )
(def (owner-read-native-forms path)
  (with-catch
   (lambda (exn)
     (vector '() (exception->string exn) #f #f #f))
   (lambda ()
     (if (member (path-extension path) +owner-items-source-extensions+)
       (if (owner-file-starts-with-lang? path)
         (owner-read-lang-syntax-forms path)
         (owner-read-syntax-forms path))
       (owner-read-syntax-forms path)))))

;;; Syntax fallback:
;;; - Suppress reader chatter so owner-items output remains protocol text.
;;; - Wrap single forms as a list to match core-read-module body shape.
;; : (-> SourcePath OwnerReadResult )
(def (owner-read-syntax-forms path)
  (parameterize ((current-output-port (open-output-string))
                 (current-error-port (open-output-string)))
    (let (body (read-syntax-from-file path))
      (vector (if (stx-list? body) (stx-map identity body) [body])
              #f #f #f #f))))

;;; #lang fallback:
;;; - Gerbil's module reader does not own non-Gerbil #lang headers.
;;; - Drop the language line and read the remaining body forms directly.
;; : (-> SourcePath OwnerReadResult )
(def (owner-read-lang-syntax-forms path)
  (let* ((lines (read-file-lines path))
         (body-text (string-join (cdr lines) "\n"))
         (forms
          (call-with-input-string body-text
            (lambda (port)
              (let ((out '())
                    (done? #f))
                (while (not done?)
                  (let (next (read-syntax port))
                    (if (eof-object? next)
                      (set! done? #t)
                      (set! out (cons next out)))))
                (reverse out))))))
    (vector forms #f #f #f #f)))

;;; Header probe:
;;; - A failed file read should not block owner browsing.
;;; - The result only selects the lightweight read strategy above.
;; : (-> SourcePath Boolean )
(def (owner-file-starts-with-lang? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let (lines (read-file-lines path))
       (and (pair? lines) (string-prefix? "#lang" (car lines)))))))

;;; Prelude probe:
;;; - Non-core preludes can break core-read-module in this standalone path.
;;; - The first lines are enough because package metadata lives at the top.
;; : (-> SourcePath Boolean )
(def (owner-file-has-non-core-prelude? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (ormap
      (lambda (line)
        (and (string-prefix? "prelude:" (string-trim line))
             (not (string-contains line ":gerbil/core"))))
      (let (lines (read-file-lines path))
        (take lines (min 12 (length lines))))))))
