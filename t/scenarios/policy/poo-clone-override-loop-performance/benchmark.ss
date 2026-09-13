((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-loop-clone-override target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
(sampleCount . 20)
 (purpose . "R028 clone override repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-clone-override")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-028")
 (optimizationFocus . "loop-local clone override")
 (inputShape . "manual loop repeatedly cloning POO state")
 (expectedOutcome . "keep the stable profile as native .o, accumulate scalar loop state, and apply one final native clone override")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o/.cc remains the optimized POO shape")
 (optimizerVisibility
  .
  "loop-local .cc is collapsed into scalar accumulation plus one final native .cc boundary, keeping the loop free of repeated object shape cloning")
 (expectedQualitySignals
  "native-.o-source-shape"
  "single-.cc-boundary"
  "scalar-loop-state"
  "no-loop-local-clone")
 (learnedStyleSources
  "gerbil://object.ss#item/def/.cc"
  "gerbil://object.ss#item/def/object/init"
  "gerbil://gerbil/compiler/optimize-call.ss#apply-optimize-call")
 (hotPathExemption . "poo-loop-state-mutation")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "optimizer-visible-poo-hot-path"
  "clone-override"
  "scalar-state-accumulation"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not replace measured scalar loop accumulation with higher-order composition unless a benchmark proves it is no slower")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "loop" "clone"))
