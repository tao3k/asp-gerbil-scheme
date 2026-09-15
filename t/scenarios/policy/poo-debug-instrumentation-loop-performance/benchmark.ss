((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-loop-debug-instrumentation target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
(sampleCount . 20)
 (purpose . "R035 debug instrumentation repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-debug-instrumentation")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-035")
 (optimizationFocus . "loop-local debug instrumentation")
 (inputShape . "manual loop repeatedly wrapping trace-poo instrumentation")
 (expectedOutcome . "keep the stable profile as native .o and hoist trace-poo outside the loop")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the profile/config source shape")
 (hotPathExemption . "debug-instrumentation-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "debug-wrapper"
  "hoisted-setup-boundary"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not introduce repeated debug wrappers inside a measured loop; keep instrumentation at one setup boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "loop" "debug"))
