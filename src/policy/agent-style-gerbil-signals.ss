;;; -*- Gerbil -*-
;;; Gerbil-specific style signals for R013 typed-combinator guidance.

(import :asp-gerbil-scheme/src/parser/facade
        (only-in :asp-gerbil-scheme/src/policy/agent-style-gerbil-boundary-signals
                 typed-combinator-style-concurrency-control-quality-facets
                 typed-combinator-style-concurrency-control-signals
                 typed-combinator-style-concurrency-control-targets
                 typed-combinator-style-ssxi-optimizer-metadata-boundary-quality-facets
                 typed-combinator-style-ssxi-optimizer-metadata-boundary-signals
                 typed-combinator-style-ssxi-optimizer-metadata-boundary-targets
                 typed-combinator-style-expander-root-boundary-quality-facets
                 typed-combinator-style-expander-root-boundary-signals
                 typed-combinator-style-expander-root-boundary-targets
                 typed-combinator-style-actor-runtime-boundary-quality-facets
                 typed-combinator-style-actor-runtime-boundary-signals
                 typed-combinator-style-actor-runtime-boundary-targets
                 typed-combinator-style-mop-c3-linearization-boundary-quality-facets
                 typed-combinator-style-mop-c3-linearization-boundary-signals
                 typed-combinator-style-mop-c3-linearization-boundary-targets
                 typed-combinator-style-exception-continuation-boundary-quality-facets
                 typed-combinator-style-exception-continuation-boundary-signals
                 typed-combinator-style-exception-continuation-boundary-targets
                 typed-combinator-style-serialization-boundary-facts
                 typed-combinator-style-serialization-boundary-quality-facets
                 typed-combinator-style-serialization-boundary-signals
                 typed-combinator-style-serialization-boundary-targets
                 typed-combinator-style-slot-lens-boundary-quality-facets
                 typed-combinator-style-slot-lens-boundary-signals
                 typed-combinator-style-slot-lens-boundary-targets)
        :asp-gerbil-scheme/src/policy/agent-style-gerbil-macro-signals
        (only-in :asp-gerbil-scheme/src/policy/agent-style-gerbil-signal-support
                 typed-combinator-style-facts->quality-facet
                 typed-combinator-style-facts->signals
                 typed-combinator-style-facts->targets
                 typed-contract-fact-mentions-any?)
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-contains string-empty?)
        (only-in :std/sugar cut filter ormap))

