((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-loop-object-construction target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
(sampleCount . 20)
 (purpose . "R033 object construction repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-object-construction")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-033")
 (optimizationFocus . "loop-local object construction")
 (inputShape . "manual loop repeatedly constructing POO objects through object<-hash, object<-fun, and make-object")
 (expectedOutcome . "use native .o for the stable profile shape, collapse repeated adapter construction into scalar loop state, and build one final native object at the boundary")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the optimized POO shape")
 (hotPathExemption . "object-construction-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "object-construction"
  "object<-hash"
  "object<-fun"
  "make-object"
  "single-boundary-object"
  "optimizer-visible-poo-hot-path"
  "benchmark-contract")
 (optimizerVisibility
  .
  "native .o names the stable shape once while the loop carries scalar state, so repeated adapter constructors do not obscure the hot path")
 (expectedQualitySignals
  "native-.o-declaration"
  "single-boundary-object"
  "scalar-loop-state"
  "no-loop-local-constructor")
 (learnedStyleSources
  "gerbil://object.ss#item/def/object<-fun"
  "gerbil://object.ss#item/def/object/init"
  "gerbil://gerbil/compiler/optimize-call.ss#apply-optimize-call")
 (styleRewriteBoundary
  .
  "do not construct stable POO objects inside a measured loop when scalar/list/hash accumulation can preserve one final boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "loop" "construction"))
