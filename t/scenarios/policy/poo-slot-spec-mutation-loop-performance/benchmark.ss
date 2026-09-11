((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-loop-slot-spec-mutation target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
(sampleCount . 20)
 (purpose . "R036 slot spec mutation repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-slot-spec-mutation")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-036")
 (optimizationFocus . "loop-local slot spec mutation")
 (inputShape . "manual loop repeatedly mutating POO slot definitions")
 (expectedOutcome . "construct the mutable profile with native .o, define slots once, and mutate values intentionally")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the mutable POO source shape")
 (hotPathExemption . "slot-spec-mutation-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "slot-spec-mutation"
  "value-mutation-boundary"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not perform structural slot-spec mutation inside a measured loop; keep structure setup outside and value mutation explicit")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "loop" "slot-spec"))
