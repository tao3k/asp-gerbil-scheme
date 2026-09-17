;;; -*- Gerbil -*-
;;; Process-level regression for the public PackageSpec startup boundary.

(import :gerbil/gambit
        (only-in :std/test test-suite test-case check)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :std/os/signal kill SIGTERM)
        (only-in :std/srfi/13 string-contains string-prefix?))

(export build-api-startup-scenario-test)

(def +build-api-startup-scenario+
  "t/scenarios/building/build-api-startup/build.ss")

(def +build-api-startup-contract+
  "t/scenarios/building/build-api-startup/startup-contract.ss")

(def (startup-contract-ref contract key)
  (let (entry (assq key contract))
    (and entry (cdr entry))))

(def (elapsed-nanoseconds started-jiffy)
  (quotient (* (- (current-jiffy) started-jiffy) 1000000000)
            (jiffies-per-second)))

(def (measure-first-event command prefix)
  (let (started-jiffy (current-jiffy))
    (run-process
     command
     stderr-redirection: #t
     check-status: #f
     coprocess:
     (lambda (process)
       (let loop ()
         (let (line (read-line process))
           (cond
            ((eof-object? line)
             (error "PackageSpec exited before its first build event"))
            ((string-prefix? prefix line)
             (let (elapsed (elapsed-nanoseconds started-jiffy))
               (with-catch void
                 (lambda () (kill (process-pid process) SIGTERM)))
               (cons elapsed line)))
            (else (loop)))))))))

(def (measure-gerbil-baseline-first-event)
  (measure-first-event
   ["env" "-u" "DEVELOPER_DIR" "-u" "SDKROOT"
    "gerbil" "interactive" "-e"
    "(displayln \"[asp-startup-baseline] ready\")"]
   "[asp-startup-baseline]"))

(def (measure-package-spec-first-event)
  (measure-first-event
   ["env" "-u" "DEVELOPER_DIR" "-u" "SDKROOT"
    "GERBIL_BUILD_VERBOSE=1"
    "gerbil" "interactive" +build-api-startup-scenario+ "spec"]
   "[asp-build] phase=spec-project-start"))

(def build-api-startup-scenario-test
  (test-suite "public Build API startup scenario"
    (test-case "PackageSpec facade excludes optional subsystem closures"
      (let (source (call-with-input-file "building-api.ss" read-all-as-string))
        (for-each
         (lambda (forbidden)
           (check (string-contains source forbidden) => #f))
         '("src/building"
           "src/testing"
           "src/policy"
           "src/benchmark"
           ":clan/testing"))))
    (test-case "PackageSpec incremental first event stays within four seconds"
      (let (contract
            (call-with-input-file +build-api-startup-contract+ read))
        (check (startup-contract-ref contract 'scenarioKind)
               => 'process-startup)
        (check (startup-contract-ref contract 'attemptCount) => 1)
        (let* ((baseline-sample (measure-gerbil-baseline-first-event))
               (baseline-nanoseconds (car baseline-sample))
               (sample (measure-package-spec-first-event))
               (elapsed-nanoseconds (car sample))
               (incremental-nanoseconds
                (max 0 (- elapsed-nanoseconds baseline-nanoseconds)))
               (event (cdr sample)))
          (displayln "[build-api-startup-scenario] baselineNs="
                     baseline-nanoseconds
                     " elapsedNs=" elapsed-nanoseconds
                     " incrementalNs=" incremental-nanoseconds)
          (check (string-prefix? "[asp-build] phase=spec-project-start"
                                 event)
                 => #t)
          (check (< baseline-nanoseconds
                    (startup-contract-ref
                     contract 'maxBaselineFirstEventNanoseconds))
                 => #t)
          (check (< incremental-nanoseconds
                    (startup-contract-ref contract 'maxNanoseconds))
                 => #t))))))
