((benchmarkKind . scenario-e2e)
 (max_total . 900ms)
 (target_total . 100ms)
 (regression_budget . 800ms)
 (expected_over_input_budget . 900ms)
 (targetRationale
  . "A provider projection batch is a bounded transport adapter; 64 small owners must remain below one second without loading the full parser graph.")
 (sampleCount . 20)
 (purpose . "Keep Gerbil exact-owner projection bounded and independent from workspace analysis.")
 (feature . "provider-exact-owner-projection")
 (rule . "GERBIL-SCHEME-PROVIDER-LIGHTWEIGHT")
 (optimizationFocus . "stream framed owners one at a time through the native definition parser")
 (inputShape . "64 framed owners sharing one small representative Gerbil source body")
 (expectedOutcome . "Return canonical item identities without parser/core, policy, quality, or whole-package test compilation")
 (adapterBoundary . "ASP owns workspace collection and framing; ASP_GERBIL_SCHEME parses only the owner bytes present in the request")
 (expectedQualitySignals
  "bounded-framed-input"
  "single-owner-native-parse"
  "no-workspace-analysis"
  "canonical-item-selector")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "provider" "projection-batch" "integration" "streaming" "exact-owner"))
