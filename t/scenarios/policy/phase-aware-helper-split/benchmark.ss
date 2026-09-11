((benchmarkKind . scenario-e2e)
 (schemaId . "agent.semantic-protocols.gerbil-scheme-policy-scenario-benchmark")
 (schemaVersion . "4")
 (feature . "phase-aware-helper-split")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (purpose . "R013 separates public macro syntax, phase-owned parsing, and runtime POO construction")
 (inputShape . "one macro owner embeds a large begin-syntax parser and wildcard re-exports runtime helpers")
 (expectedOutcome . "thin public macro imports a compiled parser with for-syntax and exports only the macro")
 (optimizationFocus . "mixed syntax/runtime owner to explicit phase-adjusted helper module")
 (antiAiScaffoldIntent . "prevent generated macro modules from mixing parser state with runtime API ownership")
 (expectedReferencePattern . "phase-aware-helper-split")
 (expectedReferenceExamples
  "gerbil://gerbil/expander/module.ss#for-syntax"
  "gerbil://gerbil/expander/top.ss#begin-syntax-phi-plus-one")
 (learnedStyleSources
  "gerbil://gerbil/expander/module.ss"
  "gerbil://gerbil/expander/top.ss"
  "harness-self-apply")
 (expectedQualitySignals
  "phase-aware-helper-split"
  "phase-aware-macro-boundary"
  "generated-runtime-helper"
  "source-aware-syntax-error")
 (scenarioQualityAxes
  "phase-aware-helper-split"
  "phase-adjusted-import"
  "public-syntax-owner"
  "runtime-helper-owner")
 (tags "style" "macro" "phase" "module" "for-syntax")
 (targetRationale . "phase ownership is a structural macro fact and must remain inside the R013 millisecond gate")
 (sampleCount . 20)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (expected_over_input_note . #f)
 (max_total . 200ms)
 (measurementPhases
  "collect-before" "collect-after" "policy-before" "policy-after"
  "assert-time-gate" )
 (hotPathEvidence)
 (hotPathExemption . #f)
 (nativePooPrimary . #f)
 (adapterBoundary . #f)
 (styleRewriteBoundary . #f))
