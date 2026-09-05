;;; -*- Gerbil -*-
;;; Higher-cost testing framework integration and benchmark contracts.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/framework
        :asp-gerbil-scheme/src/testing/build
        :asp-gerbil-scheme/src/testing/build-runner
        :asp-gerbil-scheme/src/testing/gxtest-smoke
        :asp-gerbil-scheme/src/benchmark/framework
        :policy/testing-framework-support
        :policy/testing-framework-integration-support)

(export testing-framework-integration-test)

(def testing-framework-integration-test
  (test-suite "gerbil scheme testing framework integration contracts"
    (test-case "gated gxtest suite reports benchmark phase once"
      (let* ((receipt
              (testing-run-project
               +testing-gated-project+
               (list (fixture-path "unit-tests.ss"))
               fake-run-files))
             (suite-receipt (car (testing-receipt-children receipt)))
             (phase-names (testing-test-phase-names suite-receipt)))
        (check (member 'expand-manifest phase-names) ? true)
        (check (member 'delegate-gxtest phase-names) ? true)
        (check (member 'benchmark-assert phase-names) ? true)))

    (test-case "gated scenario suite reports benchmark phase once"
      (let* ((receipt
              (testing-run-project
               +testing-gated-project+
               (list "poo-construction-performance")
               fake-run-files))
             (suite-receipt (car (testing-receipt-children receipt)))
             (phase-names (testing-test-phase-names suite-receipt))
             (delegate-phase
              (testing-test-phase suite-receipt 'delegate-policy)))
        (check (member 'delegate-policy phase-names) ? true)
        (check (member 'benchmark-assert phase-names) ? true)
        (check (testing-receipt-files delegate-phase)
               => (testing-receipt-files suite-receipt))))

    (test-case "default testing gate includes full self-apply policy"
      (let ((files (asp-gerbil-scheme-default-gxtest-smoke-files))
            (suite (asp-gerbil-scheme-default-gxtest-smoke-suite)))
        (check (member "t/self-apply-full-gate.ss" files) ? true)
        (check (testing-suite-files suite) => files)))

    (test-case "complex upstream build file scope does not widen"
      (let (runs [])
        (def (record-run files)
          (set! runs (cons files runs))
          0)
        (let* ((selected (fixture-path "alpha-test.ss"))
               (receipt
                (testing-run-project
                 +upstream-build-improvement-project+
                 (list selected)
                 record-run))
               (children (testing-receipt-children receipt))
               (suite-receipt (car children)))
          (check (testing-receipt-ok? receipt) => #t)
          (check (length children) => 1)
          (check (testing-object-ref suite-receipt 'suite)
                 => "unit")
          (check (testing-receipt-files suite-receipt)
                 => (list selected))
          (check (reverse runs)
                 => (list (list selected))))))

    (test-case "complex upstream build manifest root stays in its suite"
      (let (runs [])
        (def (record-run files)
          (set! runs (cons files runs))
          0)
        (let* ((root (fixture-path "integration-tests.ss"))
               (gamma (fixture-path "gamma-test.ss"))
               (delta (fixture-path "delta-test.ss"))
               (receipt
                (testing-run-project
                 +upstream-build-improvement-project+
                 (list root)
                 record-run))
               (children (testing-receipt-children receipt))
               (suite-receipt (car children)))
          (check (testing-receipt-ok? receipt) => #t)
          (check (length children) => 1)
          (check (testing-object-ref suite-receipt 'suite)
                 => "integration")
          (check (testing-receipt-files suite-receipt)
                 => (list gamma delta))
          (check (reverse runs)
                 => (list (list gamma delta))))))

    (test-case "complex upstream build scenario id does not run gxtest suites"
      (let (runs [])
        (def (record-run files)
          (set! runs (cons files runs))
          0)
        (let* ((receipt
                (testing-run-project
                 +upstream-build-improvement-project+
                 (list "poo-real-dashboard-workflow-performance")
                 record-run))
               (children (testing-receipt-children receipt))
               (suite-receipt (car children)))
          (check (testing-receipt-ok? receipt) => #t)
          (check (length children) => 1)
          (check (testing-object-ref suite-receipt 'suite)
                 => "policy-scenarios-complex")
          (check (testing-receipt-files suite-receipt)
                 => (list "t/scenarios/policy/poo-real-dashboard-workflow-performance"))
          (check runs => []))))

    (test-case "downstream build enables improvement scenarios through testing config"
      (testing-build-reset! +downstream-improvement-build+)
      (let* ((receipt
              (testing-build-main
               +downstream-improvement-build+
               ["poo-construction-performance"]))
             (children (testing-receipt-children receipt))
             (suite-receipt (car children))
             (delegate-phase
              (testing-test-phase suite-receipt 'delegate-policy))
             (repair-guidance
              (testing-receipt-detail delegate-phase 'repairGuidance))
             (batch-receipt (car (testing-receipt-children suite-receipt)))
             (scenario-receipt
              (car (testing-receipt-children batch-receipt)))
             (scenario-details
              (testing-receipt-details scenario-receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref suite-receipt 'suite)
               => "improvement-scenarios")
        (check (testing-receipt-files suite-receipt)
               => ["./t/scenarios/policy/poo-construction-performance"])
        (check (testing-build-gxtest-runs +downstream-improvement-build+)
               => [])
        (check (testing-build-scenario-runs +downstream-improvement-build+)
               => ["poo-construction-performance"])
        (check (testing-details-ref scenario-details 'downstreamRepairTarget)
               => "poo-flow")
        (check (testing-details-ref scenario-details 'idiom)
               => "native-poo-construction")
        (check (testing-details-ref scenario-details 'nextRepairAction)
               => "apply the native POO construction idiom to the downstream object builder")
        (check (testing-details-ref (car repair-guidance) 'id)
               => "poo-construction-performance")
        (check (testing-details-ref (car repair-guidance) 'expectedOutcome)
               => "preserve native POO object syntax while optimizing runner mechanics")))

    (test-case "complex upstream build hot path has a benchmark gate"
      (check (benchmark-contract-valid/root?
              +upstream-build-improvement-benchmark-root+)
             => #t)
      (let (bench
            (benchmark-contract-run/root
             +upstream-build-improvement-benchmark-root+
             (lambda ()
               (let (file (fixture-path "alpha-test.ss"))
                 (testing-run-project
                  +upstream-build-improvement-project+
                  (list file)
                 fake-run-files)))))
        (check (benchmark-contract-receipt-pass? bench) => #t)))

    (test-case "performance gate remains a benchmark.ss gate under testing"
      (check (benchmark-contract-valid/root? +testing-benchmark-root+) => #t)
      (check (testing-performance-gate-valid?
              (car (testing-suite-gates +testing-gated-suite+)))
             => #t))))
