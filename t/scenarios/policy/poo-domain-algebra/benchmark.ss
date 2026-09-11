((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-domain-algebra scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "poo-domain-algebra")
 (rule . #f)
 (optimizationFocus . "POO-native polynomial domain algebra")
 (inputShape . "standalone coefficient helpers encode add and scale operations")
 (expectedOutcome . "compose a typed polynomial prototype with explicit ring and operation slots")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
