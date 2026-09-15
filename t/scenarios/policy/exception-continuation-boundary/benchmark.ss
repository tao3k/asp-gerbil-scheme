((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The exception-continuation-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 exception continuation scenario keeps learned exception-control repair within the scenario-owned timing gate")
 (feature . "exception-continuation-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "local exception continuation and contextual logging boundary")
 (inputShape
  .
  "single exported function mixes Exception, Continuation, Handler, Context, and Raise responsibilities")
 (expectedOutcome
  .
  "local exception helpers split printable diagnostics, contextual logging, and re-raise behavior without adding gerbil-utils dependencies")
 (expectedReferencePattern . "exception-continuation-boundary")
 (expectedReferenceExamples
  "gerbil-utils/exception.ss#with-catch/cont"
  "gerbil-utils/exception.ss#call-with-logged-exceptions"
  "gerbil-utils/exception.ss#with-logged-exceptions")
 (expectedQualitySignals
  "handler-restoration-boundary"
  "contextual-exception-logging"
  "re-raise-after-logging")
 (learnedStyleSources "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject catch-all exception scaffolding when contracts expose continuation and handler responsibilities")
 (scenarioQualityAxes "exception-continuation-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "exception" "continuation" "context-boundary"))
