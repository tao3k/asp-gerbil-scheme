((max_total . 24ms)
 (observed_total . 6ms)
 (target_total . 14ms)
 (regression_budget . 18ms)
 (expected_over_input_budget . 0ns)
 (observedTimings
  ((name . collect-before) (durationMs . 2) (durationNs . 2000000))
  ((name . collect-after) (durationMs . 2) (durationNs . 2000000))
  ((name . policy-before) (durationMs . 1) (durationNs . 1000000))
  ((name . policy-after) (durationMs . 1) (durationNs . 1000000)))
 (targetRationale
  .
  "dynamic-scope-cleanup-boundary keeps current-directory/current-port cleanup parser-owned and verifies expected dynamic-wind repair is no slower than input")
 (maxCollectMs . 10)
 (observedCollectMs . 4)
 (maxParseMs . 14)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 6)
 (observedPhaseMs . 2)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 dynamic scope cleanup scenario rejects manual dynamic state restore when dynamic-wind or parameterize is available")
 (feature . "dynamic-scope-cleanup-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "manual dynamic state save/restore to dynamic-wind or parameterize cleanup boundary")
 (inputShape
  .
  "single exported helper saves current-directory, mutates it, runs thunk, and restores only after normal return")
 (expectedOutcome
  .
  "dynamic-wind before/thunk/after boundary restores current-directory across exceptions and continuations")
 (expectedReferencePattern . "gerbil-runtime-dynamic-scope-cleanup-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/runtime/control.ss#dynamic-wind"
  "gerbil://gerbil/runtime/control.ss#with-unwind-protect"
  "gerbil://gerbil/runtime/control.ss#call-with-parameters"
  "poo-flow/build.ss#poo-flow-with-directory"
  "asp-gerbil-scheme/src/build-api/source-coverage.ss#with-directory")
 (expectedQualitySignals
  "dynamic-scope-cleanup-boundary"
  "manual-dynamic-scope-restore"
  "dynamic-wind-cleanup-boundary"
  "parameterize-state-boundary"
  "unwind-cleanup-boundary")
 (learnedStyleSources
  "gerbil://gerbil/runtime/control.ss"
  "poo-flow/build.ss"
  "asp-gerbil-scheme/src/build-api/source-coverage.ss")
 (antiAiScaffoldIntent
  .
  "reject AI-style post-thunk manual dynamic state restoration when Gerbil dynamic-wind or parameterize can encode the cleanup boundary")
 (scenarioQualityAxes
  "dynamic-scope-cleanup-boundary"
  "anti-ai-dynamic-state-restore")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "dynamic-scope" "dynamic-wind" "cleanup" "anti-scaffold"))
