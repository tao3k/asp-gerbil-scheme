((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-loop-composition target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
(sampleCount . 20)
 (purpose . "R030 POO composition repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-composition")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-030")
 (optimizationFocus . "loop-local POO composition")
 (inputShape . "manual loop repeatedly composing POO objects")
 (expectedOutcome . "keep the stable profile as native .o, accumulate scalar state, and apply one final native .o overlay composition")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o/.mix remains the optimized POO shape")
 (optimizerVisibility
  .
  "loop-local composition is collapsed into scalar accumulation plus one final native .o/.mix composition boundary, preserving stable supers and direct loop state")
 (expectedQualitySignals
  "native-.o-source-shape"
  "single-composition-boundary"
  "scalar-loop-state"
  "no-loop-local-composition")
 (learnedStyleSources
  "gerbil://object.ss#item/def/.mix"
  "gerbil://object.ss#item/def/.extend"
  "gerbil://object.ss#item/def/object/init")
 (hotPathExemption . "poo-composition-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "optimizer-visible-poo-hot-path"
  "poo-composition"
  "single-boundary-object"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not rewrite measured loop-local composition into a generic pipeline without preserving the one-boundary object construction")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "loop" "composition"))
