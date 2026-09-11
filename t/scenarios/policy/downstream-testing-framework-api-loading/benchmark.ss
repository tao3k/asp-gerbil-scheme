((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "downstream build.ss API loading must stay in the user-layer hot path and must not widen into a full project policy pass")
 (sampleCount . 20)
 (purpose . "downstream build.ss loads the harness testing framework API through package-qualified imports")
 (feature . "downstream-testing-framework-api-loading")
 (rule . "GERBIL-SCHEME-AGENT-TESTING-DOWNSTREAM-API-LOADING-001")
 (optimizationFocus
  .
  "keep downstream build.ss as a thin user-facing layer over std/make/gxtest while preserving incremental framework scope selection and framework-owned benchmark body receipts")
 (inputShape
  .
  "downstream build.ss declares gxtest, performance, and policy scenario suites through the stable :asp-gerbil-scheme/build-api facade; the input performance test builds benchmark timing directly")
 (expectedOutcome
  .
  "use the package-qualified testing API in build.ss, pass the upstream-selected scope through unchanged, and route direct performance tests through testing-benchmark-run/result so benchmark-body timing is a framework receipt")
 (measurementPhases
  "collect-before"
  "policy-before"
  "collect-after"
  "policy-after"
  "load-api"
  "select-file"
  "expand-manifest"
  "benchmark-body-helper"
  "select-scenario"
  "assert-time-gate"
  )
 (tags "testing"
       "framework"
       "downstream"
       "build.ss"
       "api-loading"
       "scenario"
       "performance"
       "hot"))
