;;; -*- Gerbil -*-
;;; Parser-owned function quality profiles composed from native facts.

(import :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/higher-order
        :asp-gerbil-scheme/src/parser/function-quality-signals
        (only-in :clan/base fun)
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :std/sugar cut filter find foldl ormap))

(export function-quality-profiles-from-source)

;; (List Callee)
;;; Profile fan-out is a pure definition-to-profile transform.
;;; The cut captures shared owner evidence once, then map keeps each function
;;; profile independent so policy can repair one function boundary at a time.
;; : (-> Relpath Exports Definitions CallFacts TypedContracts CommentFacts ControlFlowFacts HigherOrderFacts PredicateFamilies FieldAccessFacts LoopDrivers MacroFacts PooFacts (List FunctionQualityProfile) )
(def (function-quality-profiles-from-source relpath exports definitions calls typed-contracts comment-facts control-flow-forms higher-order-forms predicate-family-facts field-access-pattern-facts loop-driver-facts macros poo-forms)
  (let ((typed-contract-index
         (function-quality-index-by-field
          typed-contract-fact-definition-name typed-contracts))
        (comment-index
         (function-quality-index-by-field
          comment-quality-fact-target-name comment-facts))
        (call-index
         (function-quality-index-by-field call-fact-caller calls))
        (control-flow-index
         (function-quality-index-by-field
          control-flow-fact-caller control-flow-forms))
        (higher-order-index
         (function-quality-index-by-field
          higher-order-fact-caller higher-order-forms))
        (predicate-family-index
         (function-quality-index-by-member-field
          predicate-family-fact-predicate-names predicate-family-facts))
        (field-access-index
         (function-quality-index-by-member-field
          field-access-pattern-fact-callers field-access-pattern-facts))
        (loop-driver-index
         (function-quality-index-by-any-field
          [loop-driver-fact-name loop-driver-fact-caller]
          loop-driver-facts))
        (macro-index
         (function-quality-index-by-field macro-fact-name macros))
        (poo-index
         (function-quality-index-by-any-field
          [poo-form-fact-name
           poo-form-fact-generic
           poo-form-fact-receiver]
          poo-forms)))
    (map (cut function-quality-profile-from-definition/indexed
              relpath exports <>
              typed-contract-index comment-index
              call-index
              control-flow-index higher-order-index
              predicate-family-index field-access-index
              loop-driver-index macro-index poo-index)
         definitions)))

;;; Profile materialization stays parser-owned: policy receives one
;;; function-level packet instead of re-joining typed, comment, control-flow,
;;; higher-order, POO, macro, and predicate-family evidence.
;; : (-> Relpath Exports Definition CallFacts TypedContracts CommentFacts ControlFlowFacts HigherOrderFacts PredicateFamilies FieldAccessFacts LoopDrivers MacroFacts PooFacts FunctionQualityProfile )
(def (function-quality-profile-from-definition relpath exports definition calls typed-contracts comment-facts control-flow-forms higher-order-forms predicate-family-facts field-access-pattern-facts loop-driver-facts macros poo-forms)
  (function-quality-profile-from-definition/indexed
   relpath exports definition
   (function-quality-index-by-field
    typed-contract-fact-definition-name typed-contracts)
   (function-quality-index-by-field
    comment-quality-fact-target-name comment-facts)
   (function-quality-index-by-field call-fact-caller calls)
   (function-quality-index-by-field
    control-flow-fact-caller control-flow-forms)
   (function-quality-index-by-field
    higher-order-fact-caller higher-order-forms)
   (function-quality-index-by-member-field
    predicate-family-fact-predicate-names predicate-family-facts)
   (function-quality-index-by-member-field
    field-access-pattern-fact-callers field-access-pattern-facts)
   (function-quality-index-by-any-field
    [loop-driver-fact-name loop-driver-fact-caller]
    loop-driver-facts)
   (function-quality-index-by-field macro-fact-name macros)
   (function-quality-index-by-any-field
    [poo-form-fact-name
     poo-form-fact-generic
     poo-form-fact-receiver]
    poo-forms)))

