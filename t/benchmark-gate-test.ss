;;; -*- Gerbil -*-
;;; Boundary: upstream benchmark gate helpers stay reusable by downstream tests.

(import :gerbil/gambit
        :std/test
        (only-in :asp-gerbil-scheme/src/support/time
                 duration-literal->nanos)
        :asp-gerbil-scheme/src/benchmark/gate
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
        (cdr benchmark-gate-fixture)))

;; : (-> Symbol Alist Alist)
(def (benchmark-gate-without key fixture)
  (filter (lambda (entry) (not (eq? (car entry) key)))
          fixture))

;; : (-> Symbol Value Alist Alist)
(def (benchmark-gate-with key value fixture)
  (cons (cons key value)
        (benchmark-gate-without key fixture)))

;; : Alist
(def benchmark-gate-missing-observed-fixture
  (benchmark-gate-without 'observedTimings benchmark-gate-fixture))

;; : Alist
(def benchmark-gate-invalid-observed-fixture
  (cons (cons 'observedTimings
              '(((name . measure-best) (durationMs . -1))))
        (benchmark-gate-without 'observedTimings benchmark-gate-fixture)))

;; : Alist
(def benchmark-gate-slow-expected-fixture
  (benchmark-gate-with
   'expected_over_input_budget
   '1ms
   (benchmark-gate-with
    'observedTimings
    '(((name . collect-before) (durationMs . 1))
      ((name . policy-before) (durationMs . 0))
      ((name . collect-after) (durationMs . 3))
      ((name . policy-after) (durationMs . 0)))
    benchmark-gate-fixture)))

;; : Alist
(def benchmark-gate-missing-observed-peer-fixture
  (benchmark-gate-without 'observedCollectMs benchmark-gate-fixture))

;; : Alist
(def benchmark-gate-observed-over-max-fixture
  (benchmark-gate-with 'observedPhaseMs 7 benchmark-gate-fixture))

;; : Alist
(def benchmark-gate-subsecond-fixture
  (benchmark-gate-with
   'max_total
   '750us
   (benchmark-gate-with
    'observed_total
    '250us
    (benchmark-gate-with
     'target_total
     '500us
     (benchmark-gate-with
      'regression_budget
      '250us
      (benchmark-gate-with
       'expected_over_input_budget
       '125us
       (benchmark-gate-with
        'observedTimings
        '(((name . collect-before) (durationMs . 0.125) (durationNs . 125000))
          ((name . policy-before) (durationMs . 0) (durationNs . 0))
          ((name . collect-after) (durationMs . 0.125) (durationNs . 125000))
          ((name . policy-after) (durationMs . 0) (durationNs . 0)))
        benchmark-gate-fixture)))))))

;; : Alist
(def benchmark-gate-slow-hot-fixture
  (benchmark-gate-with
   'target_total
   '100ms
   benchmark-gate-fixture))

;; : Alist
(def benchmark-gate-integration-fixture
  (benchmark-gate-with
   'tags
   '(gxtest import-closure)
   (benchmark-gate-with
    'max_total
    '200ms
    (benchmark-gate-with
     'target_total
     '100ms
     (benchmark-gate-with
      'observed_total
      '80ms
      benchmark-gate-fixture)))))

;; : Alist
(def benchmark-gate-slow-integration-fixture
  (benchmark-gate-with
   'max_total
   '1s
   benchmark-gate-integration-fixture))

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
      (check (duration-literal->nanos '0.1ns) => #f))

    (test-case "fixture carries reusable gate metadata"
      (check (benchmark-fixture-ref benchmark-gate-fixture 'max_total)
             => '100ms)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'maxRssMb)
             => 512)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'memoryMetric)
             => 'resident-set-size)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'memoryUnit)
             => "MB")
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observed_total)
             => '10ms)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'target_total)
             => '25ms)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'regression_budget)
             => '15ms)
      (check (number?
              (benchmark-fixture-ref benchmark-gate-fixture 'maxCollectMs))
             => #t)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observedCollectMs)
             => 10)
      (check (number?
              (benchmark-fixture-ref benchmark-gate-fixture 'maxParseMs))
             => #t)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observedParseMs)
             => 0)
      (check (number?
              (benchmark-fixture-ref benchmark-gate-fixture 'maxFileMs))
             => #t)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observedFileMs)
             => 0)
      (check (number?
              (benchmark-fixture-ref benchmark-gate-fixture 'maxPhaseMs))
             => #t)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observedPhaseMs)
             => 6)
      (check (benchmark-fixture-ref benchmark-gate-fixture
                                    'expected_over_input_budget)
             => '15ms)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observedTimings)
             => '(((name . collect-before) (durationMs . 6))
                  ((name . collect-after) (durationMs . 4))
                  ((name . policy-before) (durationMs . 0))
                  ((name . policy-after) (durationMs . 0))))
      (check (benchmark-fixture-ref benchmark-gate-fixture 'targetRationale)
             => "default generated benchmark fixture target")
      (check (member 'assert-memory-gate
                     (benchmark-fixture-ref benchmark-gate-fixture
                                            'measurementPhases))
             => '(assert-memory-gate))
      (check (benchmark-fixture-ref benchmark-gate-fixture 'iterations) => 3)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'tags)
             => '(benchmark gate test))
      (check (benchmark-fixture-missing-keys benchmark-gate-fixture) => [])
      (check (benchmark-fixture-memory-contract-pass? benchmark-gate-fixture)
             => #t)
      (check (benchmark-fixture-observed-timings-contract-pass?
              benchmark-gate-fixture)
             => #t)
      (check (benchmark-fixture-input-expected-comparison-pass?
              benchmark-gate-fixture)
             => #t)
      (check (benchmark-fixture-timing-class-contract-pass?
              benchmark-gate-fixture)
             => #t)
      (check (benchmark-fixture-contract-pass? benchmark-gate-fixture) => #t))

    (test-case "observed timing baseline is required by the gate contract"
      (check (benchmark-fixture-missing-keys
              benchmark-gate-missing-observed-fixture)
             => '(observedTimings))
      (check (benchmark-fixture-observed-timings-contract-pass?
              benchmark-gate-missing-observed-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-missing-observed-fixture)
             => #f)
      (check (benchmark-fixture-observed-timings-contract-pass?
              benchmark-gate-invalid-observed-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-invalid-observed-fixture)
             => #f))

    (test-case "max gates require observed peer fields"
      (check (not
              (not
               (member 'observedCollectMs
                       (benchmark-fixture-missing-keys
                        benchmark-gate-missing-observed-peer-fixture))))
             => #t)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-missing-observed-peer-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-observed-over-max-fixture)
             => #f))

    (test-case "input and expected timing comparison is enforced"
      (check (benchmark-fixture-observed-timings-contract-pass?
              benchmark-gate-slow-expected-fixture)
             => #t)
      (check (benchmark-fixture-input-expected-comparison-pass?
              benchmark-gate-slow-expected-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-slow-expected-fixture)
             => #f))

    (test-case "subsecond timing baselines satisfy the gate contract"
      (check (benchmark-fixture-ref benchmark-gate-subsecond-fixture
                                    'max_total)
             => '750us)
      (check (benchmark-fixture-ref benchmark-gate-subsecond-fixture
                                    'observed_total)
             => '250us)
      (check (benchmark-fixture-observed-timings-contract-pass?
              benchmark-gate-subsecond-fixture)
             => #t)
      (check (benchmark-fixture-input-expected-comparison-pass?
              benchmark-gate-subsecond-fixture)
             => #t)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-subsecond-fixture)
             => #t))

    (test-case "benchmark timing class separates hot policy and integration scope"
      (check (benchmark-fixture-integration-scope?
              benchmark-gate-fixture)
             => #f)
      (check (benchmark-fixture-timing-class-contract-pass?
              benchmark-gate-slow-hot-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-slow-hot-fixture)
             => #f)
      (check (benchmark-fixture-integration-scope?
              benchmark-gate-integration-fixture)
             => #t)
      (check (benchmark-fixture-timing-class-contract-pass?
              benchmark-gate-integration-fixture)
             => #t)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-integration-fixture)
             => #t)
      (check (benchmark-fixture-timing-class-contract-pass?
              benchmark-gate-slow-integration-fixture)
             => #f))

    (test-case "scenario benchmark fixtures satisfy the shared gate contract"
      (let (paths (benchmark-gate-scenario-benchmark-paths))
        (check (> (length paths) 0) => #t)
        (for-each
         (lambda (path)
           (let (fixture (benchmark-contract-read path))
             (check (benchmark-contract-input-expected-pass? path) => #t)
             (check (benchmark-fixture-missing-keys fixture) => [])
             (check (benchmark-fixture-memory-contract-pass? fixture) => #t)
             (check (benchmark-fixture-contract-pass? fixture) => #t)))
         paths)))

    (test-case "run returns pass receipt under threshold"
      (let (receipt
            (benchmark-run benchmark-gate-fixture
                           (lambda () 'ok)))
        (check (benchmark-fixture-ref receipt 'feature)
               => 'fixture-gate)
        (check (benchmark-fixture-ref receipt 'maxRssMb)
               => 512)
        (check (benchmark-fixture-ref receipt 'memoryMetric)
               => 'resident-set-size)
        (check (benchmark-fixture-ref receipt 'memoryUnit)
               => "MB")
        (check (>= (benchmark-fixture-ref receipt 'elapsedMicros) 0)
               => #t)
        (check (benchmark-fixture-ref receipt 'observed_total)
               => '10ms)
        (check (benchmark-fixture-ref receipt 'target_total)
               => '25ms)
        (check (benchmark-fixture-ref receipt 'regression_budget)
               => '15ms)
        (check (benchmark-fixture-ref receipt 'observedTimings)
               => '(((name . collect-before) (durationMs . 6))
                    ((name . collect-after) (durationMs . 4))
                    ((name . policy-before) (durationMs . 0))
                    ((name . policy-after) (durationMs . 0))))
        (check (benchmark-fixture-ref receipt 'targetRationale)
               => "default generated benchmark fixture target")
        (check (benchmark-receipt-pass? receipt) => #t)))

    (test-case "run returns fail receipt at zero threshold"
      (let (receipt
            (benchmark-run benchmark-gate-fail-fixture
                           (lambda () 'ok)))
        (check (benchmark-fixture-ref receipt 'max_total) => '0ns)
        (check (benchmark-receipt-pass? receipt) => #f)))))
