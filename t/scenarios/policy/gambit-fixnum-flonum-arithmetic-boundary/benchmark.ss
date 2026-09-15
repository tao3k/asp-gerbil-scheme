((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The gambit-fixnum-flonum-arithmetic-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 teaches agents to use Gambit numeric primitive families only behind explicit type/range boundaries")
 (feature . "gambit-fixnum-flonum-arithmetic-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "fixnum/flonum primitive arithmetic with checked boundary tests")
 (inputShape
  .
  "hot numeric loops use generic arithmetic even when values are already constrained to fixnum or flonum domains")
 (expectedOutcome
  .
  "surface the numeric domain contract, use fx/fl primitive families in the hot lane, and keep overflow/type behavior covered by tests")
 (expectedReferencePattern . "gambit-numeric-primitive-domain-boundary")
 (expectedReferenceExamples
  "gambit://tests/unit-tests/01-fixnum/fxadd.scm#fx+"
  "gambit://tests/unit-tests/01-fixnum/fxadd.scm#fixnum-overflow-exception"
  "gambit://tests/unit-tests/02-flonum/fladd.scm#fl+")
 (expectedQualitySignals
  "numeric-domain-contract"
  "fixnum-overflow-covered"
  "flonum-type-covered"
  "hot-loop-primitive-family")
 (learnedStyleSources
  "gambit://tests/unit-tests/01-fixnum/fxadd.scm"
  "gambit://tests/unit-tests/02-flonum/fladd.scm")
 (antiAiScaffoldIntent
  .
  "reject generated hot numeric loops that default to generic arithmetic while omitting the fixnum/flonum domain and failure-mode tests")
 (scenarioQualityAxes
  "gambit-numeric-primitives"
  "typed-hot-loop-boundary"
  "overflow-and-type-tests"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "gambit-native" "numeric" "fixnum" "flonum" "hot-loop"))
