;;; -*- Gerbil -*-
;;; gerbil scheme harness agent style functional branch policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        :std/sort
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-style
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(import :policy/agent-style-support)
(export agent-style-functional-branch-policy-test)

;; PolicyTest
(def agent-style-functional-branch-policy-test
  (test-suite "gerbil scheme harness agent style functional branch policy"
(test-case "agent policy reports nested conditional dispatch before launcher-style repair"
          (let* ((root ".run/policy-controlled-branch-conditional-dispatch")
                 (_ (write-controlled-branch-conditional-dispatch-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-014" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (hash-get (type-finding-details finding) 'shape)
                   => "nested-conditional-dispatch")
            (check (hash-get (type-finding-details finding) 'conditionalBranchCount)
                   => 4)
            (check (hash-get (type-finding-details finding) 'conditionalDispatchGate)
                   => 4)
            (check (not (not (string-contains
                              (type-finding-message finding)
                              "source-backed Gerbil idioms such as fun, cut/curry/rcurry, compose/rcompose, or named fallback helpers")))
                   => #t)))
(test-case "agent policy validates higher-order branch repair scenario under performance gate"
          (let* ((scenario
                  (make-policy-scenario
                   "controlled-branch-higher-order-performance"
                   "t/scenarios/policy/controlled-branch-higher-order-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (benchmark-contract
                  (hash-get timing 'benchmarkContract))
                 (max-total (hash-get timing 'max_total))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-POLICY-014"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-POLICY-014"))
                 (after-index (policy-scenario-index result 'after))
                 (after-file
                  (project-index-source-file-by-path
                   after-index
                   "src/orders/core.ss"))
                 (higher-order-roles
                  (source-file-higher-order-roles after-file)))
            (check (hash-get timing 'schemaId)
                   => "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
            (check (hash-get timing 'scenarioId)
                   => "controlled-branch-higher-order-performance")
            (check (length timings) => 4)
            (check (agent-style-policy-scenario-timing-steps-measured?
                    timings)
                   => #t)
            (check (hash-get benchmark-contract 'max_total) => '1s)
            (check (hash-get benchmark-contract 'feature)
                   => "typed-combinator-style")
            (check (hash-get benchmark-contract 'rule)
                   => "GERBIL-SCHEME-AGENT-POLICY-014")
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "higher-order branch repair")
            (check (hash-get timing 'benchmarkFeature)
                   => "typed-combinator-style")
            (check (hash-get timing 'benchmarkRule)
                   => "GERBIL-SCHEME-AGENT-POLICY-014")
            (check (hash-get timing 'optimizationFocus)
                   => "higher-order branch repair")
            (check max-total => '1s)
            (check (hash-get timing 'performanceStatus) => "pass")
            (check (length before-matching) => 1)
            (check after-matching => [])
            (check (not (not (member "pattern-matching-function"
                                     higher-order-roles)))
                   => #t)
            (check (not (not (member "named-lambda-abstraction"
                                     higher-order-roles)))
                   => #t)
            (check (not (not (member "function-composition"
                                     higher-order-roles)))
                   => #t)
            (check (not (not (member "function-curry"
                                     higher-order-roles)))
                   => #t)))
(test-case "agent policy reports match plus named-let selector shape before style repair"
          (let* ((root ".run/policy-controlled-branch-loop-shape")
                 (_ (write-controlled-branch-loop-shape-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-014" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-selector finding) => "src/orders/core.ss:5-12")
            (check (hash-get (type-finding-details finding) 'shape)
                   => "pattern-branch-with-manual-loop")
            (check (hash-get (type-finding-details finding) 'matchCount) => 1)
            (check (hash-get (type-finding-details finding) 'manualLoopCount) => 1)
            (check (not (not (string-contains
                              (type-finding-message finding)
                              "combines match state destructuring with a named-let loop")))
                   => #t)))
  ))
