((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "gerbil-interface-contract-boundary keeps native using/interface contract repair under the scenario-owned timing gate")
 (sampleCount . 20)
 (purpose . "R013 native Gerbil interface/contract scenario catches one-owner slot contract scaffolding and repairs it with local typed descriptor helpers")
 (feature . "gerbil-interface-contract-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "Gerbil native using/interface contract boundary")
 (inputShape
  .
  "single exported owner collapses Interface, Contract, Slot, Get, Set, Modify, and Validate responsibilities")
 (expectedOutcome
  .
  "introduce a local typed descriptor and use Gerbil `using` slot access while keeping validation and mutation in separate helpers")
 (expectedReferencePattern . "gerbil-native-interface-contract-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/core/contract.ss#using-class-interface-boundary"
  "gerbil://gerbil/core/contract.ss#slot-contract-normalize"
  "gerbil://gerbil/compiler/optimize-call.ss#using-class-slot-access"
  "gerbil://gerbil/compiler/optimize-base.ss#class-method-table")
 (expectedQualitySignals
  "slot-lens-boundary"
  "gerbil-native-using-boundary"
  "typed-descriptor-slot-access"
  "contract-projection-boundary")
 (learnedStyleSources "gerbil://" "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "teach agents to use Gerbil typed object boundaries from parser-owned contract evidence instead of broad slot/update scaffolding")
 (scenarioQualityAxes
  "gerbil-interface-contract-boundary"
  "slot-lens-boundary"
  "gerbil-gambit-native-idiom"
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
       "using"
       "interface"
       "contract"
       "slot"
       "descriptor-boundary"))
