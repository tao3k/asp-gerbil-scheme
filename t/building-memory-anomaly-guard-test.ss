;;; -*- Gerbil -*-
;;; Boundary:
;;; - These tests exercise the pure rolling-window classifier only.
;;; - They prove that stable RSS never changes compiler capacity while a rapid
;;;   ten-second trajectory and the hard line remain fail-closed.

(import (only-in :std/test test-suite test-case check)
        (only-in :std/srfi/13 string-contains)
        (only-in ../src/building/memory-anomaly-guard
                 framework-memory-anomaly-policy
                 framework-memory-anomaly-sample
                 framework-memory-anomaly-transition
                 framework-memory-guard-process-table
                 framework-memory-guard-runtime-heap-bytes
                 framework-memory-guard-load-average
                 framework-memory-guard-active-compiler-jobs
                 framework-memory-guard-process-tree-cpu-percent
                 framework-memory-anomaly-receipt
                 framework-build-start-line
                 call-with-framework-memory-anomaly-guard))

(export building-memory-anomaly-guard-test)

;; building-memory-anomaly-guard-test
;; : TestSuite
(def building-memory-anomaly-guard-test
  (test-suite "building memory anomaly guard"
    (test-case "build start is visible before std/make IO waits"
      (check (framework-build-start-line 8)
             => (string-append
                 "[asp-gerbil-scheme-build] phase=std-make-start"
                 " worker-count=8")))
    (test-case "healthy completion emits no periodic or terminal RSS receipt"
      (let (result #f)
        (check
         (with-output-to-string
           (lambda ()
             (parameterize ((current-error-port (current-output-port)))
               (set! result
                     (call-with-framework-memory-anomaly-guard
                      "test build" 1 (lambda () 'done))))))
         => (string-append
             "[asp-gerbil-scheme-build] phase=std-make-start"
             " worker-count=1\n"))
        (check result => 'done)))
    (test-case "profile admission names its phase and emits terminal evidence"
      (let (output
            (with-output-to-string
              (lambda ()
                (parameterize ((current-error-port (current-output-port)))
                  (call-with-framework-memory-anomaly-guard
                   "test admission"
                   1
                   (lambda () 'done)
                   #t
                   'profile-admission-start)))))
        (check (and (string-contains output
                                     "phase=profile-admission-start worker-count=1")
                    #t)
               => #t)
        (check (and (string-contains output
                                     "ASP_GERBIL_SCHEME_MEMORY_GUARD")
                    #t)
               => #t)
        (check (and (string-contains output "\"outcome\":\"completed\"") #t)
               => #t)))
    (test-case "denied process-table observation degrades to an empty sample"
      (check (list? (framework-memory-guard-process-table)) => #t))
    (test-case "runtime heap observation does not depend on process-table access"
      (check (framework-memory-guard-runtime-heap-bytes)
             ? (lambda (bytes) (and (integer? bytes) (>= bytes 0)))))
    (test-case "host runnable pressure is represented without fixed cores"
      (let (load-average (framework-memory-guard-load-average))
        (check (list? load-average) => #t)
        (check (andmap (lambda (value)
                         (and (real? value) (>= value 0)))
                       load-average)
               => #t)))
    (test-case "stable high RSS remains normal and never limits workers"
      (let* ((policy (framework-memory-anomaly-policy))
             (gib (* 1024 1024 1024))
             (samples
              [(framework-memory-anomaly-sample 0 (* 3 gib))
               (framework-memory-anomaly-sample 10 (* 3 gib))]))
        (check (call-with-values
                (lambda ()
                  (framework-memory-anomaly-transition
                   policy 'normal 0 samples 10 (* 3 gib)))
                list)
               => '(normal 0 within-envelope))))
    (test-case "one rapid ten-second growth window is suspect, not a core cap"
      (let* ((policy (framework-memory-anomaly-policy))
             (gib (* 1024 1024 1024))
             (samples [(framework-memory-anomaly-sample 0 gib)]))
        (check (call-with-values
                (lambda ()
                  (framework-memory-anomaly-transition
                   policy 'normal 0 samples 10 (* 2 gib)))
                list)
               => '(suspect 1 rapid-rss-growth-suspected))))
    (test-case "repeated rapid growth trips the anomaly guard"
      (let* ((policy (framework-memory-anomaly-policy))
             (gib (* 1024 1024 1024))
             (samples [(framework-memory-anomaly-sample 0 gib)]))
        (check (call-with-values
                (lambda ()
                  (framework-memory-anomaly-transition
                   policy 'suspect 1 samples 10 (* 3 gib)))
                list)
               => '(tripped 2 rapid-rss-growth))))
    (test-case "hard five GiB line trips immediately"
      (let* ((policy (framework-memory-anomaly-policy))
             (gib (* 1024 1024 1024)))
        (check (call-with-values
                (lambda ()
                  (framework-memory-anomaly-transition
                   policy 'normal 0 [] 1 (* 5 gib)))
                list)
               => '(tripped 0 hard-limit-exceeded))))
    (test-case "compiler pipelines are counted once at the scheduler frontier"
      (check
       (framework-memory-guard-active-compiler-jobs
        100
       '((101 100 1024 50.0 "gsc")
          (102 101 2048 50.0 "gcc")
          (103 102 4096 25.0 "cc1")
          (104 100 1024 10.0 "gxi")
          (105 100 1024 1.0 "ps")))
       => 2)
      (check
       (framework-memory-guard-process-tree-cpu-percent
        100
        '((101 100 1024 50.0 "gsc")
          (102 101 2048 50.0 "gcc")
          (103 102 4096 25.0 "cc1")
          (104 100 1024 10.0 "gxi")
          (105 999 1024 80.0 "other")))
       => 135.0))
    (test-case "incomplete process sampling cannot claim scheduler starvation"
      (let (receipt
            (framework-memory-anomaly-receipt
             (framework-memory-anomaly-policy)
             "test" 'completed 'within-envelope 2
             1024 0 0 10
             1 1 1 0 100.0 100.0
             9 9 '() '() 0 9 9))
        (check (hash-get receipt "ready-queue-observed") => #f)
        (check (hash-get receipt "scheduler-starvation-verdict")
               => "not-provable-with-current-std-make-public-api")
        (check (hash-get receipt "observer-sample-sequence-complete") => #f)
        (check (hash-get receipt "performance-baseline-valid") => #f)))
    (test-case "real observer cadence establishes a valid baseline"
      (let (receipt
            (framework-memory-anomaly-receipt
             (framework-memory-anomaly-policy)
             "test" 'completed 'within-envelope 2
             1024 0 0 10
             2 10 7 2 180.0 700.0
             1 9 '() '() 0 9.5 1.5))
        (check (hash-get receipt "observer-expected-samples") => 5)
        (check (hash-get receipt "observer-sample-sequence-complete") => #t)
        (check (hash-get receipt "performance-baseline-valid") => #t)
        (check (hash-get receipt "observer-maximum-interval-ms") => 1500)))))
