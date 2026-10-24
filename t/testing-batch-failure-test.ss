;;; Batch failures retain their original value without abandoning the workgroup.
(import (only-in :std/test test-suite test-case check)
        (only-in :std/misc/process run-process)
        (only-in :clan/poo/object .cc)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+ +testing-process-isolation-profile+
                 +testing-serial-resource-profile+ testing-test-selector
                 testing-interface-add-profile testing-interface-map-profile
                 testing-interface-run-test-files!))
(export testing-batch-failure-test)

;; : (-> (-> Any) Void)
(def (check-batch-failure fail)
  (def previous (getenv "GERBIL_BUILD_CORES" #f))
  (def calls 0)
  (def injected [])
  (def caught [])
  (def files
    (map (lambda (name)
           (string-append "t/scenarios/policy/upstream-gxtest-delegation/expected/t/"
                          name "-test.ss"))
         '("alpha" "beta" "gamma")))
  (def testing
    (.cc (testing-interface-map-profile
           (testing-interface-add-profile
            +asp-testing-interface+ +testing-process-isolation-profile+)
           (testing-test-selector 'contains "gamma-test.ss")
           +testing-serial-resource-profile+)
      'around-operation
      (lambda (_operation thunk)
        (set! calls (+ calls 1))
        (if (= calls 1)
          (with-catch
           (lambda (exception) (set! injected [exception]) (raise exception))
           fail)
          (thunk)))))
  (try
    ;; One worker makes abandonment deterministic: the original implementation
    ;; loses its only worker on the first failure and never joins the queue.
    (setenv "GERBIL_BUILD_CORES" "1")
    (with-catch
     (lambda (exception) (set! caught [exception]))
     (lambda () (testing-interface-run-test-files! testing files)))
    (check calls => 3)
    (check (pair? injected) => #t)
    (check (pair? caught) => #t)
    (when (and (pair? injected) (pair? caught))
      (check (eq? (car caught) (car injected)) => #t))
    (finally (setenv "GERBIL_BUILD_CORES" previous))))

(def testing-batch-failure-test
  (test-suite "native workgroup failure propagation"
    (test-case "native process failure preserves later parallel and serial batches"
      (check-batch-failure (lambda () (run-process '("sh" "-c" "exit 23")))))
    (test-case "a false exception remains a failure after every batch completes"
      (check-batch-failure (lambda () (raise #f))))))
