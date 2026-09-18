;;; -*- Gerbil -*-
;;; One-shot real ASP command startup probe. Each child is stopped at its first
;;; semantic event; compilation and test execution are outside this gate.

(import :gerbil/gambit
        (only-in :std/misc/process run-process)
        (only-in :std/os/signal kill SIGTERM)
        (only-in :std/srfi/13 string-prefix?))

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

(def (elapsed-nanoseconds started-jiffy)
  (quotient (* (- (current-jiffy) started-jiffy) 1000000000)
            (jiffies-per-second)))

(def (measure-first-event lane command event?)
  (displayln "[native-command-startup] lane=" lane " event=process-start")
  (force-output)
  (let* ((started-at (current-jiffy))
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
                   (let (elapsed (elapsed-nanoseconds started-at))
                     (stop-probe! process)
                     `((lane . ,lane)
                       (elapsedNs . ,elapsed)
                       (event . ,line))))
                  (else (loop)))))))))
    (displayln "[native-command-startup] lane=" lane
               " event=first-semantic-output elapsed-ns="
               (cdr (assq 'elapsedNs sample))
               " line=" (cdr (assq 'event sample)))
    (force-output)
    sample))

(def (sample-elapsed sample)
  (cdr (assq 'elapsedNs sample)))

(def (assert-budget lane elapsed-ns max-ns)
  (unless (< elapsed-ns max-ns)
    (error "native command startup exceeded its first-event budget"
           lane elapsed-ns max-ns)))

(def (nonnegative-delta measured baseline)
  (max 0 (- measured baseline)))

(def (main . _)
  (let* ((contract (call-with-input-file +contract-path+ read))
         (test-file (contract-ref contract 'testFile))
         (_test-file-exists
          (unless (and (string? test-file) (file-exists? test-file))
            (error "native startup test file is absent" test-file)))
         (baseline-sample
          (measure-first-event
           'gerbil-baseline
           (native-command
            ["interactive" "-e"
             "(displayln \"[asp-startup-baseline] ready\")"] [])
           (lambda (line)
             (string-prefix? "[asp-startup-baseline]" line))))
         (baseline-ns (sample-elapsed baseline-sample))
         (_baseline-within-budget
          (assert-budget
           'gerbil-baseline baseline-ns
           (contract-ref contract 'maxBaselineFirstEventNanoseconds)))
         (build-sample
          (measure-first-event
           'build
           (native-command
            ["interactive" "build.ss" "spec"]
            ["GERBIL_BUILD_VERBOSE=1"])
           (lambda (line)
             (string-prefix?
              "[asp-build] phase=spec-project-start" line))))
         (build-ns (sample-elapsed build-sample))
         (build-incremental-ns
          (nonnegative-delta build-ns baseline-ns))
         (_build-within-budget
          (assert-budget
           'build build-ns
           (contract-ref contract 'maxBuildFirstEventNanoseconds)))
         (_build-incremental-within-budget
          (assert-budget
           'build-incremental build-incremental-ns
           (contract-ref contract 'maxBuildIncrementalFirstEventNanoseconds)))
         (test-sample
          (measure-first-event
           'test
           (native-command ["test" "-v" test-file] [])
           (lambda (line) (string-prefix? "=== " line))))
         (test-ns (sample-elapsed test-sample))
         (test-incremental-ns
          (nonnegative-delta test-ns baseline-ns)))
    (assert-budget
     'test test-ns
     (contract-ref contract 'maxTestFirstEventNanoseconds))
    (assert-budget
     'test-incremental test-incremental-ns
     (contract-ref contract 'maxTestIncrementalFirstEventNanoseconds))
    (pretty-print
     `((schema . asp-gerbil-scheme.native-command-startup.v3)
       (subject . asp-gerbil-scheme-self)
       (testFile . ,test-file)
       (baselineSample . ,baseline-sample)
       (buildSample . ,build-sample)
       (testSample . ,test-sample)
       (baselineNs . ,baseline-ns)
       (buildNs . ,build-ns)
       (testNs . ,test-ns)
       (buildIncrementalNs . ,build-incremental-ns)
       (testIncrementalNs . ,test-incremental-ns)))
    (displayln "[native-command-startup] event=complete"
               " baseline-ns=" baseline-ns
               " build-ns=" build-ns
               " build-incremental-ns=" build-incremental-ns
               " test-ns=" test-ns
               " test-incremental-ns=" test-incremental-ns)))
