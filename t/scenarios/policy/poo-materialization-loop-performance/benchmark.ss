((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-loop-materialization target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
(sampleCount . 20)
 (purpose . "R029 materialization repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-materialization")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-029")
 (optimizationFocus . "loop-local materialization")
 (inputShape . "manual loop repeatedly materializing POO object data through .alist/sort, .all-slots, .all-slots/sort, hash<-object, and force-object")
 (expectedOutcome . "keep the stable profile as native .o, materialize each required boundary snapshot once, and keep loop state scalar")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the profile/config source shape")
 (hotPathExemption . "poo-materialization-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "object-materialization"
  ".alist/sort"
  ".all-slots"
  ".all-slots/sort"
  "hash<-object"
  "force-object"
  "single-boundary-snapshot"
  "optimizer-visible-poo-hot-path"
  "benchmark-contract")
 (optimizerVisibility
  .
  "full-object materialization stays as one named boundary snapshot and the loop consumes precomputed list/hash/scalar state")
 (expectedQualitySignals
  "single-boundary-snapshot"
  "scalar-loop-state"
  "no-loop-local-materialization"
  "native-.o-source-shape")
 (learnedStyleSources
  "gerbil://object.ss#item/def/.all-slots"
  "gerbil://object.ss#item/def/hash<-object"
  "gerbil://object.ss#item/def/force-object")
 (styleRewriteBoundary
  .
  "do not introduce repeated materialization inside a measured loop; keep one boundary snapshot")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "loop" "materialization"))
