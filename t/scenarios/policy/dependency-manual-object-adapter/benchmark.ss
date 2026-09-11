((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The dependency-manual-object-adapter scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "dependency-manual-object-adapter")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-017")
 (optimizationFocus . "typed POO adapter over an existing dependency data structure")
 (inputShape . "manual object methods partially wrap orderdict primitives")
 (expectedOutcome . "compose the dependency protocol surface with typed validation and executable contract tests")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
