((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "real Marlin config-interface large-object repair targets 150ms p95 with an equal regression headroom; observations remain live receipt data")
 (sampleCount . 20)
 (purpose . "real Marlin config-interface large POO objects stay native, idiomatic, and performance-gated")
 (feature . "poo-marlin-config-interface-large-object")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-027")
 (optimizationFocus . "native .o config-interface declarations with .o match-pattern projection and compact spec destructuring")
 (inputShape
  .
  "Marlin config-interface profile projection descriptors built through adapter alists plus repeated .get governor projections")
 (expectedOutcome
  .
  "represent large POO declarations with native .o, use lambda-match over compact specs, map specs to descriptors, project repeated object reads with .o match patterns, and keep adapters at external boundaries only")
 (nativePooPrimary . #t)
 (adapterBoundary . "marlin-policy-object<-alist is only valid for external alist ingestion; stable config-interface declarations stay native .o")
 (hotPathExemption . "marlin-config-interface-large-native-poo-object")
 (hotPathEvidence
  "real-marlin-config-interface"
  "native-poo-primary"
  "large-object"
  "lambda-match-spec-destructuring"
  "higher-order-map"
  ".o-match-pattern-projection"
  "batch-slot-projection"
  "match-projection-destructuring"
  "optimizer-visible-poo-hot-path"
  "adapter-boundary"
  "single-digit-ms-target"
  "benchmark-contract")
 (optimizerVisibility
  .
  "compact native .o specs, lambda-match destructuring, and .o match projection keep the hot projection path lexically visible instead of hiding it behind adapter alists")
 (expectedQualitySignals
  "native-.o-declaration"
  "lambda-match-spec-destructuring"
  ".o-match-pattern-projection"
  "lexical-direct-projection")
 (learnedStyleSources
  "gerbil://gerbil/compiler/optimize-call.ss#%#call-unchecked"
  "gerbil://object.ss#item/def/with-slots"
  "gerbil://object.ss#item/def/.refs/slots")
 (styleRewriteBoundary
  .
  "do not replace native .o config-interface declarations with object<-alist/list/cons; optimize by naming compact specs, destructuring them with lambda-match, and using .o match patterns before building boundary metadata")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "poo" "marlin" "config-interface" "large-object" "lambda-match" "performance"))
