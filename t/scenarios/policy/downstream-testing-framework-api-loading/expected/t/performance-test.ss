;;; -*- Gerbil -*-
;;; Expected repair: downstream gxtest consumes Testing Framework body timing.

(import :std/test
        (only-in :asp-gerbil-scheme/src/benchmark/gate
                 benchmark-receipt-pass?)
        (only-in :asp-gerbil-scheme/src/testing/model
                 testing-receipt-detail
                 testing-receipt-ok?)
        (only-in :asp-gerbil-scheme/src/testing/performance
                 testing-benchmark-run/result))

(export downstream-performance-test)

(def +downstream-performance-fixture+
  '((max_total . 100ms)
    (observed_total . 1ms)
    (target_total . 25ms)
    (regression_budget . 75ms)
    (observedTimings ((name . benchmark-body) (durationMs . 1)))
    (targetRationale . "expected repair delegates benchmark body timing to Testing Framework")
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
