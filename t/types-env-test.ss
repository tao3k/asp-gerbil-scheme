;;; -*- Gerbil -*-
(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/runtime-contract
        :asp-gerbil-scheme/src/parser/typed-contract-scheme
        :asp-gerbil-scheme/src/types/env
        :asp-gerbil-scheme/src/types/findings
        :asp-gerbil-scheme/src/types/model
        :asp-gerbil-scheme/src/types/signatures
        :asp-gerbil-scheme/src/types/source-findings)
(export types-env-test)

(def types-fixture-index-cache #f)
(def types-fixture-signatures-cache #f)

;; : (-> RelPath LineCount Definitions TypedContracts ParseError SourceFile)
(def (types-source-file path line-count definitions typed-contracts parse-error)
  (make-source-file path
                    line-count
                    #f
                    #f
                    #f
                    '()
                    '()
                    '()
                    definitions
                    '()
                    '()
                    '()
                    '()
                    '()
                    '()
                    '()
                    '()
                    '()
                    '()
                    '()
                    '()
                    '()
                    '()
                    '()
                    '()
                    '()
                    typed-contracts
                    '()
                    parse-error))

;; : (-> Definition Contract TypedContractFact)
(def (types-typed-contract definition contract)
  (make-typed-contract-fact (definition-name definition)
                            (definition-kind definition)
                            (definition-formals definition)
                            (definition-arity definition)
                            (definition-path definition)
                            (definition-start definition)
                            (definition-end definition)
                            0
                            0
                            contract
                            #f
                            '()
                            0
                            "aligned"
                            '()
                            1
                            0
                            "valid"
                            '()
                            '()
                            '()
                            #f))

;; : (-> SourceFile)
(def (types-invalid-read-source-file)
  (types-source-file "t/fixtures/invalid-read.fixture"
                     2
                     '()
                     '()
                     "unexpected end of input"))

;; : (-> ProjectIndex)
(def (types-fixture-index)
  (or types-fixture-index-cache
      (let* ((sum-two (make-definition "sum-two"
                                       "def"
                                       "formals.ss"
                                       1
                                       3
                                       ["x" "y"]
                                       2))
             (collect (make-definition "collect"
                                       "def"
                                       "formals.ss"
                                       5
                                       7
                                       ["xs"]
                                       1))
             (source (types-source-file
                      "formals.ss"
                      7
                      [sum-two collect]
                      [(types-typed-contract sum-two "(-> Number Number Number)")
                       (types-typed-contract collect "(-> (List Number) (List Number))")]
                      #f))
             (index (make-project-index "t/fixtures" [source] #f)))
        (set! types-fixture-index-cache index)
        index)))

;; : (-> NativeSignatures)
(def (types-fixture-signatures)
  (or types-fixture-signatures-cache
      (let (signatures (load-type-signatures "t/fixtures/type-signatures.scm"))
        (set! types-fixture-signatures-cache signatures)
        signatures)))

;; : TestSuite
(def types-reader-env-test
  (test-suite "gerbil scheme harness types reader env"
    (test-case "reader errors become type pipeline findings"
      (let* ((file (types-invalid-read-source-file))
             (findings (source-file-type-findings file))
             (finding (car findings))
             (details (type-finding-details finding))
             (location (hash-get details 'location)))
        (check (length findings) => 1)
        (check (type-finding-rule-id finding) => "GERBIL-SCHEME-READ-R001")
        (check (type-finding-severity finding) => "error")
        (check (type-finding-path finding) => "t/fixtures/invalid-read.fixture")
        (check (type-finding-selector finding)
               => (string-append "t/fixtures/invalid-read.fixture:1-"
                                 (number->string (source-file-line-count file))))
        (check (hash-get details 'schema) => "gerbil-read-diagnostic-v1")
        (check (hash-get details 'diagnosticKind) => "read-error")
        (check (hash-get details 'category) => "syntax")
        (check (hash-get details 'selector) => (type-finding-selector finding))
        (check (hash-get location 'lineStart) => 1)
        (check (hash-get location 'lineEnd) => (source-file-line-count file))
        (check (hash-get location 'precision) => "file-range-fallback")
        (check (hash-get details 'nextAction)
               => "open selector and fix reader syntax")))
    (test-case "type env is built from parser-owned typed contracts"
      (let* ((index (types-fixture-index))
             (sample-bindings
              (filter (lambda (binding)
                        (equal? (type-binding-path binding)
                                "formals.ss"))
                      (build-type-env index))))
        (check (map type-binding-name sample-bindings)
               => ["sum-two" "collect"])
        (check (map type-binding-kind sample-bindings)
               => ["def" "def"])
        (check (map type->string (map type-binding-type sample-bindings))
               => ["(function (Number Number) Number)"
                   "(function ((list Number)) (list Number))"])
        (check (map type-binding-formals sample-bindings)
               => [["x" "y"] ["xs"]])
        (check (map type-binding-arity sample-bindings)
               => [2 1])
        (let (param-bindings
              (filter (lambda (binding)
                        (equal? (type-param-binding-path binding)
                                "formals.ss"))
                      (build-param-type-env index)))
          (check (map type-param-binding-function-name param-bindings)
                 => ["sum-two" "sum-two" "collect"])
          (check (map type-param-binding-name param-bindings)
                 => ["x" "y" "xs"])
          (check (map type->string
                      (map type-param-binding-type param-bindings))
                 => ["Number" "Number" "(list Number)"]))))
    (test-case "signature types merge into native type env"
      (let* ((index (types-fixture-index))
             (signatures (types-fixture-signatures))
             (sample-bindings
              (filter (lambda (binding)
                        (equal? (type-binding-path binding)
                                "formals.ss"))
                      (build-type-env/signatures index signatures))))
        (check (map type-binding-name sample-bindings)
               => ["sum-two" "collect"])
        (check (map type->string (map type-binding-type sample-bindings))
               => ["(function (number number) number)" "(function (any) any)"])))
    (test-case "signature parameter types build native param env"
      (let* ((index (types-fixture-index))
             (signatures (types-fixture-signatures))
             (param-bindings
              (filter (lambda (binding)
                        (equal? (type-param-binding-path binding)
                                "formals.ss"))
                      (build-param-type-env/signatures index signatures))))
        (check (map type-param-binding-function-name param-bindings)
               => ["sum-two" "sum-two"])
        (check (map type-param-binding-name param-bindings)
               => ["x" "y"])
        (check (map type->string (map type-param-binding-type param-bindings))
               => ["number" "number"])))))

;; : TestSuite
(def types-runtime-contract-test
  (test-suite "gerbil scheme harness runtime contracts"
    (test-case "runtime contract arrows project to formal TypeSpec"
      (let* ((nickel-contract
              (scheme-runtime-contract-json "Dyn -> NonEmpty -> Dyn"))
             (scheme-contract
              (scheme-runtime-contract-json "(-> procedure? natural? vector?)"))
             (bad-contract
              (scheme-runtime-contract-json "Dyn -> (List) -> Dyn"))
             (nickel-type (hash-get nickel-contract 'typeSpec))
             (scheme-type (hash-get scheme-contract 'typeSpec))
             (bad-type (hash-get bad-contract 'typeSpec)))
        (check (hash-get nickel-contract 'valid) => #t)
        (check (hash-get nickel-contract 'notation) => "infix-arrow")
        (check (hash-get nickel-contract 'inputPredicates)
               => ["Dyn" "NonEmpty"])
        (check (hash-get nickel-contract 'outputPredicate) => "Dyn")
        (check (hash-get nickel-type 'display)
               => "(function (Dyn NonEmpty) Dyn)")
        (check (hash-get scheme-contract 'valid) => #t)
        (check (hash-get scheme-contract 'notation) => "scheme-prefix-arrow")
        (check (hash-get scheme-type 'display)
               => "(function (procedure? natural?) vector?)")
        (check (hash-get bad-contract 'valid) => #f)
        (check (hash-get bad-type 'diagnostics)
               => ["function-parameter[1]:list-element:unknown-type"])))
    (test-case "duplicate definitions become type env facts"
      (let* ((first (make-type-binding "answer" "definition" (make-type-unknown)
                                       '() 0 "same.ss" "same.ss:1-1"))
             (second (make-type-binding "answer" "definition" (make-type-unknown)
                                        '() 0 "same.ss" "same.ss:2-2"))
             (duplicates (duplicate-type-bindings [first second]))
             (duplicate (car duplicates)))
        (check (length duplicates) => 1)
        (check (type-binding-selector (car duplicate)) => "same.ss:2-2")
        (check (type-binding-selector (cadr duplicate)) => "same.ss:1-1")))
    (test-case "poo methods extend generic type bindings"
      (let* ((generic (make-type-binding ":render" "defgeneric" (make-type-unknown)
                                         '() 0 "same.ss" "same.ss:1-1"))
             (method (make-type-binding ":render" "defmethod" (make-type-unknown)
                                        '() 0 "same.ss" "same.ss:2-4")))
        (check (duplicate-type-bindings [generic method]) => '())))
    (test-case "poo method overloads are not duplicate type bindings"
      (let* ((first (make-type-binding ":render" "defmethod" (make-type-unknown)
                                       '() 0 "same.ss" "same.ss:2-4"))
             (second (make-type-binding ":render" "defmethod" (make-type-unknown)
                                        '() 0 "same.ss" "same.ss:5-7")))
        (check (duplicate-type-bindings [first second]) => '())))
    (test-case "same definition names in different owners are distinct"
      (let* ((first (make-type-binding "answer" "definition" (make-type-unknown)
                                       '() 0 "first.ss" "first.ss:1-1"))
             (second (make-type-binding "answer" "definition" (make-type-unknown)
                                        '() 0 "second.ss" "second.ss:2-2")))
        (check (duplicate-type-bindings [first second]) => '())))))

(def types-env-test
  (test-suite "gerbil scheme harness type env"
    types-reader-env-test
    types-runtime-contract-test))
