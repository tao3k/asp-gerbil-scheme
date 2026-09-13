((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "macro-expansion-io-boundary keeps expansion-time IO detection parser-owned and validates the thin syntax payload repair in a small millisecond gate")
 (sampleCount . 20)
 (purpose
  .
  "R040 macro expansion IO scenario rejects generated macro owners that hide filesystem reads, path resolution, and syntax generation inside one transformer")
 (feature . "macro-expansion-io-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-040")
 (optimizationFocus
  .
  "compile-time file IO in macro owners to explicit syntax payloads or source-backed build artifact boundaries")
 (inputShape
  .
  "one macro owner reads a fragment file during expansion with call-with-input-file before constructing syntax")
 (expectedOutcome
  .
  "macro consumes explicit syntax payloads and leaves fragment loading to a separate source-backed build or caller boundary")
 (expectedReferencePattern . "gerbil-macro-expansion-io-boundary")
 (expectedReferenceExamples
  "gerbil://core/expander.ss#syntax-case"
  "gerbil://core/expander.ss#stx-source"
  "poo-flow/src/module-system/init-syntax.ss#load!"
  "poo-flow/src/core/flow-syntax.ss#defpoo-flow-define-binding-macro")
 (expectedQualitySignals
  "macro-expansion-io-boundary"
  "thin-hygienic-transformer"
  "source-backed-build-artifact"
  "anti-ai-macro-scaffold")
 (learnedStyleSources
  "gerbil://core/expander.ss"
  "poo-flow/src/module-system/init-syntax.ss"
  "poo-flow/src/core/flow-syntax.ss")
 (antiAiScaffoldIntent
  .
  "reject generated macro code that mixes filesystem reads, path derivation, datum conversion, and runtime behavior inside a single transformer")
 (scenarioQualityAxes
  "macro-expansion-io-boundary"
  "anti-ai-macro-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-input-expected-comparison")
 (tags "style" "macro" "phase" "io" "expansion"))