(export typed-combinator-style-generator-quality-facets
        +typed-comment-metadata-fields+
        +gerbil-utils-implementation-signals+
        +gerbil-contract-projection-signals+
        typed-combinator-style-anti-ai-scaffold-quality-facets
        typed-combinator-style-anti-ai-scaffold-signals
        typed-combinator-style-anti-ai-scaffold-targets
        typed-combinator-style-gerbil-upstream-idiom-quality-facets
        typed-combinator-style-gerbil-upstream-idiom-signals
        typed-combinator-style-gerbil-upstream-idiom-targets
        typed-combinator-style-list-combinator-quality-facets
        typed-combinator-style-list-combinator-signals
        typed-combinator-style-list-combinator-targets
        typed-combinator-style-std-sugar-flow-quality-facets
        typed-combinator-style-std-sugar-flow-signals
        typed-combinator-style-std-sugar-flow-targets
        typed-combinator-style-loop-driver-quality-facets
        typed-combinator-style-loop-driver-signals
        typed-combinator-style-loop-driver-targets
        typed-combinator-style-parser-combinator-boundary-quality-facets
        typed-combinator-style-parser-combinator-boundary-signals
        typed-combinator-style-parser-combinator-boundary-targets
        typed-combinator-style-generator-combinator-signals
        typed-combinator-style-generator-contract-targets
        typed-combinator-style-serialization-boundary-quality-facets
        typed-combinator-style-serialization-boundary-signals
        typed-combinator-style-serialization-boundary-targets
        typed-combinator-style-slot-lens-boundary-quality-facets
        typed-combinator-style-slot-lens-boundary-signals
        typed-combinator-style-slot-lens-boundary-targets
        typed-combinator-style-concurrency-control-quality-facets
        typed-combinator-style-concurrency-control-signals
        typed-combinator-style-concurrency-control-targets
        typed-combinator-style-dynamic-scope-cleanup-quality-facets
        typed-combinator-style-dynamic-scope-cleanup-signals
        typed-combinator-style-dynamic-scope-cleanup-targets
        typed-combinator-style-ssxi-optimizer-metadata-boundary-quality-facets
        typed-combinator-style-ssxi-optimizer-metadata-boundary-signals
        typed-combinator-style-ssxi-optimizer-metadata-boundary-targets
        typed-combinator-style-expander-root-boundary-quality-facets
        typed-combinator-style-expander-root-boundary-signals
        typed-combinator-style-expander-root-boundary-targets
        typed-combinator-style-actor-runtime-boundary-quality-facets
        typed-combinator-style-actor-runtime-boundary-signals
        typed-combinator-style-actor-runtime-boundary-targets
        typed-combinator-style-mop-c3-linearization-boundary-quality-facets
        typed-combinator-style-mop-c3-linearization-boundary-signals
        typed-combinator-style-mop-c3-linearization-boundary-targets
        typed-combinator-style-exception-continuation-boundary-quality-facets
        typed-combinator-style-exception-continuation-boundary-signals
        typed-combinator-style-exception-continuation-boundary-targets
        typed-combinator-style-macro-family-quality-facets
        typed-combinator-style-macro-family-signals
        typed-combinator-style-macro-family-targets
        typed-combinator-style-macro-metaprogramming-decision-quality-facets
        typed-combinator-style-macro-metaprogramming-decision-signals
        typed-combinator-style-macro-metaprogramming-decision-targets
        typed-combinator-style-syntax-parameter-context-quality-facets
        typed-combinator-style-syntax-parameter-context-signals
        typed-combinator-style-syntax-parameter-context-targets
        typed-combinator-style-syntax-local-registry-quality-facets
        typed-combinator-style-syntax-local-registry-signals
        typed-combinator-style-syntax-local-registry-targets
        typed-combinator-style-phase-aware-macro-boundary-quality-facets
        typed-combinator-style-phase-aware-macro-boundary-signals
        typed-combinator-style-phase-aware-macro-boundary-targets
        typed-combinator-style-controlled-macro-quality-facets
        typed-combinator-style-controlled-macro-syntax-signals
        typed-combinator-style-controlled-macro-targets
        typed-combinator-style-match-extension-boundary-quality-facets
        typed-combinator-style-match-extension-boundary-signals
        typed-combinator-style-match-extension-boundary-targets
        typed-combinator-style-mop-class-macro-boundary-quality-facets
        typed-combinator-style-mop-class-macro-boundary-signals
        typed-combinator-style-mop-class-macro-boundary-targets
        typed-combinator-style-typeclass-quality-facets
        typed-combinator-style-typeclass-algebra-signals
        typed-combinator-style-typeclass-algebra-targets)

;;; Boundary:
;;; - This owner converts parser facts into bounded R013 steering signals.
;;; - It does not decide whether a finding should fire.
;;; - agent-style.ss owns policy triggering and message assembly.
;;; - Keeping these signals separate prevents the main policy owner from
;;;   becoming a sink for every Gerbil library idiom.

;;; Payload boundary:
;;; - These fields are provider-owned typedComment projection slots.
;;; - Keep them stable so policy details and JSON facts use one vocabulary.
;; (List String)
(def +typed-comment-metadata-fields+
  ["leadingName" "signatureType" "localTypes" "runtimeContracts"
   "runtimeContractsDetailed" "requires" "requiresDetailed"
   "warnings" "rationales" "docs" "docs.examples"
   "docs.hasResultExamples" "refinements"])

;;; Exemplar boundary:
;;; - These are gerbil-utils style signals, not mandatory syntax forms.
;;; - They steer repair suggestions without making policy depend on one library.
;; (List String)
(def +gerbil-utils-implementation-signals+
  ["λ/lambda-match local destructuring"
   "fun named lambda abstraction"
   "!>/!!> pipeline"
   "apply compose"
   "std/sugar chain flow"
   "if-let/when-let early-failure conditionals"
   "cut/curry/rcurry"
   "case-lambda arity specialization"
   "match/lambda-match shape dispatch"
   "values/call-with-values tuple projection"
   "parameterize/dynamic-wind control boundary"
   "parameterized expander/control state boundary"
   "syntax-case/syntax-rules hygienic macro boundary"
   "defclass/defstruct typed descriptor boundary"
   "using typed object/interface slot access"
   "parse/validate/generate split for syntax owners"
   "method-table/cache state boundary"
   "map/filter/filter-map/fold"
   "andmap/ormap/every/any predicate folds"
   "with-list-builder"])

