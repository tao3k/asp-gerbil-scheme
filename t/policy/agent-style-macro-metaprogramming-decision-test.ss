;;; -*- Gerbil -*-
;;; Macro metaprogramming decision scenario policy.

(import :std/test
        "./agent-style-support")
(export agent-style-macro-metaprogramming-decision-policy-test)

;; PolicyTest
(def agent-style-macro-metaprogramming-decision-policy-test
  (test-suite "gerbil scheme harness macro metaprogramming decision policy"
    (test-case "agent policy validates macro metaprogramming decision scenario under performance gate"
      (let* ((context
              (agent-style-policy-r013-scenario-context
               "macro-metaprogramming-decision-boundary"))
             (benchmark-contract (hash-get context 'benchmarkContract))
             (details (hash-get context 'details))
             (quality-reference (hash-get details 'qualityReference)))
        (agent-style-check-r013-scenario!
         context
         "macro-metaprogramming-decision-boundary"
         "macro-metaprogramming-decision-boundary")
        (agent-style-check-r013-scenario-learning!
         context
         ["gerbil://" "gerbil-utils" "harness-self-apply"]
         ["macro-metaprogramming-decision-boundary"
          "declarative-macro-pattern"
          "procedural-macro-transformer"
          "syntax-object-validation"
          "identifier-reconstruction"
          "with-syntax-reconstruction"
          "source-aware-syntax-error"])
        (check (hash-get benchmark-contract 'optimizationFocus)
               => "AI repeated macro wrappers to one defrules family plus syntax-case only at the validation/source-error boundary")
        (check (agent-style-member?
                "macro-metaprogramming-decision-boundary"
                (hash-get details 'qualityFacets))
               => #t)
        (check (agent-style-member?
                "declarative-procedural-macro-selection"
                (hash-get details 'qualityFacets))
               => #t)
        (check (agent-style-member?
                "syntax-object-validation"
                (hash-get details 'qualityFacets))
               => #t)
        (check (agent-style-member?
                "identifier-reconstruction"
                (hash-get details 'qualityFacets))
               => #t)
        (check (agent-style-member?
                "with-syntax-reconstruction"
                (hash-get details 'qualityFacets))
               => #t)
        (check (agent-style-member?
                "choose defrules/syntax-rules for fixed grammar-like rewrites and repeated declaration families"
                (hash-get details 'macroMetaprogrammingDecisionSignals))
               => #t)
        (check (agent-style-member?
                "upgrade to syntax-case/with-syntax only when syntax-object validation, identifier reconstruction, or source-aware errors are required"
                (hash-get details 'macroMetaprogrammingDecisionSignals))
               => #t)
        (check (agent-style-member?
                "define-flow"
                (hash-get details 'macroMetaprogrammingDecisionTargets))
               => #t)
        (check (agent-style-member?
                "with-flow-field"
                (hash-get details 'macroMetaprogrammingDecisionTargets))
               => #t)
        (check (hash-get quality-reference 'referencePattern)
               => "gerbil-macro-metaprogramming-decision-boundary")
        (check (agent-style-member?
                "gerbil://gerbil/core/sugar.ss#defrules"
                (hash-get quality-reference 'referenceExamples))
               => #t)
        (check (agent-style-member?
                "gerbil://std/sugar.ss#let-hash"
                (hash-get quality-reference 'referenceExamples))
               => #t)
        (check (agent-style-member?
                "declarative-macro-pattern"
                (hash-get quality-reference 'qualitySignals))
               => #t)
        (check (agent-style-member?
                "procedural-macro-transformer"
                (hash-get quality-reference 'qualitySignals))
               => #t)
        (check (agent-style-member?
                "syntax-object-validation"
                (hash-get quality-reference 'qualitySignals))
               => #t)
        (check (agent-style-member?
                "identifier-reconstruction"
                (hash-get quality-reference 'qualitySignals))
               => #t)
        (check (agent-style-member?
                "with-syntax-reconstruction"
                (hash-get quality-reference 'qualitySignals))
               => #t)))))
