((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "syntax-local registry scenario is a small macro owner; collection and policy must stay inside a millisecond-scale gate")
 (sampleCount . 20)
 (purpose . "R013 teaches syntax-local-value metadata lookup for compile-time macro registries")
 (feature . "syntax-local-registry-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "syntax->datum keyed compile-time hash registry to defsyntax metadata plus syntax-local-value")
 (inputShape
  .
  "macro owner stores compile-time metadata in a mutable hash table keyed by syntax->datum")
 (expectedOutcome
  .
  "bind metadata to the identifier with defsyntax and validate it through syntax-local-value before expansion")
 (expectedReferencePattern . "gerbil-syntax-local-registry-boundary")
 (expectedReferenceExamples
  "gerbil://std/generic/macros.ss#generic-info"
  "gerbil://std/protobuf/macros.ss#syntax-local-type"
  "gerbil://std/actor-v13/proto.ss#defproto")
 (expectedQualitySignals
  "syntax-local-registry-boundary"
  "manual-syntax-registry-table"
  "syntax-datum-registry-key"
  "syntax-local-registry-lookup"
  "source-aware-syntax-error")
 (learnedStyleSources
  "gerbil://std/generic/macros.ss"
  "gerbil://std/protobuf/macros.ss"
  "gerbil://std/actor-v13/proto.ss"
  "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "prevent agents from hand-rolling syntax->datum keyed macro registries when Gerbil identifier metadata already supports hygienic compile-time lookup")
 (scenarioQualityAxes
  "syntax-local-registry-boundary"
  "manual-syntax-registry-table"
  "syntax-datum-registry-key"
  "syntax-local-registry-lookup"
  "source-aware-syntax-error")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "macro" "metaprogramming" "syntax-local-value" "registry"))
