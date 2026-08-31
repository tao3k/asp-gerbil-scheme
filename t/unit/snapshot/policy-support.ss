;;; -*- Gerbil -*-
;;; Policy snapshot shared projection helpers.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios)
(export #t)

;; (List PooGuidanceCorpusScenario)
(def +poo-guidance-corpus-scenarios+
  '(("poo-type-descriptor" . "t/scenarios/policy/poo-type-descriptor")
    ("poo-method-family-serialization" . "t/scenarios/policy/poo-method-family-serialization")
    ("poo-algebra-wrapper" . "t/scenarios/policy/poo-algebra-wrapper")
    ("poo-domain-algebra" . "t/scenarios/policy/poo-domain-algebra")
    ("poo-boundary-accessors" . "t/scenarios/policy/poo-boundary-accessors")))

;; (List RuleId)
(def +poo-guidance-target-rule-ids+
  ["GERBIL-SCHEME-AGENT-POLICY-006"
   "GERBIL-SCHEME-AGENT-POLICY-007"
   "GERBIL-SCHEME-AGENT-POLICY-008"
   "GERBIL-SCHEME-AGENT-POLICY-010"
   "GERBIL-SCHEME-AGENT-POLICY-017"
   "GERBIL-SCHEME-AGENT-POLICY-026"])

