;;; -*- Gerbil -*-
;;; gerbil scheme harness parser part 8 typed comment blocks.

(import :std/test
        :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/parser/typed-contract-scheme
        :asp-gerbil-scheme/src/protocol/json
        :asp-gerbil-scheme/src/protocol/structural-facts
        :std/srfi/13)
(import :unit/parser/parser-test-part8-support)
(export parser-test-part-8-typed-comment-blocks)

;; PolicyTest
(def parser-test-part-8-typed-comment-blocks
  (test-suite "gerbil scheme harness parser part 8 typed comment blocks"
(test-case "typed contract parser accepts scheme native comment blocks"
          (let* ((root (path-normalize ".run/parser-typed-comment-block"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/core.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/typed-comment)\n")
            (write-text
             source-path
             "(package: sample/typed-comment/core)\n\
;; : (forall (a)\n\
;;     (-> (-> a a Order)\n\
;;         (List a)\n\
;;         (List a)\n\
;;         Order))\n\
;; | type Order = (U 'Lesser 'Equal 'Greater)\n\
(def (compare order left right)\n\
  (order left right))\n\
\n\
;; generate\n\
;;   : (forall (a)\n\
;;       (-> (-> Number a)\n\
;;           Number\n\
;;           (Vector a)))\n\
;;   | contract (-> procedure? natural? vector?)\n\
;;   | type Nat = (Refine Number natural?)\n\
;;   | type Result a = (Values (Vector a) (U 'Ok 'Empty))\n\
;;   | requires (natural? n)\n\
;;   | warning n must be natural for deterministic vector size\n\
;;   | rationale callers validate n through natural?\n\
;;   | doc m%\n\
;;       `generate f n` returns a vector of n generated values.\n\
;;\n\
;;       # Examples\n\
;;\n\
;;       ```scheme\n\
;;       (generate (lambda (x) x) 0)\n\
;;       ;; => #()\n\
;;       ```\n\
;;     %\n\
(def (generate f n)\n\
  (vector))\n\
\n\
;; bad-doc\n\
;;   : (-> Number Number)\n\
;;   | doc 100%\n\
;;       `bad-doc x` uses an invalid doc marker.\n\
;;     %\n\
(def (bad-doc x)\n\
  x)\n")
            (let* ((index (collect-project root))
                   (source (find-source-file (project-index-files index)
                                             "src/core.ss"))
                   (contract (find-typed-contract
                              (source-file-typed-contract-facts source)
                              "compare"))
                   (generate-contract
                    (find-typed-contract
                     (source-file-typed-contract-facts source)
                     "generate"))
                   (bad-doc-contract
                    (find-typed-contract
                     (source-file-typed-contract-facts source)
                     "bad-doc")))
              (check (typed-contract-fact-contract contract)
                     => "(forall (a) (-> (-> a a Order) (List a) (List a) Order))")
              (check (typed-contract-fact-contract-output contract) => "Order")
              (check (typed-contract-fact-contract-inputs contract)
                     => ["(-> a a Order)" "(List a)" "(List a)"])
              (check (typed-contract-fact-contract-input-count contract) => 3)
              (check (typed-contract-fact-group-count contract) => 0)
              (check (typed-contract-fact-arity-alignment contract) => "aligned")
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets contract)
                      "scheme-native-block")
                     => #t)
              (check (typed-contract-fact-contract generate-contract)
                     => "(forall (a) (-> (-> Number a) Number (Vector a)))")
              (check (typed-contract-fact-contract-output generate-contract)
                     => "(Vector a)")
              (check (typed-contract-fact-contract-inputs generate-contract)
                     => ["(-> Number a)" "Number"])
              (check (typed-contract-fact-contract-input-count generate-contract)
                     => 2)
              (check (typed-contract-fact-group-count generate-contract) => 0)
              (check (typed-contract-fact-arity-alignment generate-contract)
                     => "aligned")
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets generate-contract)
                      "runtime-contract-block")
                     => #t)
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets generate-contract)
                      "local-type-environment")
                     => #t)
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets generate-contract)
                      "refinement-type-block")
                     => #t)
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets generate-contract)
                      "precondition-block")
                     => #t)
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets generate-contract)
                      "warning-contract-block")
                     => #t)
              (check (quality-facet-member?
                      (typed-contract-fact-quality-facets generate-contract)
                      "rationale-contract-block")
                     => #t)
              (let* ((typed-comment
                      (typed-contract-fact-typed-comment generate-contract))
                     (local-type (car (hash-get typed-comment 'localTypes)))
                     (result-type (cadr (hash-get typed-comment 'localTypes)))
                     (signature-type (hash-get typed-comment 'signatureType))
                     (signature-arrow (hash-get signature-type 'arrow))
                     (signature-output (hash-get signature-arrow 'output))
                     (result-expression
                      (hash-get result-type 'expressionType))
                     (result-shape (hash-get result-expression 'shape))
                     (signature-type-spec (hash-get signature-type 'typeSpec))
                     (signature-output-spec (hash-get signature-type-spec 'result))
                     (result-union
                      (cadr (hash-get result-shape 'values)))
                     (runtime-contract
                      (car (hash-get typed-comment 'runtimeContractsDetailed)))
                     (requires-predicate
                      (car (hash-get typed-comment 'requiresDetailed)))
                     (doc (car (hash-get typed-comment 'docs)))
                     (doc-example (car (hash-get doc 'examples))))
                (check (hash-get typed-comment 'syntax)
                       => "gerbil-contract-projection")
                (check (hash-get typed-comment 'fullForm) => #t)
                (check (hash-get typed-comment 'leadingName) => "generate")
                (check (hash-get signature-type 'valid) => #t)
                (check (typed-contract-fact-reasons generate-contract) => [])
                (check (hash-get
                        (car (hash-get typed-comment 'signatureTypes))
                        'valid)
                       => #t)
                (check (hash-get signature-type 'forall) => ["a"])
                (check (hash-get signature-arrow 'inputCount) => 2)
                (check (hash-get signature-output 'kind) => "container")
                (check (hash-get signature-output 'name) => "Vector")
                (check (hash-get signature-type-spec 'display)
                       => "(function ((function (Number) a) Number) (vector a))")
                (check (hash-get signature-output-spec 'display)
                       => "(vector a)")
                (check (hash-get signature-output-spec 'kind) => "vector")
                (check (hash-get (hash-get signature-arrow 'typeSpec) 'display)
                       => "(function ((function (Number) a) Number) (vector a))")
                (check (hash-get local-type 'name) => "Nat")
                (check (hash-get local-type 'expression)
                       => "(Refine Number natural?)")
                (check (hash-get (hash-get local-type 'expressionType) 'valid)
                       => #t)
                (check (hash-get result-type 'name) => "Result")
                (check (hash-get result-type 'parameters) => ["a"])
                (check (hash-get result-expression 'valid) => #t)
                (check (hash-get result-shape 'kind) => "values")
                (check (hash-get result-union 'kind) => "union")
                (check (hash-get typed-comment 'runtimeContracts)
                       => ["(-> procedure? natural? vector?)"])
                (check (hash-get runtime-contract 'valid) => #t)
                (check (hash-get runtime-contract 'inputPredicates)
                       => ["procedure?" "natural?"])
                (check (hash-get runtime-contract 'outputPredicate)
                       => "vector?")
                (check (hash-get typed-comment 'requires)
                       => ["(natural? n)"])
                (check (hash-get requires-predicate 'valid) => #t)
                (check (hash-get requires-predicate 'name) => "natural?")
                (check (hash-get requires-predicate 'arguments) => ["n"])
                (check (hash-get typed-comment 'warnings)
                       => ["n must be natural for deterministic vector size"])
                (check (hash-get typed-comment 'rationales)
                       => ["callers validate n through natural?"])
                (check (hash-get typed-comment 'refinements)
                       => ["Nat = (Refine Number natural?)"])
                (check (hash-get doc 'marker) => "m%")
                (check (hash-get doc 'body)
                       => "`generate f n` returns a vector of n generated values.\n\n# Examples\n\n```scheme\n(generate (lambda (x) x) 0)\n;; => #()\n```")
                (check (hash-get doc 'hasExamples) => #t)
                (check (hash-get doc 'hasResultExamples) => #t)
                (check (hash-get doc-example 'language) => "scheme")
                (check (hash-get doc-example 'code)
                       => "(generate (lambda (x) x) 0)")
                (check (hash-get doc-example 'expected) => "#()")
                (check (hash-get doc-example 'hasExpectedResult) => #t)
                (let* ((structural-facts (structural-syntax-fact-json source))
                       (structural-row
                        (find (lambda (fact)
                                (and (equal? (hash-get fact 'languageKind)
                                             "typed-combinator-contract")
                                     (equal? (hash-get fact 'name)
                                             "generate")))
                              structural-facts))
                       (fields (hash-get structural-row 'fields))
                       (json-typed-comment
                        (hash-get fields 'typedComment)))
                  (check (hash-get fields 'contractOutput) => "(Vector a)")
                  (check (hash-get json-typed-comment 'leadingName)
                         => "generate")
                  (check (hash-get json-typed-comment 'runtimeContracts)
                         => ["(-> procedure? natural? vector?)"])
                  (check (hash-get
                          (car (hash-get json-typed-comment 'docs))
                          'hasResultExamples)
                         => #t)
                (check (hash-get (hash-get json-typed-comment 'signatureType)
                                   'valid)
                         => #t)
                  (check (hash-get
                          (hash-get (hash-get json-typed-comment 'signatureType)
                                    'typeSpec)
                          'display)
                         => "(function ((function (Number) a) Number) (vector a))"))
                (check (not (not (member
                                  "doc-marker-invalid:100%"
                                  (typed-contract-fact-reasons bad-doc-contract))))
                       => #t)
                (let* ((bad-hash
                        (scheme-type-expression-text-json "(Hash String)"))
                       (bad-hash-type (hash-get bad-hash 'typeSpec))
                       (bad-hash-diagnostic
                        (car (hash-get bad-hash-type 'diagnosticFacts))))
                  (check (hash-get bad-hash 'diagnostics)
                         => ["Hash-requires-key-and-value"])
                  (check (hash-get bad-hash-type 'valid) => #f)
                  (check (hash-get bad-hash-type 'diagnostics)
                         => ["hash-value:unknown-type"])
                  (check (hash-get bad-hash-diagnostic 'code)
                         => "unknown-type")
                  (check (hash-get bad-hash-diagnostic 'path)
                         => ["hash-value"])
                  (check (hash-get bad-hash-diagnostic 'category)
                         => "shape"))
                (check (hash-get (scheme-type-signature-json "(-> Output)")
                                 'diagnostics)
                       => [])))))
  ))
