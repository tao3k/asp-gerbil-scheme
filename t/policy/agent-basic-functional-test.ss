;;; -*- Gerbil -*-
;;; gerbil scheme harness agent basic functional policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        (only-in :std/text/json read-json)
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(export agent-basic-functional-policy-test)

;; PolicyTest
(def agent-basic-functional-policy-test
  (test-suite "gerbil scheme harness agent basic functional policy"
(test-case "check changed scope reports only changed-file policy findings"
          (let* ((root ".run/policy-check-changed-scope")
                 (_ (write-check-changed-project root))
                 (_ (initialize-git-fixture root))
                 (_ (write-text (string-append root "/src/changed/core.ss")
                                ";;; -*- Gerbil -*-\n(package: sample/changed)\n(def (process x) x)\n"))
             (result (policy-check-output ["--changed" root]))
                 (output (cdr result)))
            (check (car result) => 1)
            (check (not (not (string-contains output "scope=changed"))) => #t)
            (check (not (not (string-contains output "src/changed/core.ss"))) => #t)
            (check (not (string-contains output "src/stable/core.ss")) => #t)))
(test-case "agent policy preserves named-let control contexts"
          (let* ((root ".run/policy-functional-idiom-control-context")
                 (_ (write-functional-idiom-control-context-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-009" findings)))
            (check matching => [])))
(test-case "agent policy accepts explicit higher-order idiom"
          (let* ((root ".run/policy-functional-idiom-positive")
                 (_ (write-functional-idiom-positive-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-009" findings)))
            (check (length matching) => 0)))
(test-case "agent policy keeps functional idiom suppression caller scoped"
          (let* ((root ".run/policy-functional-idiom-caller-scope")
                 (_ (write-functional-idiom-caller-scope-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-009" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-selector finding) => "src/orders/core.ss:7-8")
            (check (hash-get (type-finding-details finding) 'caller)
                   => "manual-total")))
(test-case "agent policy preserves native reader loops"
          (let* ((root ".run/policy-functional-idiom-reader")
                 (_ (write-functional-idiom-reader-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-009" findings)))
            (check (length matching) => 0)))
  ))
