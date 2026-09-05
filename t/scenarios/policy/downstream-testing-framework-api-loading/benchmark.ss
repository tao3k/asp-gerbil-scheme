((max_total . 76ms)
 (observed_total . 1ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 5ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "downstream build.ss API loading must stay in the user-layer hot path and must not widen into a full project policy pass")
 (maxCollectMs . 50)
 (observedCollectMs . 1)
 (maxParseMs . 50)
 (observedParseMs . 1)
 (maxFileMs . 50)
 (observedFileMs . 1)
 (maxPhaseMs . 50)
 (observedPhaseMs . 1)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 3)
 (unit . "ms")
 (purpose . "downstream build.ss loads the harness testing framework API through package-qualified imports")
 (feature . "downstream-testing-framework-api-loading")
 (rule . "GERBIL-SCHEME-AGENT-TESTING-DOWNSTREAM-API-LOADING-001")
 (optimizationFocus
  .
  "keep downstream build.ss as a thin user-facing layer over std/make/gxtest while preserving incremental framework scope selection and framework-owned benchmark body receipts")
 (inputShape
  .
  "downstream build.ss declares gxtest, performance, and policy scenario suites through the thin :asp-gerbil-scheme/src/testing/build API; the input performance test builds benchmark timing directly")
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
  "assert-memory-gate")
 (tags "testing"
       "framework"
       "downstream"
       "build.ss"
       "api-loading"
       "scenario"
       "performance"
       "hot"))
