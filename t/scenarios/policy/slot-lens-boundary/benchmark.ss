((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The slot-lens-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 slot lens scenario keeps learned descriptor/lens repair within the scenario-owned timing gate")
 (feature . "slot-lens-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "local slot descriptor and lens boundary")
 (inputShape
  .
  "single exported function mixes Slot, Lens, Get, Set, Modify, and Validate responsibilities")
 (expectedOutcome
  .
  "local slot/lens helpers split get, set, modify, and validation without adding gerbil-poo or gerbil-utils dependencies")
 (expectedReferencePattern . "slot-lens-boundary")
 (expectedReferenceExamples
  "gerbil-poo/mop.ss#slot-checker"
  "gerbil-poo/mop.ss#Lens.modify"
  "gerbil-poo/mop.ss#slot-lens")
 (expectedQualitySignals
  "slot-descriptor-boundary"
  "lens-get-set-modify-boundary"
  "local-lens-helper")
 (learnedStyleSources "gerbil-poo")
 (antiAiScaffoldIntent
  .
  "reject repeated slot access scaffolding when contract categories prove a lens boundary")
 (scenarioQualityAxes "slot-lens-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "slot" "lens" "descriptor-boundary"))
