((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "dynamic-scope-cleanup-boundary keeps current-directory/current-port cleanup parser-owned and verifies expected dynamic-wind repair is no slower than input")
 (sampleCount . 20)
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
  )
 (tags "style" "dynamic-scope" "dynamic-wind" "cleanup" "anti-scaffold"))
