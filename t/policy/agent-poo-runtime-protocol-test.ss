;;; -*- Gerbil -*-
;;; gerbil scheme harness agent POO runtime protocol policy.

(import :gerbil/runtime/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        (only-in :std/encoding/json read-json)
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade
        "../unit/policy/poo-scenarios"
        "./fixtures")
(import "./agent-poo-support")
(export agent-poo-runtime-protocol-policy-test)

;; : (-> (List TypeFinding) (List String))
(def (macro-finding-names findings)
  (map (lambda (finding)
         (hash-get (type-finding-details finding) 'macro))
       findings))

;; PolicyTest
(def agent-poo-runtime-protocol-policy-test
  (test-suite "gerbil scheme harness agent POO runtime protocol policy"
(test-case "agent policy requires macro runtime-source witness"
          (let* ((root ".run/policy-macro-runtime-source")
                 (_ (write-macro-runtime-source-project root #f))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (build-findings
                  (run-agent-policy index
                                    test-evidence-complete?: #f))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011" findings))
                 (finding (car matching))
                 (details (type-finding-details finding)))
            (check (length matching) => 1)
            (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011"
                                build-findings)
                   => [])
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
                   => "do not weaken macro-governance or replace executable evidence with package metadata")
            (check (hash-get details 'requiredWitness)
                   => "one collected test owner with an assertion and either a parser-visible macro call or an exact load/include edge to its case owner")))
(test-case "agent policy accepts executable macro source witness"
          (let* ((root ".run/policy-macro-runtime-source-allowed")
                 (_ (write-macro-runtime-source-project root #t))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011" findings)))
            (check matching => [])))
(test-case "agent policy follows a tested macro expansion closure"
          (let* ((root ".run/policy-macro-expansion-closure")
                 (_ (write-macro-expansion-closure-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011" findings)))
            (check matching => [])))
(test-case "agent policy does not treat quoted transformer data as an expansion edge"
          (let* ((root ".run/policy-macro-quoted-data")
                 (_ (write-macro-quoted-data-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011" findings)))
            (check (length matching) => 1)
            (check (macro-finding-names matching) => ["quoted-helper"])))
(test-case "agent policy fails closed for ambiguous expansion helper owners"
          (let* ((root ".run/policy-macro-ambiguous-expansion")
                 (_ (write-macro-ambiguous-expansion-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011" findings)))
            (check (length matching) => 2)
            (check (macro-finding-names matching)
                   => ["shared-helper" "shared-helper"])))
(test-case "agent policy accepts a test loading the exact macro case owner"
          (let* ((root ".run/policy-macro-runtime-source-linked")
                 (build-graph
                  (write-linked-macro-runtime-source-project root))
                 (index
                  (collect-selected-source-scope root build-graph))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011" findings)))
            (check matching => [])))
(test-case "agent policy accepts a transitive package import to the macro case owner"
          (let* ((root ".run/policy-macro-runtime-source-import-linked")
                 (build-graph
                  (write-import-linked-macro-runtime-source-project root))
                 (index
                  (collect-selected-source-scope root build-graph))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011" findings)))
            (check matching => [])))
(test-case "agent policy follows a quoted sibling import in a tested facade"
          (let* ((root ".run/policy-macro-runtime-source-sibling-import")
                 (build-graph
                  (write-import-linked-macro-runtime-source-project root))
                 (_ (write-text
                     (string-append root "/user-interface/facade.ss")
                     ";;; -*- Gerbil -*-\n(import \"order-case.ss\")\n(export order-case)\n"))
                 (index
                  (collect-selected-source-scope root build-graph))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011" findings)))
            (check matching => [])))
(test-case "agent policy accepts a colocated asserting suite"
          (let* ((root ".run/policy-macro-runtime-source-colocated-suite")
                 (build-graph
                  (write-import-linked-macro-runtime-source-project root))
                 (_ (write-text
                     (string-append root "/t/order-case-test.ss")
                     ";;; -*- Gerbil -*-\n(import :std/test)\n"))
                 (_ (write-text
                     (string-append root "/user-interface/parser-test.ss")
                     ";;; -*- Gerbil -*-\n(import :std/test \"facade.ss\")\n(def parser-test (test-suite \"colocated\" (test-case \"macro\" (check order-case => #!void))))\n"))
                 (index
                  (collect-selected-source-scope
                   root (append build-graph
                                ["user-interface/parser-test.ss"])))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-011" findings)))
            (check matching => [])))
(test-case "agent policy rejects an assertion owner without the macro call"
          (let* ((root ".run/policy-macro-runtime-source-wrong-owner")
                 (_ (write-macro-runtime-source-project root #t))
                 (_ (write-text
                     (string-append root "/t/macro-witness-test.ss")
                     ";;; -*- Gerbil -*-\n(import :std/test)\n(def macro-witness-test (test-suite \"macro witness\" (test-case \"no macro call\" (check #t => #t))))\n"))
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
(test-case "private empty hash index is storage rather than a domain object"
          (let* ((root ".run/policy-poo-private-index")
                 (src (string-append root "/src")))
            (reset-fixture-root root)
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/index)\n")
            (write-text
             (string-append src "/index.ss")
             ";;; -*- Gerbil -*-\n(import (only-in :clan/poo/object .o))\n(export index-result)\n(def (index-result rows)\n  (def (new-index) (make-hash-table))\n  (.o rows: rows index: (new-index)))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index)))
              (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-010" findings)
                     => []))))
(test-case "mutable hash populated by a domain constructor remains visible"
          (let* ((root ".run/policy-poo-mutable-domain-hash")
                 (src (string-append root "/src")))
            (reset-fixture-root root)
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/domain-hash)\n")
            (write-text
             (string-append src "/domain.ss")
             ";;; -*- Gerbil -*-\n(import (only-in :clan/poo/object .o))\n(export make-record)\n(def (make-record value)\n  (let (record (make-hash-table))\n    (hash-put! record 'value value)\n    record))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index)))
              (check (length (filter-rule "GERBIL-SCHEME-AGENT-POLICY-010"
                                          findings))
                     => 1))))
(test-case "agent policy accepts downstream POO pattern-guided implementation"
          (let* ((root ".run/policy-downstream-poo-agent-positive")
                 (_ (write-downstream-poo-agent-positive-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index)))
            (check findings => [])))
(test-case "gxtest adapter exposes downstream policy report"
          (let* ((root ".run/policy-downstream-poo-agent-gxtest")
                 (_ (write-downstream-poo-agent-positive-project root))
                 (files ["build.ss"
                         "src/orders/core.ss"
                         "src/orders/methods.ss"])
                 (report (project-policy-report root files))
                 (agent-repair (hash-get report 'agentRepair)))
            (check (project-policy-status root files) => "pass")
            (check (project-policy-findings root files) => [])
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
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :std/string/misc)\n(def (starts? value) (string-prefix? \"a\" value))\n")
            (write-text (string-append owner "/precise.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import (only-in :std/string/misc string-prefix?))\n(def (starts? value) (string-prefix? \"a\" value))\n")
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
