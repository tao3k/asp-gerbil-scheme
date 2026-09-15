;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent style policy.

(import :std/test
        :policy/agent-style-benchmark-test
        :policy/agent-style-scenario-composition-test
        :policy/agent-style-scenario-control-test
        :policy/agent-style-typed-core-test
        :policy/agent-style-typed-evidence-test
        :policy/agent-style-comment-core-test
        :policy/agent-style-comment-doc-test
        :policy/agent-style-functional-core-test
        :policy/agent-style-functional-branch-test
        :policy/agent-style-macro-metaprogramming-decision-test
        :policy/agent-style-predicate-test
        :policy/agent-style-syntax-local-registry-test
        :policy/agent-style-syntax-parameter-context-test)
(export agent-style-policy-test)

;; PolicyTest
(def agent-style-policy-test
  (test-suite "gerbil scheme harness agent style policy"
    (test-case "agent-style-benchmark-policy-test"
      (check (run-test-suite! agent-style-benchmark-policy-test) => #t))
    (test-case "agent-style-scenario-composition-policy-test"
      (check (run-test-suite! agent-style-scenario-composition-policy-test) => #t))
    (test-case "agent-style-scenario-control-policy-test"
      (check (run-test-suite! agent-style-scenario-control-policy-test) => #t))
    (test-case "agent-style-typed-core-policy-test"
      (check (run-test-suite! agent-style-typed-core-policy-test) => #t))
    (test-case "agent-style-typed-evidence-policy-test"
      (check (run-test-suite! agent-style-typed-evidence-policy-test) => #t))
    (test-case "agent-style-comment-core-policy-test"
      (check (run-test-suite! agent-style-comment-core-policy-test) => #t))
    (test-case "agent-style-comment-doc-policy-test"
      (check (run-test-suite! agent-style-comment-doc-policy-test) => #t))
    (test-case "agent-style-functional-core-policy-test"
      (check (run-test-suite! agent-style-functional-core-policy-test) => #t))
    (test-case "agent-style-functional-branch-policy-test"
      (check (run-test-suite! agent-style-functional-branch-policy-test) => #t))
    (test-case "agent-style-macro-metaprogramming-decision-policy-test"
      (check (run-test-suite! agent-style-macro-metaprogramming-decision-policy-test) => #t))
    (test-case "agent-style-predicate-policy-test"
      (check (run-test-suite! agent-style-predicate-policy-test) => #t))
    (test-case "agent-style-syntax-local-registry-policy-test"
      (check (run-test-suite! agent-style-syntax-local-registry-policy-test) => #t))
    (test-case "agent-style-syntax-parameter-context-policy-test"
      (check (run-test-suite! agent-style-syntax-parameter-context-policy-test) => #t))))
