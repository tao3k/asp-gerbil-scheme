;;; -*- Gerbil -*-
;;; Agent-facing repair payload for typed-combinator style findings.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-style-steering
        :asp-gerbil-scheme/src/policy/agent-style-gerbil-signals
        :asp-gerbil-scheme/src/policy/agent-style-destructuring-signals
        :asp-gerbil-scheme/src/policy/agent-style-docs
        :asp-gerbil-scheme/src/policy/agent-style-message
        :asp-gerbil-scheme/src/policy/agent-style-performance-signals
        :asp-gerbil-scheme/src/policy/gerbil-utils-source
        (only-in :std/srfi/1 take)
        (only-in :std/sugar hash))

(export typed-combinator-style-details)

;;; Repair payload: keep agent-facing fields bounded while preserving enough evidence to edit safely.
;; : (-> SourceFile Nat Nat Nat Nat Nat Evidence Nat Boolean Coverage QualityFacets RepairEvidence Boolean PolicyDetails )
(def (typed-combinator-style-details file definition-count typed-comment-line-count valid-typed-comment-count invalid-typed-comment-count missing-count implementation-evidence implementation-evidence-count missing-implementation-evidence? implementation-evidence-callers covered-definition-names covered-definition-count function-definition-count minimum-covered-definition-count uncovered-definition-names implementation-coverage-insufficient? typed-doc-missing-targets typed-forall-missing-targets quality-facets repair-evidence typed-doc-missing? typed-forall-missing? quality-repair-triggered?)
  (hash (styleGuide "typed-combinator-style")
        (styleCommand "asp gerbil-scheme guide --code --topic typed-combinator-style --intent style")
        (expectedCommentPrefix ";;")
        (expectedCommentShape "adjacent Gerbil contract projection block; generic helpers should keep both the polymorphic generic reasoning line ;; : (forall (k v) (-> [(Pair k v)] [(Pair k v)] [(Pair k v)])) and a readable/domain summary such as ;; : (-> List Alist Alist)")
        (signatureShape "adjacent Gerbil contract/signature projection using human-readable polymorphic generic lines plus readable/domain lines such as ;; : (-> (Maybe Type) (Maybe Type) Boolean); every ;; : line is parser-validated")
        (expectedDocShape "full form for role/facet risk boundaries: leading name matching the definition, ;;   : signature, optional ;;   | type/contract/requires/warning/rationale fields, and ;;   | doc m% with # Examples fenced Scheme input/result")
        (typedDocRequiredWhen "arity-bearing macro/protocol/POO roles, or exported helpers that also carry parser-owned risk facets such as macro-runtime-source-witness, poo-protocol-evidence, or loop-driver-classified")
        (typedCommentMetadataFields +typed-comment-metadata-fields+)
        (runtimeWitnessPolicy
         "use | contract for runtime predicate evidence, | requires for named preconditions, and | warning/| rationale only with concrete parser-visible witness")
        (typedDocMissing typed-doc-missing?)
        (typedDocMissingCount (length typed-doc-missing-targets))
        (typedDocMissingTargets
         (take typed-doc-missing-targets
               (min 12 (length typed-doc-missing-targets))))
        (typedForallMissing typed-forall-missing?)
        (typedForallMissingCount (length typed-forall-missing-targets))
        (typedForallMissingTargets
         (take typed-forall-missing-targets
               (min 12 (length typed-forall-missing-targets))))
        (typedForallPolicy
         "parser-owned public higher-order, sequence, and parameterized functional helpers must bind type variables with explicit forall; missing either the forall line for human/agent polymorphic reasoning or the second readable/domain signature line triggers a warning")
        (contractLinePolicy "multi-line typed-combinator-style contracts are allowed when needed to preserve precision")
        (compositionShape "Gerbil-native expression shape; prefer lambda-match/match for shape dispatch, cut/curry/rcurry for specialization, case-lambda for real arity boundaries, values/call-with-values for tuple projection, and map/filter/filter-map/fold/andmap/ormap for sequence transforms")
        (qualityReferenceCorpus "gerbil-reference-corpus")
        (qualityReference
         (typed-combinator-style-quality-reference-details
          file
          quality-facets))
        (functionShape "single-purpose expression-returning helper; one visible data-flow shape per function")
        (agentRepairStandard "rewrite toward learned Gerbil/Gambit style: small algebraic helpers, lambda-match/match where shape is the boundary, cut/curry/case-lambda for specialization, values for tuple protocols, and minimal let*/mutation scaffolding")
        (expressionLevelRewrite "extract predicate/mapper/reducer helpers, then compose with lambda-match/match/cut/curry/case-lambda/values/filter-map/map/fold/andmap/ormap when behavior fits")
        (antiPattern "basic Scheme scaffolding: procedural let* pipeline, broad named-let accumulator, repeated car/cdr/list-ref projection, or nested conditional body when a Gerbil-native helper, match, selector, or combinator would expose the data flow")
        (passiveRepairFlow "policy-finding -> agentRepair -> guide-code -> bounded edit")
        (implementationEvidenceCount implementation-evidence-count)
        (implementationEvidence
         (take implementation-evidence
               (min 5 (length implementation-evidence))))
        (missingImplementationEvidence missing-implementation-evidence?)
        (implementationEvidenceCallers
         (take implementation-evidence-callers
               (min 8 (length implementation-evidence-callers))))
        (coveredDefinitionCount covered-definition-count)
        (coveredDefinitions
         (take covered-definition-names
               (min 8 (length covered-definition-names))))
        (functionDefinitionCount function-definition-count)
        (minimumCoveredDefinitionCount minimum-covered-definition-count)
        (uncoveredDefinitionCount (length uncovered-definition-names))
        (uncoveredDefinitions
         (take uncovered-definition-names
               (min 8 (length uncovered-definition-names))))
        (implementationCoverageInsufficient
         implementation-coverage-insufficient?)
        (minimumImplementationCoverage
         "at least two thirds of arity-bearing definitions must have parser-owned Gerbil-native idiom evidence")
        (gerbilNativeIdiomPriority
         ["lambda-match/match at destructuring boundaries"
          "with/with* for local destructuring boundaries"
          "alet/alet* for dependent maybe-value chains"
          "case for closed symbolic/datum dispatch"
          "ast-case/syntax-case only for real syntax-object or AST owners"
          "cut/curry/rcurry for partial application"
          "case-lambda only for real arity specialization"
          "values/call-with-values instead of anonymous vector/list tuple protocols"
          "map/filter/filter-map/fold/andmap/ormap for sequence transforms"
          "parameterize/dynamic-wind when control state or cleanup is the boundary"])
        (gerbilUtilsImplementationSignals +gerbil-utils-implementation-signals+)
        (generatorCombinatorSignals
         (typed-combinator-style-generator-combinator-signals file))
        (generatorContractTargets
         (typed-combinator-style-generator-contract-targets file))
        (serializationBoundarySignals
         (typed-combinator-style-serialization-boundary-signals file))
        (serializationBoundaryTargets
         (typed-combinator-style-serialization-boundary-targets file))
        (antiAiScaffoldSignals
         (typed-combinator-style-anti-ai-scaffold-signals file))
        (antiAiScaffoldTargets
         (typed-combinator-style-anti-ai-scaffold-targets file))
        (listCombinatorBoundarySignals
         (typed-combinator-style-list-combinator-signals file))
        (listCombinatorBoundaryTargets
         (typed-combinator-style-list-combinator-targets file))
        (gerbilUpstreamIdiomSignals
         (typed-combinator-style-gerbil-upstream-idiom-signals file))
        (gerbilUpstreamIdiomTargets
         (typed-combinator-style-gerbil-upstream-idiom-targets file))
        (stdSugarFlowBoundarySignals
         (typed-combinator-style-std-sugar-flow-signals file))
        (stdSugarFlowBoundaryTargets
         (typed-combinator-style-std-sugar-flow-targets file))
        (loopDriverCombinatorSignals
         (typed-combinator-style-loop-driver-signals file))
        (loopDriverCombinatorTargets
         (typed-combinator-style-loop-driver-targets file))
        (parserCombinatorBoundarySignals
         (typed-combinator-style-parser-combinator-boundary-signals file))
        (parserCombinatorBoundaryTargets
         (typed-combinator-style-parser-combinator-boundary-targets file))
        (destructuringBoundarySignals
         (typed-combinator-style-destructuring-signals file))
        (destructuringBoundaryTargets
         (typed-combinator-style-destructuring-targets file))
        (slotLensBoundarySignals
         (typed-combinator-style-slot-lens-boundary-signals file))
        (slotLensBoundaryTargets
         (typed-combinator-style-slot-lens-boundary-targets file))
        (concurrencyControlBoundarySignals
         (typed-combinator-style-concurrency-control-signals file))
        (concurrencyControlBoundaryTargets
         (typed-combinator-style-concurrency-control-targets file))
        (dynamicScopeCleanupSignals
         (typed-combinator-style-dynamic-scope-cleanup-signals file))
        (dynamicScopeCleanupTargets
         (typed-combinator-style-dynamic-scope-cleanup-targets file))
        (ssxiOptimizerMetadataBoundarySignals
         (typed-combinator-style-ssxi-optimizer-metadata-boundary-signals
          file))
        (ssxiOptimizerMetadataBoundaryTargets
         (typed-combinator-style-ssxi-optimizer-metadata-boundary-targets
          file))
        (expanderRootBoundarySignals
         (typed-combinator-style-expander-root-boundary-signals file))
        (expanderRootBoundaryTargets
         (typed-combinator-style-expander-root-boundary-targets file))
        (actorRuntimeBoundarySignals
         (typed-combinator-style-actor-runtime-boundary-signals file))
        (actorRuntimeBoundaryTargets
         (typed-combinator-style-actor-runtime-boundary-targets file))
        (mopC3LinearizationBoundarySignals
         (typed-combinator-style-mop-c3-linearization-boundary-signals file))
        (mopC3LinearizationBoundaryTargets
         (typed-combinator-style-mop-c3-linearization-boundary-targets file))
        (exceptionContinuationBoundarySignals
         (typed-combinator-style-exception-continuation-boundary-signals
          file))
        (exceptionContinuationBoundaryTargets
         (typed-combinator-style-exception-continuation-boundary-targets
          file))
        (macroFamilySignals
         (typed-combinator-style-macro-family-signals file))
        (macroFamilyTargets
         (typed-combinator-style-macro-family-targets file))
        (macroMetaprogrammingDecisionSignals
         (typed-combinator-style-macro-metaprogramming-decision-signals file))
        (macroMetaprogrammingDecisionTargets
         (typed-combinator-style-macro-metaprogramming-decision-targets file))
        (syntaxParameterContextSignals
         (typed-combinator-style-syntax-parameter-context-signals file))
        (syntaxParameterContextTargets
         (typed-combinator-style-syntax-parameter-context-targets file))
        (syntaxLocalRegistrySignals
         (typed-combinator-style-syntax-local-registry-signals file))
        (syntaxLocalRegistryTargets
         (typed-combinator-style-syntax-local-registry-targets file))
        (phaseAwareMacroBoundarySignals
         (typed-combinator-style-phase-aware-macro-boundary-signals file))
        (phaseAwareMacroBoundaryTargets
         (typed-combinator-style-phase-aware-macro-boundary-targets file))
        (controlledMacroSyntaxSignals
         (typed-combinator-style-controlled-macro-syntax-signals file))
        (controlledMacroTargets
         (typed-combinator-style-controlled-macro-targets file))
        (matchExtensionBoundarySignals
         (typed-combinator-style-match-extension-boundary-signals file))
        (matchExtensionBoundaryTargets
         (typed-combinator-style-match-extension-boundary-targets file))
        (mopClassMacroBoundarySignals
         (typed-combinator-style-mop-class-macro-boundary-signals file))
        (mopClassMacroBoundaryTargets
         (typed-combinator-style-mop-class-macro-boundary-targets file))
        (typeclassAlgebraSignals
         (typed-combinator-style-typeclass-algebra-signals file))
        (typeclassAlgebraTargets
         (typed-combinator-style-typeclass-algebra-targets file))
        (gerbilContractProjectionSignals +gerbil-contract-projection-signals+)
        (implementationEvidenceSource
         "parser-owned higherOrderFacts plus callFacts; do not use raw text heuristics")
        (qualityFacetSource
         "parser-owned typedContractFacts, higherOrderFacts, booleanConditionFacts, loopDriverFacts, and functionQualityProfiles derived from native call, higher-order, and control-flow facts")
        (qualityFacets quality-facets)
        (qualityFacetSteering
         (typed-combinator-style-quality-facet-steering quality-facets))
        (qualityRepairTriggered quality-repair-triggered?)
        (agentRepairEnvelope
         (hash (flexibility "agent may choose helper names and exact composition shape")
               (constraints ["preserve selector behavior"
                             "keep public exports stable unless policy evidence permits"
                             "do not cross IO/runtime/macro boundaries without witness"])
               (nativeRepairEvidence
                (take repair-evidence (min 6 (length repair-evidence))))))
        (optimizationBoundary "when using case-lambda or a specialized branch, comment why that branch exists and keep the comment about the boundary, not the code mechanics")
        (definitionCount definition-count)
        (typedCommentCount valid-typed-comment-count)
        (typedCommentLineCount typed-comment-line-count)
        (validTypedContractCount valid-typed-comment-count)
        (invalidTypedContractCount invalid-typed-comment-count)
        (missingTypedCommentCount missing-count)
        (invalidReason "typed-combinator-style comments must be parser-owned adjacent algebraic transform signatures; see invalidTypedContractReasons for exact parser reasons")
        (invalidTypedContractReasons
         (file-typed-contract-invalid-reasons file))
        (invalidTypedContractExamples
         (file-typed-contract-invalid-examples file))
        (contractFactSource "native-parser")
        (scope "source-or-test-owner")
        (adjacency "definition-leading-comment")))
