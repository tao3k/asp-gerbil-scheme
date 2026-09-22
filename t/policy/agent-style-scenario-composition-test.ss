;;; -*- Gerbil -*-
;;; agent style scenario composition policy.

(import :std/test
        (only-in :std/test/base test-result-ok? test-suite!)
        "./agent-style-scenario-composition-test-core"
        "./agent-style-scenario-composition-test-protocol")
(export agent-style-scenario-composition-policy-test)

;; PolicyTest
(def agent-style-scenario-composition-policy-test
  (test-suite "agent style scenario composition policy"
    (test-case "agent-style-scenario-composition-core-policy-test"
      (check (test-result-ok? (test-suite! agent-style-scenario-composition-core-policy-test)) => #t))
    (test-case "agent-style-scenario-composition-protocol-policy-test"
      (check (test-result-ok? (test-suite! agent-style-scenario-composition-protocol-policy-test)) => #t))))
