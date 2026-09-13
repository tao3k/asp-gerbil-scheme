((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-prototype-fixed-point scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "poo-prototype-fixed-point")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-026")
 (optimizationFocus . "prototype-local object fixed-point construction")
 (inputShape . "constructor projects several slots before rebuilding a hash object")
 (expectedOutcome . "refine and materialize one POO prototype with =>, =>.+, ?, and .mix")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
