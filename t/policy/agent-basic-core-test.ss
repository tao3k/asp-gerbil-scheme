;;; -*- Gerbil -*-
;;; gerbil scheme harness agent basic core policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        (only-in :std/text/json read-json)
        :gslph/src/parser/facade
        (only-in :gslph/src/policy/agent-basic
                 generic-owner-findings
                 vague-definition-findings)
        :gslph/src/policy/facade
        :gslph/src/policy/gxtest
        :gslph/src/policy/streaming
        :gslph/src/types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(export agent-basic-core-policy-test)

;; PolicyTest
(def agent-basic-core-policy-test
  (test-suite "gerbil scheme harness agent basic core policy"
    (test-case "agent policy requires facade intent comment"
          (let* ((root ".run/policy-agent")
                 (_ (write-facade-policy-project
                     root "bar"
                     ";;; -*- Gerbil -*-\n(export value)\n"
                     ";;; -*- Gerbil -*-\n;;; Bar core.\n(def value 1)\n"))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-001" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-POLICY-001")
            (check (type-finding-path finding) => "src/bar/facade.ss")))
    (test-case "agent policy rejects generic owner names"
          (let* ((root ".run/policy-generic-owner")
                 (_ (write-facade-policy-project
                     root "utils"
                     ";;; -*- Gerbil -*-\n;;; Utilities facade.\n(export value)\n"
                     ";;; -*- Gerbil -*-\n;;; Utilities core.\n(def value 1)\n"))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-002" findings))
                 (finding (car matching)))
            (check (length matching) => 2)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-POLICY-002")
            (check (not (not (member "src/utils/facade.ss"
                                      (map type-finding-path matching))))
                   => #t)))
    (test-case "agent policy rejects vague definition names"
          (let* ((root ".run/policy-vague-definition")
                 (_ (write-vague-definition-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-004" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-POLICY-004")
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-selector finding)
                   => "gerbil-scheme://src/orders/core.ss#item/def/process")))
    (test-case "bounded streaming preserves file-local rule order and findings"
          (let* ((root ".run/policy-basic-streaming")
                 (_ (write-facade-policy-project
                     root "utils"
                     ";;; -*- Gerbil -*-\n;;; Utilities facade.\n(export process)\n"
                     ";;; -*- Gerbil -*-\n;;; Utilities core.\n(def (process value) value)\n"))
                 (index (collect-project root))
                 (expected
                  (append (generic-owner-findings index)
                          (vague-definition-findings index)))
                 (actual (run-basic-agent-policy/streaming root 1))
                 (project-finding
                  (lambda (finding)
                    (list (type-finding-rule-id finding)
                          (type-finding-path finding)
                          (type-finding-selector finding)))))
            (check (map project-finding actual)
                   => (map project-finding expected))))
    (test-case "package agent-policy disables selected rules"
          (let* ((root ".run/policy-agent-disabled-rule")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (reset-fixture-root root)
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders\n  policy: ((agent-policy disabled-rules: (\"GERBIL-SCHEME-AGENT-POLICY-004\") explanation: \"Fixture owns the vague-definition regression separately.\")))\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (process order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-004" findings)))
              (check matching => []))))
    (test-case "agent policy rejects top-level executable calls in src"
          (let* ((root ".run/policy-top-level-executable")
                 (_ (write-top-level-executable-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-005" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-POLICY-005")
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-selector finding) => "src/orders/core.ss:3-3")
            (check (type-finding-message finding)
                   => "top-level executable call displayln should move behind a named definition or explicit entrypoint")))
    (test-case "agent policy accepts explicit search-fast entrypoints"
          (let* ((root ".run/policy-search-fast-entrypoint")
                 (_ (write-search-fast-entrypoint-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-005" findings)))
            (check matching => [])))
    (test-case "agent policy accepts exported main script entrypoints"
      (let* ((root ".run/policy-exported-main-entrypoint")
             (src (string-append root "/src"))
             (owner (string-append src "/tools")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
            (ensure-dir owner)
            (write-text
             (string-append owner "/run.ss")
             ";;; -*- Gerbil -*-\n(export main)\n(def (main . args) 0)\n(exit (apply main (cdr (command-line))))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-005" findings)))
              (check matching => []))))
    (test-case "agent policy accepts explicit test harness entrypoints"
      (let* ((root ".run/policy-test-harness-entrypoint")
             (test-root (string-append root "/t")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir test-root)
        (write-text
         (string-append root "/gerbil.pkg")
         "(package: sample/test-harness-entrypoint)\n")
        (write-text
         (string-append test-root "/sample-test.ss")
         ";;; -*- Gerbil -*-\n(import :std/test)\n(def (subject) 1)\n(run-tests!\n (test-suite \"sample\"\n   (test-case \"works\"\n     (check (subject) => 1))))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-005" findings)))
          (check matching => []))))
  ))
