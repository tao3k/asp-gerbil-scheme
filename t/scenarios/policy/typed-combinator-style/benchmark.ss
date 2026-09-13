((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The typed-combinator-style target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 typed-combinator-style scenario keeps core Gerbil expression idiom repair under the scenario timing gate")
 (feature . "typed-combinator-style")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "manual traversal and missing expression evidence to Gerbil-native combinator style")
 (inputShape . "small owner exposes hand-written named-let traversal and no adjacent typed-combinator contracts")
 (expectedOutcome . "typed docs, lambda-match shape dispatch, curry/rcurry, compose, and map traversal")
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
  "lambda-match-destructuring"
  "map-fold-boundary")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject missing typed contracts and hand-written traversal when Gerbil-native match, cut, compose, or map boundaries express the behavior")
 (scenarioQualityAxes
  "typed-combinator-style"
  "gerbil-upstream-idiom-boundary"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "typed-combinator" "gerbil-upstream" "subsecond"))
