;;; -*- Gerbil -*-
;;; Process-level regression for root-only native Import Model projection.

(import (only-in :std/test test-suite test-case check)
        (only-in :std/misc/process run-process)
        (only-in :clan/timestamp call-with-timing))

(export native-import-public-closure-scenario-test)

(def +native-import-public-closure-root+
  "t/scenarios/building/native-import-public-closure")

(def +native-import-direct-root-build+ "modules-build.ss")
(def +native-import-public-closure-build+ "build.ss")

(def +native-import-public-closure-contract+
  "t/scenarios/building/native-import-public-closure/scenario-contract.ss")

(def +native-import-public-closure-expected+ '("a.ss" "b.ss" "c.ss"))
(def +native-import-direct-root-expected+ '("c.ss"))

(def (native-import-public-closure-contract-ref contract key)
  (let (entry (assq key contract))
    (and entry (cdr entry))))

(def (project-build-spec build)
  (call-with-timing
   (lambda ()
     (run-process
      ["gerbil" "interactive" build "spec"]
      directory: +native-import-public-closure-root+
      coprocess: read))))

(def native-import-public-closure-scenario-test
  (test-suite "native Import Model public closure scenario"
    (test-case "modules and public-entry-modules preserve distinct root modes"
      (let (contract
            (call-with-input-file +native-import-public-closure-contract+ read))
        (check (native-import-public-closure-contract-ref
                contract 'scenarioKind)
               => 'native-gerbil-build)
        (check (native-import-public-closure-contract-ref
                contract 'attemptCount)
               => 2)
        (let-values (((direct-nanoseconds direct-spec)
                      (project-build-spec +native-import-direct-root-build+))
                     ((closure-nanoseconds closure-spec)
                      (project-build-spec +native-import-public-closure-build+)))
          (displayln
           "[native-import-public-closure-scenario] phase=projected direct-target-count="
           (length direct-spec)
           " closure-target-count=" (length closure-spec)
           " direct-elapsed-ns=" direct-nanoseconds
           " closure-elapsed-ns=" closure-nanoseconds)
          (check direct-spec => +native-import-direct-root-expected+)
          (check closure-spec => +native-import-public-closure-expected+)
          (check (member "unrelated.ss" closure-spec) => #f))))))
