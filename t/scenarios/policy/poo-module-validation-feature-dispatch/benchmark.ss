((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-module-validation-feature-dispatch target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 routes POO module validation drift toward compiler-style feature dispatch and local cache handlers")
 (feature . "poo-module-validation-feature-dispatch")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "resolved-field and cache receipt drift to compiler-style feature dispatch")
 (inputShape
  .
  "POO module validation repeats resolved-field traversal, harness field extraction, and cache receipt construction across object and field validators")
 (expectedOutcome
  .
  "extract feature-specific validation handlers and keep the validation surface as a dispatch table with shared cache key construction")
 (expectedReferencePattern . "gerbil-compiler-feature-dispatch")
 (expectedReferenceExamples
  "gerbil://gerbil/compiler/compile.ss#defcompile-method"
  "gerbil://gerbil/compiler/compile.ss#apply-lift-modules"
  "gerbil://gerbil/compiler/compile.ss#generate-meta-module")
 (expectedDownstreamOwners
  "poo-flow://src/module-system/object-validation-support/harness.ss#poo-flow-module-object-harness-validation"
  "poo-flow://src/module-system/object-validation-support/harness.ss#poo-flow-module-field-contract-validation-cache-receipt"
  "poo-flow://src/module-system/object-validation-support/harness.ss#poo-flow-module-validation-hash-fields")
 (expectedQualitySignals
  "feature-dispatch-surface"
  "shared-cache-key-boundary"
  "resolved-field-single-pass"
  "provider-independent-source-query")
 (learnedStyleSources
  "gerbil://gerbil/compiler/compile.ss"
  "poo-flow://src/module-system/object-validation-support/harness.ss"
  "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "reject agent-generated validation scaffolding that clones resolved-field and cache logic instead of extracting local feature handlers")
 (scenarioQualityAxes
  "compiler-feature-dispatch"
  "poo-validation-cache-boundary"
  "resolved-field-single-pass"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "gerbil-native" "compiler" "poo" "validation" "feature-dispatch" "cache"))
