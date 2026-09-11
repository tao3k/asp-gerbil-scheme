((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "upstream gxtest delegation must keep selection hot while preserving gxtest-owned suite and setup/cleanup discovery")
 (sampleCount . 20)
 (purpose . "prove the testing framework selects files and delegates gxtest semantics to the gxtest runner")
 (feature . "upstream-gxtest-delegation")
 (rule . "GERBIL-SCHEME-AGENT-TESTING-UPSTREAM-GXTEST-DELEGATION-001")
 (optimizationFocus
  .
  "keep selection and receipt construction in the framework while leaving suite export and setup/cleanup semantics to gxtest-compatible delegates")
 (inputShape
  .
  "scenario build.ss declares one gxtest manifest suite with files that export test-setup!, test-cleanup!, and *-test suites")
 (expectedOutcome
  .
  "use testing-select-project for scope selection, pass selected files to the gxtest delegate, and inspect gxtest exports through the runner")
 (measurementPhases
  "collect-before"
  "policy-before"
  "collect-after"
  "policy-after"
  "select-file"
  "delegate-contract"
  "delegate-discovery"
  "setup-cleanup-export-discovery"
  "assert-time-gate"
  )
 (tags "testing"
       "framework"
       "gxtest"
       "delegation"
       "setup-cleanup"
       "scenario"
       "performance"
       "hot"))
