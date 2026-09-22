;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent style policy.

(import :std/test
        (only-in :std/test/base test-result-ok? test-suite!)
        "./agent-style-benchmark-test"
        "./agent-style-scenario-composition-test"
        "./agent-style-scenario-control-test"
        "./agent-style-typed-core-test"
        "./agent-style-typed-evidence-test"
        "./agent-style-comment-core-test"
        "./agent-style-comment-doc-test"
        "./agent-style-functional-core-test"
        "./agent-style-functional-branch-test"
        "./agent-style-macro-metaprogramming-decision-test"
        "./agent-style-predicate-test"
        "./agent-style-syntax-local-registry-test"
        "./agent-style-syntax-parameter-context-test")
(export agent-style-policy-test)

;; PolicyTest
(def agent-style-policy-test
  (test-suite "gerbil scheme harness agent style policy"
    (test-case "agent-style-benchmark-policy-test"
      (check (test-result-ok? (test-suite! agent-style-benchmark-policy-test)) => #t))
    (test-case "agent-style-scenario-composition-policy-test"
      (check (test-result-ok? (test-suite! agent-style-scenario-composition-policy-test)) => #t))
    (test-case "agent-style-scenario-control-policy-test"
      (check (test-result-ok? (test-suite! agent-style-scenario-control-policy-test)) => #t))
    (test-case "agent-style-typed-core-policy-test"
      (check (test-result-ok? (test-suite! agent-style-typed-core-policy-test)) => #t))
    (test-case "agent-style-typed-evidence-policy-test"
      (check (test-result-ok? (test-suite! agent-style-typed-evidence-policy-test)) => #t))
    (test-case "agent-style-comment-core-policy-test"
      (check (test-result-ok? (test-suite! agent-style-comment-core-policy-test)) => #t))
    (test-case "agent-style-comment-doc-policy-test"
      (check (test-result-ok? (test-suite! agent-style-comment-doc-policy-test)) => #t))
    (test-case "agent-style-functional-core-policy-test"
      (check (test-result-ok? (test-suite! agent-style-functional-core-policy-test)) => #t))
    (test-case "agent-style-functional-branch-policy-test"
      (check (test-result-ok? (test-suite! agent-style-functional-branch-policy-test)) => #t))
    (test-case "agent-style-macro-metaprogramming-decision-policy-test"
      (check (test-result-ok? (test-suite! agent-style-macro-metaprogramming-decision-policy-test)) => #t))
    (test-case "agent-style-predicate-policy-test"
      (check (test-result-ok? (test-suite! agent-style-predicate-policy-test)) => #t))
    (test-case "agent-style-syntax-local-registry-policy-test"
      (check (test-result-ok? (test-suite! agent-style-syntax-local-registry-policy-test)) => #t))
    (test-case "agent-style-syntax-parameter-context-policy-test"
      (check (test-result-ok? (test-suite! agent-style-syntax-parameter-context-policy-test)) => #t))))
