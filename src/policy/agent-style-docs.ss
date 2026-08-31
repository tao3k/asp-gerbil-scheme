;;; -*- Gerbil -*-
;;; Typed-combinator documentation and invalid-contract detail helpers.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-support
        (only-in :std/misc/list unique)
        (only-in :std/srfi/1 take)
        (only-in :std/sugar cut filter filter-map hash hash-get ormap))

(import :asp-gerbil-scheme/src/utilities/functional)

(export typed-combinator-style-missing-doc-targets
        typed-combinator-style-missing-forall-targets
        file-typed-contract-invalid-reasons
        file-typed-contract-invalid-examples)

;; (List Role)
(def +typed-combinator-style-doc-required-roles+
  '("macro-helper" "protocol-method" "poo-protocol-boundary"))

;; (List QualityFacet)
(def +typed-combinator-style-doc-required-facets+
  '("macro-runtime-source-witness" "poo-protocol-evidence"
    "loop-driver-classified"))

(def +typed-combinator-style-forall-required-facets+
  '("higher-order-used" "parameterized-transform" "sequence-filter-map"
    "sequence-fold" "sequence-predicate"))

(def +typed-combinator-style-unbound-type-variable-prefix+
  "unbound-type-variable:")

;; (List SignatureToken)
(def +typed-combinator-style-polymorphic-summary-tokens+
  '("Alist" "AssocList" "PairList" "Predicate" "Mapper" "Reducer"))

;;; Documentation target boundary:
;;; - Merge function-profile and macro evidence into one target list.
;;; - Each source of evidence remains parser-owned before this aggregation.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-missing-doc-targets file)
  (unique
   (append
    (filter-map (cut typed-combinator-style-profile-missing-doc-target file <>)
                (source-file-function-quality-profiles file))
    (filter-map (cut typed-combinator-style-macro-missing-doc-target file <>)
                (source-file-macros file)))))

;;; Profile target boundary:
;;; - Return the public helper name only when docs are required and absent.
;;; - The caller owns de-duplication across function and macro evidence.
;; : (-> SourceFile FunctionQualityProfile MaybeTargetName )
(def (typed-combinator-style-missing-forall-targets file)
  (unique
   (filter-map (cut typed-combinator-style-profile-missing-forall-target file <>)
               (source-file-function-quality-profiles file))))

(def (typed-combinator-style-profile-missing-forall-target file profile)
  (let (fact
        (typed-combinator-style-typed-contract-fact
         file
         (function-quality-profile-name profile)))
    (and fact
         (typed-combinator-style-profile-requires-forall? profile fact)
         (function-quality-profile-name profile))))

(def (typed-combinator-style-profile-requires-forall? profile fact)
  (and (> (function-quality-profile-arity profile) 0)
       (function-quality-profile-exported profile)
       (typed-combinator-style-profile-forall-required-facet? profile)
       (or (typed-combinator-style-typed-contract-generic-candidate? fact)
           (typed-combinator-style-typed-contract-missing-polymorphic-signature? fact)
           (typed-combinator-style-typed-contract-missing-readable-domain-signature? fact))))

(def (typed-combinator-style-profile-forall-required-facet? profile)
  (list-intersects? +typed-combinator-style-forall-required-facets+
                    (function-quality-profile-quality-facets profile)))

(def (typed-combinator-style-typed-contract-generic-candidate? fact)
  (pair? (typed-combinator-style-typed-contract-missing-forall-vars fact)))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-typed-contract-missing-polymorphic-signature? fact)
  (and (not (member 'typed-contract-precision-signature
                    (typed-contract-fact-quality-facets fact)))
       (typed-combinator-style-typed-contract-polymorphic-summary? fact)))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-typed-contract-missing-readable-domain-signature? fact)
  (and (typed-combinator-style-typed-contract-has-polymorphic-signature? fact)
       (not (typed-combinator-style-typed-contract-has-readable-domain-signature? fact))))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-typed-contract-has-polymorphic-signature? fact)
  (pair? (typed-combinator-style-typed-contract-polymorphic-signatures fact)))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-typed-contract-has-readable-domain-signature? fact)
  (let ((signature-types (typed-combinator-style-typed-contract-signature-types fact))
        (polymorphic-signatures
         (typed-combinator-style-typed-contract-polymorphic-signatures fact)))
    (> (length signature-types)
       (length polymorphic-signatures))))

