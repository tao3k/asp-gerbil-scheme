((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "package-build-framework-overreach keeps build API policy scenario checks in a small fixture budget while protecting upstream std/make and clan/building ownership")
 (sampleCount . 20)
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
  )
 (tags "build" "policy" "package-build" "std-make" "clan-building" "harness-api"))
