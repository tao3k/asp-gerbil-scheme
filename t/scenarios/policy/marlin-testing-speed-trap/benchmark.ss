((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "Marlin-like downstream build.ss must keep selected tests incremental instead of expanding one user action into gxtest-main plus a broad policy scope")
 (sampleCount . 20)
 (purpose . "Capture the Marlin downstream build speed trap as a testing framework optimization metric")
 (feature . "marlin-testing-speed-trap")
 (rule . "GERBIL-SCHEME-AGENT-TESTING-MARLIN-SPEED-TRAP-001")
 (optimizationFocus
  .
  "replace agent-written all-test plus appended policy-scope dispatch with thin testing-framework scope selection")
 (inputShape
  .
  "Marlin-like build.ss keeps long gxtest file lists, appends source policy files, and routes test through one gxtest-main entrypoint")
 (expectedOutcome
  .
  "declare multiple gxtest suites and policy scenarios through the harness testing API so explicit files, manifest roots, and scenario ids stay separate")
 (measurementPhases
  "collect-before"
  "policy-before"
  "collect-after"
  "policy-after"
  "select-explicit-file"
  "expand-manifest-root"
  "select-policy-scenario"
  "assert-time-gate"
  )
 (tags "testing"
       "framework"
       "marlin"
       "downstream"
       "build.ss"
       "speed"
       "scenario"
       "performance"
       "hot"))
