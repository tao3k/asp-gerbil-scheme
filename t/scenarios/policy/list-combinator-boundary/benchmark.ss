((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The list-combinator-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 list combinator scenario keeps anti-scaffold traversal repair within the scenario-owned timing gate")
 (feature . "list-combinator-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "manual list recursion to expression-level traversal boundary")
 (inputShape
  .
  "single exported function uses named-let, reverse accumulator, and inline selection/projection over a list")
 (expectedOutcome
  .
  "local selector plus filter-map traversal with full typed documentation")
 (expectedReferencePattern . "list-combinator-boundary")
 (expectedReferenceExamples
  "gerbil-utils/list.ss#list-map"
  "gerbil-utils/list.ss#list<-monoid"
  "gerbil-utils/list.ss#with-deduplicated-list-builder"
  "gerbil-utils/base.ss#lambda-match")
 (expectedQualitySignals
  "list-combinator-boundary"
  "map-fold-boundary"
  "filter-map-selection-projection"
  "lambda-match-list-destructuring"
  "list-builder-output-shape")
 (learnedStyleSources "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject hand-written list traversal scaffolding when a mapper, selector, reducer, filter-map, fold, or builder boundary expresses the data flow")
 (scenarioQualityAxes "list-combinator-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "list" "combinator" "anti-scaffold"))
