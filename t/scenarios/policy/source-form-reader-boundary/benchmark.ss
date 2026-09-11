((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "source-form-reader-boundary keeps reader collection detection parser-owned while preserving the low-level reader helper; twenty-sample timing uses a 150ms p95 target with equal regression headroom")
 (sampleCount . 20)
 (purpose . "R013 source/form reader scenario rejects mixed reader, accumulator, and projection loops while preserving the reader boundary helper")
 (feature . "source-form-reader-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "inline source reader and mixed selection loops to read-forms port helper, source-forms file boundary, and filter-map projection")
 (inputShape
  .
  "one file helper embeds a port EOF loop, and one exported function opens a source file, reads forms, extracts def symbols, and accumulates results in the same named-let loop")
 (expectedOutcome
  .
  "read-forms owns port/read state; source-forms passes that helper to call-with-input-file; local-def-symbols composes filter-map with def-symbol")
 (expectedReferencePattern . "source-form-reader-boundary")
 (expectedReferenceExamples
  "gerbil://src/testing/gxtest-runner.ss#gxtest-file-forms"
  "gerbil://src/testing/gxtest-runner.ss#gxtest-file-local-def-symbols")
 (expectedQualitySignals
  "inline-file-reader-boundary"
  "reader-collection-boundary"
  "source-form-reader-boundary"
  "filter-map-selection-projection"
  "preserve-reader-state-helper")
 (learnedStyleSources
  "gerbil://src/testing/gxtest-runner.ss"
  "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "reject hand-written file reader loops and reader loops that also perform selection or projection; keep the port reader state helper explicit and compose callers with list combinators")
 (scenarioQualityAxes
  "inline-file-reader-boundary"
  "reader-collection-boundary"
  "source-form-reader-boundary"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "reader" "filter-map" "anti-scaffold"))