;;; Dynamic scope cleanup boundary:
;;; - Function-quality profiles own the call-fact correlation.
;;; - This layer projects that parser-owned facet into bounded repair signals.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-dynamic-scope-cleanup-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-dynamic-scope-cleanup-facts file)
   "dynamic-scope-cleanup-boundary"))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-dynamic-scope-cleanup-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-dynamic-scope-cleanup-facts file)
   ["wrap current-directory/current-port changes in dynamic-wind, with-unwind-protect, or parameterize"
    "restore dynamic state in an after thunk so exceptions and continuations cannot skip cleanup"
    "keep dynamic state changes at a narrow helper boundary"
    "prefer parameterize when the state is a parameter binding rather than a manual setter"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-dynamic-scope-cleanup-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-dynamic-scope-cleanup-facts file)
   function-quality-profile-name))

;; : (-> SourceFile (List FunctionQualityProfile) )
(def (typed-combinator-style-dynamic-scope-cleanup-facts file)
  (filter typed-combinator-style-dynamic-scope-cleanup-profile?
          (source-file-function-quality-profiles file)))

;; : (-> FunctionQualityProfile Boolean )
(def (typed-combinator-style-dynamic-scope-cleanup-profile? profile)
  (if (member "manual-dynamic-scope-restore"
              (function-quality-profile-quality-facets profile))
    #t
    #f))

;;; Projection boundary:
;;; - These strings describe how upstream Gerbil contracts reach harness facts.
;;; - Keep agent guidance tied to projection evidence instead of invented grammar.
;; (List String)
(def +gerbil-contract-projection-signals+
  ["Scheme-native ;; : contract blocks preserve arrow structure without comment-arrow fallback"
   "Gerbil contract projection ;; : (forall (a) (-> ...)) blocks carry type aliases, runtime contracts, requires, warning, rationale, and doc sections"
   "higher-order contracts may use placeholder-looking Gerbil utility variables when the arrow/group evidence is higher-order"
   "using (value :- Type) is the native boundary for repeated class/interface slot access when parser facts prove a local typed descriptor"
   "interface/slot contracts normalize once at the projection boundary; downstream helpers should not repeat get/set/validate scaffolding"])

;;; Anti-scaffold boundary:
;;; - gerbil-poo/io.ss and fun.ss teach protocol layers, not copyable code.
;;; - Emit this only when existing parser facts prove collapsed representation
;;;   or POO algebra responsibilities in one owner.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-anti-ai-scaffold-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-anti-ai-scaffold-facts file)
   "anti-ai-scaffold-boundary"))

;;; Guidance boundary:
;;; - Signals name repair moves for generated-looking protocol scaffolds.
;;; - They do not require importing gerbil-poo or gerbil-utils downstream.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-anti-ai-scaffold-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-anti-ai-scaffold-facts file)
   ["replace one-owner protocol conversion scaffolding with local adapter boundaries"
    "prefer define-type methods.* or named protocol helpers over hand-written dispatch tables"
    "use compose when json/string adapter flow is a direct transform"
    "keep marshal self-delimiting and bytes representation-only boundaries separate"
    "lift wrapper IO/JSON/bytes/marshal through wrap/unwrap when a typeclass wrapper is present"]))

;;; Target boundary:
;;; - Reuse the precise targets from proven feature facts.
;;; - The target list points at the collapsed local owner, not reference repos.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-anti-ai-scaffold-targets file)
  (append
   (typed-combinator-style-serialization-boundary-targets file)
   (typed-combinator-style-typeclass-algebra-targets file)))

;;; Fact boundary:
;;; - Anti-scaffold evidence is a union of existing parser-owned facts.
;;; - No implementation text scanning is allowed here.
;; : (-> SourceFile (List ParserOwnedFact) )
(def (typed-combinator-style-anti-ai-scaffold-facts file)
  (append
   (typed-combinator-style-serialization-boundary-facts file)
   (typed-combinator-style-typeclass-poo-forms file)))

