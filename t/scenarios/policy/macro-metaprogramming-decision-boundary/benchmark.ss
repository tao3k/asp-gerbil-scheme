((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "macro metaprogramming decision scenario is a small source owner; collection and policy must stay inside a millisecond-scale gate")
 (sampleCount . 20)
 (purpose . "R013 teaches when to use declarative macros and when to upgrade to procedural metaprogramming")
 (feature . "macro-metaprogramming-decision-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "AI repeated macro wrappers to one defrules family plus syntax-case only at the validation/source-error boundary")
 (inputShape
  .
  "same-prefix defrules wrappers plus a procedural transformer without a documented decision boundary")
 (expectedOutcome
  .
  "declarative defrules family for fixed rewrites, procedural syntax-case/with-syntax only for identifier validation and source-aware errors")
 (expectedReferencePattern . "gerbil-macro-metaprogramming-decision-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/core/sugar.ss#defrules"
  "gerbil://std/sugar.ss#let-hash"
  "gerbil://gerbil/core/match.ss#defsyntax-for-match")
 (expectedQualitySignals
  "macro-metaprogramming-decision-boundary"
  "declarative-macro-pattern"
  "procedural-macro-transformer"
  "syntax-object-validation"
  "identifier-reconstruction"
  "with-syntax-reconstruction"
  "source-aware-syntax-error")
 (learnedStyleSources "gerbil://" "gerbil-utils" "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "prevent agents from writing basic repeated Scheme wrappers or procedural macro scaffolding when Gerbil has a clearer declarative/procedural split")
 (scenarioQualityAxes
  "macro-metaprogramming-decision-boundary"
  "declarative-macro-pattern"
  "procedural-macro-transformer"
  "syntax-object-validation"
  "identifier-reconstruction"
  "with-syntax-reconstruction"
  "source-aware-syntax-error")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "macro" "metaprogramming" "declarative" "procedural"))
