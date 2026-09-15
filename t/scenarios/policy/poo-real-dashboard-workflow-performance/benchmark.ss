((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The poo-real-dashboard-workflow target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "real dashboard workflow proves POO API usage can stay boundary-oriented and performance-gated")
 (feature . "poo-real-dashboard-workflow")
   (rule . "GERBIL-SCHEME-AGENT-POO-DASHBOARD-WORKFLOW-037")
 (optimizationFocus . "multi-api POO workflow")
 (inputShape
  .
  "agent-style loop mixes object construction, validation, projection, predicates, clone overrides, composition, debug tracing, and materialization")
 (expectedOutcome
  .
  "keep dashboard config as native .o, use adapters only at external ingestion/materialization boundaries, project events to scalar deltas first, and keep the hot scoring loop scalar-only")
 (nativePooPrimary . #t)
 (adapterBoundary . "external event alists may be adapted at ingestion; profile/config/update paths stay native .o/.cc")
 (hotPathExemption . "poo-boundary-api-workflow")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "poo-api-boundary"
  "scalar-state-accumulation"
  "multi-rule-performance"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not move POO object construction, validation, tracing, materialization, or multi-slot predicates back into the loop without a benchmark proving it is no slower")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "workflow" "dashboard" "performance"))