;;; Upstream idiom boundary:
;;; - Gerbil core/compiler style teaches match-shaped dispatch, eq hash indexes,
;;;   and cut-shaped helper plumbing.
;;; - This lane reuses existing parser facts; it never scans source text or
;;;   treats gerbil:// examples as downstream dependencies.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-gerbil-upstream-idiom-quality-facets file)
  (if (or (pair? (typed-combinator-style-list-combinator-facts file))
          (pair? (typed-combinator-style-loop-driver-facts file)))
    ["gerbil-upstream-idiom-boundary"]
    []))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-gerbil-upstream-idiom-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-gerbil-upstream-idiom-quality-facets file)
   ["use match/match* or with/with* when branch structure is the data shape"
    "precompute make-hash-table-eq indexes when symbol or identifier lookup repeats in a hot traversal"
    "use cut/curry/rcurry for fixed-argument helper plumbing before adding wrapper lambdas"
    "keep hash index construction outside the traversal that consumes it"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-gerbil-upstream-idiom-targets file)
  (append
   (typed-combinator-style-list-combinator-targets file)
   (typed-combinator-style-loop-driver-targets file)))

;;; List combinator boundary:
;;; - gerbil-utils/list.ss and base.ss teach list traversal expression shape.
;;; - Emit only when parser facts prove both a List contract and manual-loop
;;;   drift in the same owner.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-list-combinator-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-list-combinator-facts file)
   "list-combinator-boundary"))

;;; Guidance boundary:
;;; - Signals name local repair moves for generated-looking list traversal.
;;; - They do not require importing gerbil-utils downstream.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-list-combinator-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-list-combinator-facts file)
   ["replace hand-written list recursion scaffolding with map/filter/fold or a named reducer boundary"
    "use lambda-match at the list destructuring boundary when pair shape is the point"
    "prefer filter-map when selection and projection happen in the same traversal"
    "use with-list-builder only when output construction needs an explicit builder"]))

;;; Target boundary:
;;; - Report typed-contract owners with proven list traversal drift.
;;; - The target list stays local to the owner being repaired.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-list-combinator-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-list-combinator-facts file)
   typed-contract-fact-definition-name))

;;; Std sugar flow boundary:
;;; - std/sugar.ss teaches `chain` for expression flow and `if-let`/`when-let`
;;;   for early-failure conditionals.
;;; - Emit only when typed contracts mark flow/workflow ownership and parser
;;;   control-flow facts prove repeated conditional scaffolding in that owner.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-std-sugar-flow-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-std-sugar-flow-facts file)
   "std-sugar-flow-boundary"))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-std-sugar-flow-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-std-sugar-flow-facts file)
   ["replace nested let/if flow scaffolding with std/sugar chain when the data path is linear"
    "use if-let or when-let when a conditional branch is just an early-failure binding"
    "keep std/sugar flow local to expression-level transforms; do not hide IO or state-machine boundaries"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-std-sugar-flow-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-std-sugar-flow-facts file)
   typed-contract-fact-definition-name))

;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-std-sugar-flow-facts file)
  (filter (lambda (fact)
            (typed-combinator-style-std-sugar-flow-fact? file fact))
          (source-file-typed-contract-facts file)))

;; : (-> SourceFile TypedContractFact Boolean )
(def (typed-combinator-style-std-sugar-flow-fact? file fact)
  (let (definition-name (typed-contract-fact-definition-name fact))
    (and (typed-combinator-style-std-sugar-flow-contract? fact)
         (typed-combinator-style-std-sugar-flow-profile?
          file
          definition-name)
         (typed-combinator-style-caller-uses-early-failure-lookup?
          file
          definition-name)
         (>= (typed-combinator-style-conditional-branch-count
              file
              definition-name)
             2)
         (not (typed-combinator-style-caller-uses-std-sugar-flow?
               file
               definition-name)))))

;; : (-> SourceFile DefinitionName Boolean )
(def (typed-combinator-style-std-sugar-flow-profile? file definition-name)
  (ormap (lambda (profile)
           (and (equal? (function-quality-profile-name profile)
                        definition-name)
                (typed-combinator-style-std-sugar-flow-profile-facets?
                 (function-quality-profile-quality-facets profile))))
         (source-file-function-quality-profiles file)))

;; : (-> (List QualityFacet) Boolean )
(def (typed-combinator-style-std-sugar-flow-profile-facets? facets)
  (and (member "control-flow:conditional-branch" facets)
       (not (typed-combinator-style-std-sugar-flow-preserved-boundary? facets))
       (not (typed-combinator-style-std-sugar-flow-composed-boundary? facets))))

;; : (-> (List QualityFacet) Boolean )
(def (typed-combinator-style-std-sugar-flow-preserved-boundary? facets)
  (ormap (cut member <> facets)
         ["control-flow:protected-control"
          "control-flow:resource-scope"
          "preserve-named-let-driver"
          "io-state-boundary"
          "state-driver-candidate"
          "higher-order-boundary"
          "macro-runtime-source-witness"
          "poo-protocol-evidence"]))

