((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The controlled-branch-shape scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "controlled-branch-shape")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-014")
 (optimizationFocus . "duplicated match-based branch extraction")
 (inputShape . "one function computes parallel created and cancelled match branches")
 (expectedOutcome . "project the event through one explicit controlled branch boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
