;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent basic policy.

(import (only-in :std/test test-suite test-case check)
        (only-in :std/test/base test-result-ok? test-suite!)
        (only-in "./agent-basic-core-test"
                 agent-basic-core-policy-test)
        (only-in "./agent-basic-declarative-test"
                 agent-basic-declarative-policy-test)
        (only-in "./agent-basic-control-test"
                 agent-basic-control-policy-test)
        (only-in "./agent-basic-functional-test"
                 agent-basic-functional-policy-test))
(export agent-basic-policy-test)

;; PolicyTest
(def agent-basic-policy-test
  (test-suite "gerbil scheme harness agent basic policy"
    (test-case "agent-basic-core-policy-test"
      (check (test-result-ok? (test-suite! agent-basic-core-policy-test)) => #t))
    (test-case "agent-basic-declarative-policy-test"
      (check (test-result-ok? (test-suite! agent-basic-declarative-policy-test)) => #t))
    (test-case "agent-basic-control-policy-test"
      (check (test-result-ok? (test-suite! agent-basic-control-policy-test)) => #t))
    (test-case "agent-basic-functional-policy-test"
      (check (test-result-ok? (test-suite! agent-basic-functional-policy-test)) => #t))))
