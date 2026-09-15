((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The predicate-family-combinator scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "predicate-family-combinator")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-016")
 (optimizationFocus . "shared predicate-family projection and membership logic")
 (inputShape . "several predicates duplicate field lookup and role comparison")
 (expectedOutcome . "factor one typed projection and compose the predicate family from it")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
