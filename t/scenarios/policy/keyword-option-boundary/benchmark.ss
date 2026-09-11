((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "keyword-option-boundary validates Gerbil native #!key option APIs as the repair for generated opts alist scanning")
 (sampleCount . 20)
 (purpose
  .
  "R022 keyword option scenario rejects generated opts alist scanning when Gerbil keyword/default parameters should own the function option contract")
 (feature . "keyword-option-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-022")
 (optimizationFocus
  .
  "repeated inline assq/cdr option-bag probing to Gerbil #!key parameters with compiler-owned keyword dispatch")
 (inputShape
  .
  "one report API repeats inline assq/cdr over an opts alist for format, limit, and metadata options")
 (expectedOutcome
  .
  "the report API declares #!key defaults and callers pass format:/limit:/metadata: keyword arguments")
 (expectedReferencePattern . "gerbil-keyword-option-boundary")
 (expectedReferenceExamples
  "gerbil://gambit/gsc/tests/69-params/optional.scm#!optional"
  "gerbil://gambit/gsc/tests/69-params/optionalkeyrest.scm#!key"
  "gerbil://std/markup/sxml/oleg/define-opt.scm#compiler-optimized-optional-dispatch")
 (expectedQualitySignals
  "inline-alist-lookup-drift"
  "keyword-option-boundary"
  "compiler-owned-optional-dispatch"
  "option-contract-boundary")
 (learnedStyleSources
  "gerbil://gambit/gsc/tests/69-params/optional.scm"
  "gerbil://gambit/gsc/tests/69-params/optionalkeyrest.scm"
  "gerbil://std/markup/sxml/oleg/define-opt.scm")
 (antiAiScaffoldIntent
  .
  "reject generated opts bags and repeated local key spelling when the function signature can express option shape directly")
 (scenarioQualityAxes
  "keyword-option-boundary"
  "inline-alist-lookup-drift"
  "anti-ai-option-bag-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-input-expected-comparison")
 (tags "style" "keyword" "optional" "anti-scaffold"))
