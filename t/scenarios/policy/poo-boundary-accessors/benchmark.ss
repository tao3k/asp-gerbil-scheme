((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-boundary-accessors scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "poo-boundary-accessors")
 (rule . #f)
 (optimizationFocus . "distinguish legal boundary reads from projection bursts")
 (inputShape . "small helpers use .ref, .@, and .get for isolated reads")
 (expectedOutcome . "retain isolated accessors while rejecting constructor-style repeated projections")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
