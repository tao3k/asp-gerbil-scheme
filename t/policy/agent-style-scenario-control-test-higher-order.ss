;;; -*- Gerbil -*-
;;; Higher-order scenario control policy.

(import :std/test
        :policy/agent-style-support
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/parser/facade)
(export agent-style-scenario-control-higher-order-policy-test)

;; PolicyTest
(def agent-style-scenario-control-higher-order-policy-test
  (test-suite "agent style higher-order scenario control policy"
(test-case "agent policy validates higher-order composition scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "higher-order-composition-performance"))
                 (result (hash-get context 'result))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference))
                 (after-index (policy-scenario-index result 'after))
                 (after-file
                  (project-index-source-file-by-path
                   after-index
                   "src/orders/core.ss"))
                 (higher-order-roles
                  (source-file-higher-order-roles after-file)))
            (agent-style-check-r013-scenario!
             context
             "higher-order-composition-performance"
             "higher-order-composition")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils"]
             ["higher-order-composition" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "wrapper lambda to composition boundary")
            (check (agent-style-member?
                    "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
                    (hash-get benchmark-contract 'expectedReferenceExamples))
                   => #t)
            (check (agent-style-member?
                    "cut-prefix-predicate"
                    (hash-get benchmark-contract 'expectedQualitySignals))
                   => #t)
            (check (agent-style-member?
                    "wrapper-lambda-drift"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "function-specialization-opportunity"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-utils-higher-order-expression")
            (check (agent-style-member?
                    "gerbil-utils/base.ss#left-to-right"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "cut-prefix-predicate"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "thin-wrapper-elimination"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member? "function-composition" higher-order-roles)
                   => #t)))
(test-case "agent policy validates case-lambda function factory scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "case-lambda-function-factory"))
                 (result (hash-get context 'result))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference))
                 (after-index (policy-scenario-index result 'after))
                 (after-file
                  (project-index-source-file-by-path
                   after-index
                   "src/orders/core.ss"))
                 (higher-order-roles
                  (source-file-higher-order-roles after-file)))
            (agent-style-check-r013-scenario!
             context
             "case-lambda-function-factory"
             "case-lambda-function-factory")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-utils"]
             ["case-lambda-function-factory" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "case-lambda arity-specialized function factory")
            (check (agent-style-member?
                    "gerbil-utils/base.ss#case-lambda specializers"
                    (hash-get benchmark-contract 'expectedReferenceExamples))
                   => #t)
            (check (agent-style-member?
                    "multi-arity-abstraction"
                    (hash-get benchmark-contract 'expectedQualitySignals))
                   => #t)
            (check (agent-style-member?
                    "wrapper-lambda-drift"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "function-specialization-opportunity"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-utils-higher-order-expression")
            (check (agent-style-member?
                    "gerbil-utils/base.ss#case-lambda specializers"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "multi-arity-abstraction"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "multi-arity-function"
                    higher-order-roles)
                   => #t)))
  ))
