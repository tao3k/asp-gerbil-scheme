;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent basic policy.

(import (only-in :std/test test-suite)
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
    agent-basic-core-policy-test
    agent-basic-declarative-policy-test
    agent-basic-control-policy-test
    agent-basic-functional-policy-test))
