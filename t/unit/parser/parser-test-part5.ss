;;; -*- Gerbil -*-
(import :std/test
        :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/protocol/json
        :std/srfi/13)
(export parser-test-part-5)

;; : (-> Selector Relpath Boolean )
(def (selector-owner? selector path)
  (and (string? selector)
       (string-prefix? (string-append path ":") selector)))

;; : (-> (List CallFact) Argument FindCallWithArgument )
(def (find-call-with-argument calls argument)
  (find (lambda (call)
          (equal? (call-fact-arguments call) [argument]))
        calls))
;; : (-> (List QualityFacet) QualityFacet Boolean )
(def (quality-facet-member? facets facet)
  (not (not (member facet facets))))
;; : (-> (List MacroFact) String MacroFact )
(def (find-macro facts name)
  (find (lambda (fact)
          (equal? (macro-fact-name fact) name))
        facts))
;; : (-> (List HigherOrderFact) String String String (List HigherOrderFact) )
(def (find-higher-order facts name role caller)
  (find (lambda (fact)
          (and (equal? (higher-order-fact-name fact) name)
               (equal? (higher-order-fact-role fact) role)
               (equal? (or (higher-order-fact-caller fact) "") caller)))
        facts))
;; : (-> (List ControlFlowFact) String String String (List ControlFlowFact) )
(def (find-control-flow facts name role caller)
  (find (lambda (fact)
          (and (equal? (control-flow-fact-name fact) name)
               (equal? (control-flow-fact-role fact) role)
               (equal? (or (control-flow-fact-caller fact) "") caller)))
        facts))
;; : (-> (List TypedContractFact) String (List TypedContractFact) )
(def (find-typed-contract facts name)
  (find (lambda (fact)
          (equal? (typed-contract-fact-definition-name fact) name))
        facts))
;; : (-> (List PredicateFamilyFact) String PredicateFamilyFact )
(def (find-predicate-family facts subject)
  (find (lambda (fact)
          (equal? (predicate-family-fact-subject fact) subject))
        facts))
;; : (-> (List FieldAccessPatternFact) String FieldAccessPatternFact )
(def (find-field-access-pattern facts field-key)
  (find (lambda (fact)
          (equal? (field-access-pattern-fact-field-key fact) field-key))
        facts))
;; : (-> (List ProjectionBurstFact) String ProjectionBurstFact )
(def (find-projection-burst facts caller)
  (find (lambda (fact)
          (equal? (projection-burst-fact-caller fact) caller))
        facts))
;; : (-> (List BooleanConditionFact) String BooleanConditionFact )
(def (find-boolean-condition facts caller)
  (find (lambda (fact)
          (equal? (boolean-condition-fact-caller fact) caller))
        facts))
;; : (-> (List LoopDriverFact) String LoopDriverFact )
(def (find-loop-driver facts caller)
  (find (lambda (fact)
          (equal? (loop-driver-fact-caller fact) caller))
        facts))
;; : (-> (List FunctionQualityProfile) String FunctionQualityProfile )
(def (find-function-quality-profile profiles name)
  (find (lambda (profile)
          (equal? (function-quality-profile-name profile) name))
        profiles))
;; : (-> (List PooFormFact) String PooFormFact )
(def (find-poo-form facts name)
  (find (lambda (fact)
          (equal? (poo-form-fact-name fact) name))
        facts))
;; : (-> (List PooFormFact) String String PooFormFact )
(def (find-poo-form-role facts name role)
  (find (lambda (fact)
          (and (equal? (poo-form-fact-name fact) name)
               (equal? (poo-form-fact-role fact) role)))
        facts))
;; ParsedData
;; : (-> String EnsureDir )
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))
;; : (-> String SourceLine Unit )
(def (write-text path text)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path)))
  (call-with-output-file path
    (lambda (port) (display text port))))
