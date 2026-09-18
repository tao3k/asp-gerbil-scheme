((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The macro-family-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 macro-family scenario catches repeated same-prefix thin macro wrappers")
 (feature . "macro-family-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "collapse repeated same-prefix macro wrappers into one hygienic family helper")
 (inputShape
  .
  "poo-flow-shaped defrules wrappers repeated across the same macro prefix")
 (expectedOutcome
  .
  "one macro family helper with typed documentation and runtime semantics left in ordinary helpers")
 (expectedReferencePattern . "gerbil-utils-controlled-macro-helper")
 (expectedReferenceExamples
  "gerbil://gerbil/compiler/method.ss#ast-case-with-syntax-map-cut"
  "gerbil://gerbil/expander/core.ss#current-expander-context"
  "gerbil://gerbil/expander/core.ss#core-apply-user-macro")
 (expectedQualitySignals
  "controlled-macro-helper"
  "macro-hygiene-boundary"
  "parameterized-expander-state")
 (learnedStyleSources "gerbil://" "gerbil-utils" "poo-flow")
 (antiAiScaffoldIntent
  .
  "use poo-flow as an experiment fixture while keeping the policy signal generic and parser-owned")
 (scenarioQualityAxes "macro-family-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "macro-family" "poo-flow-shape"))
