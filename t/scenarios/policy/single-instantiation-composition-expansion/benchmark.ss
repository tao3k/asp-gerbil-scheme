((benchmarkKind . scenario-e2e)
 (schemaId . "agent.semantic-protocols.gerbil-scheme-policy-scenario-benchmark")
 (schemaVersion . "4")
 (feature . "single-instantiation-composition-expansion")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (purpose . "R013 keeps composition macro support in one compiled Gerbil module context")
 (inputShape . "macro expansion loads parser source and guards duplicate initialization with a mutable phase global")
 (expectedOutcome . "for-syntax import reuses one registered compiled helper module with no load or eval path")
 (optimizationFocus . "per-expansion source loading to Gerbil module-registry single instantiation")
 (antiAiScaffoldIntent . "prevent generated macro loaders from re-reading source or creating mutable once-only registries")
 (expectedReferencePattern . "single-instantiation-composition-expansion")
 (expectedReferenceExamples
  "gerbil://gerbil/expander/module.ss#import-module"
  "gerbil://gerbil/expander/module.ss#module-context")
 (learnedStyleSources
  "gerbil://gerbil/expander/module.ss"
  "gerbil://gerbil/expander/top.ss"
  "harness-self-apply")
 (expectedQualitySignals
  "single-instantiation-composition-expansion"
  "phase-aware-macro-boundary"
  "global-macro-state-mutation"
  "manual-phase-context-threading")
 (scenarioQualityAxes
  "single-instantiation-composition-expansion"
  "compiled-macro-helper"
  "module-context-reuse"
  "expansion-source-load")
 (tags "style" "macro" "phase" "module-context" "single-instantiation")
 (targetRationale . "module-context reuse is a structural fact and must remain inside the R013 millisecond gate")
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