;; : (-> TypedContractFact (List Json) )
(def (typed-combinator-style-typed-contract-signature-types fact)
  (let (typed-comment (typed-contract-fact-typed-comment fact))
    (if typed-comment
      (or (hash-get typed-comment 'signatureTypes) [])
      [])))

;; : (-> TypedContractFact (List Json) )
(def (typed-combinator-style-typed-contract-polymorphic-signatures fact)
  (let (typed-comment (typed-contract-fact-typed-comment fact))
    (if typed-comment
      (or (hash-get typed-comment 'polymorphicSignatures) [])
      [])))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-typed-contract-polymorphic-summary? fact)
  (list-intersects? +typed-combinator-style-polymorphic-summary-tokens+
                    (typed-contract-fact-tokens fact)))

;; : (-> TypedContractFact (List TypeVariable) )
(def (typed-combinator-style-typed-contract-missing-forall-vars fact)
  (let* ((typed-comment (typed-contract-fact-typed-comment fact))
         (signature-type
          (and typed-comment (hash-get typed-comment 'signatureType)))
         (diagnostics
          (or (and signature-type (hash-get signature-type 'diagnostics)) [])))
    (unique
     (filter-map typed-combinator-style-unbound-type-variable-diagnostic-name
                 diagnostics))))

;; : (-> Diagnostic MaybeTypeVariable )
(def (typed-combinator-style-unbound-type-variable-diagnostic-name diagnostic)
  (and (string? diagnostic)
       (typed-combinator-style-string-prefix?
        +typed-combinator-style-unbound-type-variable-prefix+
        diagnostic)
       (let (name
             (substring
              diagnostic
              (string-length +typed-combinator-style-unbound-type-variable-prefix+)
              (string-length diagnostic)))
         (and (> (string-length name) 0) name))))

;; : (-> String String Boolean )
(def (typed-combinator-style-string-prefix? prefix text)
  (let (prefix-length (string-length prefix))
    (and (<= prefix-length (string-length text))
         (equal? (substring text 0 prefix-length) prefix))))

(def (typed-combinator-style-profile-missing-doc-target file profile)
  (and (> (function-quality-profile-arity profile) 0)
       (typed-combinator-style-profile-requires-doc? profile)
       (not (typed-combinator-style-profile-has-doc? file profile))
       (function-quality-profile-name profile)))

;;; Profile requirement boundary:
;;; - Arity-bearing helpers need docs only when role or exported risk warrants it.
;;; - This keeps routine exported accessors on the short typed-comment path.
;; : (-> FunctionQualityProfile Boolean )
(def (typed-combinator-style-profile-requires-doc? profile)
  (and (> (function-quality-profile-arity profile) 0)
       (or (member (function-quality-profile-role profile)
                   +typed-combinator-style-doc-required-roles+)
           (and (function-quality-profile-exported profile)
                (typed-combinator-style-profile-doc-required-facet? profile)))))

;;; Boundary:
;;; - Facet-driven doc requirements come from parser-owned quality evidence.
;;; - This keeps R013 extensible without hard-coding path-specific policy exceptions.
;; : (-> FunctionQualityProfile Boolean)
(def (typed-combinator-style-profile-doc-required-facet? profile)
  (list-intersects? +typed-combinator-style-doc-required-facets+
                    (function-quality-profile-quality-facets profile)))

;;; Profile doc lookup:
;;; - A profile is documented only by its own adjacent typed contract.
;;; - Other module comments cannot satisfy helper-level public docs.
;; : (-> SourceFile FunctionQualityProfile Boolean )
(def (typed-combinator-style-profile-has-doc? file profile)
  (let (fact
        (typed-combinator-style-typed-contract-fact
         file
         (function-quality-profile-name profile)))
    (and fact
         (typed-combinator-style-typed-comment-has-full-doc?
          fact
          (function-quality-profile-name profile)))))

;;; Macro target boundary:
;;; - Macro facts carry their own public names.
;;; - Missing docs are reported at the macro boundary, not runtime helpers.
;; : (-> SourceFile MacroFact MaybeTargetName )
(def (typed-combinator-style-macro-missing-doc-target file macro)
  (and (not (typed-combinator-style-macro-has-doc? file macro))
       (macro-fact-name macro)))

;;; Macro doc lookup:
;;; - Macro documentation must be owned by the macro's typed contract.
;;; - This prevents runtime helper comments from hiding macro expansion risk.
;; : (-> SourceFile MacroFact Boolean )
(def (typed-combinator-style-macro-has-doc? file macro)
  (let (fact
        (typed-combinator-style-typed-contract-fact
         file
         (macro-fact-name macro)))
    (and fact
         (typed-combinator-style-typed-comment-has-full-doc?
          fact
          (macro-fact-name macro)))))

;;; Boundary:
;;; - Typed contract lookup is keyed by parser-owned definition name.
;;; - Policy must not scan source text to decide whether docs are complete.
;; : (-> SourceFile String MaybeTypedContractFact )
(def (typed-combinator-style-typed-contract-fact file name)
  (find (lambda (fact)
          (equal? (typed-contract-fact-definition-name fact) name))
        (source-file-typed-contract-facts file)))

;;; Full-doc boundary:
;;; - Ownership and doc completeness are both required.
;;; - This prevents a complete doc block for the wrong helper from passing.
;; : (-> TypedContractFact String Boolean)
(def (typed-combinator-style-typed-comment-has-full-doc? fact expected-name)
  (let (typed-comment (typed-contract-fact-typed-comment fact))
    (and (typed-combinator-style-typed-comment-owned? typed-comment expected-name)
         (typed-combinator-style-docs-complete
          (typed-combinator-style-typed-comment-docs typed-comment)))))

;;; Ownership checks stay separate from documentation content so policy can
;;; explain whether a full-form block is missing or merely incomplete.
;; : (-> TypedCommentMetadata String Boolean)
(def (typed-combinator-style-typed-comment-owned? typed-comment expected-name)
  (and typed-comment
       (hash-get typed-comment 'fullForm)
       (equal? (hash-get typed-comment 'leadingName) expected-name)))

;;; Typed-comment docs are projected once from parser metadata; downstream
;;; body/example predicates consume the list without reaching back into hashes.
;; : (-> TypedCommentMetadata (List Json))
(def (typed-combinator-style-typed-comment-docs typed-comment)
  (or (hash-get typed-comment 'docs) []))

;;; Completeness is an aggregator over the two public doc evidence predicates.
;;; It is deliberately not a `?` helper so R016 does not treat it as another
;;; predicate-family member over `docs`.
;; : (-> (List Json) Boolean)
(def (typed-combinator-style-docs-complete docs)
  (and (typed-combinator-style-docs-have-body? docs)
       (typed-combinator-style-docs-have-result-example? docs)))

;;; Boundary:
;;; - Documentation body evidence comes from typed-comment metadata.
;;; - Empty `| doc` sections cannot satisfy public helper documentation.
;; : (-> (List Json) Boolean)
(def (typed-combinator-style-docs-have-body? docs)
  (ormap (lambda (doc)
           (let (body (or (hash-get doc 'body) ""))
             (not (blank-string? body))))
         docs))

;;; Boundary:
;;; - Result examples prove the doc block carries repair-checkable output.
;;; - Accept either section-level result evidence or parsed example packets.
;; : (-> (List Json) Boolean)
(def (typed-combinator-style-docs-have-result-example? docs)
  (ormap (lambda (doc)
           (or (hash-get doc 'hasResultExamples)
               (ormap typed-combinator-style-example-has-result?
                      (or (hash-get doc 'examples) []))))
         docs))

;;; Example result boundary:
;;; - A parsed result marker is enough evidence for repair-checkable docs.
;;; - Body-only examples remain incomplete for public helper guidance.
;; : (-> Json Boolean)
(def (typed-combinator-style-example-has-result? example)
  (if (hash-get example 'hasExpectedResult) #t #f))

;;; Boundary:
;;; - file-typed-contract-invalid-reasons composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile (List InvalidContractReason) )
(def (file-typed-contract-invalid-reasons file)
  (unique
   (apply append
          (map typed-contract-fact-reasons
               (filter invalid-typed-contract-fact?
                       (source-file-typed-contract-facts file))))))

;;; Boundary:
;;; - file-typed-contract-invalid-examples composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile (List InvalidContractExample) )
(def (file-typed-contract-invalid-examples file)
  (let (facts (filter invalid-typed-contract-fact?
                      (source-file-typed-contract-facts file)))
    (map typed-contract-fact-example
         (take facts (min 3 (length facts))))))

;;; Invalid-contract predicate:
;;; - Typed contract quality is parser-owned.
;;; - Policy filters by the public quality field instead of re-parsing text.
;; : (-> TypedContractFact Boolean )
(def (invalid-typed-contract-fact? fact)
  (equal? (typed-contract-fact-quality fact) "invalid"))

;;; Invalid-contract packet:
;;; - Preserve compact parser evidence for agent repair.
;;; - The packet avoids source snippets while keeping selector and reason detail.
;; : (-> TypedContractFact InvalidContractExample )
(def (typed-contract-fact-example fact)
  (hash (definition (typed-contract-fact-definition-name fact))
        (selector (typed-contract-fact-selector fact))
        (contract (typed-contract-fact-contract fact))
        (tokens (typed-contract-fact-tokens fact))
        (quality (typed-contract-fact-quality fact))
        (reasons (typed-contract-fact-reasons fact))
        (arrowCount (typed-contract-fact-arrow-count fact))
        (groupCount (typed-contract-fact-group-count fact))))
