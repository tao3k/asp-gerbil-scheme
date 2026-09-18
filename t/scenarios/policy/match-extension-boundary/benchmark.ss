((benchmarkKind . scenario-e2e)
 (target_total . 100ms)
 (max_total . 200ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The match-extension-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 match extension scenario keeps Gerbil core/match defsyntax-for-match and applicative destructuring guidance under the scenario-owned timing gate")
 (feature . "match-extension-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "Gerbil core/match match macro extension, syntax-local lookup, and applicative destructuring boundaries")
 (inputShape
  .
  "macro owner mixes match pattern parsing, syntax-local expansion, struct/class field accessors, applicative apply destructuring, pattern variables, and source-aware errors in one runtime dispatcher")
 (expectedOutcome
  .
  "defsyntax-for-match surface with pattern parsing isolated from runtime predicate helpers and source-aware errors kept at the match extension boundary")
 (learnedStyleSources
  "gerbil://gerbil/core/match.ss#defsyntax-for-match"
  "gerbil://gerbil/core/match.ss#syntax-local-match-macro?"
  "gerbil://gerbil/core/match.ss#struct-field-accessors")
 (antiAiScaffoldIntent
  .
  "reject table-shaped match extension macros that reimplement Gerbil match macro lookup, applicative destructuring, and struct/class accessor extraction")
 (scenarioQualityAxes
  "match-extension-boundary"
  "match-macro-destructuring-boundary"
  "syntax-local-match-macro-boundary"
  "applicative-destructuring-boundary"
  "anti-ai-scaffold")
 (expectedReferencePattern . "gerbil-core-match-extension-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/core/match.ss#match-macro"
  "gerbil://gerbil/core/match.ss#syntax-local-match-macro?"
  "gerbil://gerbil/core/match.ss#parse-match-pattern"
  "gerbil://gerbil/core/match.ss#struct-field-accessors"
  "gerbil://gerbil/core/match.ss#defsyntax-for-match"
  "gerbil://gerbil/core/match.ss#defrules-for-match")
 (expectedQualitySignals
  "match-extension-boundary"
  "match-macro-destructuring-boundary"
  "syntax-local-match-macro-boundary"
  "applicative-destructuring-boundary"
  "struct-class-accessor-boundary"
  "source-aware-pattern-error-boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "macro" "match"))
