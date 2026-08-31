;;; -*- Gerbil -*-
;;; Compact search renderer helpers for agent-facing source evidence.

(import :asp-gerbil-scheme/src/parser/source-class
        :asp-gerbil-scheme/src/utilities/functional)

(export emit-selector-resolver-line
        emit-source-example-line
        emit-source-comment-line
        emit-structural-syntax-fact-lines
        detail-list
        join-or-dash)
;; Integer
(def +syntax-fact-render-limit+ 32)
;; : (-> Resolver Selector )
(def (emit-selector-resolver-line resolver)
  (displayln "|selectorResolver scheme=" (hash-get resolver 'scheme)
             " owner=" (hash-get resolver 'owner)
             " stateNamespace=" (hash-get resolver 'stateNamespace)
             " versionKey=" (hash-get resolver 'versionKey)
             " selectorFormat=" (hash-get resolver 'selectorFormat)
             " output=" (hash-get resolver 'output)
             " indexOwner=" (hash-get resolver 'indexOwner)))
;; : (-> Example String )
(def (emit-source-example-line example)
  (let (form (hash-get example 'form))
    (displayln "|sourceExample id=" (hash-get example 'id)
               " role=" (hash-get example 'role)
               " symbol=" (hash-get example 'symbol)
               " selector=" (hash-get example 'selector)
               " head=" (hash-get form 'head)
               " operands=" (join-or-dash (hash-get form 'operands))
               " keywords=" (join-or-dash (hash-get form 'keywords))
               " commentMode=" (hash-get example 'commentMode))))
;; : (-> Comment String )
(def (emit-source-comment-line comment)
  (displayln "|sourceComment id=" (hash-get comment 'id)
             " selector=" (hash-get comment 'selector)
             " extractor=" (hash-get comment 'extractor)
             " summary=" (hash-get comment 'summary)
             " fallback=" (hash-get comment 'fallback)))
;; : (-> (List SyntaxFact) Unit )
(def (emit-structural-syntax-fact-lines facts)
  (for-each emit-syntax-fact-line
            (ranked-syntax-facts facts)))
;;; Boundary:
;;; - emit-syntax-fact-line coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> SyntaxFact Unit )
(def (emit-syntax-fact-line fact)
  (let* ((fields (hash-get fact 'fields))
         (location (hash-get fact 'location)))
    (displayln "|syntaxFact kind=" (hash-get fact 'kind)
               " languageKind=" (hash-get fact 'languageKind)
               " name=" (hash-get fact 'name)
               " owner=" (hash-get fact 'ownerPath)
               " range=" (hash-get location 'lineRange)
               " sourceClass=" (source-path-class (hash-get fact 'ownerPath))
               " role=" (field-string fields 'role)
               " generic=" (field-string fields 'generic)
               " receiver=" (field-string fields 'receiver)
               " receiverType=" (field-string fields 'receiverType)
               " supers=" (field-list-string fields 'supers)
               " slots=" (field-list-string fields 'slots)
               " options=" (field-list-string fields 'options)
               " specializers=" (field-list-string fields 'specializers)
               " dispatchArity=" (field-string fields 'dispatchArity)
               " operandCount=" (field-string fields 'operandCount)
               " arities=" (field-list-string fields 'arities)
               " formals=" (field-list-string fields 'formals)
               " caller=" (field-string fields 'caller)
               " dependency=" (field-string fields 'dependency)
               " importedSymbols=" (field-list-string fields 'importedSymbols)
               " usedSymbols=" (field-list-string fields 'usedSymbols)
               " protocolRefs=" (field-list-string fields 'protocolRefs)
               " derivedCapabilities=" (field-list-string fields 'derivedCapabilities)
               " manualObjectEncodingRisk=" (field-string fields 'manualObjectEncodingRisk)
               " genericContractWitnessKind=" (field-string fields 'genericContractWitnessKind)
               " contract=" (field-string fields 'contract)
               " contractOutput=" (field-string fields 'contractOutput)
               " contractInputs=" (field-list-string fields 'contractInputs)
               " definitionArity=" (field-string fields 'definitionArity)
               " arityAlignment=" (field-string fields 'arityAlignment)
               " targetKind=" (field-string fields 'targetKind)
               " context=" (field-string fields 'context)
               " commentKind=" (field-string fields 'commentKind)
               " required=" (field-string fields 'required)
               " quality=" (field-string fields 'quality)
               " reasons=" (field-list-string fields 'reasons)
               " commentLines=" (field-list-string fields 'commentLines)
               " tokens=" (field-list-string fields 'tokens)
               " arrowCount=" (field-string fields 'arrowCount)
               " groupCount=" (field-string fields 'groupCount))))
;; ranked-syntax-facts
;;   : (-> (List SyntaxFact) (List SyntaxFact))
;;   | doc m%
;;       `ranked-syntax-facts facts` selects a bounded, role-prioritized syntax
;;       fact list for compact search rendering.
;;
;;       # Examples
;;
;;       ```scheme
;;       (ranked-syntax-facts facts)
;;       ;; => prioritized facts
;;       ```
;;     %
(def (ranked-syntax-facts facts)
  (reverse
   (ranked-syntax-state-output
    (foldl (lambda (predicate state)
             (select-ranked-syntax-facts facts predicate state))
           ['() '() +syntax-fact-render-limit+]
           (ranked-syntax-fact-predicates)))))

;; ranked-syntax-fact-predicates
;;   : (-> (List SyntaxFactPredicate))
;;   | doc m%
;;       `ranked-syntax-fact-predicates` returns the selector predicates in the
;;       priority order used by syntax fact rendering.
;;
;;       # Examples
;;
;;       ```scheme
;;       (ranked-syntax-fact-predicates)
;;       ;; => selector predicates
;;       ```
;;     %
(def (ranked-syntax-fact-predicates)
  [poo-syntax-fact?
   dependency-adapter-quality-syntax-fact?
   invalid-typed-contract-syntax-fact?
   higher-order-syntax-fact?
   typed-contract-syntax-fact?
   weak-comment-quality-syntax-fact?
   comment-quality-syntax-fact?
   macro-or-import-syntax-fact?
   any-syntax-fact?])

;; ranked-syntax-state-output
;;   : (-> RankedSyntaxState (List SyntaxFact))
;;   | doc m%
;;       `ranked-syntax-state-output state` extracts the accumulated syntax fact
;;       output from the ranker state tuple.
;;
;;       # Examples
;;
;;       ```scheme
;;       (ranked-syntax-state-output ['() facts 0])
;;       ;; => facts
;;       ```
;;     %
(def (ranked-syntax-state-output state)
  (match state
    ([seen out remaining] out)))

;; select-ranked-syntax-facts
;;   : (-> (List SyntaxFact) SyntaxFactPredicate RankedSyntaxState RankedSyntaxState)
;;   | doc m%
;;       `select-ranked-syntax-facts facts predicate state` folds one predicate
;;       over the candidate facts and carries the ranker state forward.
;;
;;       # Examples
;;
;;       ```scheme
;;       (select-ranked-syntax-facts facts predicate ['() '() 8])
;;       ;; => updated ranker state
;;       ```
;;     %
(def (select-ranked-syntax-facts facts predicate state)
  (foldl (lambda (fact state)
           (select-ranked-syntax-fact predicate fact state))
         state
         facts))

;; select-ranked-syntax-fact
;;   : (-> SyntaxFactPredicate SyntaxFact RankedSyntaxState RankedSyntaxState)
;;   | doc m%
;;       `select-ranked-syntax-fact predicate fact state` appends one unseen
;;       fact when the predicate matches and ranking capacity remains.
;;
;;       # Examples
;;
;;       ```scheme
;;       (select-ranked-syntax-fact predicate fact ['() '() 1])
;;       ;; => updated ranker state
;;       ```
;;     %
(def (select-ranked-syntax-fact predicate fact state)
  (match state
    ([seen out remaining]
     (let (id (hash-get fact 'id))
       (if (ranked-syntax-fact-selected? predicate seen remaining fact)
         [(cons id seen) (cons fact out) (- remaining 1)]
         state)))))

;; ranked-syntax-fact-selected?
;;   : (-> SyntaxFactPredicate (List SyntaxFactId) Integer SyntaxFact Boolean)
;;   | doc m%
;;       `ranked-syntax-fact-selected? predicate seen remaining fact` checks the
;;       capacity, predicate, and duplicate guard for one syntax fact.
;;     %
(def (ranked-syntax-fact-selected? predicate seen remaining fact)
  (and (> remaining 0)
       (predicate fact)
       (not (list-contains? seen (hash-get fact 'id)))))

;;; Predicate selectors share the same syntax field accessor so role and
;;; quality checks stay expression-level instead of re-opening the fields hash
;;; in each predicate branch.
;; syntax-fact-field-string
;;   : (-> SyntaxFact Key String)
;;   | doc m%
;;       `syntax-fact-field-string fact key` reads a parser-owned syntax fact
;;       field through the renderer's dash-normalized string boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (syntax-fact-field-string fact 'role)
;;       ;; => "typed-combinator-style"
;;       ```
;;     %
(def (syntax-fact-field-string fact key)
  (field-string (hash-get fact 'fields) key))

;; syntax-fact-field-member?
;;   : (-> SyntaxFact Key (List String) Boolean)
;;   | doc m%
;;       `syntax-fact-field-member? fact key values` classifies syntax facts by
;;       membership in a normalized field value set.
;;     %
(def (syntax-fact-field-member? fact key values)
  (member (syntax-fact-field-string fact key) values))

;; syntax-fact-field=?
;;   : (-> SyntaxFact Key String Boolean)
;;   | doc m%
;;       `syntax-fact-field=? fact key expected` keeps equality checks on
;;       rendered fields aligned with the same dash-normalized access path.
;;     %
(def (syntax-fact-field=? fact key expected)
  (equal? (syntax-fact-field-string fact key) expected))

;; syntax-fact-value-member?
;;   : (-> SyntaxFact Key (List String) Boolean)
;;   | doc m%
;;       `syntax-fact-value-member? fact key values` classifies top-level syntax
;;       fact values without bypassing the renderer predicate vocabulary.
;;     %
(def (syntax-fact-value-member? fact key values)
  (member (hash-get fact key) values))

;; any-syntax-fact?
;;   : (-> SyntaxFact Boolean)
;;   | doc m%
;;       `any-syntax-fact? fact` is the explicit final selector for ranked
;;       rendering once higher-signal syntax fact predicates have run.
;;     %
(def (any-syntax-fact? fact)
  #t)

;; : (-> SyntaxFact Boolean )
(def (poo-syntax-fact? fact)
  (syntax-fact-field-member? fact 'role '("class" "generic" "protocol" "method" "type")))
;; : (-> SyntaxFact Boolean )
(def (dependency-adapter-quality-syntax-fact? fact)
  (syntax-fact-field=? fact 'role "dependency-protocol-adapter"))
;; : (-> SyntaxFact Boolean )
(def (macro-or-import-syntax-fact? fact)
  (syntax-fact-value-member? fact 'kind '("macro" "import")))
;; : (-> SyntaxFact Boolean )
(def (higher-order-syntax-fact? fact)
  (syntax-fact-field-member? fact 'role
                             '("anonymous-function"
                               "multi-arity-function"
                               "partial-application"
                               "loop-fold"
                               "sequence-map"
                               "sequence-filter"
                               "sequence-fold")))
;; : (-> SyntaxFact Boolean )
(def (typed-contract-syntax-fact? fact)
  (syntax-fact-field=? fact 'role "typed-combinator-style"))
;; : (-> SyntaxFact Boolean )
(def (invalid-typed-contract-syntax-fact? fact)
  (and (typed-contract-syntax-fact? fact)
       (syntax-fact-field=? fact 'quality "invalid")))
;; : (-> SyntaxFact Boolean )
(def (comment-quality-syntax-fact? fact)
  (syntax-fact-field=? fact 'role "engineering-comment-quality"))
;; : (-> SyntaxFact Boolean )
(def (weak-comment-quality-syntax-fact? fact)
  (and (comment-quality-syntax-fact? fact)
       (syntax-fact-field-member? fact 'quality '("absent" "weak"))))

;; field-string
;;   : (-> Fields Key String)
;;   | doc m%
;;       `field-string fields key` renders a syntax fact field for packet output,
;;       returning `-` for missing or empty data so callers do not each encode
;;       their own absence semantics.
;;     %
(def (field-string fields key)
  (if (and fields (hash-key? fields key))
    (dash-empty (value->field-string (hash-get fields key)))
    "-"))
;; field-list-string
;;   : (-> Fields Key String)
;;   | doc m%
;;       `field-list-string fields key` renders a list-valued field as a compact
;;       comma-style output value, falling back to `-` for missing data.
;;
;;       # Examples
;;
;;       ```scheme
;;       (field-list-string fields 'tokens)
;;       ;; => "let,lambda"
;;       ```
;;     %
(def (field-list-string fields key)
  (if (and fields (hash-key? fields key))
    (let (value (hash-get fields key))
      (cond
       ((list? value) (join-or-dash (map value->field-string value)))
       ((string? value) (dash-empty value))
       (else "-")))
    "-"))
;; : (-> Value DashEmpty )
(def (dash-empty value)
  (cond
   ((not value) "-")
   ((and (string? value) (not (non-empty-string? value))) "-")
   (else value)))
;; : (-> FieldValue String )
(def (value->field-string value)
  (cond
   ((number? value) (number->string value))
   ((boolean? value) (if value "true" "false"))
   (else value)))
;; : (-> Details Key DetailList )
(def (detail-list details key)
  (if (hash-key? details key)
    (hash-get details key)
    []))
;; : (-> Values JoinOrDash )
(def (join-or-dash values)
  (if (null? values)
    "-"
    (string-join-with values ",")))
