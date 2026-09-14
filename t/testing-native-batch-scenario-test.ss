;;; -*- Gerbil -*-
;;; Native process comparison for upstream clan/testing batch delegation.

(import (only-in :std/test test-suite test-case check)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :clan/timestamp call-with-timing)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 testing-interface-run-test-batch!
                 testing-interface-test-files))

(export testing-native-batch-scenario-test)

(def +native-batch-scenario-root+
  "t/scenarios/policy/upstream-gxtest-delegation/expected/t")

(def +native-batch-scenario-contract+
  "t/scenarios/policy/upstream-gxtest-delegation/native-batch-contract.ss")

(def +native-batch-scenario-entrypoint+
  "t/scenarios/policy/upstream-gxtest-delegation/native-batch-entrypoint.ss")

(def +native-batch-scenario-files+
  (map (lambda (name)
         (string-append +native-batch-scenario-root+ "/" name "-test.ss"))
       '("alpha" "beta" "gamma" "delta")))

(def (native-batch-contract-ref contract key)
  (let (entry (assq key contract))
    (and entry (cdr entry))))

(def (run-native-test-files files)
  (run-process (append ["gerbil" "test"] files)
               coprocess: read-all-as-string))

(def (run-native-test-files/serial files)
  (for-each (lambda (file) (run-native-test-files [file])) files))

(def (native-batch-entrypoint-first-output)
  (let ((first-output-nanoseconds #f)
        (first-output-line #f)
        (process-output #f))
    (run-process
     ["gerbil" "interactive" +native-batch-scenario-entrypoint+]
     stderr-redirection: #t
     coprocess:
     (lambda (process)
       (let-values (((elapsed-nanoseconds line)
                     (call-with-timing (lambda () (read-line process)))))
         (set! first-output-nanoseconds elapsed-nanoseconds)
         (set! first-output-line line)
         ;; Drain the native process so run-process can retain its normal
         ;; status checking and resource cleanup semantics.
         (set! process-output
               (string-append line "\n" (read-all-as-string process))))))
    (values first-output-nanoseconds first-output-line process-output)))

(def testing-native-batch-scenario-test
  (test-suite "native clan/testing batch process scenario"
    (test-case "native discovery of a large catalog is not the silent minute"
      (let (contract
            (call-with-input-file +native-batch-scenario-contract+ read))
        (let-values (((discovery-nanoseconds test-files)
                      (call-with-timing
                       (lambda ()
                         (testing-interface-test-files
                          +asp-testing-interface+ "unit-tests.ss")))))
          (displayln "[native-clan-testing-discovery-scenario] elapsedNs="
                     discovery-nanoseconds
                     " fileCount=" (length test-files))
          (check (>= (length test-files)
                     (native-batch-contract-ref
                      contract 'minDiscoveryFileCount))
                 => #t)
          (check (< discovery-nanoseconds
                    (native-batch-contract-ref
                     contract 'maxDiscoveryNanoseconds))
                 => #t))))
    (test-case "multi-file upstream execution removes per-file startup cost"
      (let (contract
            (call-with-input-file +native-batch-scenario-contract+ read))
        (check (native-batch-contract-ref contract 'scenarioKind)
               => 'native-clan-testing-process-comparison)
        (check (length +native-batch-scenario-files+)
               => (native-batch-contract-ref contract 'fixtureCount))
        ;; Warm module and filesystem caches before comparing process topology.
        (run-native-test-files +native-batch-scenario-files+)
        (let-values (((serial-nanoseconds _serial-result)
                      (call-with-timing
                       (lambda ()
                         (run-native-test-files/serial
                          +native-batch-scenario-files+))))
                     ((batch-nanoseconds _batch-result)
                      (call-with-timing
                       (lambda ()
                         (run-native-test-files
                          +native-batch-scenario-files+)))))
          (displayln "[native-clan-testing-batch-scenario] fixtureCount="
                     (length +native-batch-scenario-files+)
                     " serialNs=" serial-nanoseconds
                     " batchNs=" batch-nanoseconds)
          (check (< batch-nanoseconds
                    (native-batch-contract-ref
                     contract 'maxBatchNanoseconds))
                 => #t)
          (check (< (* batch-nanoseconds 100)
                    (* serial-nanoseconds
                       (native-batch-contract-ref
                        contract 'maxBatchToSerialPercent)))
                 => #t))))
    (test-case "batch handoff is observable without a sixty-second silence"
      (let (contract
            (call-with-input-file +native-batch-scenario-contract+ read))
        (let-values (((first-output-nanoseconds first-output-line
                       process-output)
                      (native-batch-entrypoint-first-output)))
          (displayln "[native-clan-testing-ttfo-scenario] firstOutputNs="
                     first-output-nanoseconds
                     " firstLine=" first-output-line)
          (check (and (string? first-output-line)
                      (string-prefix? "[asp-testing] phase=batch-dispatch"
                                      first-output-line))
                 => #t)
          (check (and (string-contains process-output
                                       "phase=batch-start")
                      (string-contains process-output
                                       "phase=batch-complete")
                      (string-contains process-output
                                       "phase=all-batches-complete")
                      #t)
                 => #t)
          (check (< first-output-nanoseconds
                    (native-batch-contract-ref
                     contract 'maxFirstOutputNanoseconds))
                 => #t))))
    (test-case "failed native batch retains an elapsed terminal receipt"
      (let ((port (open-output-string))
            (raised? #f))
        (parameterize ((current-output-port port))
          (with-catch
           (lambda (_failure) (set! raised? #t))
           (lambda ()
             (testing-interface-run-test-batch!
              +asp-testing-interface+
              '("t/scenarios/policy/upstream-gxtest-delegation/missing.ss")))))
        (let (output (get-output-string port))
          (check raised? => #t)
          (check (and (string-contains output "phase=batch-start") #t) => #t)
          (check (and (string-contains output
                                       "phase=batch-failed elapsedNs=")
                      #t)
                 => #t))))))
