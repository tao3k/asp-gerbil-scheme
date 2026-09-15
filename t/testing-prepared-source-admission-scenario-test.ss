;;; -*- Gerbil -*-

(import (only-in :std/test test-suite test-case check)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-contains))

(export testing-prepared-source-admission-scenario-test)

(def +prepared-source-admission-fixtures+
  '("t/scenarios/testing/prepared-source-admission/admission-fixture.ss"
    "t/scenarios/testing/prepared-source-admission/prepared-witness-fixture.ss"))

(def testing-prepared-source-admission-scenario-test
  (test-suite "native prepared source admission lifecycle"
    (test-case "admission runs after gxtest prepares the complete harness"
      (let (output
            (run-process
             (append ["gerbil" "test"] +prepared-source-admission-fixtures+)
             coprocess: read-all-as-string))
        (check (and (string-contains
                     output
                     "phase=prepared-source-admission-complete")
                    #t)
               => #t)))))
