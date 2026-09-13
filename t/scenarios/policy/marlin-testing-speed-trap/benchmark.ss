((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "Marlin-like downstream build.ss must keep selected tests incremental instead of expanding one user action into gxtest-main plus a broad policy scope")
 (sampleCount . 20)
 (purpose . "Capture the Marlin downstream speed trap as an upstream-selection boundary")
 (feature . "marlin-testing-speed-trap")
 (rule . "GERBIL-SCHEME-AGENT-TESTING-MARLIN-SPEED-TRAP-001")
 (optimizationFocus
  .
  "keep explicit file selection in gerbil test and map only POO instrumentation profiles")
 (inputShape
  .
  "Marlin-like build.ss keeps long gxtest file lists, appends source policy files, and routes test through one gxtest-main entrypoint")
 (expectedOutcome
  .
  "invoke explicit files through gerbil test and bind different memory profiles without a private scope collector")
 (measurementPhases
  "collect-before"
  "policy-before"
  "collect-after"
  "policy-after"
  "profile-compose"
  "upstream-selection"
  "assert-time-gate"
  )
 (tags "testing"
       "profile-extension"
       "marlin"
       "downstream"
       "build.ss"
       "speed"
       "scenario"
       "performance"
       "hot"))
