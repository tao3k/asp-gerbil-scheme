;;; -*- Gerbil -*-
;;; Syntax-parameterized macro context scenario policy.

(import :std/test
        "./agent-style-support")
(export agent-style-syntax-parameter-context-policy-test)

;; PolicyTest
(def agent-style-syntax-parameter-context-policy-test
  (test-suite "gerbil scheme harness syntax parameter context policy"
    (test-case "agent policy validates syntax-parameterized context scenario under performance gate"
      (let* ((context
              (agent-style-policy-r013-scenario-context
               "syntax-parameterized-context-boundary"))
             (benchmark-contract (hash-get context 'benchmarkContract))
             (details (hash-get context 'details))
             (quality-reference (hash-get details 'qualityReference)))
        (agent-style-check-r013-scenario!
         context
         "syntax-parameterized-context-boundary"
         "syntax-parameterized-context-boundary")
        (agent-style-check-r013-scenario-learning!
         context
         ["gerbil://std/stxparam.ss"
          "gerbil://std/text/csv.ss"
          "gerbil://std/actor-v18/message.ss"
          "harness-self-apply"]
         ["syntax-parameterized-context-boundary"
          "syntax-parameter-definition"
          "syntax-parameterized-context"
          "global-macro-state-mutation"
          "manual-phase-context-threading"
          "source-aware-syntax-error"])
        (check (hash-get benchmark-contract 'optimizationFocus)
               => "mutable compile-time macro globals to defsyntax-parameter* plus syntax-parameterize")
        (check (agent-style-member?
                "syntax-parameterized-context-boundary"
                (hash-get details 'qualityFacets))
               => #t)
        (check (agent-style-member?
                "global-macro-state-mutation"
                (hash-get details 'qualityFacets))
               => #t)
        (check (agent-style-member?
                "manual-phase-context-threading"
                (hash-get details 'qualityFacets))
               => #t)
        (check (agent-style-member?
                "replace mutable compile-time globals with defsyntax-parameter* and syntax-parameterize"
                (hash-get details 'syntaxParameterContextSignals))
               => #t)
        (check (agent-style-member?
                "with-flow-context"
                (hash-get details 'syntaxParameterContextTargets))
               => #t)
        (check (hash-get quality-reference 'referencePattern)
               => "gerbil-syntax-parameterized-context-boundary")
        (check (agent-style-member?
                "gerbil://std/stxparam.ss#defsyntax-parameter"
                (hash-get quality-reference 'referenceExamples))
               => #t)
        (check (agent-style-member?
                "gerbil://std/stxparam.ss#syntax-parameterize"
                (hash-get quality-reference 'referenceExamples))
               => #t)
        (check (agent-style-member?
                "syntax-parameter-definition"
                (hash-get quality-reference 'qualitySignals))
               => #t)
        (check (agent-style-member?
                "syntax-parameterized-context"
                (hash-get quality-reference 'qualitySignals))
               => #t)))))
