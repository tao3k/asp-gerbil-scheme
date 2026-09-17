;;; -*- Gerbil -*-
;;; Real ASP command startup probe. Each child is stopped at its first semantic
;;; event; compilation and test execution are deliberately outside this gate.

(import :gerbil/gambit
        (only-in :clan/timestamp current-tai-timestamp)
        (only-in :std/misc/process run-process)
        (only-in :std/os/signal kill SIGTERM)
        (only-in :std/srfi/13 string-prefix? string-contains)
        :asp-gerbil-scheme/src/benchmark/statistics
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 testing-interface-test-file-batches)
        (only-in :asp-gerbil-scheme/testing-runner-api
                 testing-interface-test-files))

(def +contract-path+
  "t/scenarios/building/native-command-startup/scenario-contract.ss")

(def (contract-ref contract key)
  (let (entry (assq key contract))
    (and entry (cdr entry))))

(def (native-command args environment)
  (append ["env" "-u" "DEVELOPER_DIR" "-u" "SDKROOT"]
          environment
          ["gerbil"]
          args))

(def (stop-probe! process)
  (with-catch void
    (lambda () (kill (process-pid process) SIGTERM))))

(def (measure-first-event lane command event? attempt)
  (displayln "[native-command-startup] lane=" lane
             " attempt=" attempt " event=process-start")
  (force-output)
  (let* ((started-at (current-tai-timestamp))
         (sample
          (run-process
           command
           directory: "."
           stderr-redirection: #t
           check-status: #f
           coprocess:
           (lambda (process)
             (let loop ()
               (let (line (read-line process))
                 (cond
                  ((eof-object? line)
                   (error "native command exited before its startup event"
                          lane command))
                  ((event? line)
                   (let (elapsed (- (current-tai-timestamp) started-at))
                     (stop-probe! process)
                     `((lane . ,lane)
                       (attempt . ,attempt)
                       (elapsedNs . ,elapsed)
                       (event . ,line))))
                  (else (loop)))))))))
    (displayln "[native-command-startup] lane=" lane
               " attempt=" attempt
               " event=first-semantic-output elapsed-ns="
               (cdr (assq 'elapsedNs sample))
               " line=" (cdr (assq 'event sample)))
    (force-output)
    sample))

(def (sample-elapsed sample)
  (cdr (assq 'elapsedNs sample)))

(def (measure-series lane command event? attempts)
  (map (lambda (attempt)
         (measure-first-event lane command event? attempt))
       (iota attempts 1)))

(def (assert-budget lane samples max-ns)
  (for-each
   (lambda (sample)
     (unless (< (sample-elapsed sample) max-ns)
       (error "native command startup exceeded its first-event budget"
              lane sample max-ns)))
   samples))

(def (assert-p50-budget lane p50 max-ns)
  (unless (< p50 max-ns)
    (error "native command median startup exceeded its first-event target"
           lane p50 max-ns)))

(def (main . _)
  (let* ((contract (call-with-input-file +contract-path+ read))
         (attempts (contract-ref contract 'attemptCount))
         (test-files
          (testing-interface-test-files +asp-testing-interface+ "unit-tests.ss"))
         (test-batches
          (testing-interface-test-file-batches
           +asp-testing-interface+ test-files))
         (startup-test-batch (and (pair? test-batches) (car test-batches)))
         (_ (unless (pair? startup-test-batch)
              (error "ASP native test catalog produced no executable batch")))
         (_ (displayln "[native-command-startup] lane=test event=batch-selected"
                       " catalog-file-count=" (length test-files)
                       " batch-count=" (length test-batches)
                       " startup-batch-file-count="
                       (length startup-test-batch)))
         (build-samples
          (measure-series
           'build
           (native-command ["build"] ["GERBIL_BUILD_VERBOSE=1"])
           (lambda (line)
             (and (string-contains
                   line "[asp-build] phase=spec-project-start") #t))
           attempts))
         (test-samples
          (measure-series
           'test
           (native-command
            (append ["test" "-v"] startup-test-batch) [])
           (lambda (line) (string-prefix? "=== " line))
           attempts))
         (build-p50
          (benchmark-sample-percentile (map sample-elapsed build-samples) 50))
         (test-p50
          (benchmark-sample-percentile (map sample-elapsed test-samples) 50)))
    (assert-budget
     'build build-samples
     (contract-ref contract 'maxBuildFirstEventNanoseconds))
    (assert-budget
     'test test-samples
     (contract-ref contract 'maxTestFirstEventNanoseconds))
    (assert-p50-budget
     'build build-p50
     (contract-ref contract 'targetBuildP50Nanoseconds))
    (assert-p50-budget
     'test test-p50
     (contract-ref contract 'targetTestP50Nanoseconds))
    (pretty-print
     `((schema . asp-gerbil-scheme.native-command-startup.v1)
       (subject . asp-gerbil-scheme-self)
       (testCatalogFileCount . ,(length test-files))
       (testBatchCount . ,(length test-batches))
       (startupTestBatchFileCount . ,(length startup-test-batch))
       (buildSamples . ,build-samples)
       (testSamples . ,test-samples)
       (buildP50Ns . ,build-p50)
       (testP50Ns . ,test-p50)))
    (displayln "[native-command-startup] event=complete"
               " build-p50-ns=" build-p50
               " test-p50-ns=" test-p50)))
