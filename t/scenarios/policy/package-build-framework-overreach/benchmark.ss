((max_total . 25ms)
 (observed_total . 4ms)
 (target_total . 15ms)
 (regression_budget . 21ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "package-build-framework-overreach keeps build API policy scenario checks in a small fixture budget while protecting upstream std/make and clan/building ownership")
 (maxCollectMs . 10)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 5)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R020 package build scenario catches agent-written local phase/cache/stamp and worker queue ownership layered on top of the native Gerbil build surface")
 (feature . "package-build-framework-overreach")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-020")
 (optimizationFocus . "keep std/make and clan/building as build owners; expose acceleration and receipts as harness APIs")
 (inputShape . "build.ss imports std/make and clan/building, then defines local cache freshness, stamp writing, phase receipt control, and worker queue dispatch")
 (expectedOutcome . "delete local phase/cache/stamp/worker ownership, keep the native build call path, and use a thin asp-gerbil-scheme API declaration for project coverage")
 (misuseGuard . "do not move build-system scheduling, dependency graph, worker queue, or phase ownership into downstream build.ss")
 (expectedReferencePattern . "package-build-framework-overreach")
 (expectedReferenceExamples
  "gerbil://std/make#make"
  "gerbil://clan/building#all-gerbil-modules"
  "asp-gerbil-scheme://build-api/source-coverage#asp-gerbil-scheme-source-coverage")
 (expectedQualitySignals
  "native-build-surface"
  "local-build-state-owner"
  "thin-harness-build-api"
  "upstream-build-system-boundary")
 (learnedStyleSources "gerbil://" "asp-gerbil-scheme")
 (antiAiScaffoldIntent
  .
  "reject agent scaffolding that recreates build phase state locally after already choosing the Gerbil build framework")
 (scenarioQualityAxes
  "package-build"
  "build-api-boundary"
  "build-worker-boundary"
  "upstream-build-system"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "build" "policy" "package-build" "std-make" "clan-building" "harness-api"))
