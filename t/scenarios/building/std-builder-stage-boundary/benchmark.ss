((max_total . 300ms)
 (observed_total . 2ms)
 (target_total . 20ms)
 (regression_budget . 300ms)
 (observedTimings
  ((name . "collect-before") (durationMs . 1.469))
  ((name . "collect-after") (durationMs . 0))
  ((name . "policy-before") (durationMs . .5))
  ((name . "policy-after") (durationMs . 0)))
 (targetRationale
  . "The warm-path plan must avoid std/make entirely; 300ms is a hard ceiling for the reusable stage-plan control plane, not a claim about stale compilation speed.")
 (maxCollectMs . 12)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 8)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 2000)
 (unit . "ms")
 (purpose
  . "Standardize Building stage-plan measurement through the shared Testing Framework benchmark contract.")
 (feature . "building-std-builder-stage-boundary")
 (rule . "BUILDING-TESTING-INTEGRATION")
 (optimizationFocus . "warm request projection and skipped-stage planning")
 (inputShape
  . "A reusable BuildProfile with ordered BuildRequest stage specs and a current predicate.")
 (expectedOutcome
  . "Project ordered BuildStage values and emit skipped-stage evidence without invoking std/make on the warm path.")
 (nativePooPrimary . #f)
 (adapterBoundary
  . "Build API owns package receipt persistence and std/make execution; Testing measures pure BuildRequest projection only.")
 (expectedQualitySignals
  "shared-benchmark-contract"
  "zero-warm-path-std-make"
  "ordered-build-stage-plan"
  "structured-testing-receipt")
 (learnedStyleSources
  "std/make"
  "asp-gerbil-scheme/src/building"
  "asp-gerbil-scheme/src/build-api")
 (scenarioQualityAxes
  (stdMakeReuse
   (positive std/make make stage-spec srcdir prefix parallelize)
   (negative bespoke-compiler-loop raw-gxc-loadpath))
  (stageBoundary
   (positive build-stage std-builder asp-gerbil-scheme-package-api-stage-specs)
   (negative flat-directory-scan dependency-race))
  (performanceGate
   (positive skipStageMs runStageMs packageStagePlanMs)
   (negative clean-before-build repeated-directory-scan unmeasured-warm-path)))
 (regressionProfiles
  (skipStageIterations . 2000)
  (skipStageMs . 200)
  (runStageIterations . 500)
  (runStageMs . 300)
  (packageStagePlanIterations . 500)
  (packageStagePlanMs . 300)
  (maxStageCountDrift . 1))
 (buildingStageTimings
  (skipStageMs . 1.469)
  (runStageMs . .5)
  (packageStagePlanMs . .651))
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "building" "std-make" "testing-framework" "integration" "warm-path" "stage-plan"))
