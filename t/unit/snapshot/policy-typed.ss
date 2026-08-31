;;; -*- Gerbil -*-
;;; Policy typed-combinator snapshot projections.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios)
(import :unit/snapshot/policy-support)
(export typed-combinator-style-policy-snapshot
        case-lambda-function-factory-policy-snapshot
        generator-combinator-policy-snapshot
        controlled-macro-syntax-policy-snapshot
        typeclass-algebra-policy-snapshot
        destructuring-combinator-boundary-policy-snapshot)

(def (typed-combinator-style-policy-snapshot)
  (typed-combinator-style-scenario-policy-snapshot
   "typed-combinator-style"
   "t/scenarios/policy/typed-combinator-style"))

(def (case-lambda-function-factory-policy-snapshot)
  (typed-combinator-style-scenario-policy-snapshot
   "case-lambda-function-factory"
   "t/scenarios/policy/case-lambda-function-factory"))

(def (generator-combinator-policy-snapshot)
  (typed-combinator-style-scenario-policy-snapshot
   "generator-combinator"
   "t/scenarios/policy/generator-combinator"))

(def (controlled-macro-syntax-policy-snapshot)
  (typed-combinator-style-scenario-policy-snapshot
   "controlled-macro-syntax"
   "t/scenarios/policy/controlled-macro-syntax"))

(def (typeclass-algebra-policy-snapshot)
  (typed-combinator-style-scenario-policy-snapshot
   "typeclass-algebra"
   "t/scenarios/policy/typeclass-algebra"))

(def (destructuring-combinator-boundary-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "destructuring-combinator-boundary"
           "t/scenarios/policy/destructuring-combinator-boundary"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-013"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-013")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding
                      (finding-snapshot-copy before-finding))
                (list 'destructuring
                      (list
                       (list 'qualityFacets
                             (hash-get before-details 'qualityFacets))
                       (list 'compositionShape
                             (hash-get before-details 'compositionShape))
                       (list 'destructuringBoundarySignals
                             (hash-get before-details
                                       'destructuringBoundarySignals))
                       (list 'destructuringBoundaryTargets
                             (hash-get before-details
                                       'destructuringBoundaryTargets)))))
          (list 'after
                (list 'r013Findings
                      (map finding-snapshot after-findings))))))
