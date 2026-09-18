((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The harness-dependency-policy-disable-requires-explanation scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "harness-dependency-policy-disable-requires-explanation")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-024")
 (optimizationFocus . "auditable downstream policy-disable declarations")
 (inputShape . "dependent package disables R013 without a scoped explanation")
 (expectedOutcome . "record an explicit disable rationale or retain the default policy rule")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
