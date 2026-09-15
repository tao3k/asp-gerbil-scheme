((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-algebra-wrapper scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "poo-algebra-wrapper")
 (rule . #f)
 (optimizationFocus . "POO-native wrapper and functor algebra")
 (inputShape . "standalone map, wrap, unwrap, and bind helpers encode one algebra")
 (expectedOutcome . "compose named POO wrapper and functor prototypes with method slots")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
