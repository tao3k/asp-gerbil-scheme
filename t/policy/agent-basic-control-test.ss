;;; -*- Gerbil -*-
;;; gerbil scheme harness agent basic control policy.

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
(export agent-basic-control-policy-test)

;; PolicyTest
(def agent-basic-control-policy-test
  (test-suite "gerbil scheme harness agent basic control policy"
(test-case "agent policy preserves stateful named-let mutation loops"
      (let* ((root ".run/policy-agent-stateful-loop-driver")
             (src (string-append root "/src"))
             (owner (string-append src "/stateful")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
        (ensure-dir owner)
        (write-text
         (string-append root "/gerbil.pkg")
         "(package: sample/agent-stateful-loop-driver)\n")
        (write-text
         (string-append owner "/core.ss")
         ";;; -*- Gerbil -*-\n(def (dedupe values)\n  (let (seen (make-hash-table))\n    (let loop ((rest values) (out '()))\n      (cond\n       ((null? rest) (reverse out))\n       ((hash-get seen (car rest)) (loop (cdr rest) out))\n       (else\n        (hash-put! seen (car rest) #t)\n        (loop (cdr rest) (cons (car rest) out)))))))\n")
        (let* ((index (collect-project root))
               (findings (run-policy-checks index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-009" findings)))
          (check matching => []))))
(test-case "agent policy preserves stateful conditional hot paths"
      (let* ((root ".run/policy-agent-stateful-branch-driver")
             (src (string-append root "/src"))
             (owner (string-append src "/stateful")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
        (ensure-dir owner)
        (write-text
         (string-append root "/gerbil.pkg")
         "(package: sample/agent-stateful-branch-driver)\n")
        (write-text
         (string-append owner "/core.ss")
         ";;; -*- Gerbil -*-\n;;; Boundary: this owner keeps hash mutation explicit for a hot merge path.\n;; : (-> List List)\n(def (merge-values values)\n  (let (seen (make-hash-table))\n    (map (lambda (value)\n           (cond\n            ((not value) #f)\n            ((hash-get seen value) value)\n            ((symbol? value) (begin (hash-put! seen value #t) value))\n            ((pair? value) (begin (hash-put! seen value #t) value))\n            (else value)))\n         values)))\n")
        (let* ((index (collect-project root))
               (findings (run-policy-checks index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-014" findings)))
          (check matching => []))))
(test-case "agent policy keeps positive combinator owners out of broad style warnings"
      (let* ((root ".run/policy-agent-positive-combinator-style")
             (src (string-append root "/src"))
             (owner (string-append src "/style")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
        (ensure-dir owner)
        (write-text
         (string-append root "/gerbil.pkg")
         "(package: sample/agent-positive-combinator-style)\n")
        (write-text
         (string-append owner "/core.ss")
         ";;; -*- Gerbil -*-\n;;; Boundary: sequence helpers stay expression-level and data-only.\n;; : (-> List List)\n(def (positive-symbols values)\n  (filter symbol? values))\n")
        (let* ((index (collect-project root))
               (findings (run-policy-checks index))
               (r013 (filter-rule "GERBIL-SCHEME-AGENT-POLICY-013" findings))
               (r015 (filter-rule "GERBIL-SCHEME-AGENT-POLICY-015" findings)))
          (check r013 => [])
          (check r015 => []))))
(test-case "agent policy ignores begin-syntax named-let loop drivers"
      (let* ((root ".run/policy-agent-begin-syntax-loop-driver")
             (src (string-append root "/src"))
             (owner (string-append src "/macros")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
        (ensure-dir owner)
        (write-text
         (string-append root "/gerbil.pkg")
         "(package: sample/agent-begin-syntax-loop-driver)\n")
        (write-text
         (string-append owner "/syntax.ss")
         ";;; -*- Gerbil -*-\n(begin-syntax\n  (def (syntax-list->list stx)\n    (let loop ((rest stx) (out '()))\n      (syntax-case rest ()\n        (() (reverse out))\n        ((head . tail)\n         (loop (syntax tail) (cons (syntax head) out)))\n        (_ #f)))))\n")
        (let* ((index (collect-project root))
               (findings (run-policy-checks index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-009" findings)))
          (check matching => []))))
(test-case "agent policy allows direct imports when they are public re-exports"
      (let* ((root ".run/policy-agent-import-reexport")
             (src (string-append root "/src"))
             (direct (string-append src "/direct"))
             (reexport (string-append src "/reexport")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
        (ensure-dir direct)
        (ensure-dir reexport)
        (write-text
         (string-append root "/gerbil.pkg")
         "(package: sample/agent-import-reexport)\n")
        (write-text
         (string-append direct "/core.ss")
         ";;; -*- Gerbil -*-\n(import :clan/poo/object)\n(def value (.o name: 'direct))\n")
        (write-text
         (string-append reexport "/interface.ss")
         ";;; -*- Gerbil -*-\n(import :clan/poo/object)\n(export #t (import: :clan/poo/object))\n(def value (.o name: 'reexport))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-018" findings)))
          (check (length matching) => 1)
          (check (type-finding-path (car matching)) => "src/direct/core.ss"))))
(test-case "package build policy accepts named std make build-spec helpers"
      (let* ((root ".run/policy-package-build-named-std-make-spec")
             (src (string-append root "/src")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src)
        (write-text
         (string-append root "/gerbil.pkg")
         "(package: sample/package-build-named-std-make-spec)\n")
        (write-text
         (string-append src "/core.ss")
         ";;; -*- Gerbil -*-\n(export value)\n(def value 1)\n")
        (write-text
         (string-append root "/build.ss")
         "#!/usr/bin/env gxi\n;;; -*- Gerbil -*-\n(import (only-in :std/make make))\n(def sample-build-spec '((gxc: \"src/core\")))\n(def (main . args) (apply make sample-build-spec srcdir: \".\" []))\n(apply main (cdr (command-line)))\n")
        (let* ((index (collect-project root))
               (findings (run-policy-checks index))
               (r020 (filter-rule "GERBIL-SCHEME-AGENT-POLICY-020" findings))
               (r025 (filter-rule "GERBIL-SCHEME-AGENT-POLICY-025" findings)))
          (check r020 => [])
          (check r025 => []))))
  ))
