;;; -*- Gerbil -*-
;;; Boundary: upstream benchmark gate helpers stay reusable by downstream tests.

(import :gerbil/gambit
        :std/test
        (only-in :asp-gerbil-scheme/src/support/time
                 duration-literal->nanos
                 duration-literal<=?
                 duration-nanos->text)
        :asp-gerbil-scheme/src/benchmark/gate
        :asp-gerbil-scheme/src/benchmark/statistics
        :asp-gerbil-scheme/src/benchmark/framework
        :asp-gerbil-scheme/src/testing/memory-profile)

(export benchmark-gate-test)

(declare-gxtest-memory-exception
 '((maxHeapMiB . 512)))

;; : Alist
(def benchmark-gate-fixture
  (make-benchmark-fixture
   'GERBIL-SCHEME-AGENT-POLICY-000
   'fixture-gate
   "reusable benchmark gate"
   "small deterministic thunk"
   "return a pass/fail receipt"
   '(benchmark gate test)))

;; : Alist
(def benchmark-gate-fail-fixture
  (cons (cons 'max_total '0ns)
        (filter (lambda (entry) (not (eq? (car entry) 'max_total)))
                benchmark-gate-fixture)))

;; : (-> Symbol Alist Alist)
(def (benchmark-gate-without key fixture)
  (filter (lambda (entry) (not (eq? (car entry) key)))
          fixture))

;; : (-> Symbol Value Alist Alist)
(def (benchmark-gate-with key value fixture)
  (cons (cons key value)
        (benchmark-gate-without key fixture)))

;; : Alist
(def benchmark-gate-invalid-regression-fixture
  (benchmark-gate-with
   'regression_budget
   '1ms
   benchmark-gate-fixture))

;; : Alist
(def benchmark-gate-missing-target-fixture
  (benchmark-gate-without 'target_total benchmark-gate-fixture))

;; : Alist
(def benchmark-gate-undersampled-fixture
  (benchmark-gate-with
   'sampleCount
   19
   benchmark-gate-fixture))

;; : Alist
(def benchmark-gate-subsecond-fixture
  (benchmark-gate-with
   'max_total
   '750us
   (benchmark-gate-with
    'target_total
    '500us
    (benchmark-gate-with
     'regression_budget
     '250us
     (benchmark-gate-with
      'expected_over_input_budget
      '125us
      benchmark-gate-fixture)))))

;; : Alist
(def benchmark-gate-scenario-fixture
  (benchmark-gate-with
   'max_total
   '400ms
   (benchmark-gate-with
    'target_total
    '200ms
    (benchmark-gate-with
     'regression_budget
     '200ms
     benchmark-gate-fixture))))

;; : Alist
(def benchmark-gate-overlong-scenario-fixture
  (benchmark-gate-with
   'max_total
   '1s
   (benchmark-gate-with
    'target_total
    '500ms
    (benchmark-gate-with
     'regression_budget
     '500ms
     benchmark-gate-fixture))))

;; Relpath
(def +benchmark-gate-scenario-root+ "t/scenarios/policy")

;; : (-> (List Path))
(def (benchmark-gate-scenario-benchmark-paths)
  (benchmark-contract-paths/root +benchmark-gate-scenario-root+))

;; : TestSuite
(def benchmark-gate-test
  (test-suite "gerbil scheme benchmark gate"
    (test-case "duration literals parse to exact nanoseconds"
      (check (duration-literal->nanos '800ns) => 800)
      (check (duration-literal->nanos '75us) => 75000)
      (check (duration-literal->nanos '1.2ms) => 1200000)
      (check (duration-literal->nanos '1s) => 1000000000)
      (check (duration-literal->nanos '0.1ns) => #f)
      (check (duration-literal->nanos '1minute) => #f)
      (check (duration-literal->nanos '10) => #f))

    (test-case "duration formatting selects ns us ms and s without precision loss"
      (check (duration-nanos->text 999) => "999ns")
      (check (duration-nanos->text 1250) => "1.25us")
      (check (duration-nanos->text 1200000) => "1.2ms")
      (check (duration-nanos->text 1500000000) => "1.5s"))

    (test-case "mixed duration units compare in the nanosecond domain"
      (check (duration-literal<=? '999ns '1us) => #t)
      (check (duration-literal<=? '1000us '1ms) => #t)
      (check (duration-literal<=? '999ms '1s) => #t)
      (check (duration-literal<=? '1s '999ms) => #f))

    (test-case "nearest-rank p95, not the fastest sample, owns admission"
      (let (statistics (benchmark-sample-statistics '(50 10 30 20 40)))
        (check (benchmark-fixture-ref statistics 'minNs) => 10)
        (check (benchmark-fixture-ref statistics 'p50Ns) => 30)
        (check (benchmark-fixture-ref statistics 'p95Ns) => 50)
        (check (benchmark-fixture-ref statistics 'maxNs) => 50)
        (check (benchmark-sample-percentile '(10 20 30) 95) => 30))
      (let (statistics
            (benchmark-sample-statistics
             '(20 19 18 17 16 15 14 13 12 11
               10 9 8 7 6 5 4 3 2 1)))
        (check (benchmark-fixture-ref statistics 'sampleCount) => 20)
        (check (benchmark-statistics-ref statistics 'p95Ns) => 19)
        (check (benchmark-fixture-ref statistics 'p95Ns) => 19)
        (check (benchmark-fixture-ref statistics 'maxNs) => 20)))

    (test-case "fixture carries reusable gate metadata"
      (check (benchmark-fixture-ref benchmark-gate-fixture 'benchmarkKind)
             => 'scenario-e2e)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'max_total)
             => '100ms)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'target_total)
             => '25ms)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'regression_budget)
             => '75ms)
      (check (benchmark-fixture-ref benchmark-gate-fixture
                                    'expected_over_input_budget)
             => '15ms)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'targetRationale)
             => "default generated benchmark fixture target")
      (check (member 'observe-runtime-memory
                     (benchmark-fixture-ref benchmark-gate-fixture
                                            'measurementPhases))
             => '(observe-runtime-memory))
      (check (benchmark-fixture-ref benchmark-gate-fixture 'sampleCount) => 20)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'tags)
             => '(benchmark gate test))
      (check (benchmark-fixture-missing-keys benchmark-gate-fixture) => [])
      (check (benchmark-fixture-regression-budget-contract-pass?
              benchmark-gate-fixture)
             => #t)
      (check (benchmark-fixture-kind-contract-pass? benchmark-gate-fixture)
             => #t)
      (check (benchmark-fixture-scenario-duration-contract-pass?
              benchmark-gate-fixture)
             => #t)
      (check (benchmark-fixture-contract-pass? benchmark-gate-fixture) => #t))

    (test-case "target and regression headroom are required by the gate contract"
      (check (benchmark-fixture-missing-keys
              benchmark-gate-missing-target-fixture)
             => '(target_total))
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-missing-target-fixture)
             => #f)
      (check (benchmark-fixture-regression-budget-contract-pass?
              benchmark-gate-invalid-regression-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-invalid-regression-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-undersampled-fixture)
             => #f))

    (test-case "subsecond target headroom satisfies the gate contract"
      (check (benchmark-fixture-ref benchmark-gate-subsecond-fixture
                                    'max_total)
             => '750us)
      (check (benchmark-fixture-ref benchmark-gate-subsecond-fixture
                                    'target_total)
             => '500us)
      (check (benchmark-fixture-regression-budget-contract-pass?
              benchmark-gate-subsecond-fixture)
             => #t)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-subsecond-fixture)
             => #t))

    (test-case "scenario duration contract is independent of fixture tags"
      (check (benchmark-fixture-scenario-duration-contract-pass?
              benchmark-gate-scenario-fixture)
             => #t)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-scenario-fixture)
             => #t)
      (check (benchmark-fixture-scenario-duration-contract-pass?
              (benchmark-gate-with
               'tags
               '(gxtest import-closure)
               benchmark-gate-scenario-fixture))
             => #t)
      (check (benchmark-fixture-scenario-duration-contract-pass?
              benchmark-gate-overlong-scenario-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-overlong-scenario-fixture)
             => #f))

    (test-case "scenario benchmark fixtures satisfy the shared gate contract"
      (let (paths (benchmark-gate-scenario-benchmark-paths))
        (check (> (length paths) 0) => #t)
        (for-each
         (lambda (path)
           (let (fixture (benchmark-contract-read path))
             (check (benchmark-fixture-missing-keys fixture) => [])
             (check (benchmark-fixture-regression-budget-contract-pass?
                     fixture)
                    => #t)
             (check (benchmark-fixture-contract-pass? fixture) => #t)))
         paths)))

    (test-case "run returns pass receipt under threshold"
      (let (receipt
            (benchmark-run benchmark-gate-fixture
                           (lambda () 'ok)))
        (check (benchmark-fixture-ref receipt 'feature)
               => 'fixture-gate)
        (check (> (benchmark-fixture-ref receipt 'elapsedNs) 0)
               => #t)
        (check (benchmark-fixture-ref receipt 'admissionStatistic) => 'p95)
        (check (benchmark-fixture-ref receipt 'sampleCount) => 20)
        (check (length (benchmark-fixture-ref receipt 'samplesNs)) => 20)
        (check (<= (benchmark-fixture-ref receipt 'minNs)
                   (benchmark-fixture-ref receipt 'p50Ns))
               => #t)
        (check (<= (benchmark-fixture-ref receipt 'p50Ns)
                   (benchmark-fixture-ref receipt 'p95Ns))
               => #t)
        (check (= (benchmark-fixture-ref receipt 'elapsedNs)
                  (benchmark-fixture-ref receipt 'p95Ns))
               => #t)
        (check (string? (benchmark-fixture-ref receipt 'elapsed)) => #t)
        (check (benchmark-fixture-ref receipt 'timingSource)
               => ":clan/timestamp#call-with-timing")
        (let (runtime-stats (benchmark-fixture-ref receipt 'runtimeStats))
          (check (benchmark-fixture-ref runtime-stats 'memorySource)
                 => ":gerbil/gambit###process-statistics")
          (check (benchmark-fixture-ref runtime-stats 'gcPrecondition)
                 => ":gerbil/gambit###gc")
          (check (pair? (benchmark-fixture-ref runtime-stats 'memoryBefore))
                 => #t)
          (check (pair? (benchmark-fixture-ref runtime-stats 'memoryAfter))
                 => #t)
          (check (pair? (benchmark-fixture-ref runtime-stats 'memoryDelta))
                 => #t))
        (check (benchmark-fixture-ref receipt 'target_total)
               => '25ms)
        (check (benchmark-fixture-ref receipt 'regression_budget)
               => '75ms)
        (check (benchmark-fixture-ref receipt 'targetRationale)
               => "default generated benchmark fixture target")
        (check (benchmark-receipt-pass? receipt) => #t)))

    (test-case "run returns fail receipt at zero threshold"
      (let (receipt
            (benchmark-run benchmark-gate-fail-fixture
                           (lambda () 'ok)))
        (check (benchmark-fixture-ref receipt 'max_total) => '0ns)
        (check (benchmark-receipt-pass? receipt) => #f)))))
