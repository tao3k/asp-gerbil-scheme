((benchmarkKind . scenario-e2e)
 (max_total . 100ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 5ms)
 (targetRationale . "POO scenario contract checks use the shared benchmark.ss framework gate")
 (sampleCount . 20)
 (purpose . "framework-level benchmark.ss gate for POO scenario contract checks")
 (feature . "poo-scenario-contract-framework")
 (rule . "GERBIL-SCHEME-BENCHMARK-FRAMEWORK")
 (optimizationFocus . "benchmark.ss-driven gxtest framework gate")
 (inputShape . "POO scenario benchmark fixtures plus expected source trees")
 (expectedOutcome . "reuse benchmark/framework APIs instead of ad hoc timing assertions")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "benchmark" "framework" "poo" "scenario-contract"))
