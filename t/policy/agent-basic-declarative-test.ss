;;; -*- Gerbil -*-
;;; gerbil scheme harness agent basic declarative policy.

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
(export agent-basic-declarative-policy-test)

;; PolicyTest
(def agent-basic-declarative-policy-test
  (test-suite "gerbil scheme harness agent basic declarative policy"
(test-case "agent policy treats FFI declare body as declarative range"
          (let* ((root ".run/policy-ffi-declare-declarative")
                 (_ (write-ffi-declare-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-005" findings)))
            (check matching => [])))
(test-case "agent policy treats POO declarative bodies as declarative ranges"
          (let* ((root ".run/policy-poo-declarative-range")
                 (_ (write-poo-declarative-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-005" findings)))
            (check matching => [])))
(test-case "agent policy treats user config and module object fragments as declarative"
      (let* ((root ".run/policy-agent-declarative-config")
             (src (string-append root "/src"))
             (owner (string-append src "/custom")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
        (ensure-dir owner)
        (write-text
         (string-append root "/gerbil.pkg")
         "(package: sample/agent-declarative-config)\n")
        (write-text
         (string-append owner "/config.ss")
         ";;; -*- Gerbil -*-\n(load! \"profiles/session\")\n(use-module nono-sandbox)\n")
        (write-text
         (string-append owner "/object1.ss")
         ";;; -*- Gerbil -*-\n(list\n (poo-flow-module-object\n  'demo\n  (list (poo-flow-module-field-contract 'name 'symbol))))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-005" findings)))
          (check matching => []))))
(test-case "agent policy treats single alist metadata files as declarative"
      (let* ((root ".run/policy-agent-declarative-alist-metadata")
             (src (string-append root "/src"))
             (owner (string-append src "/metadata")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
        (ensure-dir owner)
        (write-text
         (string-append root "/gerbil.pkg")
         "(package: sample/agent-declarative-alist-metadata)\n")
        (write-text
         (string-append owner "/benchmark.ss")
         ";;; -*- Gerbil -*-\n((max_total . 120ms)\n (maxCollectMs . 1000)\n (feature . flow-strand-registry-merge)\n (measurementPhases prepare-fixture measure-best assert-time-gate))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-005" findings)))
          (check matching => []))))
(test-case "agent policy treats begin-syntax as declarative expansion boundary"
      (let* ((root ".run/policy-agent-declarative-begin-syntax")
             (src (string-append root "/src"))
             (owner (string-append src "/macros")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
        (ensure-dir owner)
        (write-text
         (string-append root "/gerbil.pkg")
         "(package: sample/agent-declarative-begin-syntax)\n")
        (write-text
         (string-append owner "/syntax.ss")
         ";;; -*- Gerbil -*-\n(begin-syntax\n  (def (syntax-helper stx) stx))\n(defsyntax (identity-syntax stx) (syntax-case stx () ((_ value) (syntax value))))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-005" findings)))
          (check matching => []))))
  ))
