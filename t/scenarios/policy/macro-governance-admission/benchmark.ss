((schemaId . "agent.semantic-protocols.gerbil-scheme-policy-scenario-benchmark")
 (schemaVersion . "2")
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
 (targetRationale . "three retained samples separate parser cold initialization from the best steady-state parser plus flat governance pass; the 76ms hard ceiling covers observed clean macOS runner variance while the 18ms target and 26ms regression budget remain diagnostic")
 (unit . "ms")
 (iterations . 3)
 (target_total . 18ms)
 (regression_budget . 26ms)
 (expected_over_input_budget . 12ms)
 (expected_over_input_note . #f)
 (max_total . 76ms)
 (observed_total . 0ms)
 (maxCollectMs . 16)
 (maxParseMs . 16)
 (maxFileMs . 6)
 (maxPhaseMs . 10)
 (observedCollectMs . 0)
 (observedParseMs . 0)
 (observedFileMs . 0)
 (observedPhaseMs . 0)
 (observedTimings
  ((name . collect-before) (durationMs . 0))
  ((name . collect-after) (durationMs . 0))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 0)))
 (measurementPhases
  "collect-before" "collect-after" "policy-before" "policy-after"
  "assert-time-gate" "assert-memory-gate" "assert-input-expected-comparison")
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (maxRssMb . 512)
 (hotPathEvidence . "macro-governance-compile-rule-plan is evaluated once per policy admission")
 (hotPathExemption . #f)
 (nativePooPrimary . #t)
 (adapterBoundary . #f)
 (styleRewriteBoundary . #f))
