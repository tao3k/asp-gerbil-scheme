((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The destructuring-combinator-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 destructuring combinator scenario keeps repeated pair/alist access repair within the scenario-owned timing gate while preferring native match mechanisms when they remove runtime probing")
 (feature . "destructuring-combinator-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "temporary destructuring scaffolding to native match, selector, or syntax-local boundary")
 (inputShape . "three exported helpers repeat assq/cdr alist probing, defaults, and conditional routing over one event record")
 (expectedOutcome . "single with/match destructuring boundary, RouteKey domain type, core match dispatch, and full typed documentation")
 (expectedReferencePattern . "destructuring-combinator-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/core/match.ss#applicative-destructuring"
  "gerbil://gerbil/core/match.ss#syntax-local-match-macro"
  "gerbil://gerbil/core/match.ss#syntax-local-value-class-accessors"
  "gerbil://gerbil/core/match.ss#defsyntax-for-match"
  "gerbil-utils/base.ss#lambda-match"
  "gerbil-utils/base.ss#let-match"
  "gerbil-poo/mop.ss#slot-lens"
  "gerbil-poo/mop.ss#Lens.compose")
 (expectedQualitySignals
  "destructuring-combinator-boundary"
  "applicative-destructuring-boundary"
  "syntax-local-match-extension"
  "compile-time-metadata-lookup"
  "early-syntax-error-boundary"
  "lambda-match-destructuring"
  "named-selector-boundary"
  "slot-lens-boundary"
  "temporary-binding-collapse")
 (learnedStyleSources "gerbil://" "gerbil-utils" "gerbil-poo")
 (antiAiScaffoldIntent . "reject repeated pair/alist/object destructuring scaffolding when native match/apply destructuring, syntax-local lookup, a selector, lambda-match, or slot/lens boundary expresses the data shape")
 (scenarioQualityAxes "destructuring-combinator-boundary" "anti-ai-scaffold")
 (measurementPhases "collect-before" "collect-after" "policy-before" "policy-after" "assert-time-gate" )
 (tags "style" "destructuring" "selector" "anti-scaffold"))
