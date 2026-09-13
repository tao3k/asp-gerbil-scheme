;;; -*- Gerbil -*-
;;; Native process comparison for upstream clan/testing batch delegation.

(import (only-in :std/test test-suite test-case check)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :clan/timestamp call-with-timing))

(export testing-native-batch-scenario-test)

(def +native-batch-scenario-root+
  "t/scenarios/policy/upstream-gxtest-delegation/expected/t")

(def +native-batch-scenario-contract+
  "t/scenarios/policy/upstream-gxtest-delegation/native-batch-contract.ss")

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

(def testing-native-batch-scenario-test
  (test-suite "native clan/testing batch process scenario"
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
                 => #t))))))
