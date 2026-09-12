((benchmarkKind . scenario-e2e)
 (max_total . 100ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 5ms)
 (targetRationale . "POO profile composition must stay in hot path range")
 (sampleCount . 20)
 (purpose . "upstream Gerbil test ownership and POO profile composition gate")
 (feature . "testing-framework-upstream-build-improvement")
 (rule . "GERBIL-SCHEME-TESTING-UPSTREAM-BUILD-IMPROVEMENT")
 (optimizationFocus . "keep upstream std/make and gerbil test ownership while composing profile values")
 (inputShape . "explicit upstream test paths with immutable memory and performance profiles")
 (expectedOutcome . "map profiles without discovering files, widening scope, or replacing upstream execution")
 (measurementPhases
  "collect-before"
  "policy-before"
  "collect-after"
  "policy-after"
  "profile-compose"
  "profile-map"
  "assert-time-gate"
  )
 (tags "testing" "profile-extension" "poo" "performance" "hot"))
