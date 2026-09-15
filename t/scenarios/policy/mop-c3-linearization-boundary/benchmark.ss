((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "mop-c3-linearization-boundary is a small source-mined scenario from gerbil/runtime/c3.ss and gerbil/runtime/interface.ss; target keeps C3/MOP guidance in the low millisecond policy lane")
 (sampleCount . 20)
 (purpose . "R013 MOP/C3 linearization scenario routes ad hoc superclass ordering toward local precedence descriptors and merge helpers")
 (feature . "mop-c3-linearization-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "C3 precedence-list boundary and MOP descriptor helpers")
 (inputShape
  .
  "single exported owner reconstructs precedence order while mixing superclass shape checks, duplicate filtering, and merge policy")
 (expectedOutcome
  .
  "introduce local precedence node descriptors, split tail merge/select helpers, and keep the exported linearizer as a small orchestration boundary")
 (expectedReferencePattern . "gerbil-runtime-c3-linearization-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/runtime/c3.ss#c4-linearize"
  "gerbil://gerbil/runtime/c3.ss#merge-sis!"
  "gerbil://gerbil/runtime/c3.ss#precedence-list"
  "gerbil://gerbil/runtime/interface.ss#interface-descriptor")
 (expectedQualitySignals
  "c3-precedence-boundary"
  "mop-descriptor-boundary"
  "linearization-tail-merge-helper"
  "single-export-orchestration")
 (learnedStyleSources
  "gerbil://"
  "harness-self-apply"
  "gerbil://gerbil/runtime/c3.ss#c4-linearize"
  "gerbil://gerbil/runtime/c3.ss#merge-sis!"
  "gerbil://gerbil/runtime/interface.ss#interface-descriptor")
 (antiAiScaffoldIntent
  .
  "teach agents to isolate class precedence and MOP descriptor reasoning instead of writing broad list-mutation superclass walkers")
 (scenarioQualityAxes
  "mop-c3-linearization-boundary"
  "gerbil-runtime-mop"
  "c3-precedence-boundary"
  "mop-descriptor-boundary"
  "c3-precedence-list"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style"
       "gerbil-native"
       "mop"
       "c3"
       "linearization"
       "precedence"
       "descriptor-boundary"))
