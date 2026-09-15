((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The phase-aware-macro-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 separates Gerbil meta-syntactic tower, phase/context parsing, expansion, and runtime helper responsibilities")
 (feature . "phase-aware-macro-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "phase/context macro parsing split from runtime helper generation")
 (inputShape
  .
  "one macro owner mixes Phase, Macro, Context, Transformer, Expansion, and Runtime helper responsibilities")
 (expectedOutcome
  .
  "keep the syntax wrapper thin, document the expansion contract, and move reusable behavior into ordinary runtime helpers")
 (expectedReferencePattern . "gerbil-phase-aware-macro-boundary")
 (expectedReferenceExamples
  "gerbil://README.md#meta-syntactic-tower"
  "gerbil://gerbil/expander/top.ss#begin-syntax-phi-plus-one"
  "gerbil://gerbil/expander/core.ss#core-context-shift"
  "gerbil://gerbil/expander/module.ss#core-expand-module-begin")
 (expectedQualitySignals
  "meta-syntactic-tower-boundary"
  "phase-aware-macro-boundary"
  "phase-shift-context-boundary"
  "hygienic-transformer-boundary"
  "runtime-helper-boundary")
 (learnedStyleSources
  "gerbil://README.md"
  "gerbil://gerbil/expander/top.ss"
  "gerbil://gerbil/expander/core.ss")
 (antiAiScaffoldIntent
  .
  "reject one-owner macro DSL scaffolding that mixes phase/context parsing, expansion, and runtime behavior")
 (scenarioQualityAxes
  "meta-syntactic-tower"
  "phase-aware-macro-boundary"
  "controlled-macro-syntax")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "gerbil-native" "macro" "phase" "meta-syntactic-tower"))
