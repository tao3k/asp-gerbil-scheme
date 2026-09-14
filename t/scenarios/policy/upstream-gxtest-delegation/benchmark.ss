((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "policy selection stays subsecond; native process timing remains owned by native-batch-contract.ss")
 (sampleCount . 20)
 (purpose . "prove upstream Gerbil owns selection while ASP only declares POO instrumentation")
 (feature . "upstream-gxtest-delegation")
 (rule . "GERBIL-SCHEME-AGENT-TESTING-UPSTREAM-GXTEST-DELEGATION-001")
 (optimizationFocus
  .
  "keep policy analysis separate from native multi-file process execution")
 (inputShape
  .
  "scenario input manually selects files instead of using gerbil test")
 (expectedOutcome
  .
  "select the native batch delegation policy without charging process startup to the policy benchmark")
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
