;;; -*- Gerbil -*-
;;; gerbil scheme harness agent style functional core policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        :std/sort
        (only-in :std/text/json read-json)
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-style
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(import :policy/agent-style-support)
(export agent-style-functional-core-policy-test)

;; PolicyTest
(def agent-style-functional-core-policy-test
  (test-suite "gerbil scheme harness agent style functional core policy"
(test-case "agent policy warns on manual loops that should use functional idioms"
          (let* ((root ".run/policy-functional-idiom")
                 (_ (write-functional-idiom-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-009" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-severity finding) => "warning")
            (check (type-status matching) => "fail")
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-selector finding) => "src/orders/core.ss:5-6")
            (check (not (not (string-contains
                              (type-finding-message finding)
                              "redundant pure transform")))
                   => #t)
            (check (hash-get (type-finding-details finding) 'kind)
                   => "named-let")
            (check (hash-get (type-finding-details finding) 'namedLetPolicy)
                   => "warn-on-redundant-pure-transform-only")
            (check (hash-get (type-finding-details finding) 'detectionSignals)
                   => ["named-let"
                       "manual-loop-role"
                       "multi-binding-loop-state"
                       "no-functional-idiom-witness"
                       "no-reader-boundary"
                       "no-control-preservation-context"])
            (check (hash-get (type-finding-details finding) 'sequenceIdioms)
                   => ["map" "filter" "filter-map" "append-map" "fold/foldl/foldr" "for/fold"])
            (check (hash-get (type-finding-details finding) 'predicateIdioms)
                   => ["andmap/ormap" "every/any" "find/list-index"])
            (check (hash-get (type-finding-details finding) 'compositionIdioms)
                   => ["cut/cute" "curry/rcurry" "compose/compose1" "!>/!!>"])
            (check (hash-get (type-finding-details finding) 'nativeLambdaIdioms)
                   => ["fun" "lambda-match/λ-match" "λ" "case-lambda"])
            (check (hash-get (type-finding-details finding) 'typeclassIdioms)
                   => ["gerbil-poo/fun.ss Category." "Functor."
                       "ParametricFunctor." "Wrapper./Wrap."
                       "methods.table protocol slots"])
            (check (hash-get (type-finding-details finding) 'builderIdioms)
                   => ["with-list-builder"])
            (check (hash-get (type-finding-details finding) 'styleGuide)
                   => "typed-combinator-style")
            (check (hash-get (type-finding-details finding) 'styleCommand)
                   => "asp gerbil-scheme guide --code --topic typed-combinator-style --intent style")
            (check (hash-get (type-finding-details finding) 'detectedControlContexts)
                   => [])
            (check (hash-get (type-finding-details finding) 'callerControlContexts)
                   => [])
            (check (hash-get (type-finding-details finding) 'keepNamedLetWhen)
                   => "IO/stateful control flow, C3-style fixpoint selection, or generator/continuation driver")
            (check (not (not (string-contains
                              (hash-get (type-finding-details finding)
                                        'learnedFrom)
                              "gerbil-poo/fun.ss")))
                   => #t)
            (check (hash-get (type-finding-details finding) 'preserveNamedLetWhen)
                   => ["local recursion without accumulator boilerplate"
                       "reader or port EOF loops"
                       "stateful control flow"
                       "C3-style fixpoint selection"
                       "generator, coroutine, actor, or continuation driver"])))
(test-case "agent policy preserves focused named-let recursion"
          (let* ((root ".run/policy-functional-idiom-focused-named-let")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append owner "/facade.ss")
                        ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export resolve)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export resolve)\n;; : (-> Node Node)\n(def (resolve node)\n  (let walk ((current node))\n    (if (node-final? current)\n      current\n      (walk (node-parent current)))))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-009" findings)))
              (check matching => []))))
(test-case "agent policy check output routes findings to guide code"
          (let* ((root ".run/policy-functional-idiom-check-output")
                 (_ (write-functional-idiom-project root)))
            (match (policy-check-output [root])
              ([exit-code . output]
               (check exit-code => 1)
               (let* ((packet (call-with-input-string output read-json))
                      (repair (hash-get packet "agentRepair"))
                      (findings (hash-get packet "findings"))
                      (r009 (hash-get
                             (json-finding-by-rule
                              findings "GERBIL-SCHEME-AGENT-POLICY-009")
                             "agentRepair"))
                      (r013 (hash-get
                             (json-finding-by-rule
                              findings "GERBIL-SCHEME-AGENT-POLICY-013")
                             "agentRepair"))
                      (r015 (hash-get
                             (json-finding-by-rule
                              findings "GERBIL-SCHEME-AGENT-POLICY-015")
                             "agentRepair")))
                 (check (hash-get packet "schemaId")
                        => "agent.semantic-protocols.semantic-language-policy-report")
                 (check (hash-get repair "repairableFindings") => 3)
                 (check (hash-get repair "repairableWarnings") => 3)
                 (check (hash-get repair "repairableErrors") => 0)
                 (check (hash-get repair "trigger") => "warning")
                 (check (hash-get r009 "guideTopic")
                        => "functional-data-transform")
                 (check (hash-get r009 "guideIntent") => "repair")
                 (check (hash-get r009 "guideCommand")
                        => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-009 --intent repair")
                 (check (hash-get r009 "guideRole") => "evidence-only")
                 (check (hash-get r015 "guideCommand")
                        => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-015 --intent style")
                 (check (hash-get r013 "guideTopic")
                        => "typed-combinator-style")
                 (check (hash-get r013 "guideCommand")
                        => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-013 --intent style"))
            ))))
(test-case "agent policy reports repeated match branch shape before style repair"
          (let* ((root ".run/policy-controlled-branch-shape")
                 (_ (write-controlled-branch-shape-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-014" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-selector finding) => "src/orders/core.ss:5-7")
            (check (hash-get (type-finding-details finding) 'styleGuide)
                   => "controlled-branch-shape")
            (check (hash-get (type-finding-details finding) 'rewriteScope)
                   => "same caller or extracted helper only")
            (let (quality-reference
                  (hash-get (type-finding-details finding) 'qualityReference))
              (check (hash-get quality-reference 'referencePattern)
                     => "gerbil-utils-higher-order-expression")
              (check (not (not (member
                                "gerbil-utils/base.ss#lambda-match/lambda-ematch"
                                (hash-get quality-reference 'referenceExamples))))
                     => #t))
            (check (hash-get (type-finding-details finding) 'functionShape)
                   => "source-backed Gerbil idioms first: lambda-match/lambda-ematch for unary match destructuring, fun for reusable local lambdas, cut/curry/rcurry for specialization, compose/rcompose/!>/!!> for pipelines")
            (check (hash-get (type-finding-details finding) 'expressionLevelRewrite)
                   => "turn repeated branch or dispatch shape into lambda-match/lambda-ematch, fun, cut/curry/rcurry, compose/rcompose/!>/!!>, fold/filter-map, generator combinator, or a named helper in that order of evidence")
            (check (hash-get (type-finding-details finding)
                             'sourceBackedRepairCandidates)
                   => ["lambda-match/lambda-ematch for unary match destructuring"
                       "fun for reusable local named lambda boundaries"
                       "cut/curry/rcurry for first-class argument specialization"
                       "compose/rcompose/!>/!!> for reusable expression pipelines"
                       "case-lambda only when there are real arity specializations"
                       "plain named helpers only when no higher-order Gerbil idiom fits"])
            (match (policy-check-output [root])
              ([exit-code . output]
               (check exit-code => 1)
               (let* ((packet (call-with-input-string output read-json))
                      (finding (json-finding-by-rule
                                (hash-get packet "findings")
                                "GERBIL-SCHEME-AGENT-POLICY-014"))
                      (repair (hash-get finding "agentRepair")))
                 (check (hash-get repair "guideTopic")
                        => "controlled-branch-shape")
                 (check (hash-get repair "guideCommand")
                        => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-014 --intent style"))))))
  ))
