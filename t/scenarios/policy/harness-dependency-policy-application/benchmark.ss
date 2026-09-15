((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The harness-dependency-policy-application scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "harness-dependency-policy-application")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "automatic policy application for harness dependents")
 (inputShape . "dependent package declares the harness and contains untyped manual traversal")
 (expectedOutcome . "apply the default policy set and repair the owner to typed functional composition")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
