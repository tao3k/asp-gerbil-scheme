;;; -*- Gerbil -*-
;;; gerbil scheme harness parser part 8 source contracts.

(import :std/test
        :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/parser/formals
        :asp-gerbil-scheme/src/parser/typed-contract-scheme
        :asp-gerbil-scheme/src/protocol/json
        :asp-gerbil-scheme/src/protocol/structural-facts
        :std/srfi/13)
(import :unit/parser/parser-test-part8-support)
(export parser-test-part-8-source-contracts)

;; PolicyTest
(def parser-test-part-8-source-contracts
  (test-suite "gerbil scheme harness parser part 8 source contracts"
(test-case "source path class owns build policy scope"
          (check (source-path-class "gerbil.pkg") => "config")
          (check (source-path-class "build.ss") => "package-build")
          (check (source-path-class "src/build-api/native-build.ss")
                 => "build-runtime")
          (check (source-path-class "src/testing/gxtest-runner.ss")
                 => "build-runtime")
          (check (source-path-class "t/scenarios/policy/functional-idiom/input/src/orders/core.ss")
                 => "policy-scenario")
          (check (source-path-class "t/fixtures/parser/raw.ss") => "fixture")
          (check (source-path-class "t/snapshots/policy-functional-idiom.ss")
                 => "snapshot-output")
          (check (source-path-class "src/main.ss") => "runtime-source"))
(test-case "boolean condition facts include multi-arity path predicates"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/boolean-condition.ss"))
                 (fact
                  (find-boolean-condition
                   (source-file-boolean-condition-facts file)
                   "path-matches-token?"))
                 (callees (boolean-condition-fact-condition-callees fact)))
            (check (source-file-parse-error file) => #f)
            (check (boolean-condition-fact-formals fact) => ["relpath" "token"])
            (check (boolean-condition-fact-condition-count fact) => 6)
            (check (if (member "string-prefix?" callees) #t #f) => #t)
            (check (if (member "string-suffix?" callees) #t #f) => #t)
            (check (if (member "string-contains" callees) #t #f) => #t)
            (check (if (member "not" callees) #t #f) => #t)))
(test-case "scheme typed contracts validate type constructor applications"
          (let* ((list-expr
                  (scheme-type-expression-text-json "(List TypeFinding)"))
                 (list-shape (hash-get list-expr 'shape))
                 (list-param (car (hash-get list-shape 'parameters)))
                 (forall-signature
                  (scheme-type-signature-json
                   "(forall (a) (-> (-> a Boolean) (Array a) Boolean))"))
                 (arrow (hash-get forall-signature 'arrow))
                 (array-input (cadr (hash-get arrow 'inputs)))
                 (array-param (car (hash-get array-input 'parameters)))
                 (unbound-expr
                  (scheme-type-expression-text-json "(Array a)"))
                 (unbound-shape (hash-get unbound-expr 'shape))
                 (unbound-param (car (hash-get unbound-shape 'parameters)))
                 (hash-expr
                  (scheme-type-expression-text-json "(Hash String Number)"))
                 (hash-type-spec (hash-get hash-expr 'typeSpec))
                 (hash-key-type (car (hash-get hash-type-spec 'params)))
                 (hash-value-type (cadr (hash-get hash-type-spec 'params)))
                 (refine-expr
                  (scheme-type-expression-text-json
                   "(Refine Number natural?)"))
                 (refine-type-spec (hash-get refine-expr 'typeSpec))
                 (application-signature
                  (scheme-type-signature-json
                   "(forall (a) (-> (NonEmptyList a) a))"))
                 (application-param
                  (car
                   (hash-get
                    (hash-get application-signature 'typeSpec)
                    'params))))
            (check (hash-get list-expr 'valid) => #t)
            (check (hash-get list-shape 'kind) => "container")
            (check (hash-get list-shape 'name) => "List")
            (check (hash-get list-param 'kind) => "name")
            (check (hash-get list-param 'name) => "TypeFinding")
            (check (hash-get list-param 'role) => "type-name")
            (check (hash-get forall-signature 'valid) => #t)
            (check (hash-get array-input 'kind) => "container")
            (check (hash-get array-input 'name) => "Array")
            (check (hash-get array-param 'role) => "type-variable")
            (check (hash-get array-param 'name) => "a")
            (check (hash-get array-param 'bound) => #t)
            (check (hash-get unbound-expr 'valid) => #f)
            (check (hash-get unbound-param 'role) => "type-variable")
            (check (hash-get unbound-param 'bound) => #f)
            (check (hash-get unbound-expr 'diagnostics)
                   => ["unbound-type-variable:a"])
            (check (hash-get hash-expr 'valid) => #t)
            (check (hash-get hash-type-spec 'kind) => "hash")
            (check (hash-get hash-type-spec 'valid) => #t)
            (check (hash-get hash-type-spec 'diagnostics) => [])
            (check (hash-get hash-key-type 'display) => "String")
            (check (hash-get hash-value-type 'display) => "Number")
            (check (hash-get refine-expr 'valid) => #t)
            (check (hash-get refine-type-spec 'kind) => "refine")
            (check (hash-get refine-type-spec 'valid) => #t)
            (check (hash-get refine-type-spec 'name) => "natural?")
            (check (hash-get application-signature 'valid) => #t)
            (check (hash-get application-param 'kind) => "application")
            (check (hash-get application-param 'display)
                   => "(NonEmptyList a)")))
(test-case "scheme typed contracts group keyword parameter inputs"
          (let* ((contract
                  "(-> roots: (List Path) runtime-roots: (Maybe (List Path)) exclude-directories: (List Path) explanation: MaybeString Unit)")
                 (inputs (scheme-contract-inputs contract))
                 (signature (scheme-type-signature-json contract))
                 (arrow (hash-get signature 'arrow))
                 (arrow-inputs (hash-get arrow 'inputs))
                 (roots-input (car arrow-inputs)))
            (check inputs
                   => ["(List Path)"
                       "(Maybe (List Path))"
                       "(List Path)"
                       "MaybeString"])
            (check (length inputs) => 4)
            (check (hash-get arrow 'inputCount) => 4)
            (check (hash-get roots-input 'kind) => "keyword-parameter")
            (check (hash-get roots-input 'name) => "roots")))
(test-case "definition arity counts keyword default formals"
          (let (datum
                '(def (configure-source-coverage roots: (roots '())
                                                 runtime-roots: (runtime-roots #f)
                                                 explanation: (explanation #f))
                   #!void))
            (check (definition-formal-arity datum 'configure-source-coverage)
                   => 3)
            (check (definition-formal-names datum 'configure-source-coverage)
                   => ["roots" "runtime-roots" "explanation"])))
  ))
