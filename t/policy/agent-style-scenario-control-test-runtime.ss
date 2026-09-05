;;; -*- Gerbil -*-
;;; gerbil scheme harness agent style scenario control runtime policy.

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
(export agent-style-scenario-control-runtime-policy-test)

;; PolicyTest
(def agent-style-scenario-control-runtime-policy-test
  (test-suite "gerbil scheme harness agent style scenario control runtime policy"
(test-case "agent policy validates compiler method-pass scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "compiler-method-pass-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference
                  (hash-get details 'qualityReference)))
            (agent-style-check-r013-scenario!
             context
             "compiler-method-pass-boundary"
             "compiler-method-pass-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "harness-self-apply"]
             ["compiler-method-pass-boundary"
              "method-table-pass-boundary"
              "gerbil-gambit-native-idiom"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "method-table lambda drift to compiler-style pass handlers")
            (check (agent-style-member?
                    "method-table-lambda-drift"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-compiler-method-pass-boundary")
            (check (agent-style-member?
                    "gerbil://gerbil/compiler/method.ss#defcompile-method"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "gerbil://gerbil/compiler/optimize-top.ss#dispatch-lambda-form?"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "method-table-pass-boundary"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "ast-case-shape-dispatch"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "repair method-table lambdas by extracting slot-shaped helpers, compiler-style AST pass handlers, or cut/curry/compose adapters while preserving the receiver/protocol boundary"
                    (hash-get details 'qualityFacetSteering))
                   => #t)))
(test-case "agent policy validates Gambit numeric primitive scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "gambit-fixnum-flonum-arithmetic-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference)))
            (agent-style-check-r013-scenario!
             context
             "gambit-fixnum-flonum-arithmetic-boundary"
             "gambit-fixnum-flonum-arithmetic-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gambit://tests/unit-tests/01-fixnum/fxadd.scm"
              "gambit://tests/unit-tests/02-flonum/fladd.scm"]
             ["gambit-numeric-primitives"
              "typed-hot-loop-boundary"
              "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "fixnum/flonum primitive arithmetic with checked boundary tests")
            (check (agent-style-member?
                    "gambit-numeric-primitive-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "generic-numeric-hot-loop"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gambit-numeric-primitive-domain-boundary")
            (check (agent-style-member?
                    "gambit://tests/unit-tests/01-fixnum/fxadd.scm#fixnum-overflow-exception"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "hot-loop-primitive-family"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "when parser facts show a numeric hot loop with generic arithmetic, state the fixnum/flonum domain at the boundary, keep overflow/type behavior tested, and use Gambit fx/fl primitive families only inside that proven lane"
                    (hash-get details 'qualityFacetSteering))
                   => #t)))
(test-case "agent policy validates Gerbil inline-rule call-shape scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "gerbil-inline-rule-call-shape"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference)))
            (agent-style-check-r013-scenario!
             context
             "gerbil-inline-rule-call-shape"
             "gerbil-inline-rule-call-shape")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://gerbil/builtin-inline-rules.ssxi.ss"
              "gerbil://gerbil/compiler/optimize-top.ss"]
             ["builtin-inline-rule-shape"
              "dispatch-lambda-form"
              "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "compiler-recognizable inline primitive call shape")
            (check (agent-style-member?
                    "gerbil-inline-rule-call-shape"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "dynamic-apply-hot-loop"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-builtin-inline-rule-call-shape")
            (check (agent-style-member?
                    "gerbil://gerbil/builtin-inline-rules.ssxi.ss#ast-rules"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "no-dynamic-apply"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "when parser facts show repeated dynamic apply in a hot loop, keep primitive targets lexical and direct so Gerbil builtin inline rules and unchecked call optimization can see the call shape"
                    (hash-get details 'qualityFacetSteering))
                   => #t)))
(test-case "agent policy validates macro phase optimizer-visible scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "macro-phase-optimizer-visible-fast-path"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference)))
            (agent-style-check-r013-scenario!
             context
             "macro-phase-optimizer-visible-fast-path"
             "macro-phase-optimizer-visible-fast-path")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://README.md"
              "gerbil://gerbil/expander/top.ss"
              "gerbil://gerbil/compiler/ssxi.ss"
              "gerbil://gerbil/compiler/optimize-call.ss"]
             ["phase-aware-macro-dsl"
              "generated-runtime-helper"
              "known-procedure-call-fast-path"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "macro-generated runtime helpers that preserve lexical direct calls")
            (check (agent-style-member?
                    "macro-phase-optimizer-visible-fast-path"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "phase-macro-generated-wrapper"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "macro-phase-optimizer-visible-fast-path")
            (check (agent-style-member?
                    "gerbil://gerbil/expander/top.ss#begin-syntax-phi-plus-one"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "optimizer-visible-call-shape"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "when a macro DSL generates runtime hot paths, keep the macro surface thin but generate lexical direct helpers so SSXI metadata and known-call optimization can still see the call boundary"
                    (hash-get details 'qualityFacetSteering))
                   => #t)))
(test-case "agent policy validates exception continuation scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "exception-continuation-boundary"))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "exception-continuation-boundary"
             "exception-continuation-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-utils"]
             ["exception-continuation-boundary" "anti-ai-scaffold"])
            (check (agent-style-member?
                    "exception-continuation-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "log exception context before re-raising"
                    (hash-get details 'exceptionContinuationBoundarySignals))
                   => #t)
            (check (hash-get details
                             'exceptionContinuationBoundaryTargets)
                   => ["run-checked"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 1)
             (list 0 2))))
(test-case "agent policy validates source form reader boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "source-form-reader-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "source-form-reader-boundary"
             "source-form-reader-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://src/testing/gxtest-runner.ss"
              "harness-self-apply"]
             ["reader-collection-boundary"
              "source-form-reader-boundary"
              "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "inline source reader and mixed selection loops to read-forms port helper, source-forms file boundary, and filter-map projection")
            (check (agent-style-member?
                    "reader-collection-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "source-form-reader-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (hash-get details 'loopDriverCombinatorTargets)
                   => ["source-forms" "local-def-symbols"])
            (check (agent-style-member?
                    "split source/form reader loops from selector or projection helpers, then compose the caller with filter-map/map/fold"
                    (hash-get details 'loopDriverCombinatorSignals))
                   => #t)
            (check (agent-style-member?
                    "when a reader loop also does selection or projection, split a source/form reader helper and compose the public function with filter-map/map/fold"
                    (hash-get details 'qualityFacetSteering))
                   => #t)))
  ))
