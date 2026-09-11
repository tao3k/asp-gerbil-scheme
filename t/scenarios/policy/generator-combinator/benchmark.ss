((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The generator-combinator scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "generator-combinator")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "generator consumption through native combinators")
 (inputShape . "typed generator helper retains a manual named-let accumulator")
 (expectedOutcome . "replace manual traversal with an explicit generator combinator pipeline")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
