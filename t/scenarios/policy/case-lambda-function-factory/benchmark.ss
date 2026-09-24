((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The case-lambda-function-factory target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 case-lambda function factory scenario keeps arity-specialized repair within the scenario-owned timing gate")
 (feature . "case-lambda-function-factory")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "case-lambda arity-specialized function factory")
 (inputShape . "single wrapper-lambda factory hiding distinct arity variants")
 (expectedOutcome
  .
  "case-lambda factory with explicit arity branches and typed documentation")
 (expectedReferencePattern . "gerbil-utils-higher-order-expression")
 (expectedReferenceExamples "gerbil-utils/base.ss#case-lambda specializers")
 (expectedQualitySignals
  "function-specialization-abstraction"
  "multi-arity-abstraction"
  "thin-wrapper-elimination")
 (learnedStyleSources "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject one-size wrapper-lambda factories when case-lambda expresses real arity variants")
 (scenarioQualityAxes "case-lambda-function-factory" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "higher-order" "case-lambda" "arity"))
