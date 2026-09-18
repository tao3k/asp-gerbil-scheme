((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The macro-phase-optimizer-visible-fast-path target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 connects Gerbil phase-aware macro DSLs to optimizer-visible runtime call shapes")
 (feature . "macro-phase-optimizer-visible-fast-path")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "macro-generated runtime helpers that preserve lexical direct calls")
 (inputShape
  .
  "macro DSL generates a hot runtime helper that routes a known operation through a dynamic table and repeated apply")
 (expectedOutcome
  .
  "keep the macro surface thin, pass the checked helper lexically, and generate a loop whose hot call remains direct and optimizer-visible")
 (expectedReferencePattern . "macro-phase-optimizer-visible-fast-path")
 (expectedReferenceExamples
  "gerbil://README.md#meta-syntactic-tower"
  "gerbil://gerbil/expander/top.ss#begin-syntax-phi-plus-one"
  "gerbil://gerbil/compiler/ssxi.ss#declare-inline-rule!"
  "gerbil://gerbil/compiler/optimize-call.ss#%#call-unchecked")
 (expectedQualitySignals
  "phase-aware-macro-boundary"
  "generated-runtime-helper"
  "lexical-direct-helper"
  "optimizer-visible-call-shape")
 (learnedStyleSources
  "gerbil://README.md"
  "gerbil://gerbil/expander/top.ss"
  "gerbil://gerbil/compiler/ssxi.ss"
  "gerbil://gerbil/compiler/optimize-call.ss")
 (antiAiScaffoldIntent
  .
  "reject generated macro DSL helpers that hide known runtime calls behind dynamic tables or apply and therefore erase Gerbil optimizer visibility")
 (scenarioQualityAxes
  "phase-aware-macro-dsl"
  "generated-runtime-helper"
  "known-procedure-call-fast-path"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "gerbil-native" "macro" "phase" "compiler" "optimizer" "direct-call"))
