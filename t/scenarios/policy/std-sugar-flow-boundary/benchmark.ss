((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The std-sugar-flow-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 std sugar flow scenario keeps nested let/if agent scaffolding under the scenario-owned timing gate while preferring std/sugar chain and if-let for local expression flow")
 (feature . "std-sugar-flow-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "nested let/if flow scaffolding to std/sugar chain and if-let")
 (inputShape . "workflow helpers combine nested conditional branches, required field lookups, optional retry state, and a resource-scoped audit writer")
 (expectedOutcome . "use if-let for required bindings and chain for the linear status projection while preserving resource-scoped output flow")
 (misuseGuard . "do not rewrite call-with-output-file or other resource/control boundaries into std/sugar expression flow")
 (expectedReferencePattern . "std-sugar-flow-boundary")
 (expectedReferenceExamples
  "gerbil://std/sugar.ss#chain"
  "gerbil://std/sugar.ss#if-let"
  "gerbil://std/sugar.ss#when-let")
 (expectedQualitySignals
  "std-sugar-flow-boundary"
  "basic-syntax-scaffold"
  "chain-expression-flow"
  "early-failure-conditional")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject nested let/if scaffolding when the owner is a local workflow expression and std/sugar chain or if-let exposes the data path, but preserve resource/control boundaries")
 (scenarioQualityAxes
  "std-sugar-flow-boundary"
  "gerbil-gambit-native-idiom"
  "anti-ai-scaffold"
  "misuse-resistant-resource-boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "std-sugar" "chain" "if-let" "conditional" "anti-scaffold"))
