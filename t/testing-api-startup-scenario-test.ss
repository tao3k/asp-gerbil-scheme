;;; -*- Gerbil -*-
;;; Process-level regression for the ordinary Testing API import boundary.

(import (only-in :std/test test-suite test-case check)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :std/string/misc string-contains)
        (only-in :asp-gerbil-scheme/src/support/time call-with-timing))

(export testing-api-startup-scenario-test)

(def +testing-api-startup-contract+
  "t/scenarios/testing/testing-api-startup/startup-contract.ss")

(def (contract-ref contract key)
  (let (entry (assq key contract))
    (and entry (cdr entry))))

(def testing-api-startup-scenario-test
  (test-suite "public Testing API startup scenario"
    (test-case "ordinary Testing API excludes optional execution closures"
      (let* ((contract
              (call-with-input-file +testing-api-startup-contract+ read))
             (extension-source
              (call-with-input-file
               "src/testing/extension.ss" read-all-as-string))
             (api-source
              (call-with-input-file "testing-api.ss" read-all-as-string)))
        (for-each
         (lambda (forbidden)
           (check (or (string-contains extension-source forbidden)
                      (string-contains api-source forbidden))
                  => #f))
         (contract-ref contract 'forbiddenBaseDependencies))))
    (test-case "fresh ordinary Testing API process starts within four seconds"
      (let (contract
            (call-with-input-file +testing-api-startup-contract+ read))
        (check (contract-ref contract 'scenarioKind)
               => 'testing-api-process-startup)
        (check (contract-ref contract 'attemptCount) => 1)
        (let-values (((elapsed-nanoseconds output)
                      (call-with-timing
                       (lambda ()
                         (run-process
                          ["gerbil" "interactive" "-e"
                           "(begin (import :asp-gerbil-scheme/testing-api) (displayln \"testing-api-ready\"))"]
                          coprocess: read-all-as-string)))))
          (displayln "[testing-api-startup-scenario] elapsedNs="
                     elapsed-nanoseconds)
          (check output => "testing-api-ready\n")
          (check (< elapsed-nanoseconds
                    (contract-ref contract 'maxNanoseconds))
                 => #t))))))
