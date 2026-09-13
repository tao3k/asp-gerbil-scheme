((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The package-build-std-build-script scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "package-build-std-build-script")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-025")
 (optimizationFocus . "preserve native std/build-script declarations")
 (inputShape . "minimal defbuild-script library and executable specification")
 (expectedOutcome . "admit the native declarative build shape without local orchestration")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
