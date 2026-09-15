;;; -*- Gerbil -*-
;;; Gerbil scheme harness anonymous pair access policy tests.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :policy/fixtures
        :asp-gerbil-scheme/src/types/facade)

(export agent-anonymous-pair-policy-test)

;; PolicyTest
(def agent-anonymous-pair-policy-test
  (test-suite "gerbil scheme harness anonymous pair policy"
    (test-case "agent policy rejects repeated anonymous result pair access"
      (let* ((root ".run/policy-anonymous-pair")
             (test-dir (string-append root "/t")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir test-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/pair)\n")
        (write-text
         (string-append test-dir "/bad-test.ss")
         ";;; -*- Gerbil -*-\n(def (checks result)\n  [(car result) (cdr result) (car result) (cdr result) (car result) (cdr result)])\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-023" findings))
               (finding (car matching))
               (details (type-finding-details finding)))
          (check (length matching) => 1)
          (check (type-finding-path finding) => "t/bad-test.ss")
          (check (hash-get details 'kind) => "anonymous-result-pair-access")
          (check (hash-get details 'accessCount) => 6))))
    (test-case "agent policy accepts named result accessors"
      (let* ((root ".run/policy-anonymous-pair-accessor")
             (test-dir (string-append root "/t")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir test-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/pair)\n")
        (write-text
         (string-append test-dir "/good-test.ss")
         ";;; -*- Gerbil -*-\n(def (result-status result) (car result))\n(def (result-output result) (cdr result))\n(def (checks result)\n  [(result-status result) (result-output result) (result-status result) (result-output result)])\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-023" findings)))
          (check matching => []))))))

