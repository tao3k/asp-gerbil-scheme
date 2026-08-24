;;; -*- Gerbil -*-
;;; Boundary:
;;; - Top-level policy suite only composes smaller policy owners.
;;; - Keep individual policy test files under modularity limits.

(import :std/test
        :gslph/src/policy/gxtest
        :gslph/src/testing/memory-profile
  "./policy/modularity-test"
  "./policy/agent-basic-test"
  "./policy/agent-list-growth-test"
  "./policy/agent-list-random-access-test"
  "./policy/agent-macro-io-test"
  "./policy/agent-string-growth-test"
  "./policy/agent-alist-access-test"
  "./policy/agent-anonymous-pair-test"
  "./policy/agent-build-test"
  "./policy/agent-source-scope-test"
  "./policy/agent-repair-test"
  "./policy/agent-style-higher-order-test"
  "./policy/agent-style-test"
  "./policy/agent-dependency-adapter-test"
  "./policy/agent-poo-test"
  "./policy/downstream-gxtest-policy-scope-test"
  "./policy/scenario-benchmark-test"
  "./policy/detection-test"
  "./policy/gerbil-utils-source-test")
(export policy-test)

(declare-gxtest-memory-exception
 '((maxHeapMiB . 512)))

;; : TestSuite
(def policy-test
  (test-suite "gerbil scheme harness policy"
    modularity-policy-test
    agent-basic-policy-test
    agent-list-growth-policy-test
    agent-list-random-access-policy-test
    agent-macro-io-policy-test
    agent-string-growth-policy-test
    agent-alist-access-policy-test
    agent-anonymous-pair-policy-test
    agent-build-policy-test
    agent-source-scope-policy-test
    agent-repair-policy-test
    agent-style-higher-order-policy-test
    agent-style-policy-test
    agent-dependency-adapter-policy-test
    agent-poo-policy-test
    downstream-gxtest-policy-scope-test
    scenario-benchmark-policy-test
    detection-policy-test
    gerbil-utils-source-policy-test))
