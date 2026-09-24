;;; -*- Gerbil -*-
;;; Syntax-local registry scenario policy.

(import :std/test
        "./agent-style-support")
(export agent-style-syntax-local-registry-policy-test)

;; PolicyTest
(def agent-style-syntax-local-registry-policy-test
  (test-suite "gerbil scheme harness syntax local registry policy"
    (test-case "agent policy validates syntax-local registry scenario under performance gate"
      (let* ((context
              (agent-style-policy-r013-scenario-context
               "syntax-local-registry-boundary"))
             (benchmark-contract (hash-get context 'benchmarkContract))
             (details (hash-get context 'details))
             (quality-reference (hash-get details 'qualityReference)))
        (agent-style-check-r013-scenario!
         context
         "syntax-local-registry-boundary"
         "syntax-local-registry-boundary")
        (agent-style-check-r013-scenario-learning!
         context
         ["gerbil://std/generic/macros.ss"
          "gerbil://std/protobuf/macros.ss"
          "gerbil://std/actor-v13/proto.ss"
          "harness-self-apply"]
         ["syntax-local-registry-boundary"
          "manual-syntax-registry-table"
          "syntax-datum-registry-key"
          "syntax-local-registry-lookup"
          "source-aware-syntax-error"])
        (check (hash-get benchmark-contract 'optimizationFocus)
               => "syntax->datum keyed compile-time hash registry to defsyntax metadata plus syntax-local-value")
        (check (agent-style-member?
                "syntax-local-registry-boundary"
                (hash-get details 'qualityFacets))
               => #t)
        (check (agent-style-member?
                "manual-syntax-registry-table"
                (hash-get details 'qualityFacets))
               => #t)
        (check (agent-style-member?
                "syntax-datum-registry-key"
                (hash-get details 'qualityFacets))
               => #t)
        (check (agent-style-member?
                "replace syntax->datum keyed macro hash registries with defsyntax metadata objects"
                (hash-get details 'syntaxLocalRegistrySignals))
               => #t)
        (check (agent-style-member?
                "def-flow-type"
                (hash-get details 'syntaxLocalRegistryTargets))
               => #t)
        (check (hash-get quality-reference 'referencePattern)
               => "gerbil-syntax-local-registry-boundary")
        (check (agent-style-member?
                "gerbil://std/generic/macros.ss#generic-info"
                (hash-get quality-reference 'referenceExamples))
               => #t)
        (check (agent-style-member?
                "gerbil://std/protobuf/macros.ss#syntax-local-type"
                (hash-get quality-reference 'referenceExamples))
               => #t)
        (check (agent-style-member?
                "syntax-local-registry-lookup"
                (hash-get quality-reference 'qualitySignals))
               => #t)
        (check (agent-style-member?
                "manual-syntax-registry-table"
                (hash-get quality-reference 'qualitySignals))
               => #t)))))
