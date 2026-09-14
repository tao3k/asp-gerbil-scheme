;;; -*- Gerbil -*-
;;; Process-level regression for root-only native Import Model projection.

(import (only-in :std/test test-suite test-case check)
        (only-in :std/misc/process run-process)
        (only-in :clan/timestamp call-with-timing))

(export native-import-public-closure-scenario-test)

(def +native-import-public-closure-root+
  "t/scenarios/building/native-import-public-closure")

(def +native-import-public-closure-build+ "build.ss")

(def +native-import-public-closure-contract+
  "t/scenarios/building/native-import-public-closure/scenario-contract.ss")

(def +native-import-public-closure-expected+ '("a.ss" "b.ss" "c.ss"))

(def (native-import-public-closure-contract-ref contract key)
  (let (entry (assq key contract))
    (and entry (cdr entry))))

(def native-import-public-closure-scenario-test
  (test-suite "native Import Model public closure scenario"
    (test-case "fresh process projects only the entry import closure"
      (let (contract
            (call-with-input-file +native-import-public-closure-contract+ read))
        (check (native-import-public-closure-contract-ref
                contract 'scenarioKind)
               => 'native-gerbil-build)
        (check (native-import-public-closure-contract-ref
                contract 'attemptCount)
               => 1)
        (let-values (((elapsed-nanoseconds result)
                      (call-with-timing
                       (lambda ()
                         (run-process
                          ["gerbil" "interactive"
                           +native-import-public-closure-build+ "spec"]
                          directory: +native-import-public-closure-root+
                          coprocess: read)))))
          (displayln "[native-import-public-closure-scenario] phase=projected target-count="
                     (length result)
                     " elapsedNs=" elapsed-nanoseconds)
          (check result => +native-import-public-closure-expected+)
          (check (< elapsed-nanoseconds
                    (native-import-public-closure-contract-ref
                     contract 'maxNanoseconds))
                 => #t))))))
