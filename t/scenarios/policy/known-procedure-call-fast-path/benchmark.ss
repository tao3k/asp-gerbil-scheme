((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The known-procedure-call-fast-path target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 routes hot call-site drift toward Gerbil optimizer-style known-procedure fast paths")
 (feature . "known-procedure-call-fast-path")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "type-resolved procedure calls and source-preserving unchecked call lowering")
 (inputShape
  .
  "hot code repeatedly calls a known procedure through generic wrappers or dynamic dispatch after the callable boundary is already known")
 (expectedOutcome
  .
  "make the callable boundary explicit, preserve the checked public edge, and keep the hot internal path eligible for known-procedure lowering")
 (expectedReferencePattern . "gerbil-optimizer-known-call-fast-path")
 (expectedReferenceExamples
  "gerbil://gerbil/compiler/optimize-call.ss#apply-optimize-call"
  "gerbil://gerbil/compiler/optimize-call.ss#optimize-call%"
  "gerbil://gerbil/compiler/optimize-call.ss#%#call-unchecked")
 (expectedQualitySignals
  "known-call-boundary"
  "checked-public-edge"
  "unchecked-internal-fast-path"
  "source-preserving-transform")
 (learnedStyleSources
  "gerbil://gerbil/compiler/optimize-call.ss"
  "gerbil://gerbil/compiler/method.ss")
 (antiAiScaffoldIntent
  .
  "reject generated wrapper stacks that hide known procedure boundaries and force every hot call through generic runtime dispatch")
 (scenarioQualityAxes
  "known-procedure-call-fast-path"
  "checked-vs-unchecked-boundary"
  "gerbil-optimizer-native-idiom"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "gerbil-native" "compiler" "optimizer" "call-fast-path" "unchecked-call"))
