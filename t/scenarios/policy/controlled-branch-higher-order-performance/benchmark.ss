((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The typed-combinator-style target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R014 higher-order branch repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "typed-combinator-style")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-014")
 (optimizationFocus . "higher-order branch repair")
 (inputShape . "conditional dispatch helper with repeated branch bodies")
 (expectedOutcome . "source-backed fun/compose/curry style")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "higher-order" "branch"))
