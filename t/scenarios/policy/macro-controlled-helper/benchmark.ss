((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The macro-helper-runtime-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R011 controlled macro helper scenario keeps macro runtime-source policy within the timing gate")
 (feature . "macro-helper-runtime-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-011")
 (optimizationFocus . "controlled macro helper boundary")
 (inputShape . "macro transformer without local parser helper")
 (expectedOutcome . "syntax-case transformer with local syntax error helper")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "macro" "runtime-boundary"))
