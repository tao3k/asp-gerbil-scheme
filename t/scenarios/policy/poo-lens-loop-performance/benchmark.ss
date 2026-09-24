((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-loop-lens target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
(sampleCount . 20)
 (purpose . "R032 lens modify repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-lens")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-032")
 (optimizationFocus . "loop-local lens modification")
 (inputShape . "manual loop repeatedly applying lens-style POO updates")
 (expectedOutcome
  .
  "keep the stable profile as native .o, accumulate scalar lens target state, and apply one final native update")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o/.cc remains the optimized POO shape")
 (optimizerVisibility
  .
  "lens-style object updates are reduced to scalar target accumulation and one final native update boundary, keeping repeated slot mutation out of the loop")
 (expectedQualitySignals
  "native-.o-source-shape"
  "single-lens-update-boundary"
  "scalar-loop-state"
  "no-loop-local-lens-update")
 (learnedStyleSources
  "gerbil://mop.ss#item/def/slot-lens"
  "gerbil://mop.ss#item/def/Lens"
  "gerbil://object.ss#item/def/.cc")
 (hotPathExemption . "poo-lens-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "optimizer-visible-poo-hot-path"
  "lens-update"
  "scalar-state-accumulation"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not replace measured scalar lens accumulation with repeated object lens updates")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "loop" "lens"))
