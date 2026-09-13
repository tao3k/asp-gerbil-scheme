;;; -*- Gerbil -*-
;;; Process-level regression for the public PackageSpec startup boundary.

(import :gerbil/gambit
        (only-in :std/test test-suite test-case check)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-contains)
        (only-in :clan/timestamp call-with-timing))

(export build-api-startup-scenario-test)

(def +build-api-startup-scenario+
  "t/scenarios/building/build-api-startup/build.ss")

(def +build-api-startup-contract+
  "t/scenarios/building/build-api-startup/startup-contract.ss")

(def (startup-contract-ref contract key)
  (let (entry (assq key contract))
    (and entry (cdr entry))))

(def build-api-startup-scenario-test
  (test-suite "public Build API startup scenario"
    (test-case "PackageSpec facade excludes optional subsystem closures"
      (let (source (call-with-input-file "build-api.ss" read-all-as-string))
        (for-each
         (lambda (forbidden)
           (check (string-contains source forbidden) => #f))
         '("src/building"
           "src/testing"
           "src/policy"
           "src/benchmark"
           ":clan/testing"))))
    (test-case "fresh downstream PackageSpec process starts within three seconds"
      (let (contract
            (call-with-input-file +build-api-startup-contract+ read))
        (check (startup-contract-ref contract 'scenarioKind)
               => 'process-startup)
        (check (startup-contract-ref contract 'attemptCount) => 1)
        (let-values (((elapsed-nanoseconds result)
                      (call-with-timing
                       (lambda ()
                         (run-process
                          ["gerbil" "interactive"
                           +build-api-startup-scenario+ "spec"]
                          coprocess: read)))))
          (displayln "[build-api-startup-scenario] elapsedNs="
                     elapsed-nanoseconds)
          (check result => '())
          (check (< elapsed-nanoseconds
                    (startup-contract-ref contract 'maxNanoseconds))
                 => #t))))))
