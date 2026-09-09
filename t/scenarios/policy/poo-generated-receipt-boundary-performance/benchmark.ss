((max_total . 18ms)
 (observed_total . 5ms)
 (target_total . 10ms)
 (regression_budget . 13ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "retired P043 must stay silent for semantic POO constructors regardless of receipt-like owner names")
 (maxCollectMs . 8)
 (observedCollectMs . 0)
 (maxParseMs . 10)
 (observedParseMs . 0)
 (maxFileMs . 4)
 (observedFileMs . 0)
 (maxPhaseMs . 5)
 (observedPhaseMs . 0)
 (maxRssMb . 256)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
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
  "assert-memory-gate")
 (tags "poo" "receipt" "object-constructor" "policy-retirement" "performance"))
