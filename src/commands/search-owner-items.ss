;;; -*- Gerbil -*-
;;; Owner-items rendering over definitions plus parser-owned owner facts.

(import :asp-gerbil-scheme/src/parser/owner-items
        (only-in :asp-gerbil-scheme/src/parser/selectors item-structural-selector)
        :asp-gerbil-scheme/src/protocol/json
        :asp-gerbil-scheme/src/support/args
        (only-in :std/srfi/1 take)
        (only-in :std/srfi/13
                 string-contains
                 string-empty?
                 string-prefix?
                 string-suffix?)
        (only-in :std/sugar cut filter filter-map hash ormap))

(export emit-owner-items
        emit-owner-items-command
        matching-owner-syntax-facts
        owner-item-query-terms)

;; Integer
(def +owner-items-default-limit+ 80)

;;; CLI boundary:
;;; - This command is the fast owner-items materializer behind search owner.
;;; - It validates unsupported output modes before touching parser facts.
;; : (-> Args ExitCode )
(def (emit-owner-items-command args)
  (let (args (if (and (pair? args) (equal? (car args) "search"))
              (cdr args)
              args))
    (when (flag? "--code" args)
      (error "fast owner-items does not handle --code"))
    (let* ((root (path-normalize (project-root args)))
           (args (drop-project-root args))
           (json? (flag? "--json" args))
           (positionals (positional-args args))
           (owner (and (pair? positionals) (car positionals)))
           (items? (and (pair? (cdr positionals))
                        (equal? (cadr positionals) "items"))))
      (unless owner (error "search owner requires a path"))
      (unless items? (error "fast owner-items requires the items view"))
      (let* ((query (option "--query" args))
             (terms (owner-item-query-terms query))
             (limit (owner-items-limit args))
             (file (parse-explicit-owner-items-file root owner limit terms))
             (definition-matches
              (matching-definitions (source-file-definitions file) terms))
             (syntax-matches []))
        (if json?
          (write-json-line
           (owner-items-evidence-packet file
                                        definition-matches
                                        syntax-matches
                                        limit))
        (if (flag? "--names-only" args)
          (begin
            (for-each (lambda (defn) (displayln (definition-name defn)))
                      (take definition-matches
                            (min limit (length definition-matches)))))
          (emit-owner-items file definition-matches syntax-matches limit))))
      0)))

;;; Parse boundary:
;;; - Owner paths are resolved inside the requested project root.
;;; - The parser owner builds the source file; command code only validates path shape.
;; : (-> Root OwnerPath SourceFile )
(def (parse-explicit-owner-items-file root owner . maybe-limit/terms)
  (let* ((root (path-normalize root))
         (path (path-normalize (path-expand owner root))))
    (unless (and (owner-items-path-within-root? root path)
                 (owner-items-source-path? path)
                 (file-exists? path))
      (error "owner not found" owner))
    (if (and (pair? maybe-limit/terms)
             (pair? (cdr maybe-limit/terms)))
      (parse-owner-items-source-file root path
                                     (car maybe-limit/terms)
                                     (cadr maybe-limit/terms))
      (parse-owner-items-source-file root path))))

(def (owner-items-path-within-root? root path)
  (let* ((root (path-normalize (path-expand root)))
         (path (path-normalize (path-expand path root)))
         (prefix (if (string-suffix? "/" root)
                   root
                   (string-append root "/"))))
    (or (equal? path root)
        (string-prefix? prefix path))))

;;; Limit boundary:
;;; - Missing limits use the public default.
;;; - Invalid numeric values fail before rendering partial output.
;; : (-> Args Nat )
(def (owner-items-limit args)
  (let* ((value (option "--limit" args))
         (parsed (and value (string->number value))))
    (cond
     ((not value) +owner-items-default-limit+)
     ((and (integer? parsed) (>= parsed 0)) parsed)
     (else (error "invalid owner-items --limit" value)))))

;;; Definition filter:
;;; - Empty term lists are an all-definitions owner browse.
;;; - Non-empty terms reuse the single-definition predicate below.
;; : (-> (List Definition) (List Term) (List Definition) )
(def (matching-definitions definitions terms)
  (if (null? terms)
    definitions
    (filter (cut definition-matches-any-term? <> terms) definitions)))

