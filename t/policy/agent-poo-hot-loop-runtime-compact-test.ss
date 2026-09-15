;;; -*- Gerbil -*-
;;; gerbil scheme harness agent POO hot loop runtime compact policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        (only-in :std/text/json read-json)
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(import :policy/agent-poo-support)
(export agent-poo-hot-loop-runtime-compact-policy-test)

;; PolicyTest
(def agent-poo-hot-loop-runtime-compact-policy-test
  (test-suite "gerbil scheme harness agent POO hot loop runtime compact policy"
    (test-case "agent policy accepts compact POO object construction"
          (let* ((root ".run/policy-poo-construction-performance-compact")
                 (src (string-append root "/src"))
                 (owner (string-append src "/reports")))
            (reset-fixture-root root)
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/reports)\n")
            (write-text
             (string-append owner "/profile.ss")
             ";;; -*- Gerbil -*-\n(import :clan/poo)\n(def (build-report-ref)\n  (.o id: \"orders\" status: \"hot\"))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-027" findings)))
            (check matching => []))))
  ))
