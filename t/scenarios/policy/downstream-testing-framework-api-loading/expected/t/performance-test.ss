;;; -*- Gerbil -*-
;;; Expected repair: downstream gxtest consumes a POO benchmark observation.

(import :std/test
        (only-in :clan/poo/object .ref object?)
        (only-in :asp-gerbil-scheme/build-api
                 benchmark-receipt-pass?
                 testing-benchmark-run/result))

(export downstream-performance-test)

(def +downstream-performance-fixture+
  '((benchmarkKind . scenario-e2e)
    (max_total . 100ms)
    (target_total . 25ms)
    (regression_budget . 75ms)
    (expected_over_input_budget . 75ms)
    (targetRationale . "expected repair projects benchmark body timing as a POO receipt")
    (sampleCount . 20)
    (feature . "downstream-testing-framework-api-loading")
    (rule . "GERBIL-SCHEME-AGENT-TESTING-DOWNSTREAM-BENCHMARK-HELPER-001")
    (optimizationFocus . "expose downstream benchmark body timing through a POO profile receipt")
    (inputShape . "gxtest performance case asks the extension for raw receipt, result, and body phase")
    (expectedOutcome . "route the benchmark through testing-benchmark-run/result")
    (measurementPhases "benchmark-body")
    (tags "testing" "profile-extension" "downstream" "benchmark-body" "hot")))

(def (downstream-performance-work)
  1)

(def downstream-performance-test
  (test-suite "downstream performance POO benchmark extension"
    (test-case "exposes benchmark body phase receipt"
      (let-values (((receipt result body-phase)
                    (testing-benchmark-run/result
                     "downstream-performance"
                     +downstream-performance-fixture+
                     downstream-performance-work
                     '((case . downstream-performance)))))
        (check result => 1)
        (check (benchmark-receipt-pass? receipt) => #t)
        (check (object? body-phase) => #t)
        (check (.ref body-phase 'status) => 'ok)
        (check (assq 'phase (.ref body-phase 'details))
               => '(phase . benchmark-body))))))
