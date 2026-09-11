((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-type-descriptor scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "poo-type-descriptor")
 (rule . #f)
 (optimizationFocus . "POO-native type descriptor and validation boundary")
 (inputShape . "raw hash validation and construction helpers encode one order schema")
 (expectedOutcome . "compose a class-backed POO type with slot descriptors, validation, and construction methods")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
