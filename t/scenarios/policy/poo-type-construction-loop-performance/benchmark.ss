((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-loop-type-construction target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
(sampleCount . 20)
 (purpose . "R034 type construction repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-type-construction")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-034")
 (optimizationFocus . "loop-local type construction")
 (inputShape
  .
  "manual loop repeatedly constructing stable POO/MOP type objects")
 (expectedOutcome . "hoist stable type object to a named binding")
 (hotPathExemption . "type-object-construction-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "type-object"
  "hoisted-type-binding"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not rebuild stable type objects inside a measured loop; keep named type bindings outside the loop")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "loop" "type"))