;; : (-> (List QualityFacet) Boolean )
(def (typed-combinator-style-std-sugar-flow-composed-boundary? facets)
  (ormap (cut member <> facets)
         ["higher-order-used"
          "combinator-backed"
          "higher-order-transform"
          "combinator-composition"
          "function-specialization-abstraction"
          "expression-level-composition"
          "base-style-combinator-composition"
          "pipeline-composition"]))

;; : (-> SourceFile DefinitionName Boolean )
(def (typed-combinator-style-caller-uses-early-failure-lookup? file definition-name)
  (ormap (lambda (call)
           (and (equal? (or (call-fact-caller call) "")
                        definition-name)
                (member (call-fact-callee call)
                        ["assq" "assv" "assoc" "hash-get" "table-ref"
                         "alist-ref" "agetq" "getq"])))
         (source-file-calls file)))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-std-sugar-flow-contract? fact)
  (typed-contract-fact-mentions-any?
   fact
   ["Flow" "flow" "Workflow" "workflow" "Pipeline" "pipeline"
    "Decision" "decision" "Maybe" "maybe" "Optional" "optional"]))

;; : (-> SourceFile DefinitionName Integer )
(def (typed-combinator-style-conditional-branch-count file definition-name)
  (length
   (filter (lambda (fact)
             (and (equal? (or (control-flow-fact-caller fact) "")
                          definition-name)
                  (equal? (control-flow-fact-role fact)
                          "conditional-branch")))
           (source-file-control-flow-forms file))))

;; : (-> SourceFile DefinitionName Boolean )
(def (typed-combinator-style-caller-uses-std-sugar-flow? file definition-name)
  (ormap (lambda (call)
           (and (equal? (or (call-fact-caller call) "") definition-name)
                (member (call-fact-callee call)
                        ["chain" "if-let" "when-let" "awhen"])))
         (source-file-calls file)))

;;; Loop-driver boundary:
;;; - Pure named-let loops are parser-owned evidence even when older code lacks
;;;   a precise List traversal contract.
;;; - IO, state, and higher-order loops stay preserved by the loop-driver
;;;   classifier and do not emit this repair signal.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-loop-driver-quality-facets file)
  (let (facts (typed-combinator-style-loop-driver-facts file))
    (if (null? facts)
      []
      (unique
       (apply append
              (map loop-driver-fact-quality-facets facts))))))

;;; Guidance boundary:
;;; - This is the combinator repair lane for pure transform owners.
;;; - Keep the advice constrained to pure transform loops.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-loop-driver-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-loop-driver-facts file)
   ["replace pure named-let accumulator loops with map/filter/filter-map/fold when behavior is a data transform"
    "split source/form reader loops from selector or projection helpers, then compose the caller with filter-map/map/fold"
    "extract inline call-with-input-file reader loops into a port reader helper, then pass that helper to the file reader boundary"
    "extract mapper, predicate, and reducer helpers before rewriting the loop body"
    "preserve named-let loops when parser facts show state, generator, higher-order, or pure reader-boundary evidence"]))

;;; Target boundary:
;;; - Use caller names when available, otherwise the loop label.
;;; - This gives repair a bounded edit target without relying on typed comments.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-loop-driver-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-loop-driver-facts file)
   typed-combinator-style-loop-driver-target-name))

;;; Fact boundary:
;;; - Consume only parser-classified pure transform loops.
;;; - No source text or reference-repo dependency is used here.
;; : (-> SourceFile (List LoopDriverFact) )
(def (typed-combinator-style-loop-driver-facts file)
  (filter typed-combinator-style-loop-driver-fact?
          (source-file-loop-driver-facts file)))

;; : (-> LoopDriverFact Boolean )
(def (typed-combinator-style-loop-driver-fact? fact)
  (member "manual-loop-drift"
          (loop-driver-fact-quality-facets fact)))

;; : (-> LoopDriverFact TargetName )
(def (typed-combinator-style-loop-driver-target-name fact)
  (let (caller (loop-driver-fact-caller fact))
    (if (and (string? caller)
             (not (string-empty? caller)))
      caller
      (loop-driver-fact-name fact))))

;;; Parser-combinator boundary:
;;; - std/parser/defparser.ss teaches grammar-owned parser construction.
;;; - Emit only when parser-owned loop facts prove string cursor parsing drift.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-parser-combinator-boundary-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-parser-combinator-boundary-facts file)
   "parser-combinator-boundary"))

