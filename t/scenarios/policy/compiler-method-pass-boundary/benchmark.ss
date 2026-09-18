((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The compiler-method-pass-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 compiler method-pass scenario routes method-table drift toward local AST pass handlers")
 (feature . "compiler-method-pass-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "method-table lambda drift to compiler-style pass handlers")
 (inputShape
  .
  "method table slots are anonymous lambdas that hide dispatch and pass boundaries")
 (expectedOutcome
  .
  "extract local pass handlers and keep the method table as a dispatch surface")
 (expectedReferencePattern . "gerbil-compiler-method-pass-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/compiler/method.ss#defcompile-method"
  "gerbil://gerbil/compiler/method.ss#xform-wrap-source"
  "gerbil://gerbil/compiler/optimize-top.ss#dispatch-lambda-form?")
 (expectedQualitySignals
  "method-table-pass-boundary"
  "ast-case-shape-dispatch"
  "source-preserving-transform"
  "typed-pass-pipeline")
 (learnedStyleSources "gerbil://" "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "teach agents to replace method-table lambda sinks with local pass handlers and shape predicates")
 (scenarioQualityAxes
  "compiler-method-pass-boundary"
  "method-table-pass-boundary"
  "gerbil-gambit-native-idiom"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "gerbil-native" "compiler" "method-table" "ast-case" "pass-boundary"))
