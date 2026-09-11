((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The typeclass-wrapper-adapter target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 typeclass wrapper scenario keeps learned wrap/unwrap method adapter repair within the scenario-owned timing gate")
 (feature . "typeclass-wrapper-adapter")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "local wrapper/functor method adapter lift")
 (inputShape
  .
  "single define-type mixes Wrapper, Functor, wrap/unwrap, and IO/JSON/bytes/marshal method lambdas")
 (expectedOutcome
  .
  "local adapter helpers lift protocol methods through wrap/unwrap without adding gerbil-poo dependencies")
 (expectedReferencePattern . "typeclass-wrapper-adapter")
 (expectedReferenceExamples
  "gerbil-poo/fun.ss#methods.io<-wrap"
  "gerbil-poo/fun.ss#Wrapper."
  "gerbil-poo/fun.ss#Wrap^.")
 (expectedQualitySignals
  "wrapper-adapter-lift"
  "wrap-unwrap-boundary"
  "method-protocol-lift")
 (learnedStyleSources "gerbil-poo")
 (antiAiScaffoldIntent
  .
  "reject table-shaped wrapper method scaffolding when POO typeclass facts expose protocol lifts")
 (scenarioQualityAxes "poo-typeclass-algebra-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "typeclass" "wrapper" "method-adapter"))
