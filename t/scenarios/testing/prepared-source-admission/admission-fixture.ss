;;; -*- Gerbil -*-

(import (only-in :std/test check check-exception)
        (only-in :clan/poo/object .cc)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-source-admission-profile+
                 testing-interface-add-profile)
        (only-in :asp-gerbil-scheme/testing-source-admission-api
                 testing-interface-prepared-source-admission-suite)
        (only-in :asp-gerbil-scheme/src/build-api/native-import-closure
                 asp-gerbil-scheme-native-import-closure
                 asp-gerbil-scheme-prepared-native-import-closure)
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
         ;; The adapter establishes the prepared-source lifecycle before this
         ;; user-declared slot is invoked.
         (check prepared-source-witness-ready? => #t)
         (check test => "prepared-source-admission")
         (check roots => +prepared-source-roots+)
         (check
          (member
           "t/scenarios/testing/prepared-source-admission/prepared-witness-fixture.ss"
           (asp-gerbil-scheme-prepared-native-import-closure "." roots))
          ? pair?)
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
