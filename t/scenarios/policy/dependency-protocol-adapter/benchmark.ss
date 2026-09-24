((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The dependency-protocol-adapter scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "dependency-protocol-adapter")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-017")
 (optimizationFocus . "complete dependency-backed protocol adapter surface")
 (inputShape . "POO type exposes only a partial orderdict method table")
 (expectedOutcome . "supply primitive slots, derived capabilities, validation, and a generic contract witness")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
