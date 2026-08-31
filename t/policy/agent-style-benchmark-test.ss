;;; -*- Gerbil -*-
;;; gerbil scheme harness agent style benchmark policy.

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
(export agent-style-benchmark-policy-test)

;; PolicyTest
(def agent-style-benchmark-policy-test
  (test-suite "gerbil scheme harness agent style benchmark policy"
(test-case "policy scenario fixtures declare benchmark contracts"
          (check (agent-style-policy-scenario-missing-benchmarks) => []))
(test-case "typed-combinator-style self-apply keeps repaired owners clean"
          (let (index (collect-project "."))
            (for-each
             (lambda (path)
               (check (agent-style-policy-r013-findings-for-owner index path)
                      => []))
             +agent-style-policy-self-apply-r013-clean-owners+)))
(test-case "typed-combinator-style warns on anonymous result index protocols"
          (let* ((root ".run/policy-result-index-scaffold")
                 (src (string-append root "/src"))
                 (owner (string-append src "/demo"))
                 (path "src/demo/core.ss"))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/demo)\n(export unpack)\n;; unpack\n;;   : (-> Result (List Any))\n;;   | type Result = Vector\n;;   | doc m%\n;;       `unpack result` projects an anonymous result vector.\n;;     %\n(def (unpack result)\n  (list (vector-ref result 0)\n        (vector-ref result 1)))\n")
            (let* ((index (collect-project root))
                   (findings
                    (agent-style-policy-r013-findings-for-owner index path))
                   (finding (car findings))
                   (details (type-finding-details finding)))
              (check (length findings) => 1)
              (check (agent-style-member?
                      "result-index-scaffold"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "anonymous-result-protocol"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "replace anonymous vector-ref result/index protocols with values binding, named records, or a small domain object boundary"
                      (hash-get details 'qualityFacetSteering))
                     => #t))))
(test-case "agent policy validates gerbil upstream idiom performance scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "gerbil-upstream-idiom-performance"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference
                  (hash-get details 'qualityReference)))
            (agent-style-check-r013-scenario!
             context
             "gerbil-upstream-idiom-performance"
             "gerbil-upstream-idiom-performance")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "harness-self-apply"]
             ["gerbil-upstream-idiom-boundary"
              "match-shape-dispatch"
              "eq-hash-index-hot-path"
              "cut-helper-plumbing"
              "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'observed_total)
                   => '8.5ms)
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "basic Scheme route scaffolding to match dispatch, one eq-hash index, and cut-specialized traversal")
            (check (agent-style-member?
                    "gerbil-upstream-idiom-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "precompute make-hash-table-eq indexes when symbol or identifier lookup repeats in a hot traversal"
                    (hash-get details 'gerbilUpstreamIdiomSignals))
                   => #t)
            (check (agent-style-member?
                    "route-events"
                    (hash-get details 'gerbilUpstreamIdiomTargets))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-upstream-idiom-performance")
            (check (agent-style-member?
                    "gerbil://gerbil/compiler/optimize-spec.ss#make-hash-table-eq-method-calls"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "eq-hash-index-hot-path"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)))
(test-case "agent policy validates macro family thin wrapper scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "macro-family-thin-wrapper"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "macro-family-thin-wrapper"
             "macro-family-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils" "poo-flow"]
             ["macro-family-boundary" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "collapse repeated same-prefix macro wrappers into one hygienic family helper")
            (check (agent-style-member?
                    "macro-family-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "collapse repeated same-prefix macro wrappers into one macro family helper"
                    (hash-get details 'macroFamilySignals))
                   => #t)
            (check (agent-style-member?
                    "prefer a syntax-rules family table or stx helper over copy-pasted defrules"
                    (hash-get details 'macroFamilySignals))
                   => #t)
            (check (hash-get details 'macroFamilyTargets)
                   => ["defpoo-flow"])
            (check (agent-style-member?
                    "collapse repeated same-prefix thin macros into one hygienic macro family helper or table, then keep runtime behavior in ordinary functions"
                    (hash-get details 'qualityFacetSteering))
                   => #t)
            (agent-style-check-r013-quality-reference!
             context
             (list 0 1)
             (list 0 1))))
  ))
