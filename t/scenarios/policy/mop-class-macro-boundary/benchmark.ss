((benchmarkKind . scenario-e2e)
 (target_total . 150ms)
 (max_total . 300ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The mop-class-macro-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 MOP class macro scenario keeps defclass-style descriptor generation and runtime method binding under the scenario-owned timing gate")
 (feature . "mop-class-macro-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "Gerbil core/mop defclass descriptor, mixin slot accessor, and defmethod binding boundaries")
 (inputShape
  .
  "macro owner mixes class descriptor tables, slot layout, mixin accessors and mutators, constructor/predicate metadata, method binding, and slot contract/default metadata")
 (expectedOutcome
  .
  "native defclass/defmethod surface with descriptor metadata declared once and runtime behavior kept in ordinary method helpers")
 (learnedStyleSources
  "gerbil://gerbil/core/mop.ss#defclass"
  "gerbil://gerbil/core/mop.ss#defmethod"
  "gerbil://gerbil/core/mop.ss#generate-defclass")
 (antiAiScaffoldIntent
  .
  "reject table-shaped class DSL macros that reimplement Gerbil MOP descriptor, slot accessor, mutator, and method-binding semantics in one syntax owner")
 (scenarioQualityAxes
  "mop-class-macro-boundary"
  "class-descriptor-macro-boundary"
  "mixin-slot-accessor-boundary"
  "method-binding-boundary"
  "anti-ai-scaffold")
 (expectedReferencePattern . "gerbil-core-mop-class-macro-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/core/mop.ss#defclass"
  "gerbil://gerbil/core/mop.ss#defmethod"
  "gerbil://gerbil/core/mop.ss#generate-defclass"
  "gerbil://gerbil/core/mop.ss#class-type-info"
  "gerbil://gerbil/core/mop.ss#get-mixin-slots"
  "gerbil://gerbil/core/mop.ss#bind-method!")
 (expectedQualitySignals
  "mop-class-macro-boundary"
  "class-descriptor-macro-boundary"
  "class-type-info-boundary"
  "mixin-slot-accessor-boundary"
  "method-binding-boundary"
  "constructor-predicate-metadata-boundary"
  "slot-contract-metadata-boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "macro" "mop" "class"))
