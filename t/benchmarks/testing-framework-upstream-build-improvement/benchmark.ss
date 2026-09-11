((benchmarkKind . scenario-e2e)
 (max_total . 100ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 5ms)
 (targetRationale . "testing framework user-layer scope selection must stay in hot path range")
 (sampleCount . 20)
 (purpose . "upstream Gerbil build/test user-layer improvement gate")
 (feature . "testing-framework-upstream-build-improvement")
 (rule . "GERBIL-SCHEME-TESTING-UPSTREAM-BUILD-IMPROVEMENT")
 (optimizationFocus . "keep upstream std/make/gxtest ownership while preserving incremental scope, receipts, and benchmark gates")
 (inputShape . "multi-suite testing project with explicit gxtest file, manifest root, and policy scenario id")
 (expectedOutcome . "declare a thin build.ss testing project and pass upstream-selected scope into the framework without widening")
 (measurementPhases
  "collect-before"
  "policy-before"
  "collect-after"
  "policy-after"
  "batch-split"
  "scenario-root-projection"
  "assert-time-gate"
  )
 (tags "testing" "framework" "scenario" "performance" "hot"))