;; : (-> ScenarioId Root PolicyScenarioSnapshot )
(def (poo-guidance-scenario-policy-snapshot id root)
  (let* ((scenario (make-policy-scenario id root))
         (result (policy-scenario-run scenario)))
    (list 'scenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (poo-guidance-phase-snapshot result 'before))
          (list 'after
                (poo-guidance-phase-snapshot result 'after)))))

;; : (-> PolicyScenarioResult Symbol PolicyPhaseSnapshot )
(def (poo-guidance-phase-snapshot result phase)
  (let (index (policy-scenario-index result phase))
    (list 'phase
          (list 'targetFindings
                (map finding-snapshot-copy
                     (poo-guidance-target-findings index)))
          (list 'pooForms
                (poo-guidance-poo-form-snapshots index)))))

;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-guidance-target-findings index)
  (filter (lambda (finding)
            (member (type-finding-rule-id finding)
                    +poo-guidance-target-rule-ids+))
          (run-agent-policy index)))

;; : (-> ProjectIndex (List PooFormSnapshot) )
(def (poo-guidance-poo-form-snapshots index)
  (apply append
         (map (lambda (file)
                (map poo-guidance-poo-form-snapshot
                     (source-file-poo-forms file)))
              (project-index-files index))))

;; : (-> PooFormFact PooFormSnapshot )
(def (poo-guidance-poo-form-snapshot fact)
  (list 'pooForm
        (list 'name (poo-form-fact-name fact))
        (list 'role (poo-form-fact-role fact))
        (list 'supers (poo-form-fact-supers fact))
        (list 'slots (poo-form-fact-slots fact))
        (list 'options (poo-form-fact-options fact))
        (list 'selector (poo-form-fact-selector fact))))

;; : (-> PolicyDetails FunctionalIdiomGuidanceSnapshot )
(def (functional-idiom-guidance-snapshot details)
  (list (list 'kind (hash-get details 'kind))
        (list 'caller (hash-get details 'caller))
        (list 'advice (hash-get details 'advice))
        (list 'basicSyntaxSmells (hash-get details 'basicSyntaxSmells))
        (list 'nativeRepairContract
              (hash-get details 'nativeRepairContract))
        (list 'designFeaturePriority
              (hash-get details 'designFeaturePriority))
        (list 'sequenceIdioms (hash-get details 'sequenceIdioms))
        (list 'predicateIdioms (hash-get details 'predicateIdioms))
        (list 'compositionIdioms (hash-get details 'compositionIdioms))
        (list 'nativeLambdaIdioms (hash-get details 'nativeLambdaIdioms))
        (list 'typeclassIdioms (hash-get details 'typeclassIdioms))
        (list 'builderIdioms (hash-get details 'builderIdioms))
        (list 'styleGuide (hash-get details 'styleGuide))
        (list 'styleCommand (hash-get details 'styleCommand))
        (list 'detectedControlContexts
              (hash-get details 'detectedControlContexts))
        (list 'keepNamedLetWhen (hash-get details 'keepNamedLetWhen))
        (list 'learnedFrom (hash-get details 'learnedFrom))))

;; : (-> PolicyDetails ControlledBranchShapeGuidanceSnapshot )
(def (controlled-branch-shape-guidance-snapshot details)
  (list (list 'caller (hash-get details 'caller))
        (list 'shape (hash-get details 'shape))
        (list 'matchCount (hash-get details 'matchCount))
        (list 'manualLoopCount (hash-get details 'manualLoopCount))
        (list 'conditionalBranchCount
              (hash-get details 'conditionalBranchCount))
        (list 'conditionalDispatchGate
              (hash-get details 'conditionalDispatchGate))
        (list 'evidence (hash-get details 'evidence))
        (list 'advice (hash-get details 'advice))
        (list 'styleGuide (hash-get details 'styleGuide))
        (list 'styleCommand (hash-get details 'styleCommand))
        (list 'rewriteScope (hash-get details 'rewriteScope))
        (list 'sourceBackedOwners
              (hash-get details 'sourceBackedOwners))
        (list 'sourceBackedRepairCandidates
              (hash-get details 'sourceBackedRepairCandidates))
        (list 'functionShape (hash-get details 'functionShape))
        (list 'expressionLevelRewrite
              (hash-get details 'expressionLevelRewrite))))

;; : (-> ScenarioId Root PolicyScenarioSnapshot )
(def (typed-combinator-style-scenario-policy-snapshot id root)
  (let* ((scenario
          (make-policy-scenario
           id
           root))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-013"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-013")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding
                      (finding-snapshot-copy before-finding))
                (list 'style
                      (typed-combinator-style-guidance-snapshot
                       before-details)))
          (list 'after
                (list 'r013Findings
                      (map finding-snapshot after-findings))))))

;; : (-> PolicyDetails TypedCombinatorStyleGuidanceSnapshot )
(def (typed-combinator-style-guidance-snapshot details)
  (list (list 'styleGuide (hash-get details 'styleGuide))
        (list 'expectedCommentShape
              (hash-get details 'expectedCommentShape))
        (list 'compositionShape (hash-get details 'compositionShape))
        (list 'functionShape (hash-get details 'functionShape))
        (list 'agentRepairStandard
              (hash-get details 'agentRepairStandard))
        (list 'expressionLevelRewrite
              (hash-get details 'expressionLevelRewrite))
        (list 'definitionCount (hash-get details 'definitionCount))
        (list 'typedCommentCount (hash-get details 'typedCommentCount))
        (list 'missingTypedCommentCount
              (hash-get details 'missingTypedCommentCount))
        (list 'implementationEvidenceCount
              (hash-get details 'implementationEvidenceCount))
        (list 'qualityFacets (hash-get details 'qualityFacets))
        (list 'gerbilUtilsImplementationSignals
              (hash-get details 'gerbilUtilsImplementationSignals))
        (list 'generatorCombinatorSignals
              (hash-get details 'generatorCombinatorSignals))
        (list 'generatorContractTargets
              (hash-get details 'generatorContractTargets))
        (list 'controlledMacroSyntaxSignals
              (hash-get details 'controlledMacroSyntaxSignals))
        (list 'controlledMacroTargets
              (hash-get details 'controlledMacroTargets))
        (list 'typeclassAlgebraSignals
              (hash-get details 'typeclassAlgebraSignals))
        (list 'typeclassAlgebraTargets
              (hash-get details 'typeclassAlgebraTargets))
        (list 'gerbilContractProjectionSignals
              (hash-get details 'gerbilContractProjectionSignals))
        (list 'qualityFacetSteering
              (hash-get details 'qualityFacetSteering))))

;; : (-> TypeFinding FindingSnapshot )
(def (finding-snapshot-copy finding)
  [(type-finding-rule-id finding)
   (and (type-finding-path finding)
        (string-copy (type-finding-path finding)))
   (and (type-finding-selector finding)
        (string-copy (type-finding-selector finding)))
   (and (type-finding-message finding)
        (string-copy (type-finding-message finding)))])

;; : (-> PolicyDetails CommentQualityGuidanceSnapshot )
(def (comment-quality-guidance-snapshot details)
  (let* ((examples (hash-get details 'weakCommentExamples))
         (example (and (pair? examples) (car examples))))
    (list (list 'styleGuide (hash-get details 'styleGuide))
          (list 'evidenceSource (hash-get details 'evidenceSource))
          (list 'repairInstruction
                (hash-get details 'repairInstruction))
          (list 'repairOrder (hash-get details 'repairOrder))
          (list 'expectedCommentPrefix
                (hash-get details 'expectedCommentPrefix))
          (list 'commentLinePolicy
                (hash-get details 'commentLinePolicy))
          (list 'typedContractBoundary
                (hash-get details 'typedContractBoundary))
          (list 'weakCommentCount
                (hash-get details 'weakCommentCount))
          (list 'repairTargets
                (map string-copy
                     (hash-get details 'repairTargets)))
          (list 'exampleTarget
                (and (hash-get example 'target)
                     (string-copy (hash-get example 'target))))
          (list 'exampleContext (hash-get example 'context))
          (list 'exampleCommentKind (hash-get example 'commentKind))
          (list 'exampleQuality (hash-get example 'quality))
          (list 'exampleReasons (hash-get example 'reasons)))))

;; : (-> ProjectPackage PackageAgentPolicySnapshot )
(def (package-agent-policy-snapshot package)
  (let (policy (and package (project-package-agent-policy package)))
    (list (list 'dependencies
                (and package (project-package-dependencies package)))
          (list 'default "all-rules-enabled")
          (list 'disabledRules
                (if policy (agent-policy-disabled-rules policy) '()))
          (list 'explanation
                (and policy (agent-policy-explanation policy))))))

;; : (-> PolicyDetails MacroControlledHelperGuidanceSnapshot )
(def (macro-controlled-helper-guidance-snapshot details)
  (let ((runtime (hash-get details 'runtimeSourceRequirement))
        (reference (hash-get details 'qualityReference)))
    (list (list 'macro (hash-get details 'macro))
          (list 'phase (hash-get details 'phase))
          (list 'hygienic (hash-get details 'hygienic))
          (list 'qualityFacets (hash-get details 'qualityFacets))
          (list 'allowedMacroShape (hash-get details 'allowedMacroShape))
          (list 'runtimeSelectorFormat
                (hash-get runtime 'selectorFormat))
          (list 'styleReferencePattern
                (hash-get reference 'referencePattern))
          (list 'styleReferenceExamples
                (hash-get reference 'referenceExamples))
          (list 'escapeConstraint
                (hash-get details 'agentEscapeConstraint)))))

;; : (-> PolicyDetails PredicateCombinatorProfileSnapshot )
(def (predicate-combinator-profile-snapshot details)
  (let ((reference (hash-get details 'qualityReference)))
    (list (list 'styleGuide (hash-get details 'styleGuide))
          (list 'subject (hash-get details 'subject))
          (list 'predicateCount (hash-get details 'predicateCount))
          (list 'fieldKeys (hash-get details 'fieldKeys))
          (list 'repeatedCallees (hash-get details 'repeatedCallees))
          (list 'referencePattern
                (hash-get reference 'referencePattern))
          (list 'referenceExamples
                (hash-get reference 'referenceExamples))
          (list 'qualitySignals (hash-get reference 'qualitySignals))
          (list 'repairStandard
                (hash-get details 'agentRepairStandard)))))

;; : (-> PolicyDetails PackageBuildCanonicalShapeSnapshot )
(def (package-build-canonical-shape-snapshot details)
  (list (list 'kind (hash-get details 'kind))
        (list 'nativeBuildImport
              (hash-get details 'nativeBuildImport))
        (list 'nativeBuildImportModifier
              (hash-get details 'nativeBuildImportModifier))
        (list 'buildSpecEntrypoint
              (hash-get details 'buildSpecEntrypoint))
        (list 'manualCompilerDispatch
              (hash-get details 'manualCompilerDispatch))
        (list 'handWrittenMain
              (hash-get details 'handWrittenMain))
        (list 'allowedShape (hash-get details 'allowedShape))
        (list 'disallowedShape (hash-get details 'disallowedShape))
        (list 'sourceEvidence (hash-get details 'sourceEvidence))
        (list 'nativeFactSource (hash-get details 'nativeFactSource))
        (list 'next (hash-get details 'next))))

;; : (-> ScenarioId Root PolicyScenarioSnapshot )
(def (build-runtime-quality-policy-snapshot id root)
  (let* ((scenario
          (make-policy-scenario
           id
           root))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-020"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-020")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'runtimeQuality
                      (build-runtime-quality-snapshot before-details)))
          (list 'after
                (list 'r020Findings
                      (map finding-snapshot after-findings))))))

;; : (-> PolicyDetails BuildRuntimeQualitySnapshot )
(def (build-runtime-quality-snapshot details)
  (list (list 'kind (hash-get details 'kind))
        (list 'detectionCombiner (hash-get details 'detectionCombiner))
        (list 'detectionCombinerKind
              (hash-get details 'detectionCombinerKind))
        (list 'detectionSourcePattern
              (hash-get details 'detectionSourcePattern))
        (list 'requiredGroups (hash-get details 'requiredGroups))
        (list 'evidenceGroups (hash-get details 'evidenceGroups))
        (list 'evidenceCounts (hash-get details 'evidenceCounts))
        (list 'allowedShape (hash-get details 'allowedShape))
        (list 'disallowedShape (hash-get details 'disallowedShape))
        (list 'next (hash-get details 'next))))

;; : (-> ScenarioId Root PolicyScenarioSnapshot )
(def (dependency-adapter-policy-snapshot id root)
  (let* ((scenario
          (make-policy-scenario
           id
           root))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-017"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-017")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'adapter
                      (dependency-adapter-profile-snapshot before-details)))
          (list 'after
                (list 'r017Findings
                      (map finding-snapshot after-findings))))))

;; : (-> PolicyDetails DependencyAdapterProfileSnapshot )
(def (dependency-adapter-profile-snapshot details)
  (list (list 'styleGuide (hash-get details 'styleGuide))
        (list 'dependency (hash-get details 'dependency))
        (list 'quality (hash-get details 'quality))
        (list 'manualObjectEncodingRisk
              (hash-get details 'manualObjectEncodingRisk))
        (list 'genericContractWitnessKind
              (hash-get details 'genericContractWitnessKind))
        (list 'contractWitnessPresent
              (hash-get details 'contractWitnessPresent))
        (list 'contractWitnessKind
              (hash-get details 'contractWitnessKind))
        (list 'missingEvidence (hash-get details 'missingEvidence))
        (list 'qualityFacets (hash-get details 'qualityFacets))
        (list 'derivedCapabilities
              (hash-get details 'derivedCapabilities))
        (list 'methodTablePrimitiveSlots
              (hash-get details 'methodTablePrimitiveSlots))
        (list 'methodTableDerivedFamilies
              (hash-get details 'methodTableDerivedFamilies))
        (list 'adapterRepairShape
              (hash-get details 'adapterRepairShape))
        (list 'agentRepairStandard
              (hash-get details 'agentRepairStandard))))

;; : (-> MacroFact MacroFactSnapshot )
(def (macro-fact-snapshot fact)
  (list (list 'macro (macro-fact-name fact))
        (list 'transformer (macro-fact-transformer fact))
        (list 'phase (macro-fact-phase fact))
        (list 'hygienic (macro-fact-hygienic fact))
        (list 'qualityFacets (macro-fact-quality-facets fact))))
