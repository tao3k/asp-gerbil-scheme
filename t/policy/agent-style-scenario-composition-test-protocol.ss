;;; -*- Gerbil -*-
;;; gerbil scheme harness agent style scenario composition protocol policy.

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
(export agent-style-scenario-composition-protocol-policy-test)

;; PolicyTest
(def agent-style-scenario-composition-protocol-policy-test
  (test-suite "gerbil scheme harness agent style scenario composition protocol policy"
(test-case "agent policy validates destructuring combinator boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "destructuring-combinator-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "destructuring-combinator-boundary"
             "destructuring-combinator-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils" "gerbil-poo"]
             ["destructuring-combinator-boundary" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "temporary destructuring scaffolding to native match, selector, or syntax-local boundary")
            (check (agent-style-member?
                    "destructuring-combinator-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "replace repeated car/cdr/assq scaffolding with a named selector or match boundary"
                    (hash-get details 'destructuringBoundarySignals))
                   => #t)
            (check (agent-style-member?
                    "prefer native match/apply destructuring when it removes runtime probing"
                    (hash-get details 'destructuringBoundarySignals))
                   => #t)
            (check (agent-style-member?
                    "use syntax-local metadata lookup when the shape is known at expansion time"
                    (hash-get details 'destructuringBoundarySignals))
                   => #t)
            (check (hash-get details 'destructuringBoundaryTargets)
                   => ["render-event"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 2 5 7)
             (list 0 1 2 4))))
(test-case "agent policy validates pair tuple projection boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "pair-tuple-projection-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "pair-tuple-projection-boundary"
             "pair-tuple-projection-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils"]
             ["pair-tuple-projection-boundary"
              "gerbil-gambit-native-idiom"
              "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "cons-built Pair result protocol to values/call-with-values tuple projection")
            (check (agent-style-member?
                    "pair-tuple-projection-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "anonymous-result-protocol"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "replace cons-built Pair tuple returns with values/call-with-values when the pair is not the domain interface"
                    (hash-get details 'destructuringBoundarySignals))
                   => #t)
            (check (hash-get details 'destructuringBoundaryTargets)
                   => ["backend-values"])
            (check (agent-style-member?
                    "replace cons-built Pair tuple results with values/call-with-values unless pair/list protocol behavior is the public contract"
                    (hash-get details 'qualityFacetSteering))
                   => #t)))
(test-case "agent policy validates std sugar flow boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "std-sugar-flow-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "std-sugar-flow-boundary"
             "std-sugar-flow-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils"]
             ["std-sugar-flow-boundary"
              "gerbil-gambit-native-idiom"
              "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "nested let/if flow scaffolding to std/sugar chain and if-let")
            (check (hash-get benchmark-contract 'misuseGuard)
                   => "do not rewrite call-with-output-file or other resource/control boundaries into std/sugar expression flow")
            (check (agent-style-member?
                    "std-sugar-flow-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "replace nested let/if flow scaffolding with std/sugar chain when the data path is linear"
                    (hash-get details 'stdSugarFlowBoundarySignals))
                   => #t)
            (check (agent-style-member?
                    "use if-let or when-let when a conditional branch is just an early-failure binding"
                    (hash-get details 'stdSugarFlowBoundarySignals))
                   => #t)
            (check (hash-get details 'stdSugarFlowBoundaryTargets)
                   => ["workflow-status"])
            (check (agent-style-member?
                    "replace nested let/if flow scaffolding with std/sugar chain or if-let/when-let when parser facts show a local expression-flow boundary"
                    (hash-get details 'qualityFacetSteering))
                   => #t)))
(test-case "agent policy validates protocol serialization boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "protocol-serialization-boundary"))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "protocol-serialization-boundary"
             "protocol-serialization-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-poo" "gerbil-utils"]
             ["protocol-serialization-boundary" "anti-ai-scaffold"])
            (check (agent-style-member?
                    "protocol-serialization-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "split JSON/string/bytes/marshal representation layers"
                    (hash-get details 'serializationBoundarySignals))
                   => #t)
            (check (hash-get details 'serializationBoundaryTargets)
                   => ["encode-wire"])
            (check (agent-style-member?
                    "anti-ai-scaffold-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "replace one-owner protocol conversion scaffolding with local adapter boundaries"
                    (hash-get details 'antiAiScaffoldSignals))
                   => #t)
            (check (hash-get details 'antiAiScaffoldTargets)
                   => ["encode-wire"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 1)
             (list 0 2))))
  ))
