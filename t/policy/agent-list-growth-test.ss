;;; -*- Gerbil -*-
;;; Gerbil scheme harness list growth loop policy tests.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :policy/fixtures
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade)

(export agent-list-growth-policy-test)

;; PolicyTest
(def agent-list-growth-policy-test
  (test-suite "gerbil scheme harness list growth loop policy"
    (test-case "agent policy rejects append inside a loop"
      (let* ((root ".run/policy-list-growth-loop")
             (source-dir (string-append root "/src/reports")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/reports)\n")
        (write-text
         (string-append source-dir "/merge.ss")
         ";;; -*- Gerbil -*-\n(package: sample/reports)\n(export merge-chunks)\n(def (merge-chunks chunks)\n  (let loop ((remaining chunks) (acc '()))\n    (if (null? remaining)\n      acc\n      (loop (cdr remaining)\n            (append acc (car remaining))))))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-039" findings))
               (finding (car matching))
               (details (type-finding-details finding)))
          (check (length matching) => 1)
          (check (type-finding-path finding) => "src/reports/merge.ss")
          (check (hash-get details 'kind) => "list-growth-loop-performance")
          (check (hash-get details 'callee) => "append")
          (check (hash-get details 'loopName) => "loop")
          (check (if (member "cons-reverse-once"
                             (hash-get details 'repairStrategies))
                   #t
                   #f)
                 => #t))))
    (test-case "agent policy accepts cons accumulator and one reverse boundary"
      (let* ((root ".run/policy-list-growth-accumulator")
             (source-dir (string-append root "/src/reports")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/reports)\n")
        (write-text
         (string-append source-dir "/merge.ss")
         ";;; -*- Gerbil -*-\n(package: sample/reports)\n(export merge-chunks)\n(def (merge-chunks chunks)\n  (let outer ((remaining chunks) (rev '()))\n    (if (null? remaining)\n      (reverse rev)\n      (let inner ((items (car remaining)) (next-rev rev))\n        (if (null? items)\n          (outer (cdr remaining) next-rev)\n          (inner (cdr items) (cons (car items) next-rev)))))))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-039" findings)))
          (check matching => []))))
    (test-case "agent policy validates list append loop scenario under performance gate"
      (let* ((scenario
              (make-policy-scenario
               "list-append-loop-performance"
               "t/scenarios/policy/list-append-loop-performance"))
             (timing (policy-scenario-run/timed scenario))
             (result (hash-get timing 'result))
             (benchmark-contract (hash-get timing 'benchmarkContract))
             (before-matching
              (policy-scenario-findings
               result
               'before
               "GERBIL-SCHEME-AGENT-POLICY-039"))
             (after-matching
              (policy-scenario-findings
               result
               'after
               "GERBIL-SCHEME-AGENT-POLICY-039"))
             (finding (car before-matching))
             (details (type-finding-details finding)))
        (check (hash-get timing 'schemaId)
               => "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
        (check (hash-get timing 'scenarioId) => "list-append-loop-performance")
        (check (hash-get timing 'performanceStatus) => "pass")
        (check (or (equal? (hash-get timing 'inputExpectedStatus) "pass")
                   (equal? (hash-get timing 'inputExpectedStatus)
                           "pass annotated"))
               => #t)
        (check (hash-get benchmark-contract 'feature)
               => "list-append-loop-performance")
        (check (hash-get benchmark-contract 'rule)
               => "GERBIL-SCHEME-AGENT-POLICY-039")
        (check (length before-matching) => 1)
        (check after-matching => [])
        (check (type-finding-path finding) => "src/reports/merge.ss")
        (check (hash-get details 'kind) => "list-growth-loop-performance")
        (check (hash-get details 'callee) => "append")
        (check (if (member "hash-index-with-ordered-keys"
                           (hash-get details 'repairStrategies))
                 #t
                 #f)
               => #t)))))
