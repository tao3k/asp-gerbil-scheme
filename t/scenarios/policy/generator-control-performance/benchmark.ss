((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The generator-control target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (routeSource . "parser-scenario")
 (maxProviderProcessCount . 0)
 (maxStdoutBytes . 8192)
 (fallbackReason . "none")
 (sampleCount . 20)
 (purpose . "R013 generator control scenario keeps learned generator-boundary repair within the scenario-owned timing gate")
 (feature . "generator-control")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "push/pull generator control inversion boundary")
 (inputShape . "manual pull generator loop behind a Generating contract")
 (expectedOutcome
  .
  "local generator reducer boundary with full typed documentation")
 (expectedReferencePattern . "gerbil-utils-generator-control")
 (expectedReferenceExamples
  "gerbil-utils/generator.ss#generating<-for-each"
  "gerbil-utils/generator.ss#yield-continuation-boundary")
 (expectedQualitySignals
  "push-pull-control-inversion"
  "call/cc-yield-boundary")
 (learnedStyleSources "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject hand-written producer-loop scaffolding when generator contracts prove a combinator boundary")
 (scenarioQualityAxes "generator-combinator-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "generator" "control-inversion"))