;; TestSuite
(def parser-test-part-5-higher-order-control
  (test-suite "gerbil scheme harness parser part 5 higher-order control"
    (test-case "native reader captures higher-order syntax facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/higher-order.ss"))
                 (facts (source-file-higher-order-forms file))
                 (select-definition
                  (find (lambda (definition)
                          (equal? (definition-name definition) "select"))
                        (source-file-definitions file)))
                 (bump-definition
                  (find (lambda (definition)
                          (equal? (definition-name definition) "bump"))
                        (source-file-definitions file)))
                 (case-lambda-fact
                  (find-higher-order facts "case-lambda" "multi-arity-function" "select"))
                 (map-fact
                  (find-higher-order facts "map" "sequence-map" "names"))
                 (map-lambda
                  (find-higher-order facts "lambda" "anonymous-function" "names"))
                 (filter-fact
                  (find-higher-order facts "filter" "sequence-filter" "positives"))
                 (filter-map-fact
                  (find-higher-order facts "filter-map" "sequence-filter-map" "positive-names"))
                 (predicate-fact
                  (find-higher-order facts "ormap" "sequence-predicate" "any-positive?"))
                 (search-fact
                  (find-higher-order facts "find" "sequence-search" "first-positive"))
                 (fold-fact
                  (find-higher-order facts "fold-left" "sequence-fold" "total"))
                 (cut-fact
                  (find-higher-order facts "cut" "partial-application" "bump"))
                 (for-fold-fact
                  (find-higher-order facts "for/fold" "loop-fold" "counted"))
                 (autocurry-fact
                  (find-higher-order facts "defn" "autocurry-semantics" "autocurried"))
                 (pipeline-fact
                  (find-higher-order facts "!>" "pipeline-composition" "pipeline"))
                 (rcompose-fact
                  (find-higher-order facts "rcompose" "function-composition" "compose-values"))
                 (syntax-helper-fact
                  (find-higher-order facts "stx-apply" "syntax-helper-dsl" "syntax-helper"))
                 (generator-fact
                  (find-higher-order facts "generating<-for-each" "generator-transform" "generator-source"))
                 (generator-thread-fact
                  (find-higher-order facts "generating<-cothread" "generator-control-inversion" "generator-thread"))
                 (peekable-fact
                  (find-higher-order facts ":peekable-iter" "stateful-protocol-wrapper" "peekable")))
            (check (source-file-parse-error file) => #f)
            (check (not (null? facts)) => #t)
            (check (definition-formals select-definition) => ["x"])
            (check (definition-arity select-definition) => 1)
            (check (definition-formals bump-definition) => ["<>"])
            (check (definition-arity bump-definition) => 1)
            (check (higher-order-fact-arities case-lambda-fact) => [0 1])
            (check (higher-order-fact-operand-count map-fact) => 2)
            (check (higher-order-fact-arities map-lambda) => [1])
            (check (higher-order-fact-formals map-lambda) => ["widget"])
            (check (higher-order-fact-operand-count filter-fact) => 2)
            (check (higher-order-fact-operand-count filter-map-fact) => 2)
            (check (higher-order-fact-operand-count predicate-fact) => 2)
            (check (higher-order-fact-operand-count search-fact) => 2)
            (check (higher-order-fact-operand-count fold-fact) => 3)
            (check (higher-order-fact-operand-count cut-fact) => 3)
            (check (higher-order-fact-operand-count for-fold-fact) => 3)
            (check (higher-order-fact-operand-count autocurry-fact) => 2)
            (check (higher-order-fact-operand-count pipeline-fact) => 3)
            (check (higher-order-fact-operand-count rcompose-fact) => 2)
            (check (higher-order-fact-operand-count syntax-helper-fact) => 2)
            (check (higher-order-fact-operand-count generator-fact) => 1)
            (check (higher-order-fact-operand-count generator-thread-fact) => 1)
            (check (higher-order-fact-operand-count peekable-fact) => 1)
            (check (quality-facet-member? (higher-order-quality-facets case-lambda-fact)
                                          "case-lambda-optimization-boundary")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets case-lambda-fact)
                                          "multi-arity-abstraction")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets map-lambda)
                                          "lambda-local-abstraction")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets map-lambda)
                                          "parameterized-transform")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets map-fact)
                                          "expression-level-composition")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets fold-fact)
                                          "expression-level-composition")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets cut-fact)
                                          "combinator-composition")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets cut-fact)
                                          "function-specialization-abstraction")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets for-fold-fact)
                                          "builder-or-fold-combinator")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets autocurry-fact)
                                          "autocurry-application-semantics")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets pipeline-fact)
                                          "multi-value-composition")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets pipeline-fact)
                                          "function-pipeline-abstraction")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets rcompose-fact)
                                          "function-pipeline-abstraction")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets syntax-helper-fact)
                                          "syntax-helper-extraction")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets generator-thread-fact)
                                          "continuation-or-coroutine-boundary")
                   => #t)
            (check (quality-facet-member? (higher-order-quality-facets peekable-fact)
                                          "stateful-protocol-wrapper")
                   => #t)))
    (test-case "native reader captures control-flow syntax facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/control-flow.ss"))
                 (facts (source-file-control-flow-forms file))
                 (loop-fact
                  (find-control-flow facts "loop" "manual-loop" "total"))
                 (continuation-fact
                  (find-control-flow facts "let/cc" "continuation-control" "first-or-stop"))
                 (builder-fact
                  (find-control-flow facts "with-list-builder" "builder-control" "safe-take"))
                 (try-fact
                  (find-control-flow facts "try" "protected-control" "safe-take"))
                 (catch-fact
                  (find-control-flow facts "catch" "protected-handler" "safe-take"))
                 (finally-fact
                  (find-control-flow facts "finally" "protected-handler" "safe-take"))
                 (resource-fact
                  (find-control-flow facts "call-with-output-string" "resource-scope" "capture-output"))
                 (parameter-fact
                  (find-control-flow facts "parameterize" "resource-scope" "capture-output"))
                 (parameter-state-fact
                  (find-control-flow facts "make-parameter" "parameter-state" "current-setting"))
                 (cleanup-fact
                  (find-control-flow facts "dynamic-wind" "cleanup-boundary" "with-dynamic"))
                 (parameter-call-fact
                  (find-control-flow facts "call-with-parameters" "parameter-state" "parameter-call"))
                 (actor-fact
                  (find-control-flow facts "spawn/name" "actor-control" "worker"))
                 (coroutine-fact
                  (find-control-flow facts "in-cothread" "coroutine-control" "coroutine-source"))
                 (continuation-debug-fact
                  (find-control-flow facts "continuation-capture" "continuation-control" "continuation-debug"))
                 (total-contract
                  (find-typed-contract (source-file-typed-contract-facts file) "total"))
                 (repair-evidence
                  (typed-contract-fact-repair-evidence total-contract)))
            (check (source-file-parse-error file) => #f)
            (check (>= (length facts) 8) => #t)
            (check (control-flow-fact-kind loop-fact) => "named-let")
            (check (control-flow-fact-binding-count loop-fact) => 2)
            (check (control-flow-fact-body-form-count loop-fact) => 1)
            (check (selector-owner? (control-flow-fact-selector loop-fact)
                                    "t/fixtures/parser/control-flow.ss")
                   => #t)
            (check (control-flow-fact-kind continuation-fact) => "let/cc")
            (check (control-flow-fact-kind builder-fact) => "with-list-builder")
            (check (control-flow-fact-kind try-fact) => "try")
            (check (control-flow-fact-kind catch-fact) => "catch")
            (check (control-flow-fact-kind finally-fact) => "finally")
            (check (control-flow-fact-kind resource-fact) => "call-with-output-string")
            (check (control-flow-fact-kind parameter-fact) => "parameterize")
            (check (control-flow-fact-kind parameter-state-fact) => "make-parameter")
            (check (control-flow-fact-kind cleanup-fact) => "dynamic-wind")
            (check (control-flow-fact-kind parameter-call-fact) => "call-with-parameters")
            (check (control-flow-fact-kind actor-fact) => "spawn/name")
            (check (control-flow-fact-kind coroutine-fact) => "in-cothread")
            (check (control-flow-fact-kind continuation-debug-fact) => "continuation-capture")
            (check (quality-facet-member? (control-flow-quality-facets cleanup-fact)
                                          "dynamic-cleanup-boundary")
                   => #t)
            (check (quality-facet-member? (control-flow-quality-facets actor-fact)
                                          "actor-continuation-diagnostics")
                   => #t)
            (check (quality-facet-member? (control-flow-quality-facets coroutine-fact)
                                          "generator-control-inversion")
                   => #t)
            (check (quality-facet-member? (control-flow-quality-facets continuation-debug-fact)
                                          "continuation-capture-boundary")
                   => #t)
            (check (not (not (member "manual-loop-drift"
                                      (typed-contract-fact-quality-facets total-contract))))
                   => #t)
            (check (not (not (member "combinator-candidate"
                                      (typed-contract-fact-quality-facets total-contract))))
                   => #t)
            (check (hash-get repair-evidence 'factSource) => "native-parser")
            (check (not (not (member "replace-manual-loop-with-higher-order-combinator-when-no-state-witness"
                                      (hash-get repair-evidence 'allowedMoves))))
                   => #t)))
  ))

;; TestSuite
(def parser-test-part-5-quality-shape
  (test-suite "gerbil scheme harness parser part 5 quality shape"
    (test-case "native reader keeps quality-shape parser facts stable"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "src/parser/quality-shape.ss")))
            (check (source-file-parse-error file) => #f)
            (check (source-file-predicate-family-facts file) => '())
            (check (source-file-field-access-pattern-facts file) => '())
            (check (source-file-boolean-condition-facts file) => '())
            (check (source-file-loop-driver-facts file) => '())))
    (test-case "native reader captures quality-shape parser facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/predicate-family.fixture"))
                 (family (find-predicate-family
                          (source-file-predicate-family-facts file) "fact"))
                 (role-access (find-field-access-pattern
                               (source-file-field-access-pattern-facts file) "role"))
                 (fields-access (find-field-access-pattern
                                 (source-file-field-access-pattern-facts file) "fields"))
                 (paid-condition (find-boolean-condition
                                  (source-file-boolean-condition-facts file)
                                  "paid-event?"))
                 (loop-driver (find-loop-driver
                               (source-file-loop-driver-facts file)
                               "collect-ids"))
                 (created-profile
                  (find-function-quality-profile
                   (source-file-function-quality-profiles file)
                   "created-event?")))
            (check (source-file-parse-error file) => #f)
            (check (predicate-family-fact-predicate-count family) => 3)
            (check (predicate-family-fact-predicate-names family)
                   => ["created-event?" "paid-event?" "cancelled-event?"])
            (check (not (not (member "role" (predicate-family-fact-field-keys family))))
                   => #t)
            (check (not (not (member "hash-get" (predicate-family-fact-repeated-callees family))))
                   => #t)
            (check (field-access-pattern-fact-access-count role-access) => 3)
            (check (field-access-pattern-fact-access-count fields-access) => 3)
            (check (boolean-condition-fact-condition-count paid-condition) => 3)
            (check (loop-driver-fact-driver-kind loop-driver) => "pure-transform-candidate")
            (check (not (not (member "combinator-candidate"
                                      (loop-driver-fact-quality-facets loop-driver))))
                   => #t)
            (check (function-quality-profile-role created-profile) => "predicate")
            (check (function-quality-profile-suggested-repair-class created-profile)
                   => "predicate-family-combinator")
            (check (not (not (member "predicate-family:fact"
                                      (function-quality-profile-predicate-family-refs
                                       created-profile))))
                   => #t)
            (check (not (not (member "field-access:role"
                                      (function-quality-profile-field-access-pattern-refs
                                       created-profile))))
                   => #t)
            (check (not (not (member "functionQualityProfile"
                                      (function-quality-profile-quality-facets
                                       created-profile))))
                   => #t)))
    (test-case "native reader captures projection-burst parser facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/projection-burst.ss"))
                 (burst (find-projection-burst
                         (source-file-projection-burst-facts file)
                         "emit-order-line")))
            (check (source-file-parse-error file) => #f)
            (check (projection-burst-fact-caller burst) => "emit-order-line")
            (check (projection-burst-fact-access-count burst) => 12)
            (check (projection-burst-fact-accessor-count burst) => 4)
            (check (projection-burst-fact-emitter-count burst) => 2)
            (check (not (not (member "id"
                                      (projection-burst-fact-field-keys burst))))
                   => #t)
            (check (not (not (member "displayln"
                                      (projection-burst-fact-emitters burst))))
                   => #t)
            (check (not (not (member "emitter-projection-burst"
                                      (projection-burst-fact-quality-facets burst))))
                   => #t)
            (check (selector-owner? (projection-burst-fact-selector burst)
                                    "t/fixtures/parser/projection-burst.ss")
                   => #t)))))

;; TestSuite
(def parser-test-part-5
  (test-suite "gerbil scheme harness parser part 5"
    parser-test-part-5-higher-order-control
    parser-test-part-5-quality-shape))