;;; Definition predicate:
;;; - Terms are alternatives, matching owner-items pipe semantics.
;;; - The predicate stays separate so syntax facts can use their own fields.
;; : (-> Definition (List Term) Boolean )
(def (definition-matches-any-term? defn terms)
  (ormap (cut definition-matches-term? defn <>) terms))

;;; Definition term predicate:
;;; - Match normalized parser-owned definition fields, not source text.
;;; - Selector matching keeps line-range searches available to agents.
;; : (-> Definition Term Boolean )
(def (definition-matches-term? defn term)
  (ormap (cut string-contains <> term)
         [(definition-name defn)
          (definition-kind defn)]))

;;; Boundary:
;;; - Render definition matches before syntax facts so exact owner symbols stay first.
;;; - Syntax facts keep parser provenance visible instead of reading source text.
;;; Boundary:
;;; - Merge definition matches with parser-owned syntax facts for one owner.
;;; - Keep rendering line-oriented so ASP fast-path receipts stay compact.
;; : (-> SourceFile Matches SyntaxMatches Unit )
(def (emit-owner-items file definition-matches syntax-matches . maybe-limit)
  (let* ((limit (owner-items-effective-limit maybe-limit))
         (shown-definitions
          (take definition-matches (min limit (length definition-matches))))
         (syntax-budget (max 0 (- limit (length shown-definitions))))
         (shown-syntax
          (take syntax-matches (min syntax-budget (length syntax-matches)))))
  (displayln "[gerbil-owner-items] path=" (source-file-path file)
             " matches=" (+ (length definition-matches)
                             (length syntax-matches))
             " shown=" (+ (length shown-definitions)
                           (length shown-syntax))
             " limit=" limit)
  (for-each
   (lambda (defn)
     (emit-owner-definition-item defn))
   shown-definitions)
  (for-each (lambda (fact)
              (emit-owner-syntax-item fact))
            shown-syntax)))

;; : (-> Definition Unit)
(def (emit-owner-definition-item defn)
  (let* ((selector (definition-selector defn))
         (proof-span (owner-item-source-span (definition-path defn)
                                             (definition-start defn)
                                             (definition-end defn))))
    (displayln "|item kind=" (definition-kind defn)
               " name=" (definition-name defn)
               " readSelector=" selector
               " proofSpan=" proof-span
               " source=native-parser"
               " nextCommand=\"asp gerbil-scheme query --selector "
               selector
               " --workspace . --projection source\"")))

(def (owner-items-effective-limit maybe-limit)
  (if (and (pair? maybe-limit) (car maybe-limit))
    (car maybe-limit)
    +owner-items-default-limit+))

