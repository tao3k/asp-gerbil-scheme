;;; -*- Gerbil -*-
;;; Boundary:
;;; - Top-level policy suite only composes smaller policy owners.
;;; - Keep individual policy test files under modularity limits.

(import :std/test
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/testing/memory-profile
        :asp-gerbil-scheme/src/testing/execution-profile
  "./policy/modularity-test"
  "./policy/agent-basic-test"
  "./policy/agent-list-growth-test"
  "./policy/agent-list-random-access-test"
  "./policy/agent-macro-io-test"
  "./policy/macro-governance-framework-test"
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

(declare-gxtest-serial policy-aggregate)

;; : TestSuite
(def policy-test
  (test-suite "gerbil scheme harness policy"
    (test-case "modularity-policy-test"
      (check (run-test-suite! modularity-policy-test) => #t))
    (test-case "agent-basic-policy-test"
      (check (run-test-suite! agent-basic-policy-test) => #t))
    (test-case "agent-list-growth-policy-test"
      (check (run-test-suite! agent-list-growth-policy-test) => #t))
    (test-case "agent-list-random-access-policy-test"
      (check (run-test-suite! agent-list-random-access-policy-test) => #t))
    (test-case "agent-macro-io-policy-test"
      (check (run-test-suite! agent-macro-io-policy-test) => #t))
    (test-case "macro-governance-framework-policy-test"
      (check (run-test-suite! macro-governance-framework-policy-test) => #t))
    (test-case "agent-string-growth-policy-test"
      (check (run-test-suite! agent-string-growth-policy-test) => #t))
    (test-case "agent-alist-access-policy-test"
      (check (run-test-suite! agent-alist-access-policy-test) => #t))
    (test-case "agent-anonymous-pair-policy-test"
      (check (run-test-suite! agent-anonymous-pair-policy-test) => #t))
    (test-case "agent-build-policy-test"
      (check (run-test-suite! agent-build-policy-test) => #t))
    (test-case "agent-source-scope-policy-test"
      (check (run-test-suite! agent-source-scope-policy-test) => #t))
    (test-case "agent-repair-policy-test"
      (check (run-test-suite! agent-repair-policy-test) => #t))
    (test-case "agent-style-higher-order-policy-test"
      (check (run-test-suite! agent-style-higher-order-policy-test) => #t))
    (test-case "agent-style-policy-test"
      (check (run-test-suite! agent-style-policy-test) => #t))
    (test-case "agent-dependency-adapter-policy-test"
      (check (run-test-suite! agent-dependency-adapter-policy-test) => #t))
    (test-case "agent-poo-policy-test"
      (check (run-test-suite! agent-poo-policy-test) => #t))
    downstream-gxtest-policy-scope-test
    (test-case "scenario-benchmark-policy-test"
      (check (run-test-suite! scenario-benchmark-policy-test) => #t))
    (test-case "detection-policy-test"
      (check (run-test-suite! detection-policy-test) => #t))
    (test-case "gerbil-utils-source-policy-test"
      (check (run-test-suite! gerbil-utils-source-policy-test) => #t))))
