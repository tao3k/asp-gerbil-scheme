((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The higher-order-composition target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 higher-order composition scenario keeps wrapper-lambda repair within the scenario-owned timing gate")
 (feature . "higher-order-composition")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "wrapper lambda to composition boundary")
 (inputShape . "repeated wrapper lambdas around a reusable string transform")
 (expectedOutcome . "compose/cut pipeline with full typed documentation")
 (expectedReferencePattern . "gerbil-utils-higher-order-expression")
 (expectedReferenceExamples
  "gerbil-utils/base.ss#left-to-right"
  "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate")
 (expectedQualitySignals
  "function-pipeline-abstraction"
  "cut-prefix-predicate"
  "thin-wrapper-elimination")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject repeated wrapper-lambda scaffolding when compose/cut expresses the data flow")
 (scenarioQualityAxes "higher-order-composition" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "higher-order" "composition"))
