((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The comment-quality scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "comment-quality")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-015")
 (optimizationFocus . "engineering-comment evidence at policy-sensitive definitions")
 (inputShape . "typed public helpers whose comments repeat only algebraic shape")
 (expectedOutcome . "retain typed contracts and add adjacent responsibility and boundary rationale")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