;;; Guidance boundary:
;;; - Manual cursor parsing is the high-impact AI scaffold this rule repairs.
;;; - The repair stays local to parser grammar and error boundaries.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-parser-combinator-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-parser-combinator-boundary-facts file)
   ["replace manual string cursor parsers with std/parser defparser grammar boundaries"
    "use parser-fail/parser-rewind and raise-parse-error for source-aware parser failures"
    "keep token/domain construction at the parser boundary instead of leaking substring cursor tuples"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-parser-combinator-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-parser-combinator-boundary-facts file)
   typed-combinator-style-loop-driver-target-name))

;; : (-> SourceFile (List LoopDriverFact) )
(def (typed-combinator-style-parser-combinator-boundary-facts file)
  (filter typed-combinator-style-parser-combinator-boundary-fact?
          (source-file-loop-driver-facts file)))

;; : (-> LoopDriverFact Boolean )
(def (typed-combinator-style-parser-combinator-boundary-fact? fact)
  (and (equal? (loop-driver-fact-driver-kind fact)
               "manual-parser-state-machine")
       (member "parser-combinator-boundary"
               (loop-driver-fact-quality-facets fact))))

;;; Fact boundary:
;;; - A List contract alone is not enough: the parser must also classify a
;;;   manual loop profile for this owner.
;;; - The filter remains typed-contract based so policy does not read source.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-list-combinator-facts file)
  (if (typed-combinator-style-list-combinator-profile? file)
    (filter typed-combinator-style-list-combinator-fact?
            (source-file-typed-contract-facts file))
    []))

;;; Profile gate:
;;; - Manual-loop drift is parser-owned shape evidence.
;;; - Positive sequence roles alone must not trigger this anti-scaffold facet.
;; : (-> SourceFile Boolean )
(def (typed-combinator-style-list-combinator-profile? file)
  (ormap (lambda (profile)
           (member "manual-loop-drift"
                   (function-quality-profile-quality-facets profile)))
         (source-file-function-quality-profiles file)))

;;; Contract gate:
;;; - Require an explicit list traversal contract, not an arbitrary List type.
;;; - Scenario fixtures and production owners use Scheme-native typed blocks.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-list-combinator-fact? fact)
  (and (typed-contract-fact-mentions-any?
        fact
        ["List" "NonEmptyList" "list"])
       (typed-contract-fact-mentions-any?
        fact
        ["Map" "map" "Filter" "filter" "Fold" "fold" "Builder" "builder"
         "Traversal" "traversal"])))

;;; Generator contracts are first-class style evidence.  They should steer the
;;; agent toward named generator protocol boundaries instead of ad hoc producer
;;; loops. gerbil-utils/generator.ss is the reference corpus, not a required
;;; downstream dependency.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-generator-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-generator-contract-facts file)
   "generator-combinator-boundary"))

;;; Signal boundary:
;;; - Generator guidance is emitted only when typed-contract facts prove it.
;;; - Empty output means the caller should not recommend generator rewrites.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-generator-combinator-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-generator-contract-facts file)
   ["Generating contract projection"
    "generating<-list source adapter"
    "generating-map transform"
    "generating-fold reducer"
    "generating-partition split"
    "generating-merge priority merge"
    "generating<-cothread continuation bridge"]))

;;; Target projection keeps the public policy payload compact.
;;; Mapping over facts is safe here because the detector already filtered to
;;; generator contracts; no fallback source scan is needed.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-generator-contract-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-generator-contract-facts file)
   typed-contract-fact-definition-name))

;;; Boundary:
;;; - Generator detection is derived from typed-contract facts.
;;; - Output, inputs, and tokens are all checked because typed blocks can
;;;   carry `Generating` at different nesting levels.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-generator-contract-facts file)
  (filter typed-combinator-style-generator-contract-fact?
          (source-file-typed-contract-facts file)))

;;; Predicate boundary:
;;; - A generator contract can mention `Generating` in output, input, or tokens.
;;; - The ormap path preserves nested typed blocks without flattening them into
;;;   raw text heuristics.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-generator-contract-fact? fact)
  (or (member "Generating" (typed-contract-fact-tokens fact))
      (and (string? (typed-contract-fact-contract-output fact))
           (string-contains (typed-contract-fact-contract-output fact)
                            "Generating"))
      (ormap (lambda (input)
               (and (string? input)
                    (string-contains input "Generating")))
             (typed-contract-fact-contract-inputs fact))))
