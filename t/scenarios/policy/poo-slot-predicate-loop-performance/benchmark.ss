((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-loop-slot-predicate target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
(sampleCount . 20)
 (purpose . "R037 slot predicate repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-slot-predicate")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-037")
 (optimizationFocus . "loop-local slot predicate")
 (inputShape . "manual loop repeatedly checking stable slot predicates")
 (expectedOutcome
  .
  "keep the stable profile as native .o and hoist predicate result or predicate closure outside the loop")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the profile/config source shape")
 (hotPathExemption . "poo-slot-predicate-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "slot-predicate"
  "hoisted-predicate-boundary"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not recompute stable slot predicate closures inside a measured loop")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "loop" "predicate"))
