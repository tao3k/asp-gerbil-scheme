;;; -*- Gerbil -*-
;;; gerbil scheme harness agent style scenario composition core policy.

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
(export agent-style-scenario-composition-core-policy-test)

;; PolicyTest
(def agent-style-scenario-composition-core-policy-test
  (test-suite "gerbil scheme harness agent style scenario composition core policy"
(test-case "agent policy validates generator control scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "generator-control-performance"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "generator-control-performance"
             "generator-control")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-utils"]
             ["generator-combinator-boundary" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "push/pull generator control inversion boundary")
            (check (agent-style-member?
                    "generator-combinator-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "generating-fold reducer"
                    (hash-get details 'generatorCombinatorSignals))
                   => #t)
            (check (hash-get details 'generatorContractTargets)
                   => ["sum-generated"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 1)
             (list 0 1))))
(test-case "agent policy validates list combinator boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "list-combinator-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "list-combinator-boundary"
             "list-combinator-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-utils"]
             ["list-combinator-boundary" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "manual list recursion to expression-level traversal boundary")
            (check (agent-style-member?
                    "list-combinator-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "replace hand-written list recursion scaffolding with map/filter/fold or a named reducer boundary"
                    (hash-get details 'listCombinatorBoundarySignals))
                   => #t)
            (check (hash-get details 'listCombinatorBoundaryTargets)
                   => ["render-active-orders"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 2 3)
             (list 0 1 2))))
(test-case "agent policy validates functional idiom scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "functional-idiom"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "functional-idiom"
             "functional-idiom")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils"]
             ["functional-idiom" "loop-driver-combinator-boundary" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "manual recursion to fold/pipeline and lambda-match boundary")
            (check (agent-style-member?
                    "gerbil://std/actor-v13/rpc/proto/cipher.ss#foldl-chunk-accumulator"
                    (hash-get benchmark-contract 'expectedReferenceExamples))
                   => #t)
            (check (agent-style-member?
                    "manual-loop-drift"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "replace manual loops with map/filter/filter-map/fold pipelines when parser facts show no IO/state/generator witness"
                    (hash-get details 'qualityFacetSteering))
                   => #t)
            (check (agent-style-member?
                    "replace pure named-let accumulator loops with map/filter/filter-map/fold when behavior is a data transform"
                    (hash-get details 'loopDriverCombinatorSignals))
                   => #t)
            (check (hash-get details 'loopDriverCombinatorTargets)
                   => ["total"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 2 3)
             (list 1 2 3 5 6))))
(test-case "agent policy validates wrapper lambda function factory scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "wrapper-lambda-function-factory"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "wrapper-lambda-function-factory"
             "wrapper-lambda-function-factory")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-utils"]
             ["wrapper-lambda-drift"
              "function-specialization-opportunity"
              "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "repeated wrapper lambdas to named specializer and factory boundaries")
            (check (agent-style-member?
                    "wrapper-lambda-drift"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "function-specialization-opportunity"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "extract repeated wrapper lambdas into a named factory, case-lambda function factory, curry/rcurry specializer, or compose/rcompose pipeline"
                    (hash-get details 'qualityFacetSteering))
                   => #t)
            (check (agent-style-member?
                    "repair anonymous specialization by introducing one first-class helper boundary before changing call sites"
                    (hash-get details 'qualityFacetSteering))
                   => #t)
            (agent-style-check-r013-quality-reference!
             context
             (list 0 2 3 4)
             (list 0 1 2 3))))
  ))
