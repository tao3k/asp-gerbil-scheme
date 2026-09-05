;;; -*- Gerbil -*-
;;; Gerbil scheme harness list random access policy tests.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :policy/fixtures
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade)

(export agent-list-random-access-policy-test)

;; PolicyTest
(def agent-list-random-access-policy-test
  (test-suite "gerbil scheme harness list random access loop policy"
    (test-case "agent policy rejects list-ref inside an indexed loop"
      (let* ((root ".run/policy-list-random-access-loop")
             (source-dir (string-append root "/src/indexed")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/indexed)\n")
        (write-text
         (string-append source-dir "/select.ss")
         ";;; -*- Gerbil -*-\n(package: sample/indexed)\n(export select-indexes)\n(def (select-indexes values indexes)\n  (let loop ((remaining indexes) (out '()))\n    (if (null? remaining)\n      (reverse out)\n      (loop (cdr remaining)\n            (cons (list-ref values (car remaining)) out)))))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-041" findings))
               (finding (car matching))
               (details (type-finding-details finding)))
          (check (length matching) => 1)
          (check (type-finding-path finding) => "src/indexed/select.ss")
          (check (hash-get details 'kind) => "list-random-access-loop-performance")
          (check (hash-get details 'callee) => "list-ref")
          (check (hash-get details 'loopName) => "loop")
          (check (if (member "list-to-vector-boundary"
                             (hash-get details 'repairStrategies))
                   #t
                   #f)
                 => #t))))
    (test-case "agent policy accepts vector-ref after one vector boundary"
      (let* ((root ".run/policy-list-random-access-vector")
             (source-dir (string-append root "/src/indexed")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/indexed)\n")
        (write-text
         (string-append source-dir "/select.ss")
         ";;; -*- Gerbil -*-\n(package: sample/indexed)\n(export select-indexes)\n(def (select-indexes values indexes)\n  (let (indexed (list->vector values))\n    (let loop ((remaining indexes) (out '()))\n      (if (null? remaining)\n        (reverse out)\n        (loop (cdr remaining)\n              (cons (vector-ref indexed (car remaining)) out))))))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-041" findings)))
          (check matching => []))))
    (test-case "agent policy validates list random access scenario under performance gate"
      (let* ((scenario
              (make-policy-scenario
               "list-random-access-loop-performance"
               "t/scenarios/policy/list-random-access-loop-performance"))
             (timing (policy-scenario-run/timed scenario))
             (result (hash-get timing 'result))
             (benchmark-contract (hash-get timing 'benchmarkContract))
             (before-matching
              (policy-scenario-findings
               result
               'before
               "GERBIL-SCHEME-AGENT-POLICY-041"))
             (after-matching
              (policy-scenario-findings
               result
               'after
               "GERBIL-SCHEME-AGENT-POLICY-041"))
             (finding (car before-matching))
             (details (type-finding-details finding)))
        (check (hash-get timing 'schemaId)
               => "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
        (check (hash-get timing 'scenarioId)
               => "list-random-access-loop-performance")
        (check (hash-get timing 'performanceStatus) => "pass")
        (check (or (equal? (hash-get timing 'inputExpectedStatus) "pass")
                   (equal? (hash-get timing 'inputExpectedStatus)
                           "pass annotated"))
               => #t)
        (check (hash-get benchmark-contract 'feature)
               => "list-random-access-loop-performance")
        (check (hash-get benchmark-contract 'rule)
               => "GERBIL-SCHEME-AGENT-POLICY-041")
        (check (length before-matching) => 1)
        (check after-matching => [])
        (check (type-finding-path finding) => "src/indexed/select.ss")
        (check (hash-get details 'kind) => "list-random-access-loop-performance")
        (check (hash-get details 'callee) => "list-ref")))))
