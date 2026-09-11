((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-loop-finite-field-type-construction target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
(sampleCount . 20)
 (purpose . "R034 finite-field type construction repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-finite-field-type-construction")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-034")
 (optimizationFocus . "loop-local finite-field type construction")
 (inputShape . "manual loop repeatedly constructing stable F_q type objects")
 (expectedOutcome . "hoist stable F_q type object to a named binding")
 (hotPathExemption . "numeric-type-construction-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "numeric-type-object"
  "hoisted-type-binding"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not rebuild finite-field numeric type objects inside a measured loop; keep stable type objects hoisted")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "loop" "type" "finite-field"))
