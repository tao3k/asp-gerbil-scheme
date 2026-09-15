((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-loop-validation target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
(sampleCount . 20)
 (purpose . "R031 validation repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-validation")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-031")
 (optimizationFocus . "loop-local validation")
 (inputShape . "manual loop repeatedly validating the same POO shape")
 (expectedOutcome . "keep the stable profile as native .o and validate once outside the loop")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the typed profile shape")
 (optimizerVisibility
  .
  "stable POO validation is performed once at the checked boundary, leaving the loop with a validated native object and scalar state")
 (expectedQualitySignals
  "single-validation-boundary"
  "validated-native-object"
  "scalar-loop-state"
  "no-loop-local-validation")
 (learnedStyleSources
  "gerbil://mop.ss#item/def/MonomorphicObject"
  "gerbil://mop.ss#item/def/validate"
  "gerbil://gerbil/core/contract.ss#using-class-interface-boundary")
 (hotPathExemption . "poo-validation-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "optimizer-visible-poo-hot-path"
  "validation"
  "single-boundary-check"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not repeat stable validation inside a measured loop; keep one validation boundary before scalar/object work")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "loop" "validation"))
