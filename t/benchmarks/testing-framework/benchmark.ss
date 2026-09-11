((benchmarkKind . scenario-e2e)
 (max_total . 100ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 5ms)
 (targetRationale . "testing framework user-interface checks must stay in hot policy range")
 (sampleCount . 20)
 (purpose . "framework-level testing API gate")
 (feature . "poo-shaped-testing-framework")
 (rule . "GERBIL-SCHEME-TESTING-FRAMEWORK")
 (optimizationFocus . "user-friendly gxtest expansion and receipt gate")
 (inputShape . "POO-shaped testing project with manifest root and batch runner")
 (expectedOutcome . "declare testing project once; let framework expand and receipt batches")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "batch-split"
  "scenario-root-projection"
  "assert-time-gate"
  )
 (tags "testing" "framework" "poo" "gxtest"))
