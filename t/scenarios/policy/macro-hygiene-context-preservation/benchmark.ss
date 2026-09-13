((benchmarkKind . scenario-e2e)
 (schemaId . "agent.semantic-protocols.gerbil-scheme-policy-scenario-benchmark")
 (schemaVersion . "4")
 (feature . "macro-hygiene-context-preservation")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (purpose . "R013 proves that grammar literals and generated forms retain lexical and source context")
 (inputShape . "macro grammar collapses syntax to printed symbols and stores call context in a mutable phase global")
 (expectedOutcome . "binding-aware literal comparison, syntax-preserving planning, and source-aware expansion errors")
 (optimizationFocus . "syntax->datum string dispatch to free-identifier equality and syntax context preservation")
 (antiAiScaffoldIntent . "prevent generated DSL macros from erasing lexical identity and source locations")
 (expectedReferencePattern . "macro-hygiene-context-preservation")
 (expectedReferenceExamples
  "gerbil://gerbil/expander/core.ss#free-identifier=?"
  "gerbil://gerbil/expander/stx.ss#syntax/loc"
  "gerbil://gerbil/expander/core.ss#raise-syntax-error")
 (learnedStyleSources
  "gerbil://gerbil/expander/core.ss"
  "gerbil://gerbil/expander/stx.ss"
  "harness-self-apply")
 (expectedQualitySignals
  "macro-hygiene-context-preservation"
  "macro-hygiene-boundary"
  "scoped-expander-state-boundary"
  "source-aware-syntax-error")
 (scenarioQualityAxes
  "macro-hygiene-context-preservation"
  "binding-aware-grammar-literal"
  "syntax-context-preservation"
  "source-aware-syntax-error")
 (tags "style" "macro" "hygiene" "syntax-context" "source-location")
 (targetRationale . "syntax-context inspection must remain inside the small R013 macro-policy gate")
 (sampleCount . 20)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (expected_over_input_note . #f)
 (max_total . 200ms)
 (measurementPhases
  "collect-before" "collect-after" "policy-before" "policy-after"
  "assert-time-gate" )
 (hotPathEvidence)
 (hotPathExemption . #f)
 (nativePooPrimary . #f)
 (adapterBoundary . #f)
 (styleRewriteBoundary . #f))
