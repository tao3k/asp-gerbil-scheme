((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 20ms)
 (regression_budget . 280ms)
 (expected_over_input_budget . 280ms)
 (targetRationale
  . "The warm-path plan must avoid std/make entirely; 300ms is a hard ceiling for the reusable stage-plan control plane, not a claim about stale compilation speed.")
 (sampleCount . 20)
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
   (positive skipStage runStage packageStagePlan)
   (negative clean-before-build repeated-directory-scan unmeasured-warm-path)))
 (regressionProfiles
  (skipStageIterations . 2000)
  (skipStage . 200ms)
  (runStageIterations . 500)
  (runStage . 300ms)
  (packageStagePlanIterations . 500)
  (packageStagePlan . 300ms)
  (maxStageCountDrift . 1))
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "building" "std-make" "testing-framework" "integration" "warm-path" "stage-plan"))
