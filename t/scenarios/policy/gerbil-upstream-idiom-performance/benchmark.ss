((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The gerbil-upstream-idiom-performance target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 upstream idiom scenario connects gerbil:// match, compiler eq-hash indexing, and cut-style helper plumbing to agent-facing policy repair")
 (feature . "gerbil-upstream-idiom-performance")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "basic Scheme route scaffolding to match dispatch, one eq-hash index, and cut-specialized traversal")
 (inputShape
  .
  "agent-authored owner repeats assq route lookup, named-let traversal, reverse accumulator, and branch-local defaulting")
 (expectedOutcome
  .
  "event shape helpers, core match dispatch, route-index make-hash-table-eq precomputation, cut-specialized map traversal, and filter-map label projection")
 (expectedReferencePattern . "gerbil-upstream-idiom-performance")
 (expectedReferenceExamples
  "gerbil://gerbil/core/match.ss#match/match*"
  "gerbil://gerbil/core/match.ss#with/with*"
  "gerbil://gerbil/compiler/optimize-spec.ss#make-hash-table-eq-method-calls"
  "gerbil://gerbil/compiler/optimize-spec.ss#cut-compile-e"
  "gerbil://gerbil/compiler/optimize-top.ss#optimizer-cache-facts")
 (expectedQualitySignals
  "gerbil-upstream-idiom-boundary"
  "match-shape-dispatch"
  "with-destructuring-boundary"
  "eq-hash-index-hot-path"
  "cut-helper-plumbing"
  "hash-index-outside-traversal")
 (learnedStyleSources "gerbil://" "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "reject broad agent-authored Scheme scaffolding when Gerbil core/compiler idioms expose data shape and move repeated symbolic lookup out of hot traversal")
 (scenarioQualityAxes
  "gerbil-upstream-idiom-boundary"
  "match-shape-dispatch"
  "eq-hash-index-hot-path"
  "cut-helper-plumbing"
  "anti-ai-scaffold")
 (hotPathExemption . "symbol-route-index")
 (hotPathEvidence
  "repeated-assq-route-lookup"
  "symbol-key-route-table"
  "single-index-build-before-map"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "build the eq hash route index once before traversal; do not reintroduce route-table scans inside route-event without a benchmark proving it is no slower")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style"
       "gerbil-upstream"
       "match"
       "with"
       "eq-hash"
       "cut"
       "hot-path"
       "subsecond"))