;;; The indexed path is the hot path for whole-file parsing.  It keeps the
;;; profile join linear in facts plus definitions instead of scanning every fact
;;; family for every definition.
;; : (-> Relpath Exports Definition HashTable HashTable HashTable HashTable HashTable HashTable HashTable HashTable HashTable HashTable FunctionQualityProfile )
(def (function-quality-profile-from-definition/indexed relpath exports definition typed-contract-index comment-index call-index control-flow-index higher-order-index predicate-family-index field-access-index loop-driver-index macro-index poo-index)
  (let* ((name (definition-name definition))
         (typed-contract
          (function-quality-first-indexed-fact typed-contract-index name))
         (comment-fact
          (matching-comment-quality/indexed name comment-index))
         (matched-calls
          (function-quality-indexed-facts call-index name))
         (matched-control-flow
          (function-quality-indexed-facts control-flow-index name))
         (matched-higher-order
          (function-quality-indexed-facts higher-order-index name))
         (matched-predicate-families
          (function-quality-indexed-facts predicate-family-index name))
         (matched-field-access
          (function-quality-indexed-facts field-access-index name))
         (matched-loop-drivers
          (function-quality-indexed-facts loop-driver-index name))
         (matched-macros
          (function-quality-indexed-facts macro-index name))
         (matched-poo
          (function-quality-indexed-facts poo-index name))
         (exported? (and (member name exports) #t))
         (role (function-quality-role definition exported?
                                      matched-macros matched-poo
                                      matched-loop-drivers))
         (typed-quality (if typed-contract
                          (typed-contract-fact-quality typed-contract)
                          "missing"))
         (comment-quality (if comment-fact
                            (comment-quality-fact-quality comment-fact)
                            "missing"))
         (quality-facets
          (function-quality-facets role exported? typed-quality comment-quality
                                   typed-contract comment-fact
                                   matched-calls
                                   matched-control-flow matched-higher-order
                                   matched-predicate-families matched-field-access
                                   matched-loop-drivers matched-macros matched-poo))
         (preservation-reasons
          (function-quality-preservation-reasons exported?
                                                 matched-loop-drivers
                                                 matched-macros
                                                 matched-poo))
         (repair-class
          (function-quality-repair-class typed-quality comment-quality
                                         quality-facets
                                         matched-predicate-families))
         (parser-confidence
          (function-quality-parser-confidence typed-contract comment-fact
                                              matched-calls
                                              matched-control-flow
                                              matched-higher-order
                                              matched-predicate-families
                                              matched-field-access
                                              matched-loop-drivers
                                              matched-macros
                                              matched-poo)))
    (make-function-quality-profile
     name
     "function-quality-profile"
     relpath
     (definition-start definition)
     (definition-end definition)
     (definition-formals definition)
     (definition-arity definition)
     role
     exported?
     typed-quality
     comment-quality
     (unique (filter identity (map control-flow-fact-role matched-control-flow)))
     (unique (filter identity (map higher-order-fact-role matched-higher-order)))
     (map predicate-family-fact-name matched-predicate-families)
     (map field-access-pattern-fact-name matched-field-access)
     (map loop-driver-fact-name matched-loop-drivers)
     (map macro-fact-name matched-macros)
     (map poo-form-fact-name matched-poo)
     quality-facets
     preservation-reasons
     repair-class
     parser-confidence
     (function-quality-advice repair-class preservation-reasons quality-facets))))

;;; Index builders keep append-free hot paths: facts are consed during indexing
;;; and reversed on lookup to preserve source order.  Multi-field facts are
;;; deduplicated per fact before insertion so a single POO/loop fact cannot
;;; appear twice for one definition.
;; : (-> (-> Fact Key) (List Fact) HashTable )
(def (function-quality-index-by-field accessor facts)
  (let (table (make-hash-table))
    (for-each
     (lambda (fact)
       (function-quality-index-fact-keys! table fact [(accessor fact)]))
     facts)
    table))

;; : (-> (List (-> Fact Key)) (List Fact) HashTable )
(def (function-quality-index-by-any-field accessors facts)
  (let (table (make-hash-table))
    (for-each
     (lambda (fact)
       (function-quality-index-fact-keys!
        table fact
        (map (lambda (accessor) (accessor fact)) accessors)))
     facts)
    table))

;; : (-> (-> Fact (List Key)) (List Fact) HashTable )
(def (function-quality-index-by-member-field accessor facts)
  (let (table (make-hash-table))
    (for-each
     (lambda (fact)
       (function-quality-index-fact-keys! table fact (accessor fact)))
     facts)
    table))

;; : (-> HashTable Fact (List Key) Void )
(def (function-quality-index-fact-keys! table fact keys)
  (for-each
   (cut function-quality-index-fact-key! table fact <>)
   (unique (filter identity keys))))

;; : (-> HashTable Fact Key Void )
(def (function-quality-index-fact-key! table fact key)
  (when key
    (let (existing
          (if (hash-key? table key)
            (hash-get table key)
            '()))
      (hash-put! table key (cons fact existing)))))

;; : (-> HashTable Key (List Fact) )
(def (function-quality-indexed-facts table key)
  (if (and key (hash-key? table key))
    (reverse (hash-get table key))
    '()))

;; : (-> HashTable Key MaybeFact )
(def (function-quality-first-indexed-fact table key)
  (let (facts (function-quality-indexed-facts table key))
    (and (pair? facts) (car facts))))

;;; Matching helpers keep correlation parser-owned and local to one name.
;;; `find` preserves the first adjacent typed contract fact without inventing
;;; fallback evidence from rendered comments or source text.
;; : (-> DefinitionName TypedContracts TypedContractFact )
(def (matching-typed-contract name facts)
  (first-fact-with-field facts typed-contract-fact-definition-name name))

;;; Comment facts are keyed by definition target, not by free text.
;;; This prevents file/module comments from satisfying a function-level repair.
;; : (-> DefinitionName CommentFacts CommentQualityFact )
(def (matching-comment-quality name facts)
  (find (fun (definition-comment-fact? fact)
          (and (equal? (comment-quality-fact-target-kind fact) "definition")
               (fact-field=? comment-quality-fact-target-name name fact)))
        facts))

;; : (-> DefinitionName HashTable CommentQualityFact )
(def (matching-comment-quality/indexed name fact-index)
  (find (fun (definition-comment-fact? fact)
          (equal? (comment-quality-fact-target-kind fact) "definition"))
        (function-quality-indexed-facts fact-index name)))

;;; Control-flow correlation is caller-owned.
;;; The filter keeps loops, continuations, and resource scopes attached to the
;;; function that would be rewritten by a style policy.
;; : (-> DefinitionName ControlFlowFacts (List ControlFlowFact) )
(def (matching-control-flow name facts)
  (facts-with-field facts control-flow-fact-caller name))

;;; Higher-order evidence is caller-owned.
;;; The filtered roles show whether a function already uses map/filter/fold/cut
;;; or needs a combinator-style repair.
;; : (-> DefinitionName HigherOrderFacts (List HigherOrderFact) )
(def (matching-higher-order name facts)
  (facts-with-field facts higher-order-fact-caller name))

;;; Predicate-family facts point back to predicate function names.
;;; Filtering by membership lets policy repair repeated predicate shape without
;;; scanning source bodies again.
;; : (-> DefinitionName PredicateFamilies (List PredicateFamilyFact) )
(def (matching-predicate-families name facts)
  (facts-containing-field facts predicate-family-fact-predicate-names name))

;;; Field-access patterns record callers that repeat the same selector shape.
;;; Filtering by caller keeps selector-helper advice scoped to the functions
;;; that own the repeated access.
;; : (-> DefinitionName FieldAccessFacts (List FieldAccessPatternFact) )
(def (matching-field-access name facts)
  (facts-containing-field facts field-access-pattern-fact-callers name))

;;; Loop-driver facts can name either the loop or its enclosing function.
;;; Both links are preserved so pure-transform repair does not erase IO/state
;;; driver boundaries.
;; : (-> DefinitionName LoopDrivers (List LoopDriverFact) )
(def (matching-loop-drivers name facts)
  (facts-with-any-field facts
                        [loop-driver-fact-name
                         loop-driver-fact-caller]
                        name))

;;; Macro matching marks transformer-owned helpers as preservation boundaries.
;;; A name match is enough here because macro facts already carry parser-owned
;;; selectors and quality facets.
;; : (-> DefinitionName MacroFacts (List MacroFact) )
(def (matching-macros name facts)
  (facts-with-field facts macro-fact-name name))

;;; POO facts can relate through class/protocol name, generic, or receiver.
;;; The disjunction keeps method and receiver evidence attached before policy
;;; suggests object-system repairs.
;; : (-> DefinitionName PooFacts (List PooFormFact) )
(def (matching-poo-protocols name facts)
  (facts-with-any-field facts
                        [poo-form-fact-name
                         poo-form-fact-generic
                         poo-form-fact-receiver]
                        name))

;;; Fact matching combinators keep parser correlation declarative.
;;; Each owner-specific matcher supplies only an accessor and the target name;
;;; the shared helpers own optional-field normalization and list membership.
;;; Higher-order boundary: accessor procedures are caller-owned evidence routes;
;;; these helpers own only reusable filter/search composition.
;; facts-with-field
;;   : (forall (fact)
;;       (-> (List fact)
;;           (-> fact MaybeString)
;;           DefinitionName
;;           (List fact)))
;;   | doc m%
;;       `facts-with-field facts accessor name` keeps facts whose optional
;;       string field equals the definition name.
;;     %
(def (facts-with-field facts accessor name)
  (filter (fun (matches-field? fact)
            (fact-field=? accessor name fact))
          facts))

;;; Higher-order boundary: this helper is the disjunction form for facts that
;;; can point at a definition through several parser-owned accessors.
;; facts-with-any-field
;;   : (forall (fact)
;;       (-> (List fact)
;;           (List (-> fact MaybeString))
;;           DefinitionName
;;           (List fact)))
;;   | doc m%
;;       `facts-with-any-field facts accessors name` keeps facts when any
;;       optional string field links the fact to `name`.
;;     %
(def (facts-with-any-field facts accessors name)
  (filter (fun (matches-any-field? fact)
            (ormap (cut fact-field=? <> name fact) accessors))
          facts))

;;; Higher-order boundary: membership accessors remain explicit so repeated
;;; caller-name lists do not become ad hoc source-text scans.
;; facts-containing-field
;;   : (forall (fact)
;;       (-> (List fact)
;;           (-> fact (List DefinitionName))
;;           DefinitionName
;;           (List fact)))
;;   | doc m%
;;       `facts-containing-field facts accessor name` keeps facts whose
;;       parser-owned name list contains the definition.
;;     %
(def (facts-containing-field facts accessor name)
  (filter (fun (contains-field? fact)
            (member name (accessor fact)))
          facts))

;;; Higher-order boundary: this is the single-result variant of field matching,
;;; used where adjacency makes the first parser fact authoritative.
;; first-fact-with-field
;;   : (forall (fact)
;;       (-> (List fact)
;;           (-> fact MaybeString)
;;           DefinitionName
;;           (Maybe fact)))
;;   | doc m%
;;       `first-fact-with-field facts accessor name` returns the first adjacent
;;       parser fact linked by the supplied accessor.
;;     %
(def (first-fact-with-field facts accessor name)
  (find (fun (matches-field? fact)
          (fact-field=? accessor name fact))
        facts))

;; fact-field=?
;;   : (forall (fact)
;;       (-> (-> fact MaybeString)
;;           DefinitionName
;;           fact
;;           Boolean))
;;   | doc m%
;;       `fact-field=? accessor name fact` compares optional parser string
;;       fields with a definition name.
;;     %
(def (fact-field=? accessor name fact)
  (equal? (or (accessor fact) "") name))

;;; Role classification compresses parser evidence into a repair boundary.
;;; Specific preservation roles win before generic public/internal helper roles.
;; : (-> Definition Exported? MacroFacts PooFacts LoopDrivers Role )
(def (function-quality-role definition exported? macros poo-forms loop-drivers)
  (cond
   ((pair? macros) "macro-helper")
   ((poo-method-profile? poo-forms) "protocol-method")
   ((pair? poo-forms) "poo-protocol-boundary")
   ((pair? loop-drivers) "driver")
   ((string-suffix? "?" (definition-name definition)) "predicate")
   (exported? "public-api")
   ((zero? (definition-arity definition)) "constant")
   (else "internal-helper")))

;;; Method profiles preserve protocol dispatch before generic POO evidence.
;;; The predicate stays small so role precedence remains obvious.
;; : (-> PooFacts Boolean )
(def (poo-method-profile? poo-forms)
  (ormap (lambda (fact)
           (member (poo-form-fact-role fact) '("method" "protocol")))
         poo-forms))

;;; Facet aggregation is the profile's searchable vocabulary.
;;; Each parser fact family contributes only stable role/facet tokens so search
;;; and policy can compose repairs without reading source text.
;; : (-> Role Exported? TypedQuality CommentQuality TypedContract CommentFact CallFacts ControlFlow HigherOrder PredicateFamilies FieldAccess LoopDrivers Macros PooFacts (List QualityFacet) )
(def (function-quality-facets role exported? typed-quality comment-quality typed-contract comment-fact calls control-flow-forms higher-order-forms predicate-family-facts field-access-pattern-facts loop-driver-facts macros poo-forms)
  (unique
   (filter identity
           (append ["function-quality-profile"
                    "functionQualityProfile"
                    "quality-profile"
                    "function-quality"
                    role
                    (and exported? "public-api")
                    (string-append "typed-contract-" typed-quality)
                    (string-append "comment-quality-" comment-quality)
                    (and (not typed-contract) "typed-contract-missing")
                    (and (not comment-fact) "comment-quality-missing")
                    (and (pair? predicate-family-facts)
                         "predicate-family-combinator")
                    (and (pair? field-access-pattern-facts)
                         "selector-helper")
                    (and (pair? loop-driver-facts)
                         "loop-driver-classified")
                    (and (pair? macros)
                         "macro-runtime-source-witness")
                    (and (pair? poo-forms)
                         "poo-protocol-evidence")]
                   (apply append
                          (map typed-contract-profile-facets
                               (if typed-contract [typed-contract] [])))
                   (apply append
                          (map comment-quality-fact-reasons
                               (if comment-fact [comment-fact] [])))
                   (function-quality-higher-order-profile-facets
                    higher-order-forms)
                   (function-quality-dynamic-scope-cleanup-facets
                    calls)
                   (map control-flow-fact-role control-flow-forms)
                   (map higher-order-fact-role higher-order-forms)
                   (apply append
                          (map higher-order-quality-facets
                               higher-order-forms))
                   (apply append
                          (map predicate-family-fact-quality-facets
                               predicate-family-facts))
                   (apply append
                          (map field-access-pattern-fact-quality-facets
                               field-access-pattern-facts))
                   (apply append
                          (map loop-driver-fact-quality-facets
                               loop-driver-facts))
                   (apply append
                          (map function-quality-poo-profile-facets
                               poo-forms))))))

;;; POO profile facets consume option tokens emitted by parser/poo.ss.  The
;;; parser owns method body shape classification from native datum syntax; this
;;; layer only turns those stable tokens into repair vocabulary.
;; : (-> PooFormFact (List QualityFacet) )
(def (function-quality-poo-profile-facets fact)
  (unique
   (filter identity
          (append [(and (member "methodTableBody:combinator"
                                 (poo-form-fact-options fact))
                         "method-table-combinator-body")
                    (and (member "methodTableBody:validation-boundary"
                                 (poo-form-fact-options fact))
                         "method-table-validation-boundary")
                    (and (member "methodTableBody:lambda-drift"
                                 (poo-form-fact-options fact))
                         "method-table-lambda-drift")
                    (and (member "methodTableBody:low-level"
                                 (poo-form-fact-options fact))
                         "method-table-low-level-body")]
                   (map function-quality-poo-option-facet
                        (poo-form-fact-options fact))))))

;;; Slot-specific facets let search and policy cite the exact method-table slot
;;; without reparsing source.  Only parser-owned quality tokens are projected.
;; : (-> String MaybeQualityFacet )
(def (function-quality-poo-option-facet option)
  (cond
   ((string-prefix? "methodBodyQuality:" option) option)
   (else #f)))

;;; Preservation reasons are guardrails for automated repair.
;;; Public API, macro, POO, and driver evidence become explicit constraints
;;; before style rewrites are proposed.
;; : (-> Exported? LoopDrivers MacroFacts PooFacts (List PreservationReason) )
(def (function-quality-preservation-reasons exported? loop-drivers macros poo-forms)
  (unique
   (filter identity
           (append [(and exported? "preserve-public-api")
                    (and (pair? macros)
                         "macro-runtime-source-witness-required")
                    (and (pair? poo-forms)
                         "poo-protocol-boundary")]
                   (map loop-driver-preservation-reason loop-drivers)))))

;;; Loop-driver preservation separates stateful drivers from pure loops.
;;; The driver kind decides whether policy may suggest a pure transform rewrite.
;; : (-> LoopDriverFact PreservationReason )
(def (loop-driver-preservation-reason fact)
  (let (driver-kind (loop-driver-fact-driver-kind fact))
    (cond
     ((equal? driver-kind "manual-parser-state-machine")
      "parser-combinator-rewrite-allowed-when-grammar-tests-preserve-behavior")
     ((member driver-kind
              '("io-reader-driver" "state-driver-candidate"
                "higher-order-boundary"))
      (string-append "preserve-" driver-kind))
     (else "pure-transform-rewrite-allowed-when-tests-preserve-behavior"))))

;;; Repair class is ordered from structural drift to comment polish.
;;; Comment repair is chosen only after parser facts rule out stronger shape or
;;; boundary repairs.
;; : (-> TypedQuality CommentQuality QualityFacets PredicateFamilies RepairClass )
(def (function-quality-repair-class typed-quality comment-quality quality-facets predicate-family-facts)
   (cond
   ((member "dynamic-scope-cleanup-boundary" quality-facets)
    "typed-combinator-style")
   ((pair? predicate-family-facts) "predicate-family-combinator")
   ((member "parser-combinator-boundary" quality-facets)
    "typed-combinator-style")
   ((or (member "method-table-lambda-drift" quality-facets)
        (member "method-table-low-level-body" quality-facets))
    "poo-policy")
   ((member "manual-loop-drift" quality-facets) "typed-combinator-style")
   ((member "wrapper-lambda-drift" quality-facets) "typed-combinator-style")
   ((member "function-specialization-opportunity" quality-facets)
    "typed-combinator-style")
   ((member "lambda-match-rewrite-opportunity" quality-facets)
    "typed-combinator-style")
   ((member typed-quality '("missing" "invalid" "weak"))
    "typed-combinator-style")
   ((member comment-quality '("missing" "absent" "weak"))
    "engineering-comment-quality")
   ((member "poo-protocol-evidence" quality-facets) "poo-policy")
   ((member "macro-runtime-source-witness" quality-facets)
    "macro-runtime-source-witness")
   (else "stable")))

;;; Parser confidence is a simple evidence count, not a semantic proof.
;;; It tells downstream ranking how much native evidence backs the profile.
;; : (-> TypedContract CommentFact CallFacts ControlFlow HigherOrder PredicateFamilies FieldAccess LoopDrivers MacroFacts PooFacts ParserConfidence )
(def (function-quality-parser-confidence typed-contract comment-fact calls control-flow-forms higher-order-forms predicate-family-facts field-access-pattern-facts loop-driver-facts macros poo-forms)
  (let (evidence-count
        (+ (if typed-contract 1 0)
           (if comment-fact 1 0)
           (length calls)
           (length control-flow-forms)
           (length higher-order-forms)
           (length predicate-family-facts)
           (length field-access-pattern-facts)
           (length loop-driver-facts)
           (length macros)
           (length poo-forms)))
    (cond
     ((>= evidence-count 4) "high")
     ((>= evidence-count 2) "medium")
     (else "baseline"))))

;;; Advice is intentionally compact because LLM repair receives the profile too.
;;; The text names the repair direction while preservation reasons carry the
;;; concrete constraints.
;; : (-> RepairClass PreservationReasons QualityFacets Advice )
(def (function-quality-advice repair-class preservation-reasons quality-facets)
  (cond
   ((member "dynamic-scope-cleanup-boundary" quality-facets)
    "wrap dynamic state changes in dynamic-wind, with-unwind-protect, or parameterize so cleanup runs across exceptions and continuations")
   ((equal? repair-class "predicate-family-combinator")
    "repair predicate drift with small selector helpers or a bounded predicate combinator; keep public predicate names stable")
   ((member "wrapper-lambda-drift" quality-facets)
    "replace repeated wrapper lambdas with a named function factory, cut/curry/rcurry, or compose/rcompose pipeline; use case-lambda when arity variants are real")
   ((member "function-specialization-opportunity" quality-facets)
    "turn repeated anonymous specialization into a first-class helper boundary before editing call sites")
   ((member "lambda-match-rewrite-opportunity" quality-facets)
    "replace unary lambdas whose whole body matches the same argument with lambda-match or lambda-ematch")
   ((member "method-table-lambda-drift" quality-facets)
    "repair method-table lambdas with gerbil-poo/table.ss slot-shaped helpers, cut/curry/compose, or selector methods; preserve the protocol receiver boundary")
   ((member "method-table-low-level-body" quality-facets)
    "move low-level method-table bodies behind named helpers or combinator slots before widening the adapter")
   ((equal? repair-class "typed-combinator-style")
    "prefer small expression-returning helpers and map/filter/fold/cut when parser facts show pure transform drift")
   ((equal? repair-class "engineering-comment-quality")
    "write as many adjacent engineering comment lines as the parser evidence needs after code shape is stable")
   ((equal? repair-class "poo-policy")
    "preserve defclass/defgeneric/defmethod/defprotocol boundaries and cite parser-owned receiver evidence")
   ((equal? repair-class "macro-runtime-source-witness")
    "check runtime-source macro witness before editing transformers")
   ((pair? preservation-reasons)
    "preserve public, macro, POO, IO, or state boundaries before style repair")
   (else "no policy repair is implied; profile is available for search and future correlation")))
