((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The ssxi-optimizer-metadata-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 keeps SSXI optimizer metadata adjacent to compiler-visible primitive call shape")
 (feature . "ssxi-optimizer-metadata-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "SSXI metadata and inline-rule visibility for direct primitive calls")
 (inputShape
  .
  "one helper mixes SSXI, inline rule, optimizer metadata, primitive dispatch, and dynamic apply")
 (expectedOutcome
  .
  "name the optimizer boundary and keep the primitive call lexical and direct instead of routing through a dynamic table")
 (expectedReferencePattern . "gerbil-ssxi-optimizer-metadata-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/compiler/ssxi.ss#declare-inline-rule!"
  "gerbil://gerbil/builtin-inline-rules.ssxi.ss#declare-inline-rules!"
  "gerbil://gerbil/compiler/optimize-call.ss#call-unchecked"
  "gerbil://gerbil/compiler/optimize-top.ss#dispatch-lambda-form?")
 (expectedQualitySignals
  "ssxi-metadata-boundary"
  "declare-inline-rule-boundary"
  "lexical-primitive-call"
  "direct-call-shape"
  "unchecked-call-visibility")
 (learnedStyleSources
  "gerbil://gerbil/compiler/ssxi.ss"
  "gerbil://gerbil/builtin-inline-rules.ssxi.ss"
  "gerbil://gerbil/compiler/optimize-call.ss")
 (antiAiScaffoldIntent
  .
  "reject dynamic primitive tables that hide compiler-known call shapes from SSXI inline metadata")
 (scenarioQualityAxes
  "ssxi-optimizer-metadata-boundary"
  "direct-call-shape"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "gerbil-native" "ssxi" "optimizer" "inline" "direct-call"))
