((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The functional-idiom target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 functional idiom scenario keeps manual fold and local destructuring repair within the scenario-owned timing gate")
 (feature . "functional-idiom")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "manual recursion to fold/pipeline and lambda-match boundary")
 (inputShape
  .
  "single exported function uses named-let, cdr/car traversal, and an accumulator over a list")
 (expectedOutcome
  .
  "foldl total, !>/curry pipeline, and named lambda-match classifier with full typed documentation")
 (expectedReferencePattern . "loop-driver-combinator-boundary")
 (expectedReferenceExamples
  "gerbil://std/actor-v13/rpc/proto/cipher.ss#foldl-chunk-accumulator"
  "gerbil-utils/list.ss#list-map"
  "gerbil-utils/list.ss#list<-monoid"
  "gerbil-utils/base.ss#lambda-match"
  "gerbil-utils/base.ss#compose/rcompose")
 (expectedQualitySignals
  "manual-loop-drift"
  "pure-loop-driver-combinator-boundary"
  "fold-reducer-boundary"
  "map-fold-boundary"
  "lambda-match-list-destructuring")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject hand-written traversal and anonymous destructuring when fold, cut/curry pipeline, or lambda-match exposes the data flow")
 (scenarioQualityAxes
  "functional-idiom"
  "gerbil-gambit-native-idiom"
  "loop-driver-combinator-boundary"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style"
       "functional"
       "gerbil-idiom"
       "gambit-control"
       "fold"
       "pipeline"
       "lambda-match"
       "anti-scaffold"))
