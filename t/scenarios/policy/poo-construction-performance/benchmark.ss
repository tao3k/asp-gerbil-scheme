((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-native-object-shape-reuse target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R027 native POO construction guard keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-native-object-shape-reuse")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-027")
 (optimizationFocus . "native large .o object shape reuse")
 (inputShape . "large native POO profile projection shape with one dynamic overlay")
 (expectedOutcome . "preserve native .o shape, compose a small boundary overlay, and keep loop state scalar")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the optimized POO declaration shape")
 (hotPathExemption . "native-poo-declaration")
 (hotPathEvidence
  "native-poo-primary"
  "slot-spec-count"
  "native-.o-construction"
  "stable-shape-reuse"
  "boundary-overlay"
  "loop-slot-capture"
  "scalar-loop-state"
  "boundary-declaration"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not rewrite native .o profile/config declarations to object<-alist; optimize by naming stable native shapes, composing only small boundary overlays, and keeping loops in scalar state")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "construction" "native-object-shape-reuse"))
