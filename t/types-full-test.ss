;;; -*- Gerbil -*-
(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/types/model
        :asp-gerbil-scheme/src/types/signatures
        :asp-gerbil-scheme/src/types/validation
        (only-in :asp-gerbil-scheme/src/utilities/contracts
                 contract-issue-code
                 make-object-type-contract
                 make-slot-contract
                 object-contract-issues
                 object-contract-valid?
                 require-object-contract!)
        (only-in :asp-gerbil-scheme/src/utilities/contract-syntax
                 defobject-contract)
        (only-in :asp-gerbil-scheme/src/utilities/projection
                 object-contract-report-rows
                 object-type-contract->alist))
(export types-full-test)

;;; Executable macro witness: the test owns both the declaration expansion and
;;; observable runtime assertions, without package metadata or policy escapes.
(defobject-contract contract-witness
  owner: 'types-test
  object-kind: 'contract-witness
  slots:
  ((name String string? required)))

;; : TestSuite
(def types-parser-shape-test
  (test-suite "gerbil scheme harness type parser shapes"
    (test-case "signature parser supports structured native type forms"
      (let* ((signatures (load-type-signatures "t/fixtures/type-signatures.scm"))
             (pair-type (signature-type-for "pair-value" signatures))
             (numbers-type (signature-type-for "numbers" signatures))
             (names-type (signature-type-for "names" signatures))
             (union-type (signature-type-for "string-or-number" signatures))
             (node-type (signature-type-for "node" signatures))
             (rest-type (signature-type-for "rest-sum" signatures))
             (contract-type (signature-type-for "contract-findings" signatures))
             (identity-type (signature-type-for "identity" signatures))
             (native-list-arrow-type
              (parse-type-contract "(-> (List Number) (List Number))"))
             (keyword-arrow-type
              (parse-type-contract "(-> String SlotPrototype supers: (List SlotProfile) SlotProfile)"))
             (hash-type (parse-type-contract "(Hash String Number)"))
             (values-type (parse-type-contract "(Values String Number)"))
             (refine-type (parse-type-contract "(Refine Number natural?)"))
             (application-type
              (parse-type-contract "(NonEmptyList TypeFinding)"))
              (literal-union-type
               (parse-type-contract "(U 'Left 'Right)"))
              (application-arrow-type
               (parse-type-contract "(forall (a) (-> (NonEmptyList a) a))"))
              (pair-list-arrow-type
               (parse-type-contract "(forall (k v) (-> [(Pair k v)] [(Pair k v)] [(Pair k v)]))"))
              (maybe-arrow-type
               (parse-type-contract "(-> (Maybe Type) (Maybe Type) Boolean)")))
        (check (type->string pair-type) => "(pair string number)")
        (check (type->string (type-pair-car pair-type)) => "string")
        (check (type->string (type-pair-cdr pair-type)) => "number")
        (check (type->string numbers-type) => "(list number)")
        (check (type->string (type-list-elem numbers-type)) => "number")
        (check (type->string names-type) => "(vector string)")
        (check (type->string (type-vector-elem names-type)) => "string")
        (check (type->string union-type) => "(union string number)")
        (check (map type->string (type-union-members union-type))
               => ["string" "number"])
        (check (type->string node-type)
               => "(record ((value number) (next (union null any))) (value))")
        (check (type-record-required node-type) => ["value"])
        (check (type->string (record-field-type node-type "next"))
               => "(union null any)")
        (check (type->string rest-type) => "(function* number number 1)")
        (check (type-kind rest-type) => 'function-variadic)
        (check (type-function-variadic-min-arity rest-type) => 1)
        (check (type->string (parse-type-contract "(Maybe TypeSignature)"))
               => "(maybe TypeSignature)")
        (check (type->string native-list-arrow-type)
               => "(function ((list Number)) (list Number))")
        (check (map type->string (type-params native-list-arrow-type))
               => ["(list Number)"])
        (check (type->string keyword-arrow-type)
               => "(function (String SlotPrototype supers: (list SlotProfile)) SlotProfile)")
        (check (map type->string (type-params keyword-arrow-type))
               => ["String" "SlotPrototype" "supers: (list SlotProfile)"])
        (check (type-kind (caddr (type-params keyword-arrow-type)))
               => 'keyword-parameter)
        (check (type-keyword-parameter-name
                (caddr (type-params keyword-arrow-type)))
               => "supers")
        (check (type->string
                (type-keyword-parameter-type
                 (caddr (type-params keyword-arrow-type))))
               => "(list SlotProfile)")
        (check (type->string contract-type)
               => "(function (CallFact NativeSignatures ParamEnv) (list TypeFinding))")
        (check (map type->string (type-params contract-type))
               => ["CallFact" "NativeSignatures" "ParamEnv"])
        (check (type->string (type-result contract-type))
               => "(list TypeFinding)")
        (check (type->string identity-type) => "(function (a) a)")
        (check (type-kind (car (type-params identity-type))) => 'variable)
        (check (type-variable-name (type-result identity-type)) => "a")
        (check (type->string hash-type) => "(hash String Number)")
        (check (type-kind hash-type) => 'hash)
        (check (type->string (type-hash-key hash-type)) => "String")
        (check (type->string (type-hash-value hash-type)) => "Number")
        (check (type->string values-type) => "(values String Number)")
        (check (map type->string (type-values-members values-type))
               => ["String" "Number"])
        (check (type->string refine-type) => "(refine Number natural?)")
        (check (type->string (type-refine-base refine-type)) => "Number")
        (check (type-refine-predicate refine-type) => "natural?")
        (check (type->string application-type)
               => "(NonEmptyList TypeFinding)")
        (check (type-kind application-type) => 'application)
        (check (type-name application-type) => "NonEmptyList")
        (check (type->string literal-union-type)
               => "(union 'Left 'Right)")
        (check (type->string application-arrow-type)
               => "(function ((NonEmptyList a)) a)")
        (check (type-kind (car (type-params application-arrow-type)))
               => 'application)
        (check (type->string pair-list-arrow-type)
               => "(function ((list (pair k v)) (list (pair k v))) (list (pair k v)))")
        (check (type->string maybe-arrow-type)
               => "(function ((maybe Type) (maybe Type)) Boolean)")))))

;; : TestSuite
(def types-subtyping-proof-test
  (test-suite "gerbil scheme harness type subtyping proofs"
    (test-case "type specs validate structurally and support subtyping"
      (let* ((number-type (parse-type-contract "Number"))
             (string-type (parse-type-contract "String"))
             (refined-number (parse-type-contract "(Refine Number natural?)"))
             (null-type (parse-type-contract "Null"))
             (number-list (parse-type-contract "(List Number)"))
             (number-pair-list
              (make-type-pair number-type number-list))
             (string-or-number (parse-type-contract "(U String Number)"))
             (non-empty-number
              (parse-type-contract "(NonEmptyList Number)"))
             (non-empty-string
              (parse-type-contract "(NonEmptyList String)"))
             (bad-hash (parse-type-contract "(Hash String)"))
             (bad-values (parse-type-sexpr '(Values)))
             (bad-refine (parse-type-contract "(Refine Number)"))
             (bad-keyword-arrow
              (parse-type-contract "(-> String supers: (List) Result)"))
             (alias-env
              (type-alias-env-bind
               (make-type-alias-env)
               "NonEmptyList"
               1))
             (box-alias-env
              (type-alias-env-bind-type
               alias-env
               "Box"
               ["a"]
               (make-type-list (make-type-variable "a"))))
             (box-number (parse-type-contract "(Box Number)"))
             (bad-hash-diagnostic
              (car (type-validation-diagnostic-facts bad-hash)))
             (bad-application
              (parse-type-contract "(NonEmptyList String Number)"))
             (duplicate-union
              (simplify-union [number-type number-type]))
             (nested-union
              (simplify-union
               [number-type (make-type-union [number-type string-type])]))
             (expected-record
              (make-type-record
               (list (cons "value" number-type))
               ["value"]))
             (actual-record
              (make-type-record
               (list (cons "value" refined-number)
                     (cons "tag" string-type))
               ["value"]))
             (refined-union-proof
              (type-subtype-proof refined-number string-or-number))
             (alias-equivalence-proof
              (type-alias-equivalence-proof box-number
                                            number-list
                                            box-alias-env))
             (alias-compatible-proof
              (type-compatible-proof box-number number-list box-alias-env))
             (record-proof
              (type-subtype-proof actual-record expected-record)))
        (check (type-spec-valid? refined-number) => #t)
        (check (type-validation-diagnostics bad-hash)
               => ["hash-value:unknown-type"])
        (check (type-validation-diagnostic-code bad-hash-diagnostic)
               => "unknown-type")
        (check (type-validation-diagnostic-path bad-hash-diagnostic)
               => ["hash-value"])
        (check (type-validation-diagnostic-category bad-hash-diagnostic)
               => "shape")
        (check (type-validation-diagnostic-message bad-hash-diagnostic)
               => "hash-value:unknown-type")
        (check (type-validation-diagnostics bad-values)
               => ["values-requires-at-least-one-value"])
        (check (type-validation-diagnostics bad-refine)
               => ["refine-requires-predicate"])
        (check (type-validation-diagnostics bad-keyword-arrow)
               => ["function-parameter[1]:keyword-parameter:list-element:unknown-type"])
        (check (type-validation-diagnostics bad-application alias-env)
               => ["application-arity-mismatch:NonEmptyList:expected=1:actual=2"])
        (check (type-subtype? refined-number number-type) => #t)
        (check (type-subtype? number-type refined-number) => #f)
        (check (type-compatible? refined-number number-type) => #t)
        (check (type-compatible? number-type refined-number) => #f)
        (check (type-compatible? number-type string-or-number) => #t)
        (check (type-compatible? null-type number-list) => #t)
        (check (type-compatible? number-list number-pair-list) => #t)
        (check (type->string (type-expand-aliases box-number box-alias-env))
               => "(list Number)")
        (check (type-alias-equivalent? box-number number-list box-alias-env)
               => #t)
        (check (type-alias-equivalent? number-list box-number box-alias-env)
               => #t)
        (check (type-compatible? box-number number-list box-alias-env) => #t)
        (check (type-proof? refined-union-proof) => #t)
        (check (type-proof-rule refined-union-proof) => "refine-base")
        (check (type-proof-conclusion refined-union-proof)
               => ["subtype"
                   "(refine Number natural?)"
                   "(union String Number)"])
        (check (map type-proof-rule (type-proof-premises refined-union-proof))
               => ["union-right"])
        (check (type-proof-rules refined-union-proof)
               => ["refine-base" "union-right" "type-equal"])
        (check (type-proof-depth refined-union-proof) => 3)
        (check (type-proof-node-count refined-union-proof) => 3)
        (check (type-proof-rule alias-equivalence-proof)
               => "alias-equivalent")
        (check (type-proof-detail alias-equivalence-proof)
               => [(cons "leftExpanded" "(list Number)")
                   (cons "rightExpanded" "(list Number)")])
        (check (type-proof-rule alias-compatible-proof)
               => "compatible-subtype")
        (check (type-proof-conclusion alias-compatible-proof)
               => ["compatible" "(list Number)" "(list Number)"])
        (check (map type-proof-rule
                    (type-proof-premises alias-compatible-proof))
               => ["type-equal"])
        (check (type-subtype-proof number-type refined-number) => #f)
        (check (type-compatible-proof number-type refined-number) => #f)
        (check (type->string duplicate-union) => "Number")
        (check (type->string nested-union) => "(union Number String)")
        (check (type=? (simplify-union [nested-union]) nested-union) => #t)
        (check (type-subtype? non-empty-number non-empty-number) => #t)
        (check (type-subtype? refined-number string-or-number) => #t)
        (check (type-subtype? non-empty-number non-empty-string) => #f)
        (check (type-subtype? actual-record expected-record) => #t)
        (check (type-proof-rule record-proof) => "record")
        (check (map type-proof-rule (type-proof-premises record-proof))
               => ["record-field"])
        (let ((record-profile (type-proof-profile-json record-proof))
              (record-json (type-proof-json record-proof)))
          (check (hash-get record-profile 'rootRule) => "record")
          (check (hash-get record-profile 'depth) => 4)
          (check (hash-get record-profile 'nodeCount) => 4)
          (check (hash-get record-json 'rule) => "record")
          (check (hash-get (car (hash-get record-json 'premises)) 'rule)
                 => "record-field"))))))

(def types-object-contract-test
  (test-suite "gerbil scheme harness type object contracts"
    (test-case "type specs expose declarative slot contracts"
      (let* ((number-type (parse-type-contract "Number"))
             (invalid-object "not-a-type-spec")
             (invalid-issues (type-spec-contract-issues invalid-object))
             (contract-alist (type-spec-type-contract->alist))
             (slot-alists (cdr (assoc 'slots contract-alist)))
             (slot-names (map (lambda (slot)
                                (cdr (assoc 'name slot)))
                              slot-alists))
             (slot-types (map (lambda (slot)
                                (cdr (assoc 'type slot)))
                              slot-alists))
             (report-slot-names
              (map (lambda (row)
                     (cdr (assoc 'slot row)))
                   (type-spec-contract-report-rows))))
        (check (require-type-spec-slots! number-type) => number-type)
        (check (type-spec-contract-valid? number-type) => #t)
        (check (type-spec-contract-issues number-type) => '())
        (check (type-spec-contract-valid? invalid-object) => #f)
        (check (length invalid-issues) => 1)
        (check (cdr (assoc 'owner contract-alist)) => 'types)
        (check (cdr (assoc 'object-kind contract-alist)) => 'type-spec)
        (check slot-names => '(kind name params result))
        (check slot-types => '(Symbol Any Any Any))
        (check report-slot-names => '(kind name params result))))
    (test-case "defobject-contract emits executable validation helpers"
      (let* ((valid (make-contract-witness "ready"))
             (invalid (make-contract-witness 7))
             (contract-alist (contract-witness-type-contract->alist))
             (report (contract-witness-contract-report-rows valid)))
        (check (contract-witness? valid) => #t)
        (check (require-contract-witness-slots! valid) => valid)
        (check (contract-witness-contract-valid? valid) => #t)
        (check (contract-witness-contract-valid? invalid) => #f)
        (check (map contract-issue-code
                    (contract-witness-contract-issues invalid))
               => '(slot-predicate))
        (check (cdr (assoc 'owner contract-alist)) => 'types-test)
        (check (map (lambda (row) (cdr (assoc 'status row))) report)
               => '(ok))))))

(def types-full-test
  (test-suite "gerbil scheme harness types"
    types-parser-shape-test
    types-subtyping-proof-test
    types-object-contract-test))
