((max_total . 900ms)
 (observed_total . 0ms)
 (target_total . 100ms)
 (regression_budget . 800ms)
 (expected_over_input_budget . 900ms)
 (observedTimings
  ((name . collect-before) (durationMs . 0))
  ((name . collect-after) (durationMs . 0))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  . "A provider projection batch is a bounded transport adapter; 64 small owners must remain below one second without loading the full parser graph.")
 (maxCollectMs . 25)
 (observedCollectMs . 0)
 (maxParseMs . 100)
 (observedParseMs . 0)
 (maxFileMs . 25)
 (observedFileMs . 0)
 (maxPhaseMs . 100)
 (observedPhaseMs . 0)
 (maxRssMb . 256)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 3)
 (unit . "ms")
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
  "assert-memory-gate")
 (tags "provider" "projection-batch" "integration" "streaming" "exact-owner"))
