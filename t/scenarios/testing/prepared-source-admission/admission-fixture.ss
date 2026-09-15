;;; -*- Gerbil -*-

(import (only-in :std/test check)
        (only-in :clan/poo/object .cc)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-source-admission-profile+
                 testing-interface-add-profile
                 testing-interface-prepared-source-admission-suite)
        "./state")

(export prepared-source-admission-test)

(def +prepared-source-roots+
  '("t/scenarios/testing/prepared-source-admission/prepared-witness-fixture.ss"))

(def +prepared-source-admission-interface+
  (.cc (testing-interface-add-profile
        +asp-testing-interface+
        +testing-source-admission-profile+)
       .admit-prepared-source-graph:
       (lambda (test roots)
         ;; The admission fixture is listed before the witness fixture.  This
         ;; can only be true here when native gxtest has prepared every module
         ;; before executing this generated suite.
         (check prepared-source-witness-ready? => #t)
         (check test => "prepared-source-admission")
         (check roots => +prepared-source-roots+)
         (displayln "[asp-testing] phase=prepared-source-admission-complete")
         #t)))

(def prepared-source-admission-test
  (testing-interface-prepared-source-admission-suite
   +prepared-source-admission-interface+
   "prepared-source-admission"
   +prepared-source-roots+))
