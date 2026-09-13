;;; -*- Gerbil -*-
;;; gerbil scheme harness agent style scenario control branch policy.

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
(export agent-style-scenario-control-branch-policy-test)

;; PolicyTest
(def agent-style-scenario-control-branch-policy-test
  (test-suite "gerbil scheme harness agent style scenario control branch policy"
(test-case "agent policy validates concurrency control boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "concurrency-control-boundary"))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "concurrency-control-boundary"
             "concurrency-control-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils"]
             ["concurrency-control-boundary" "anti-ai-scaffold"])
            (check (agent-style-member?
                    "concurrency-control-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "split spawn/join/mutex/race responsibilities"
                    (hash-get details 'concurrencyControlBoundarySignals))
                   => #t)
            (check (agent-style-member?
                    "preserve reentry guards and cleanup around dynamic-wind/unwind boundaries"
                    (hash-get details 'concurrencyControlBoundarySignals))
                   => #t)
            (check (hash-get details 'concurrencyControlBoundaryTargets)
                   => ["run-jobs"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 2 3)
             (list 0 1 3))))
(test-case "agent policy validates typeclass wrapper adapter scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "typeclass-wrapper-adapter"))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "typeclass-wrapper-adapter"
             "typeclass-wrapper-adapter")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-poo"]
             ["poo-typeclass-algebra-boundary" "anti-ai-scaffold"])
            (check (agent-style-member?
                    "poo-typeclass-algebra-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "methods.io<-wrap lifts IO/JSON/bytes/marshal through wrap/unwrap"
                    (hash-get details 'typeclassAlgebraSignals))
                   => #t)
            (check (hash-get details 'typeclassAlgebraTargets)
                   => ["WrappedCodec."])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 2)
             (list 0 2))))
(test-case "agent policy validates slot lens boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "slot-lens-boundary"))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "slot-lens-boundary"
             "slot-lens-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-poo"]
             ["slot-lens-boundary" "anti-ai-scaffold"])
            (check (agent-style-member?
                    "slot-lens-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "introduce local slot descriptor or lens helpers"
                    (hash-get details 'slotLensBoundarySignals))
                   => #t)
            (check (hash-get details 'slotLensBoundaryTargets)
                   => ["rename-widget"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 2)
             (list 0 2))))
(test-case "agent policy validates Gerbil native interface contract scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "gerbil-interface-contract-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "gerbil-interface-contract-boundary"
             "gerbil-interface-contract-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "harness-self-apply"]
             ["gerbil-interface-contract-boundary"
              "slot-lens-boundary"
              "gerbil-gambit-native-idiom"
              "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "Gerbil native using/interface contract boundary")
            (check (agent-style-member?
                    "gerbil://gerbil/core/contract.ss#using-class-interface-boundary"
                    (hash-get benchmark-contract 'expectedReferenceExamples))
                   => #t)
            (check (agent-style-member?
                    "slot-lens-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "use Gerbil `using (value :- Type)` when repeated slot access has a known local class or interface descriptor"
                    (hash-get details 'slotLensBoundarySignals))
                   => #t)
            (check (agent-style-member?
                    "model descriptor state as a small defclass/defstruct before adding ad hoc get/set branches"
                    (hash-get details 'slotLensBoundarySignals))
                   => #t)
            (check (hash-get details 'slotLensBoundaryTargets)
                   => ["update-widget"])
            (check (agent-style-member?
                    "when one owner mixes slot/get/set/modify/validation responsibilities, introduce local lens or slot descriptor helpers; use Gerbil `using (value :- Type)` for known class/interface descriptors and keep validation at the update boundary without requiring gerbil-poo or gerbil-utils dependencies"
                   (hash-get details 'qualityFacetSteering))
                   => #t)
            (agent-style-check-r013-quality-reference!
             context
             (list 0 1 2)
             (list 0 1 2))))
  ))
