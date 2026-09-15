((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The wrapper-lambda-function-factory target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 wrapper lambda scenario keeps function-factory repair within the scenario-owned timing gate")
 (feature . "wrapper-lambda-function-factory")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "repeated wrapper lambdas to named specializer and factory boundaries")
 (inputShape
  .
  "single exported function allocates repeated same-formal lambdas inside one let before returning another wrapper")
 (expectedOutcome
  .
  "prefix/suffix specializers plus a named normalization helper, preserving the public function factory")
 (expectedReferencePattern . "gerbil-utils-higher-order-expression")
 (expectedReferenceExamples
  "gerbil-utils/base.ss#lambda-match/lambda-ematch"
  "gerbil-utils/base.ss#fun"
  "gerbil-utils/base.ss#compose/rcompose/!>/!!>"
  "gerbil-utils/base.ss#cut/curry/rcurry"
  "gerbil-utils/base.ss#case-lambda specializers")
 (expectedQualitySignals
  "function-specialization-abstraction"
  "function-pipeline-abstraction"
  "thin-wrapper-elimination"
  "multi-arity-abstraction")
 (learnedStyleSources "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject repeated anonymous wrapper lambdas when a named function factory, specializer, or pipeline boundary exposes the data flow")
 (scenarioQualityAxes
  "wrapper-lambda-drift"
  "function-specialization-opportunity"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "higher-order" "function-factory" "anti-scaffold"))
