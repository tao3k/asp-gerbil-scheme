((benchmarkKind . scenario-e2e)
 (max_total . 100ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 5ms)
 (targetRationale . "testing profile composition checks must stay in hot policy range")
 (sampleCount . 20)
 (purpose . "POO-native testing profile extension gate")
 (feature . "poo-shaped-testing-profile-extension")
 (rule . "GERBIL-SCHEME-TESTING-PROFILE-EXTENSION")
 (optimizationFocus . "immutable profile override, mapping, and removal")
 (inputShape . "POO testing interface with explicit upstream test paths")
 (expectedOutcome . "compose profiles without implementing discovery, execution, or reporting")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "profile-compose"
  "profile-remove"
  "assert-time-gate"
  )
 (tags "testing" "profile-extension" "poo" "gxtest"))
