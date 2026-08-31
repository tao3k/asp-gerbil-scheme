;;; -*- Gerbil -*-
;;; Gerbil scheme harness string growth policy tests.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :policy/fixtures
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade)

(export agent-string-growth-policy-test)

;; PolicyTest
(def agent-string-growth-policy-test
  (test-suite "gerbil scheme harness string growth loop policy"
    (test-case "agent policy rejects string-append inside a render loop"
      (let* ((root ".run/policy-string-growth-loop")
             (source-dir (string-append root "/src/reports")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/reports)\n")
        (write-text
         (string-append source-dir "/render.ss")
         ";;; -*- Gerbil -*-\n(package: sample/reports)\n(export render-lines)\n(def (render-lines lines)\n  (let loop ((remaining lines) (out \"\"))\n    (if (null? remaining)\n      out\n      (loop (cdr remaining)\n            (string-append out (car remaining) \"\\n\")))))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-042" findings))
               (finding (car matching))
               (details (type-finding-details finding)))
          (check (length matching) => 1)
          (check (type-finding-path finding) => "src/reports/render.ss")
          (check (hash-get details 'kind) => "string-growth-loop-performance")
          (check (hash-get details 'callee) => "string-append")
          (check (hash-get details 'loopName) => "loop")
          (check (if (member "output-string-port"
                             (hash-get details 'repairStrategies))
                   #t
                   #f)
                 => #t))))
    (test-case "agent policy accepts string-append at one final boundary"
      (let* ((root ".run/policy-string-growth-boundary")
             (source-dir (string-append root "/src/reports")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/reports)\n")
        (write-text
         (string-append source-dir "/render.ss")
         ";;; -*- Gerbil -*-\n(package: sample/reports)\n(export render-lines)\n(def (render-lines lines)\n  (string-append (string-join lines \"\\n\") \"\\n\"))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-042" findings)))
          (check matching => []))))
    (test-case "agent policy validates string append scenario under performance gate"
      (let* ((scenario
              (make-policy-scenario
               "string-append-loop-performance"
               "t/scenarios/policy/string-append-loop-performance"))
             (timing (policy-scenario-run/timed scenario))
             (result (hash-get timing 'result))
             (benchmark-contract (hash-get timing 'benchmarkContract))
             (before-matching
              (policy-scenario-findings
               result
               'before
               "GERBIL-SCHEME-AGENT-POLICY-042"))
             (after-matching
              (policy-scenario-findings
               result
               'after
               "GERBIL-SCHEME-AGENT-POLICY-042"))
             (finding (car before-matching))
             (details (type-finding-details finding)))
        (check (hash-get timing 'schemaId)
               => "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
        (check (hash-get timing 'scenarioId)
               => "string-append-loop-performance")
        (check (hash-get timing 'performanceStatus) => "pass")
        (check (or (equal? (hash-get timing 'inputExpectedStatus) "pass")
                   (equal? (hash-get timing 'inputExpectedStatus)
                           "pass annotated"))
               => #t)
        (check (hash-get benchmark-contract 'feature)
               => "string-append-loop-performance")
        (check (hash-get benchmark-contract 'rule)
               => "GERBIL-SCHEME-AGENT-POLICY-042")
        (check (length before-matching) => 1)
        (check after-matching => [])
        (check (type-finding-path finding) => "src/reports/render.ss")
        (check (hash-get details 'kind) => "string-growth-loop-performance")
        (check (hash-get details 'callee) => "string-append")))))
