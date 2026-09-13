((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "Twenty-sample p95 admission targets 150ms with equal regression headroom while keeping observations exclusively in live receipts and retired P043 silent.")
 (sampleCount . 20)
 (purpose . "P043 retirement regression keeps representation choice outside naming-based policy")
 (feature . "poo-generated-receipt-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-043")
 (optimizationFocus . "no naming-based representation policy for generated receipt state")
 (inputShape . "agent-generated receipt builder using object<-alist for internal runtime state")
 (expectedOutcome . "object<-alist remains a valid semantic POO constructor in receipt-named owners")
 (generatedRuntimeBoundary . #t)
 (hotPathExemption . "generated-receipt-boundary")
 (hotPathEvidence
  "generated-runtime-receipt"
  "defstruct-internal-state"
  "bounded-alist-boundary"
  "adapter-boundary"
  "single-digit-ms-target"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not infer representation defects from receipt, manifest, snapshot, handoff, or diagnostic names")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "receipt" "object-constructor" "policy-retirement" "performance"))
