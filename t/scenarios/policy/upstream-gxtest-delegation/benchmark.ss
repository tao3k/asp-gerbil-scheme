((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "upstream gxtest delegation must keep selection hot while preserving gxtest-owned suite and setup/cleanup discovery")
 (sampleCount . 20)
 (purpose . "prove upstream Gerbil owns selection while ASP only declares POO instrumentation")
 (feature . "upstream-gxtest-delegation")
 (rule . "GERBIL-SCHEME-AGENT-TESTING-UPSTREAM-GXTEST-DELEGATION-001")
 (optimizationFocus
  .
  "remove ASP selection and execution ownership while preserving per-test POO profile mapping")
 (inputShape
  .
  "scenario input manually selects files instead of using gerbil test")
 (expectedOutcome
  .
  "use gerbil test for selection and execution; bind optional instrumentation to the explicit test path")
 (measurementPhases
  "collect-before"
  "policy-before"
  "collect-after"
  "policy-after"
  "profile-compose"
  "upstream-boundary"
  "assert-time-gate"
  )
 (tags "testing"
       "profile-extension"
       "gxtest"
       "upstream-ownership"
       "setup-cleanup"
       "scenario"
       "performance"
       "hot"))
