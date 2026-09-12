((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "downstream build.ss API loading must stay in the user-layer hot path and must not widen into a full project policy pass")
 (sampleCount . 20)
 (purpose . "downstream code loads only POO testing profiles through the package-qualified API")
 (feature . "downstream-testing-framework-api-loading")
 (rule . "GERBIL-SCHEME-AGENT-TESTING-DOWNSTREAM-API-LOADING-001")
 (optimizationFocus
  .
  "keep gerbil test and clan/testing authoritative while composing bounded POO instrumentation")
 (inputShape
  .
  "downstream build.ss declares gxtest, performance, and policy scenario suites through the stable :asp-gerbil-scheme/build-api facade; the input performance test builds benchmark timing directly")
 (expectedOutcome
  .
  "map optional profiles to explicit upstream test paths and keep benchmark timing as a POO observation receipt")
 (measurementPhases
  "collect-before"
  "policy-before"
  "collect-after"
  "policy-after"
  "load-api"
  "profile-compose"
  "upstream-boundary"
  "benchmark-body-helper"
  "assert-time-gate"
  )
 (tags "testing"
       "profile-extension"
       "downstream"
       "build.ss"
       "api-loading"
       "scenario"
       "performance"
       "hot"))
