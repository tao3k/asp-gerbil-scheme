;;; -*- Gerbil -*-

(import (only-in :std/test check check-exception)
        (only-in :clan/poo/object .cc)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-source-admission-profile+
                 asp-gerbil-scheme-prepared-native-import-closure
                 testing-interface-add-profile
                 testing-interface-prepared-source-admission-suite)
        (only-in :asp-gerbil-scheme/src/build-api/native-import-closure
                 asp-gerbil-scheme-native-import-closure)
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
         (check
          (member
           "t/scenarios/testing/prepared-source-admission/prepared-witness-fixture.ss"
           (asp-gerbil-scheme-prepared-native-import-closure "." roots))
          ? pair?)
         ;; This source exists, but the scenario did not ask gxtest to prepare
         ;; it.  The prepared projection must fail instead of importing it.
         (check-exception
          (asp-gerbil-scheme-prepared-native-import-closure
           "." '("t/testing-extension-test.ss"))
          true)
         (check-exception
          (asp-gerbil-scheme-native-import-closure "." roots)
          true)
         (displayln "[asp-testing] phase=prepared-source-negative-path-blocked")
         (displayln "[asp-testing] phase=prepared-source-admission-complete")
         #t)))

(def prepared-source-admission-test
  (testing-interface-prepared-source-admission-suite
   +prepared-source-admission-interface+
   "prepared-source-admission"
   +prepared-source-roots+))
