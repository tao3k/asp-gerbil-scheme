((benchmarkKind . scenario-e2e)
 (max_total . 10s)
 (target_total . 3s)
 (regression_budget . 7s)
 (expected_over_input_budget . 3s)
 (targetRationale
  .
  "native multi-file clan/testing must beat four warmed per-file Gerbil processes while preserving suite discovery")
 (sampleCount . 20)
 (purpose . "prove upstream Gerbil owns selection while ASP only declares POO instrumentation")
 (feature . "upstream-gxtest-delegation")
 (rule . "GERBIL-SCHEME-AGENT-TESTING-UPSTREAM-GXTEST-DELEGATION-001")
 (optimizationFocus
  .
  "reuse bounded multi-file Gerbil/clan testing batches with host-capacity workers")
 (inputShape
  .
  "scenario input manually selects files instead of using gerbil test")
 (expectedOutcome
  .
  "execute ordinary tests in bounded concurrent batches instead of one process per file or one unbounded heap")
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
