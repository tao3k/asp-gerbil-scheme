;;; -*- Gerbil -*-
;;; Fast smoke coverage for the POO-shaped testing framework.

(import (only-in :std/test test-suite test-case check)
        (only-in :clan/poo/object object? .ref .slot?)
        :gslph/src/testing/model
        :gslph/src/testing/framework)

(export testing-framework-smoke-test)

;; : (-> (List Path) Integer)
(def (fake-run-files files)
  0)

(def +smoke-suite+
  (gxtest-suite
   name: "unit"
   roots: ["t/fixtures/testing-framework"]
   files: ["t/fixtures/testing-framework/alpha-test.ss"]
   batch-size: 1))

(def +smoke-project+
  (testing-project
   name: "poo-flow-like"
   suites: [+smoke-suite+]
   roots: ["t/fixtures/testing-framework"]))

(def testing-framework-smoke-test
  (test-suite "gerbil scheme testing framework smoke"
    (test-case "testing project and suite are POO-shaped objects"
      (check (object? +smoke-project+) => #t)
      (check (.slot? +smoke-project+ 'name) => #t)
      (check (.ref +smoke-project+ 'name) => "poo-flow-like")
      (check (testing-object-kind +smoke-suite+) => 'gxtest-suite))

    (test-case "project selection stays lazy and targeted"
      (let* ((selection
              (testing-select-project
               +smoke-project+
               ["t/fixtures/testing-framework/alpha-test.ss"]))
             (receipt (testing-run-selection selection fake-run-files))
             (suite-receipt (car (testing-receipt-children receipt))))
        (check (testing-selection-ok? selection) => #t)
        (check (testing-receipt-ok? receipt) => #t)
        (check (testing-receipt-files suite-receipt)
               => ["t/fixtures/testing-framework/alpha-test.ss"])))))
