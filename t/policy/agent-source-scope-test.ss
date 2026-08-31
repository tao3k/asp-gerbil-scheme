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
    (test-case "parser reads package source coverage from build API and default tests"
      (let* ((root ".run/policy-source-scope-build-api")
             (src-dir (string-append root "/src"))
             (test-dir (string-append root "/t")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src-dir)
        (ensure-dir test-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/build-api-scope)\n")
        (write-text (string-append root "/build.ss")
                    ";;; -*- Gerbil -*-\n(import :asp-gerbil-scheme/src/build-api/source-coverage)\n(asp-gerbil-scheme-source-coverage\n roots: '(\"src\")\n runtime-roots: '(\"src\"))\n")
        (write-text (string-append src-dir "/core.ss")
                    ";;; -*- Gerbil -*-\n(def core-value 1)\n")
        (write-text (string-append test-dir "/root-test.ss")
                    ";;; -*- Gerbil -*-\n(import :std/test)\n(def root-test (test-suite \"root\"))\n")
        (let* ((index (collect-project root))
               (package (project-index-package index))
               (scope (project-package-source-scope-policy package))
               (paths (map source-file-path (project-index-files index))))
          (check (not (not (member "src/core.ss" paths))) => #t)
          (check (not (not (member "t/root-test.ss" paths))) => #t)
          (check (source-scope-policy-roots scope) => ["src"])
          (check (source-scope-policy-runtime-roots scope)
                 => ["src"]))))
    (test-case "test source scope re-expands a module reached later at a shallower depth"
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
                    (collect-test-source-scope
                     root
                     ["t/deep-test.ss" "t/shallow-test.ss"]))))
          (check (not (not (member "src/reader.ss" paths))) => #t))))
    (test-case "gxtest scoped policy intersects test files with source coverage"
      (let* ((root ".run/policy-source-scope-gxtest-files")
             (src-dir (string-append root "/src")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir src-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/gxtest-file-scope)\n")
        (write-text (string-append root "/build.ss")
                    ";;; -*- Gerbil -*-\n(import :asp-gerbil-scheme/src/build-api/source-coverage)\n(asp-gerbil-scheme-source-coverage roots: '(\"src\") runtime-roots: '(\"src\"))\n")
        (write-text (string-append src-dir "/target.ss")
                    ";;; -*- Gerbil -*-\n(def target-value 1)\n")
        (write-text (string-append src-dir "/other.ss")
                    ";;; -*- Gerbil -*-\n(def other-value 1)\n")
        (let (report (policy-report root ["src/target.ss"]))
          (check (hash-get report 'scope) => "files")
          (check (hash-get report 'requestedFiles) => ["src/target.ss"])
          (check (hash-get report 'files) => 1))))))
