((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The package-build-canonical-shape scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "package-build-canonical-shape")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-025")
 (optimizationFocus . "canonical package build declaration and native compiler handoff")
 (inputShape . "build script mixes std/make with manual environment and gxc process dispatch")
 (expectedOutcome . "declare the package build graph once and leave compilation ownership to the Build API")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
