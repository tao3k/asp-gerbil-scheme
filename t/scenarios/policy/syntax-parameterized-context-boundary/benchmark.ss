((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "syntax-parameterized context is a small macro owner; collection and policy must stay inside a millisecond-scale gate")
 (sampleCount . 20)
 (purpose . "R013 teaches Gerbil syntax parameters for scoped compile-time macro context")
 (feature . "syntax-parameterized-context-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "mutable compile-time macro globals to defsyntax-parameter* plus syntax-parameterize")
 (inputShape
  .
  "macro owner mutates a compile-time global to simulate contextual macro state")
 (expectedOutcome
  .
  "defsyntax-parameter* declares the contextual macro and syntax-parameterize binds it at the call boundary")
 (expectedReferencePattern . "gerbil-syntax-parameterized-context-boundary")
 (expectedReferenceExamples
  "gerbil://std/stxparam.ss#defsyntax-parameter"
  "gerbil://std/stxparam.ss#syntax-parameterize"
  "gerbil://std/text/csv.ss#ambient-csv-options"
  "gerbil://std/actor-v18/message.ss#@envelope")
 (expectedQualitySignals
  "syntax-parameterized-context-boundary"
  "syntax-parameter-definition"
  "syntax-parameterized-context"
  "global-macro-state-mutation"
  "manual-phase-context-threading"
  "source-aware-syntax-error")
 (learnedStyleSources
  "gerbil://std/stxparam.ss"
  "gerbil://std/text/csv.ss"
  "gerbil://std/actor-v18/message.ss"
  "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "prevent agents from storing contextual macro state in mutable compile-time globals when Gerbil syntax parameters provide a scoped phase-safe boundary")
 (scenarioQualityAxes
  "syntax-parameterized-context-boundary"
  "syntax-parameter-definition"
  "syntax-parameterized-context"
  "global-macro-state-mutation"
  "manual-phase-context-threading"
  "source-aware-syntax-error")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "macro" "metaprogramming" "syntax-parameter" "phase-context"))
