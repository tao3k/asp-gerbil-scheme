;;; -*- Gerbil -*-
;;; Gerbil scheme harness policy source scope self-audit tests.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :policy/fixtures
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/types/facade)

(export agent-source-scope-policy-test)

;; PolicyTest
(def agent-source-scope-policy-test
  (test-suite "gerbil scheme harness policy source scope"
    (test-case "agent policy rejects policy path scope hardcoding"
      (let* ((root ".run/policy-source-scope-hardcoded")
             (source-dir (string-append root "/src/policy")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/policy-scope)\n")
        (write-text
         (string-append source-dir "/bad.ss")
         ";;; -*- Gerbil -*-\n(import (only-in :std/srfi/13 string-prefix?))\n(def (policy-file? path)\n  (not (string-prefix? \"t/scenarios/\" path)))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-021" findings))
               (finding (car matching))
               (details (type-finding-details finding)))
          (check (length matching) => 1)
          (check (type-finding-path finding) => "src/policy/bad.ss")
          (check (hash-get details 'kind) => "policy-source-scope")
          (check (hash-get details 'parserOwner) => "src/parser/source-class.ss"))))
    (test-case "agent policy accepts parser-owned source class scope"
      (let* ((root ".run/policy-source-scope-class")
             (source-dir (string-append root "/src/policy")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/policy-scope)\n")
        (write-text
         (string-append source-dir "/good.ss")
         ";;; -*- Gerbil -*-\n(import :asp-gerbil-scheme/src/parser/facade)\n(def (policy-file? path)\n  (not (equal? (source-path-class path) \"policy-scenario\")))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-021" findings)))
          (check matching => []))))
    (test-case "project policy uses explicit files without executing fixture build.ss"
      (let* ((root ".run/policy-source-scope-package-spec")
             (src-dir (string-append root "/src"))
             (test-dir (string-append root "/t")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src-dir)
        (ensure-dir test-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/package-spec-scope)\n")
        (write-text
         (string-append root "/build.ss")
         (string-append
          ";;; -*- Gerbil -*-\n"
          "(import :asp-gerbil-scheme/build-api\n"
          "        (only-in :std/build-script defbuild-script))\n"
          "(def +modules+ '(\"src/core.ss\"))\n"
          "(asp-gerbil-scheme-package-spec!\n"
          " (sample-package-spec @ asp-gerbil-scheme-library-package-prototype)\n"
          " (spec sample-build-spec)\n"
          " (modules +modules+))\n"
          "(defbuild-script (sample-build-spec))\n"))
        (write-text (string-append src-dir "/core.ss")
                    ";;; -*- Gerbil -*-\n(def core-value 1)\n")
        (write-text (string-append test-dir "/core-test.ss")
                    ";;; -*- Gerbil -*-\n(displayln \"explicit test script\")\n")
        (let* ((report (project-policy-report
                        root ["build.ss" "src/core.ss"]))
               (findings (hash-get report 'findings)))
          ;; Explicit policy evidence admits the declarative build.ss owner and
          ;; its declared library source without executing the script.
          (check (hash-get report 'files) => 2)
          (check (filter-rule "GERBIL-SCHEME-AGENT-POLICY-005" findings)
                 => []))))
    (test-case "selected source scope never reconstructs an import graph"
      (let* ((root ".run/policy-source-scope-depth-order")
             (src-dir (string-append root "/src"))
             (test-dir (string-append root "/t")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src-dir)
        (ensure-dir test-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/depth-order)\n")
        (write-text (string-append test-dir "/deep-test.ss")
                    ";;; -*- Gerbil -*-\n(import :sample/depth-order/a)\n")
        (write-text (string-append test-dir "/shallow-test.ss")
                    ";;; -*- Gerbil -*-\n(import :sample/depth-order/core)\n")
        (write-text (string-append src-dir "/a.ss")
                    ";;; -*- Gerbil -*-\n(import :sample/depth-order/core)\n")
        (write-text (string-append src-dir "/core.ss")
                    ";;; -*- Gerbil -*-\n(import :sample/depth-order/reader)\n")
        (write-text (string-append src-dir "/reader.ss")
                    ";;; -*- Gerbil -*-\n(def reader-value 1)\n")
        (let (paths
              (map source-file-path
                   (project-index-files
                    (collect-selected-source-scope
                     root
                     ["t/deep-test.ss" "t/shallow-test.ss"]))))
          (check paths => ["t/deep-test.ss" "t/shallow-test.ss"])
          (check (member "src/core.ss" paths) => #f)
          (check (member "src/reader.ss" paths) => #f))))
    (test-case "gxtest scoped policy uses explicit files"
      (let* ((root ".run/policy-source-scope-gxtest-files")
             (src-dir (string-append root "/src")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/gxtest-file-scope)\n")
        (write-text (string-append src-dir "/target.ss")
                    ";;; -*- Gerbil -*-\n(def target-value 1)\n")
        (write-text (string-append src-dir "/other.ss")
                    ";;; -*- Gerbil -*-\n(def other-value 1)\n")
        (let (report (policy-report root ["src/target.ss"]))
          (check (hash-get report 'scope) => "files")
          (check (hash-get report 'requestedFiles) => ["src/target.ss"])
          (check (hash-get report 'files) => 1))))))
