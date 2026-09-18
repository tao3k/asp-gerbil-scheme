((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The gerbil-inline-rule-call-shape target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 routes hot primitive call drift toward Gerbil builtin inline-rule and dispatch-lambda shapes")
 (feature . "gerbil-inline-rule-call-shape")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "compiler-recognizable inline primitive call shape")
 (inputShape
  .
  "hot code hides primitive operations behind dynamic tables and apply, preventing Gerbil builtin inline rules from seeing the call shape")
 (expectedOutcome
  .
  "keep the hot primitive call target lexical and direct, using fixnum primitives when the value boundary is already known")
 (expectedReferencePattern . "gerbil-builtin-inline-rule-call-shape")
 (expectedReferenceExamples
  "gerbil://gerbil/builtin-inline-rules.ssxi.ss#declare-inline-rules!"
  "gerbil://gerbil/builtin-inline-rules.ssxi.ss#ast-rules"
  "gerbil://gerbil/compiler/optimize-top.ss#dispatch-lambda-form?")
 (expectedQualitySignals
  "lexical-primitive-call"
  "direct-call-shape"
  "fixnum-boundary"
  "no-dynamic-apply")
 (learnedStyleSources
  "gerbil://gerbil/builtin-inline-rules.ssxi.ss"
  "gerbil://gerbil/compiler/optimize-top.ss")
 (antiAiScaffoldIntent
  .
  "reject generated primitive dispatch tables that hide hot arithmetic and predicates from compiler-recognizable inline rules")
 (scenarioQualityAxes
  "builtin-inline-rule-shape"
  "dispatch-lambda-form"
  "fixnum-hot-path"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "gerbil-native" "compiler" "optimizer" "inline-rule" "fixnum"))
