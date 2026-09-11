;;; -*- Gerbil -*-
;;; Execute real installed clan libraries through the shared benchmark gate.

(import :gerbil/gambit
        :std/test
        (only-in :clan/debug traced-function)
        :clan/poo/object
        :clan/poo/brace
        (only-in :clan/poo/debug DDT trace-poo)
        (only-in :asp-gerbil-scheme/src/benchmark/gate
                 benchmark-fixture-ref
                 benchmark-receipt-pass?
                 benchmark-run/result
                 make-benchmark-fixture)
        (only-in :asp-gerbil-scheme/src/benchmark/micro-kernel
                 make-micro-kernel-fixture
                 micro-kernel-fixture-contract-pass?
                 micro-kernel-receipt-pass?
                 micro-kernel-run/result)
        :asp-gerbil-scheme/src/testing/memory-profile)

(export upstream-library-benchmark-test)

(declare-gxtest-memory-exception
 '((maxHeapMiB . 512)))

(def +upstream-debug-reference-sources+
  '(".data/gerbil-utils/debug.ss#traced-function"
    ".data/gerbil-poo/debug.ss#trace-poo"))

(def upstream-debug-benchmark-fixture
  (cons
   (cons 'benchmarkLibrary ":clan/timestamp#call-with-timing")
   (cons
    (cons 'referenceSources +upstream-debug-reference-sources+)
    (make-benchmark-fixture
     'GERBIL-SCHEME-UPSTREAM-LIBRARY-BENCHMARK
     'clan-debug-runtime
     "installed clan debug call and POO tracing paths"
     "real :clan/debug and :clan/poo/debug procedures"
     "preserve upstream behavior and emit an exact nanosecond receipt"
     '(benchmark upstream library debug)))))

(def upstream-poo-micro-kernel-fixture
  (make-micro-kernel-fixture
   'upstream-poo-slot-dispatch
   400
   200
   "Development calibration measured p50 at 82-366 ns/op and optimized -O runs measured p50 at 162-255 ns/op; the 400 ns/op target and 600 ns/op hard ceiling retain explicit regression headroom while p95/max remain jitter diagnostics."))

(def (micro-kernel-fixture-with fixture key value)
  (cons (cons key value)
        (filter (lambda (entry) (not (eq? (car entry) key))) fixture)))

(.def upstream-debug-benchmark-object
  increment: (lambda (value) (+ value 1)))

(def (run-traced-function-benchmark)
  (let* ((port (open-output-string))
         (traced (traced-function 'increment
                                  (lambda (value) (+ value 1))
                                  port)))
    (traced 41)))

(def (run-trace-poo-benchmark)
  (parameterize ((current-error-port (open-output-string)))
    (let (traced (trace-poo upstream-debug-benchmark-object
                            'upstream-debug-benchmark-object))
      ((.@ traced increment) 41))))

(def (run-ddt-benchmark)
  (parameterize ((current-error-port (open-output-string)))
    (DDT 'upstream-ddt #f (+ 20 22))))

(def upstream-library-benchmark-test
  (test-suite "upstream clan library benchmark"
    (test-case "fixture records upstream timing and source owners"
      (check (benchmark-fixture-ref upstream-debug-benchmark-fixture
                                    'benchmarkLibrary)
             => ":clan/timestamp#call-with-timing")
      (check (benchmark-fixture-ref upstream-debug-benchmark-fixture
                                    'referenceSources)
             => +upstream-debug-reference-sources+))

    (test-case ":clan/debug traced-function executes under the benchmark gate"
      (let-values (((receipt result)
                    (benchmark-run/result upstream-debug-benchmark-fixture
                                          run-traced-function-benchmark)))
        (check result => 42)
        (check (benchmark-receipt-pass? receipt) => #t)
        (check (benchmark-fixture-ref receipt 'timingSource)
               => ":clan/timestamp#call-with-timing")
        (check (benchmark-fixture-ref
                (benchmark-fixture-ref receipt 'runtimeStats)
                'memorySource)
               => ":gerbil/gambit###process-statistics")))

    (test-case ":clan/poo/debug trace-poo executes under the benchmark gate"
      (let-values (((receipt result)
                    (benchmark-run/result upstream-debug-benchmark-fixture
                                          run-trace-poo-benchmark)))
        (check result => 42)
        (check (benchmark-receipt-pass? receipt) => #t)
        (check (> (benchmark-fixture-ref receipt 'elapsedNs) 0) => #t)))

    (test-case ":clan/poo/debug DDT executes under the benchmark gate"
      (let-values (((receipt result)
                    (benchmark-run/result upstream-debug-benchmark-fixture
                                          run-ddt-benchmark)))
        (check result => 42)
        (check (benchmark-receipt-pass? receipt) => #t)))

    (test-case "installed clan POO dispatch emits a batched ns-per-op receipt"
      (check (micro-kernel-fixture-contract-pass?
              upstream-poo-micro-kernel-fixture)
             => #t)
      (check (benchmark-fixture-ref upstream-poo-micro-kernel-fixture
                                    'targetNsPerOp)
             => 400)
      (check (benchmark-fixture-ref upstream-poo-micro-kernel-fixture
                                    'regressionBudgetNsPerOp)
             => 200)
      (check (benchmark-fixture-ref upstream-poo-micro-kernel-fixture
                                    'maxNsPerOp)
             => 600)
      (let-values (((receipt result)
                    (micro-kernel-run/result
                     upstream-poo-micro-kernel-fixture
                     (lambda ()
                       ((.@ upstream-debug-benchmark-object increment) 41)))))
        (displayln "[asp-gerbil-scheme-micro-kernel] name=upstream-poo-slot-dispatch"
                   " p50NetNs=" (benchmark-fixture-ref receipt 'p50Ns)
                   " p95NetNs=" (benchmark-fixture-ref receipt 'p95Ns)
                   " maxNetNs=" (benchmark-fixture-ref receipt 'maxNs)
                   " p50NsPerOp="
                   (benchmark-fixture-ref receipt 'nsPerOpCeiling)
                   " targetNsPerOp="
                   (benchmark-fixture-ref receipt 'targetNsPerOp)
                   " maxNsPerOp="
                   (benchmark-fixture-ref receipt 'maxNsPerOp))
        (check result => 42)
        (check (micro-kernel-receipt-pass? receipt) => #t)
        (check (benchmark-fixture-ref receipt 'benchmarkKind)
               => 'micro-kernel)
        (check (benchmark-fixture-ref receipt 'timingSource)
               => ":gerbil/gambit#cpu-time")
        (check (benchmark-fixture-ref receipt 'wallTimingSource)
               => ":clan/timestamp#call-with-timing")
        (check (benchmark-fixture-ref receipt 'admissionStatistic) => 'p50)
        (check (benchmark-fixture-ref receipt 'baselineStatistic)
               => 'bracket-min)
        (check (benchmark-fixture-ref receipt 'sampleGcPrecondition)
               => ":gerbil/gambit###gc")
        (check (benchmark-fixture-ref receipt 'sampleCount) => 20)
        (check (> (benchmark-fixture-ref receipt 'p50NetNs) 0) => #t)
        (check (> (benchmark-fixture-ref receipt 'p95Ns) 0) => #t)
        (check (> (benchmark-fixture-ref receipt 'maxNs) 0) => #t)
        (check (> (benchmark-fixture-ref receipt 'nsPerOpNumerator) 0) => #t)
        (check (benchmark-fixture-ref receipt 'nsPerOpDenominator)
               => 100000)
        (check (> (benchmark-fixture-ref receipt 'nsPerOpCeiling) 0) => #t)
        (check (<= (benchmark-fixture-ref receipt 'nsPerOpCeiling)
                   (benchmark-fixture-ref receipt 'maxNsPerOp))
               => #t)))

    (test-case "micro-kernel contract rejects undersampling and fake headroom"
      (check (micro-kernel-fixture-contract-pass?
              (micro-kernel-fixture-with
               upstream-poo-micro-kernel-fixture
               'sampleCount
               19))
             => #f)
      (check (micro-kernel-fixture-contract-pass?
              (micro-kernel-fixture-with
               upstream-poo-micro-kernel-fixture
               'maxNsPerOp
               601))
             => #f))))
