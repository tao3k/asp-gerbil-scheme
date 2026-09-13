((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The controlled-branch-conditional-dispatch scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "controlled-branch-conditional-dispatch")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-014")
 (optimizationFocus . "nested conditional command dispatch")
 (inputShape . "launcher-style dispatcher with four nested conditional branches")
 (expectedOutcome . "use named fallback helpers and compact functional dispatch composition")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
