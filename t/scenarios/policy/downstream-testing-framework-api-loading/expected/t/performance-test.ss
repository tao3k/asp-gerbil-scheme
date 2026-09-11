;;; -*- Gerbil -*-
;;; Expected repair: downstream gxtest consumes Testing Framework body timing.

(import :std/test
        (only-in :asp-gerbil-scheme/build-api
                 benchmark-receipt-pass?
                 testing-receipt-detail
                 testing-receipt-ok?
                 testing-benchmark-run/result))

(export downstream-performance-test)

(def +downstream-performance-fixture+
  '((max_total . 100ms)
    (target_total . 25ms)
    (regression_budget . 75ms)
    (expected_over_input_budget . 75ms)
    (targetRationale . "expected repair delegates benchmark body timing to Testing Framework")
    (sampleCount . 20)
    (feature . "downstream-testing-framework-api-loading")
    (rule . "GERBIL-SCHEME-AGENT-TESTING-DOWNSTREAM-BENCHMARK-HELPER-001")
    (optimizationFocus . "expose downstream benchmark body timing through Testing Framework receipts")
    (inputShape . "gxtest performance case asks the framework for raw receipt, result, and body phase")
    (expectedOutcome . "route the benchmark through testing-benchmark-run/result")
    (measurementPhases "benchmark-body")
    (tags "testing" "framework" "downstream" "benchmark-body" "hot")))

(def (downstream-performance-work)
  1)

(def downstream-performance-test
  (test-suite "downstream performance framework benchmark helper"
    (test-case "exposes benchmark body phase receipt"
      (let-values (((receipt result body-phase)
                    (testing-benchmark-run/result
                     "downstream-performance"
                     +downstream-performance-fixture+
                     downstream-performance-work
                     '((case . downstream-performance)))))
        (check result => 1)
        (check (benchmark-receipt-pass? receipt) => #t)
        (check (testing-receipt-detail body-phase 'phase) => 'benchmark-body)
        (check (testing-receipt-ok? body-phase) => #t)))))
