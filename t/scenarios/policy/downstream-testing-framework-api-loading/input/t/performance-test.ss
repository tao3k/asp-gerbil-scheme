;;; -*- Gerbil -*-
;;; Input anti-pattern: downstream gxtest builds benchmark timing directly.

(import :std/test
        (only-in :asp-gerbil-scheme/src/benchmark/gate
                 benchmark-receipt-pass?
                 benchmark-run/result))

(export downstream-performance-test)

(def +downstream-performance-fixture+
  '((max_total . 100ms)
    (observed_total . 1ms)
    (target_total . 25ms)
    (regression_budget . 75ms)
    (observedTimings ((name . benchmark-body) (durationMs . 1)))
    (targetRationale . "input demonstrates direct benchmark glue")
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
    (iterations . 1)
    (unit . "ms")
    (feature . "downstream-testing-framework-api-loading")
    (rule . "GERBIL-SCHEME-AGENT-TESTING-DOWNSTREAM-BENCHMARK-HELPER-001")
    (optimizationFocus . "detect downstream direct benchmark glue before it becomes user API")
    (inputShape . "gxtest performance case calls benchmark-run/result directly")
    (expectedOutcome . "route the benchmark through testing-benchmark-run/result")
    (measurementPhases "benchmark-body")
    (tags "testing" "framework" "downstream" "benchmark-body" "hot")))

(def (downstream-performance-work)
  1)

(def downstream-performance-test
  (test-suite "downstream performance direct benchmark input"
    (test-case "uses raw benchmark result"
      (let-values (((receipt result)
                    (benchmark-run/result
                     +downstream-performance-fixture+
                     downstream-performance-work)))
        (check result => 1)
        (check (benchmark-receipt-pass? receipt) => #t)))))
