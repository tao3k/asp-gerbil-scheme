((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-loop-object-iteration target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
(sampleCount . 20)
 (purpose . "R029 object iteration repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-object-iteration")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-029")
 (optimizationFocus . "loop-local object iteration")
 (inputShape . "manual loop repeatedly iterating a POO object")
 (expectedOutcome . "keep the stable profile as native .o and iterate from one boundary snapshot or direct slot access")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the profile/config source shape")
 (hotPathExemption . "poo-object-iteration-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "object-iteration"
  "single-boundary-snapshot"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not introduce repeated object iteration snapshots inside a measured loop")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "loop" "iteration"))
