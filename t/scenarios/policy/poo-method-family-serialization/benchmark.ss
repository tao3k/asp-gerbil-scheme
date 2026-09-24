((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-method-family-serialization scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "poo-method-family-serialization")
 (rule . #f)
 (optimizationFocus . "POO serialization method-family composition")
 (inputShape . "separate JSON, string, and byte conversion helpers repeat one codec family")
 (expectedOutcome . "compose a wrapper prototype with named serialization method slots")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