;;; Boundary: syntax items preserve parser fact ownership while giving owner-items operator granularity.
;; : (-> SyntaxFact Unit )
(def (emit-owner-syntax-item fact)
  (let* ((location (hash-get fact 'location))
         (path (hash-get location 'path))
         (line-range (hash-get location 'lineRange))
         (kind (hash-get fact 'kind))
         (name (hash-get fact 'name)))
  (displayln "|item kind=" kind
             " name=" name
             " evidenceSelector=" (owner-item-structural-selector path kind name)
             " graphOnly=true"
             " proofSpan=" path ":" line-range
             " source=" (hash-get fact 'source)
             " languageKind=" (hash-get fact 'languageKind)
             (owner-syntax-role-segment fact))))

;; : (-> Path Kind Name Selector)
(def (owner-item-structural-selector path kind name)
  (item-structural-selector path kind name))

;; : (-> SourceFile (List Definition) (List SyntaxFact) Nat Json)
(def (owner-items-evidence-packet file definition-matches syntax-matches limit)
  (let* ((shown-definitions
          (take definition-matches (min limit (length definition-matches))))
         (syntax-budget (max 0 (- limit (length shown-definitions))))
         (shown-syntax
          (take syntax-matches (min syntax-budget (length syntax-matches)))))
    (hash (schemaId "semantic-owner-item-evidence.v2")
          (schemaVersion "2")
          (language "gerbil-scheme")
          (owner (hash (path (source-file-path file))))
          (limit limit)
          (matches (+ (length definition-matches)
                      (length syntax-matches)))
          (shown (+ (length shown-definitions)
                    (length shown-syntax)))
          (items (append (map owner-definition-evidence-json shown-definitions)
                         (map owner-syntax-evidence-json shown-syntax)))
          (edges (hash (calls (map owner-syntax-call-edge-json
                                   (filter owner-syntax-call-fact?
                                           shown-syntax))))))))

;; : (-> Definition Json)
(def (owner-definition-evidence-json defn)
  (hash (kind (definition-kind defn))
        (name (definition-name defn))
        (readSelector (definition-selector defn))
        (proof (hash (source "native-parser")
                     (span (owner-item-source-span (definition-path defn)
                                                   (definition-start defn)
                                                   (definition-end defn)))))
        (next (hash (readCommand
                     (string-append
                      "asp gerbil-scheme query --selector '"
                      (definition-selector defn)
                      "' --workspace . --projection source"))))))

;; : (-> Path Line Line Selector)
(def (owner-item-source-span path start end)
  (string-append path ":"
                 (number->string start)
                 "-"
                 (number->string end)))

;; : (-> SyntaxFact Json)
(def (owner-syntax-evidence-json fact)
  (let* ((location (hash-get fact 'location))
         (path (hash-get location 'path))
         (line-range (hash-get location 'lineRange))
         (kind (hash-get fact 'kind))
         (name (hash-get fact 'name)))
    (hash (kind kind)
          (name name)
          (evidenceSelector (owner-item-structural-selector path kind name))
          (graphOnly #t)
          (proof (hash (source (hash-get fact 'source))
                       (span (string-append path ":" line-range))))
          (languageKind (hash-get fact 'languageKind))
          (role (syntax-fact-field-string fact 'role)))))

;; : (-> SyntaxFact Boolean)
(def (owner-syntax-call-fact? fact)
  (equal? (hash-get fact 'languageKind) "call"))

;; : (-> SyntaxFact Json)
(def (owner-syntax-call-edge-json fact)
  (let* ((location (hash-get fact 'location))
         (path (hash-get location 'path))
         (line-range (hash-get location 'lineRange))
         (name (hash-get fact 'name)))
    (hash (callee name)
          (evidenceSelector (owner-item-structural-selector path "call" name))
          (proof (hash (source (hash-get fact 'source))
                       (span (string-append path ":" line-range)))))))

;; : (-> SyntaxFact String )
(def (owner-syntax-role-segment fact)
  (let (role (syntax-fact-field-string fact 'role))
    (if (string-empty? role)
      ""
      (string-append " role=" role))))

;;; Boundary:
;;; - Match against structural fields/queryKeys, not raw source text.
;;; - Preserve parser-owned fact provenance while filtering owner items.
;; : (-> SourceFile (List String) (List SyntaxFact) )
(def (matching-owner-syntax-facts file terms . maybe-limit/root)
  (let* ((limit (and (pair? maybe-limit/root)
                     (car maybe-limit/root)))
         (root (and (pair? maybe-limit/root)
                    (pair? (cdr maybe-limit/root))
                    (cadr maybe-limit/root))))
    (cond
     ((and limit (<= limit 0)) '())
     (else
      (let (facts (owner-items-syntax-fact-json file root))
        (if limit
          (matching-owner-syntax-facts/limit facts terms limit [])
          (filter (cut syntax-fact-matches-any-term? <> terms) facts)))))))

;; : (-> (List SyntaxFact) (List String) Integer (List SyntaxFact) (List SyntaxFact) )
(def (matching-owner-syntax-facts/limit facts terms remaining out)
  (cond
   ((or (null? facts) (<= remaining 0))
    (reverse out))
   ((syntax-fact-matches-any-term? (car facts) terms)
    (matching-owner-syntax-facts/limit
     (cdr facts) terms (- remaining 1) (cons (car facts) out)))
   (else
    (matching-owner-syntax-facts/limit
     (cdr facts) terms remaining out))))

;;; Boundary:
;;; - Empty term lists intentionally match all syntax facts for owner browsing.
;;; - Non-empty terms keep predicate matching isolated to one fact at a time.
;; : (-> SyntaxFact (List String) Boolean )
(def (syntax-fact-matches-any-term? fact terms)
  (or (null? terms)
      (ormap (cut syntax-fact-matches-term? fact <>) terms)))

;;; Boundary:
;;; - This predicate searches normalized syntax fact fields only.
;;; - Query semantics stay independent from source text formatting.
;; : (-> SyntaxFact String Boolean )
(def (syntax-fact-matches-term? fact term)
  (ormap (cut string-contains <> term)
         (syntax-fact-search-values fact)))

;;; Boundary: syntax fact term search is a value projection followed by one
;;; matcher, not an expanding boolean predicate over individual fields.
;; : (-> SyntaxFact (List String) )
(def (syntax-fact-search-values fact)
  (filter string?
          (append [(hash-get fact 'kind)
                   (hash-get fact 'name)
                   (hash-get fact 'languageKind)]
                  (syntax-fact-query-key-search-values fact)
                  (syntax-fact-field-values fact))))

;;; Boundary:
;;; - The owner path already selected the file before item filtering.
;;; - Re-matching the selected path makes broad owner terms match every call.
;; : (-> SyntaxFact (List String) )
(def (syntax-fact-query-key-search-values fact)
  (let ((keys (hash-get fact 'queryKeys))
        (owner-path (hash-get fact 'ownerPath)))
    (if (equal? (hash-get fact 'kind) "package")
      keys
      (filter (lambda (value) (not (equal? value owner-path)))
              keys))))

;;; Boundary:
;;; - Flatten selected structured fields into string search keys.
;;; - Keep unsupported field values out of the match surface.
;; : (-> SyntaxFact (List String) )
(def (syntax-fact-field-values fact)
  (let (fields (hash-get fact 'fields))
    (if fields
      (filter-map (lambda (key)
                    (let (value (hash-get fields key))
                      (cond
                       ((string? value) value)
                       ((number? value) (number->string value))
                       (else #f))))
                  '(role generic receiver receiverType syntaxHead operator
                         slotCacheRole cacheOperation sourceSelector))
      '())))

;; : (-> SyntaxFact Key String )
(def (syntax-fact-field-string fact key)
  (let* ((fields (hash-get fact 'fields))
         (value (and fields (hash-get fields key))))
    (cond
     ((string? value) value)
     ((number? value) (number->string value))
     (else ""))))

;;; Boundary:
;;; - Owner item queries accept pipe and whitespace alternatives.
;;; - Empty query strings remain an explicit all-items request.
;; : (-> MaybeString (List String) )
(def (owner-item-query-terms query)
  (if query
    (owner-item-query-terms/limit
     (filter owner-item-query-term? (split-owner-item-query query))
     6)
    '()))

(def (owner-item-query-terms/limit terms remaining)
  (cond
   ((or (null? terms) (<= remaining 0)) '())
   (else
    (cons (car terms)
          (owner-item-query-terms/limit (cdr terms) (- remaining 1))))))

;; : (-> String Boolean )
(def (owner-item-query-term? value)
  (and (string? value)
       (not (string-empty? value))
       (<= (string-length value) 128)))

;;; Boundary:
;;; - Split only the owner-items query grammar, not global search parsing.
;;; - The helper recursion keeps token state explicit without named-let loops.
;; : (-> String (List String) )
(def (split-owner-item-query query)
  (split-owner-item-query/chars (string->list query) [] []))

;; : (-> (List Char) (List Char) (List String) (List String) )
(def (split-owner-item-query/chars chars token out)
  (cond
   ((null? chars)
    (reverse (cons-owner-query-token/chars token out)))
   ((owner-item-query-separator? (car chars))
    (split-owner-item-query/chars
     (cdr chars) [] (cons-owner-query-token/chars token out)))
   (else
    (split-owner-item-query/chars (cdr chars) (cons (car chars) token) out))))

;; : (-> (List Char) (List String) (List String) )
(def (cons-owner-query-token/chars token out)
  (if (null? token)
    out
    (cons (list->string (reverse token)) out)))

;; : (-> Char Boolean )
(def (owner-item-query-separator? char)
  (or (char=? char #\|)
      (char=? char #\space)
      (char=? char #\tab)
      (char=? char #\newline)
      (char=? char #\return)))
