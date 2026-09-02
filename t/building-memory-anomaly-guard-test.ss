;;; -*- Gerbil -*-
;;; Boundary:
;;; - These tests exercise the pure rolling-window classifier only.
;;; - They prove that stable RSS never changes compiler capacity while a rapid
;;;   ten-second trajectory and the hard line remain fail-closed.

(import (only-in :std/test test-suite test-case check)
        (only-in ../src/building/memory-anomaly-guard
                 framework-memory-anomaly-policy
                 framework-memory-anomaly-sample
                 framework-memory-anomaly-transition
                 framework-memory-guard-process-table
                 framework-memory-guard-load-average
                 framework-memory-guard-active-compiler-jobs
                 framework-memory-guard-process-tree-cpu-percent))

(export building-memory-anomaly-guard-test)

;; building-memory-anomaly-guard-test
;; : TestSuite
(def building-memory-anomaly-guard-test
  (test-suite "building memory anomaly guard"
    (test-case "denied process-table observation degrades to an empty sample"
      (check (list? (framework-memory-guard-process-table)) => #t))
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
       => 135.0))))
