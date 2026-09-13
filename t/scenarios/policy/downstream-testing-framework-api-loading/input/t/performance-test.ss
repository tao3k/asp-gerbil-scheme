;;; -*- Gerbil -*-
;;; Input anti-pattern: downstream gxtest builds benchmark timing directly.

(import :std/test
        (only-in :asp-gerbil-scheme/benchmark-api
                 benchmark-receipt-pass?
                 benchmark-run/result))

(export downstream-performance-test)

(def +downstream-performance-fixture+
  '((max_total . 100ms)
    (target_total . 25ms)
    (regression_budget . 75ms)
    (expected_over_input_budget . 75ms)
    (targetRationale . "input demonstrates direct benchmark glue")
    (sampleCount . 20)
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
