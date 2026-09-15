((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The gerbil-iteration-macro-loop-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 teaches agents to use Gerbil iteration macros when the loop contract is static and can be generated hygienically")
 (feature . "gerbil-iteration-macro-loop-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "macro-generated iteration with binding contracts and filter clauses")
 (inputShape
  .
  "agent-generated loops manually thread accumulators, predicates, and pattern checks through verbose generic recursion")
 (expectedOutcome
  .
  "use Gerbil for/iteration macro forms when bindings, filters, contracts, or match patterns are static enough to generate a tight loop")
 (expectedReferencePattern . "gerbil-iteration-macro-contract-boundary")
 (expectedReferenceExamples
  "gerbil://std/iter/macros.ss#for"
  "gerbil://std/iter/macros.ss#for-binding?"
  "gerbil://std/iter/macros.ss#make-lambda-body")
 (expectedQualitySignals
  "macro-generated-loop"
  "binding-contract-preserved"
  "filter-clause-preserved"
  "manual-recursion-eliminated")
 (learnedStyleSources
  "gerbil://std/iter/macros.ss"
  "gerbil://gerbil/core/match.ss")
 (antiAiScaffoldIntent
  .
  "reject verbose hand-rolled loop scaffolding when Gerbil iteration macros can express the binding, filter, and match contract directly")
 (scenarioQualityAxes
  "gerbil-iteration-macros"
  "macro-generated-hot-loop"
  "contract-aware-binding"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "gerbil-native" "macro" "iteration" "for" "hot-loop"))
