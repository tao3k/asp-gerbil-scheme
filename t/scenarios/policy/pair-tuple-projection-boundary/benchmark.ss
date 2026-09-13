((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The pair-tuple-projection-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 pair tuple projection scenario keeps cons-built Pair result protocols under the scenario-owned timing gate while preferring Gerbil values when the pair is not the domain interface")
 (feature . "pair-tuple-projection-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "cons-built Pair result protocol to values/call-with-values tuple projection")
 (inputShape . "one helper returns a Pair with cons and a public config helper immediately splits it with car/cdr")
 (expectedOutcome . "producer returns multiple values and consumer destructures with call-with-values while preserving the public config API")
 (expectedReferencePattern . "pair-tuple-projection-boundary")
 (expectedReferenceExamples
  "gerbil-utils/base.ss#values/call-with-values"
  "gerbil://gerbil/core/match.ss#applicative-destructuring")
 (expectedQualitySignals
  "pair-tuple-projection-boundary"
  "anonymous-result-protocol"
  "values/call-with-values tuple projection"
  "temporary-binding-collapse")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject cons-built Pair tuple protocols when values/call-with-values exposes the producer and consumer boundary without inventing a domain pair")
 (scenarioQualityAxes
  "pair-tuple-projection-boundary"
  "gerbil-gambit-native-idiom"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "destructuring" "values" "tuple" "anti-scaffold"))
