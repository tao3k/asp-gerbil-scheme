((benchmarkKind . scenario-e2e)
 (max_total . 400ms)
 (target_total . 200ms)
 (regression_budget . 200ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The package-build-std-make-ssi scenario owns a 200ms optimization target and an equal explicit regression headroom; all observations remain live p95 receipt data.")
 (sampleCount . 20)
 (feature . "package-build-std-make-ssi")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-025")
 (optimizationFocus . "preserve native std/make SSI and FFI stage declarations")
 (inputShape . "std/make spec contains gsc, ssi, and source stages")
 (expectedOutcome . "admit the native ordered build spec without replacing its stage owner")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate")
 (tags "policy" "scenario-e2e"))
