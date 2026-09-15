((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The typeclass-algebra scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "typeclass-algebra")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "typed POO typeclass algebra composition")
 (inputShape . "type declaration names functor methods without a complete typed helper boundary")
 (expectedOutcome . "expose a documented parametric functor adapter with coherent map, tap, and ap slots")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
