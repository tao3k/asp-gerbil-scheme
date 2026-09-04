;;; -*- Gerbil -*-
;;; gerbil scheme harness agent POO runtime protocol policy.

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
(export agent-poo-runtime-protocol-policy-test)

;; PolicyTest
(def agent-poo-runtime-protocol-policy-test
  (test-suite "gerbil scheme harness agent POO runtime protocol policy"
(test-case "agent policy requires macro runtime-source witness"
          (let* ((root ".run/policy-macro-runtime-source")
                 (_ (write-macro-runtime-source-project root #f))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011" findings))
                 (finding (car matching))
                 (details (type-finding-details finding)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/macros/core.ss")
            (check (hash-get details 'next)
                   => "search runtime-source macro sugar module-sugar")
            (check (hash-get details 'phase) => "syntax")
            (check (hash-get details 'patternCount) => 0)
            (check (hash-get details 'hygienic) => #t)
            (check (not (not (member "syntax-template-witness"
                                     (hash-get details 'qualityFacets))))
                   => #t)
            (check (hash-get details 'macroFactSource)
                   => "parser-owned macroFacts from native Gerbil syntax extraction")
            (check (hash-get details 'policyBoundary)
                   => "macros are allowed when they stay controlled, source-backed, and explainable")
            (check (hash-get (hash-get details 'runtimeSourceRequirement)
                             'selectorScheme)
                   => "gerbil-runtime-source")
            (check (hash-get (hash-get details 'runtimeSourceRequirement)
                             'selectorFormat)
                   => "gerbil-runtime-source://<source-path>#<symbol>")
            (check (hash-get (hash-get details 'qualityReference)
                             'referencePattern)
                   => "gerbil-utils-controlled-macro-helper")
            (check (not (not (member "gerbil-utils/syntax.ss#syntax-case"
                                     (hash-get (hash-get details
                                                         'qualityReference)
                                               'referenceExamples))))
                   => #t)
            (check (hash-get details 'agentEscapeConstraint)
                   => "do not weaken macro-governance from a source macro edit; update gerbil.pkg only with a clear explanation and witness")))
(test-case "agent policy accepts macro runtime-source witness policy"
          (let* ((root ".run/policy-macro-runtime-source-allowed")
                 (_ (write-macro-runtime-source-project root #t))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011" findings)))
            (check matching => [])))
(test-case "agent policy rejects a macro witness owner without the macro call"
          (let* ((root ".run/policy-macro-runtime-source-wrong-owner")
                 (_ (write-macro-runtime-source-project root #t))
                 (_ (write-text
                     (string-append root "/gerbil.pkg")
                     "(package: sample/macros\n  policy: ((macro-governance explanation: \"Macro transformer edits are allowed only with runtime-source and expansion evidence.\" witnesses: ((\"with-order\" \"src/macros/core.ss\")))))\n"))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011" findings)))
            (check (length matching) => 1)))
(test-case "agent policy requires declared protocol evidence"
          (let* ((root ".run/policy-protocol-evidence")
                 (_ (write-protocol-evidence-project root #f))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-012" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/protocol.ss")
            (check (hash-get (type-finding-details finding) 'next)
                   => "search pattern poo protocol")))
(test-case "agent policy accepts declared protocol evidence"
          (let* ((root ".run/policy-protocol-evidence-positive")
                 (_ (write-protocol-evidence-project root #t))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-012" findings)))
            (check matching => [])))
(test-case "agent policy catches downstream POO implementation drift"
          (let* ((root ".run/policy-downstream-poo-agent")
                 (_ (write-downstream-poo-agent-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (vague (filter-rule "GERBIL-SCHEME-AGENT-POLICY-004" findings))
                 (direct-writeenv (filter-rule "GERBIL-SCHEME-AGENT-POLICY-006" findings))
                 (runtime-witness (filter-rule "GERBIL-SCHEME-AGENT-POLICY-007" findings))
                 (method-shape (filter-rule "GERBIL-SCHEME-AGENT-POLICY-008" findings))
                 (object-model (filter-rule "GERBIL-SCHEME-AGENT-POLICY-010" findings)))
            (check (length vague) => 1)
            (check (length direct-writeenv) => 1)
            (check (length runtime-witness) => 1)
            (check (length method-shape) => 1)
            (check (length object-model) => 1)
            (check (type-finding-path (car vague)) => "src/orders/core.ss")
            (check (type-finding-path (car direct-writeenv)) => "src/orders/io.ss")
            (check (type-finding-path (car runtime-witness)) => "src/orders/io.ss")
            (check (type-finding-path (car method-shape)) => "src/orders/io.ss")
            (check (type-finding-path (car object-model)) => "src/orders/core.ss")
            (check (type-finding-selector (car object-model)) => "src/orders/core.ss:4-4")))
(test-case "agent policy accepts downstream POO pattern-guided implementation"
          (let* ((root ".run/policy-downstream-poo-agent-positive")
                 (_ (write-downstream-poo-agent-positive-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index)))
            (check findings => [])))
(test-case "gxtest adapter exposes downstream policy report"
          (let* ((root ".run/policy-downstream-poo-agent-gxtest")
                 (_ (write-downstream-poo-agent-positive-project root))
                 (report (project-policy-report root))
                 (agent-repair (hash-get report 'agentRepair)))
            (check (project-policy-status root) => "pass")
            (check (project-policy-findings root) => [])
            (check (hash-get report 'schemaId)
                   => "agent.semantic-protocols.asp-gerbil-scheme-gxtest-report")
            (check (hash-get report 'status) => "pass")
            (check (> (hash-get report 'files) 0) => #t)
            (check (> (hash-get report 'definitions) 0) => #t)
            (check (hash-get report 'findings) => [])
            (check (hash-get agent-repair 'status) => "none")))
(test-case "agent policy warns on broad runtime imports"
          (let* ((root ".run/policy-explicit-precise-import")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (reset-fixture-root root)
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/broad.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :std/srfi/13)\n(def (starts? value) (string-prefix? \"a\" value))\n")
            (write-text (string-append owner "/precise.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import (only-in :std/srfi/13 string-prefix?))\n(def (starts? value) (string-prefix? \"a\" value))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-018" findings))
                   (finding (car matching)))
              (check (length matching) => 1)
              (check (type-finding-path finding) => "src/orders/broad.ss")
              (check (type-finding-selector finding) => "src/orders/broad.ss:3-3")))
    (test-case "agent policy rejects duplicate facade exports"
          (let* ((root ".run/policy-export-conflict")
                 (_alpha (write-facade-policy-project
                          root "alpha"
                          ";;; -*- Gerbil -*-\n;;; Alpha facade.\n(export value)\n"
                          ";;; -*- Gerbil -*-\n;;; Alpha core.\n(def value 1)\n"))
                 (_beta (write-facade-policy-project
                         root "beta"
                         ";;; -*- Gerbil -*-\n;;; Beta facade.\n(export value)\n"
                         ";;; -*- Gerbil -*-\n;;; Beta core.\n(def value 2)\n"))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-003" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-POLICY-003")
            (check (type-finding-path finding) => "src/beta/facade.ss"))))
(test-case "agent policy rejects duplicate facade exports"
          (let* ((root ".run/policy-export-conflict")
                 (_alpha (write-facade-policy-project
                          root "alpha"
                          ";;; -*- Gerbil -*-\n;;; Alpha facade.\n(export value)\n"
                          ";;; -*- Gerbil -*-\n;;; Alpha core.\n(def value 1)\n"))
                 (_beta (write-facade-policy-project
                         root "beta"
                         ";;; -*- Gerbil -*-\n;;; Beta facade.\n(export value)\n"
                         ";;; -*- Gerbil -*-\n;;; Beta core.\n(def value 2)\n"))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-003" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-rule-id finding)
                   => "GERBIL-SCHEME-AGENT-POLICY-003")
            (check (type-finding-path finding) => "src/beta/facade.ss")))
  ))
