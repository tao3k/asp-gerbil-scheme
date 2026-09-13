((benchmarkKind . scenario-e2e)
 (schemaId . "agent.semantic-protocols.gerbil-scheme-policy-scenario-benchmark")
 (schemaVersion . "4")
 (feature . "macro-governance-admission")
 (rule . "GERBIL-SCHEME-MACRO-GOVERNANCE-001")
 (purpose . "Macro governance compiles one POO profile and admits parser-owned macro facts without expansion replay")
 (inputShape . "one function-shaped defsyntax transformer with executable witness metadata and a parser-owned test invocation")
 (expectedOutcome . "one bounded declarative defrules transformer preserving the same public behavior and executable witness")
 (optimizationFocus . "compile POO policy once, then evaluate a flat rule plan over collected MacroFacts")
 (antiAiScaffoldIntent . "reject opaque generated transformer functions when a small hygienic structural rewrite carries the contract")
 (expectedReferencePattern . "poo-macro-governance-admission")
 (expectedReferenceExamples
  "gerbil://gerbil/expander/core.ss#syntax-case"
  "gerbil://std/sugar.ss#defrules"
  "asp-gerbil-scheme/src/macro-governance/model.ss#asp-strict-macro-governance-profile")
 (learnedStyleSources
  "gerbil://gerbil/expander/core.ss"
  "gerbil-poo"
  "harness-self-apply")
 (expectedQualitySignals
  "parser-owned-macro-fact"
  "poo-profile"
  "hygienic-macro"
  "typed-admission-receipt")
 (scenarioQualityAxes
  "macro-governance-admission"
  "hygiene"
  "bounded-pattern-family"
  "executable-witness")
 (tags "style" "macro" "poo" "hygiene" "admission")
 (targetRationale
  .
  "The macro-governance-admission target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (expected_over_input_note . #f)
 (max_total . 200ms)
 (measurementPhases
  "collect-before" "collect-after" "policy-before" "policy-after"
  "assert-time-gate"  "assert-input-expected-comparison")
 (hotPathEvidence . "macro-governance-compile-rule-plan is evaluated once per policy admission")
 (hotPathExemption . #f)
 (nativePooPrimary . #t)
 (adapterBoundary . #f)
 (styleRewriteBoundary . #f))
