;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent basic policy.

(import (only-in :std/test test-suite test-case check run-test-suite!)
        (only-in :policy/agent-basic-core-test
                 agent-basic-core-policy-test)
        (only-in :policy/agent-basic-declarative-test
                 agent-basic-declarative-policy-test)
        (only-in :policy/agent-basic-control-test
                 agent-basic-control-policy-test)
        (only-in :policy/agent-basic-functional-test
                 agent-basic-functional-policy-test))
(export agent-basic-policy-test)

;; PolicyTest
(def agent-basic-policy-test
  (test-suite "gerbil scheme harness agent basic policy"
    (test-case "agent-basic-core-policy-test"
      (check (run-test-suite! agent-basic-core-policy-test) => #t))
    (test-case "agent-basic-declarative-policy-test"
      (check (run-test-suite! agent-basic-declarative-policy-test) => #t))
    (test-case "agent-basic-control-policy-test"
      (check (run-test-suite! agent-basic-control-policy-test) => #t))
    (test-case "agent-basic-functional-policy-test"
      (check (run-test-suite! agent-basic-functional-policy-test) => #t))))
