((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The macro-hygiene target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 controlled macro syntax scenario keeps macro guidance within the scenario-owned timing gate")
 (feature . "macro-hygiene")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "scoped expander state and controlled macro syntax boundary")
 (inputShape
  .
  "macro transformer with global mutable phase/context state, datum dispatcher, no source-aware syntax error, and no expansion documentation")
 (expectedOutcome
  .
  "thin hygienic syntax-case/with-syntax transformer with typed expansion context, parameterized macro state, source-aware syntax errors, and full typed documentation")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject generated macro scaffolding that hides hygiene and phase/context state behind global mutation or verbose dispatcher code")
 (scenarioQualityAxes
  "macro-hygiene-boundary"
  "scoped-expander-state-boundary"
  "source-aware-syntax-error"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "macro" "hygiene"))
