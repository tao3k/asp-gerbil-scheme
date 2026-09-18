;;; -*- Gerbil -*-
;;; Conservative TypeSpec subtyping proof engine.

(import :gerbil/gambit
        (only-in :std/sugar hash)
        :asp-gerbil-scheme/src/types/model)

(export make-type-proof
        type-proof?
        type-proof-rule
        type-proof-conclusion
        type-proof-premises
        type-proof-detail
        type-proof-rules
        type-proof-depth
        type-proof-node-count
        type-proof-json
        type-proof-profile-json
        relation-proof
        type-open?
        type-subtype-proof*
        type-subtype?*)

;; TypeProof
(defstruct type-proof (rule conclusion premises detail))

;; type-proof-rules
;;   : (-> TypeProof (List TypeProofRule))
;;   | doc m%
;;       `type-proof-rules proof` returns a preorder rule chain so policy code
;;       can combine proof signals without knowing the proof tree layout.
;;     %
(def (type-proof-rules proof)
  (cons (type-proof-rule proof)
        (apply append (map type-proof-rules (type-proof-premises proof)))))

;; type-proof-depth
;;   : (-> TypeProof PositiveInteger)
;;   | doc m%
;;       `type-proof-depth proof` measures the derivation tree depth so command
;;       packets can expose proof cost without knowing the tree layout.
;;     %
(def (type-proof-depth proof)
  (let (premises (type-proof-premises proof))
    (if (null? premises)
      1
      (+ 1 (foldl max 0 (map type-proof-depth premises))))))

;; type-proof-node-count
;;   : (-> TypeProof PositiveInteger)
;;   | doc m%
;;       `type-proof-node-count proof` counts derivation nodes for stable
;;       medium-weight proof budgeting and packet validation.
;;     %
(def (type-proof-node-count proof)
  (+ 1 (foldl + 0 (map type-proof-node-count
                       (type-proof-premises proof)))))

;; type-proof-json
;;   : (-> TypeProof Json)
;;   | doc m%
;;       `type-proof-json proof` is the stable recursive projection of a
;;       TypeProof.  It is evidence serialization, not a separate prover.
;;     %
(def (type-proof-json proof)
  (hash (rule (type-proof-rule proof))
        (conclusion (type-proof-conclusion proof))
        (detail (type-proof-detail-json (type-proof-detail proof)))
        (premises (map type-proof-json (type-proof-premises proof)))))

;;; Detail projection is an order-preserving map from internal alist evidence
;;; to schema nodes.  Validation already happened at proof construction, so this
;;; layer only serializes keys and values without mutating the witness.
;; : (-> TypeProofDetail Json)
(def (type-proof-detail-json detail)
  (map (lambda (entry)
         (hash (key (car entry))
               (value (cdr entry))))
       detail))

;; type-proof-profile-json
;;   : (-> TypeProof Json)
;;   | doc m%
;;       `type-proof-profile-json proof` exposes root rule, depth, node count,
;;       and preorder rule chain for policy/search consumers.
;;     %
(def (type-proof-profile-json proof)
  (hash (rootRule (type-proof-rule proof))
        (conclusion (type-proof-conclusion proof))
        (depth (type-proof-depth proof))
        (nodeCount (type-proof-node-count proof))
        (rules (type-proof-rules proof))))

;; : (-> TypeRelation TypeSpec TypeSpec TypeProofConclusion)
(def (proof-conclusion relation actual expected)
  [relation (type->string actual) (type->string expected)])

;; : (-> (List TypeProofDetail) TypeProofDetail)
(def (optional-proof-detail maybe-detail)
  (if (pair? maybe-detail) (car maybe-detail) []))

;; : (-> TypeProofRule TypeRelation TypeSpec TypeSpec (List TypeProof) TypeProof)
(def (relation-proof rule relation actual expected premises . maybe-detail)
  (make-type-proof rule
                   (proof-conclusion relation actual expected)
                   premises
                   (optional-proof-detail maybe-detail)))

;; : (-> TypeProofRule TypeSpec TypeSpec (List TypeProof) TypeProof)
(def (subtype-proof rule actual expected premises . maybe-detail)
  (make-type-proof rule
                   (proof-conclusion "subtype" actual expected)
                   premises
                   (optional-proof-detail maybe-detail)))

;; type-open?
;;   : (-> TypeSpec OpenTypePredicate)
;;   | type OpenTypePredicate = Boolean
;;   | doc m%
;;       `type-open? type` identifies permissive type variables that should not
;;       produce speculative compatibility findings.
;;     %
(def (type-open? type)
  (member (type-kind type) '(unknown any variable)))

;;; Subtyping boundary:
;;; - This relation is intentionally conservative.
;;; - Unknowns only match through compatibility wrappers, not subtype proof.
;;; - Each positive branch returns a TypeProof so policy/check callers can cite
;;;   structural evidence instead of a bare boolean.
;; : (-> ActualType ExpectedType TypeAliasEnv Boolean)
(def (type-subtype?* actual expected env)
  (and (type-subtype-proof* actual expected env) #t))

;;; Proof dispatch boundary:
;;; - Branch order keeps exact equality and open expected types cheap.
;;; - Recursive branches must return TypeProof evidence, never bare truth.
;;; - Compatibility owns permissive unknown handling outside this subtype core.
;; : (-> ActualType ExpectedType TypeAliasEnv (Maybe TypeProof))
(def (type-subtype-proof* actual expected env)
  (cond
   ((type=? actual expected)
    (subtype-proof "type-equal" actual expected []))
   ((eq? (type-kind expected) 'any)
    (subtype-proof "expected-any" actual expected []))
   ((or (eq? (type-kind actual) 'unknown)
        (eq? (type-kind expected) 'unknown))
    #f)
   ((and (base-type-name? actual ["Null" "null"])
         (eq? (type-kind expected) 'list))
    (subtype-proof "null-list" actual expected []))
   ((and (eq? (type-kind actual) 'refine)
         (eq? (type-kind expected) 'refine))
    (and (equal? (type-refine-predicate actual)
                 (type-refine-predicate expected))
         (let (proof (type-subtype-proof* (type-refine-base actual)
                                          (type-refine-base expected)
                                          env))
           (and proof
                (subtype-proof "refine" actual expected [proof])))))
   ((eq? (type-kind actual) 'refine)
    (let (proof (type-subtype-proof* (type-refine-base actual) expected env))
      (and proof
           (subtype-proof "refine-base" actual expected [proof]))))
   ((eq? (type-kind expected) 'union)
    (let (proof (any-type-subtype-proof actual (type-union-members expected) env))
      (and proof
           (subtype-proof "union-right" actual expected [proof]))))
   ((eq? (type-kind actual) 'union)
    (let (proofs (all-type-subtype-proofs (type-union-members actual)
                                          expected
                                          env))
      (and proofs
           (subtype-proof "union-left" actual expected proofs))))
   ((and (eq? (type-kind actual) 'list)
         (eq? (type-kind expected) 'list))
    (let (proof (type-subtype-proof* (type-list-elem actual)
                                     (type-list-elem expected)
                                     env))
      (and proof
           (subtype-proof "list" actual expected [proof]))))
   ((and (eq? (type-kind actual) 'vector)
         (eq? (type-kind expected) 'vector))
    (let (proof (type-subtype-proof* (type-vector-elem actual)
                                     (type-vector-elem expected)
                                     env))
      (and proof
           (subtype-proof "vector" actual expected [proof]))))
   ((and (eq? (type-kind actual) 'maybe)
         (eq? (type-kind expected) 'maybe))
    (let (proof (type-subtype-proof* (type-list-elem actual)
                                     (type-list-elem expected)
                                     env))
      (and proof
           (subtype-proof "maybe" actual expected [proof]))))
   ((and (eq? (type-kind actual) 'pair)
         (eq? (type-kind expected) 'pair))
    (let* ((car-proof (type-subtype-proof* (type-pair-car actual)
                                           (type-pair-car expected)
                                           env))
           (cdr-proof (and car-proof
                           (type-subtype-proof* (type-pair-cdr actual)
                                                (type-pair-cdr expected)
                                                env))))
      (and car-proof
           cdr-proof
           (subtype-proof "pair" actual expected [car-proof cdr-proof]))))
   ((and (eq? (type-kind actual) 'list)
         (eq? (type-kind expected) 'pair))
    (let* ((car-proof (type-subtype-proof* (type-list-elem actual)
                                           (type-pair-car expected)
                                           env))
           (cdr-proof (and car-proof
                           (type-subtype-proof* actual
                                                (type-pair-cdr expected)
                                                env))))
      (and car-proof
           cdr-proof
           (subtype-proof "list-pair" actual expected [car-proof cdr-proof]))))
   ((and (eq? (type-kind actual) 'hash)
         (eq? (type-kind expected) 'hash))
    (let* ((key-proof (type-subtype-proof* (type-hash-key actual)
                                           (type-hash-key expected)
                                           env))
           (value-proof (and key-proof
                             (type-subtype-proof* (type-hash-value actual)
                                                  (type-hash-value expected)
                                                  env))))
      (and key-proof
           value-proof
           (subtype-proof "hash" actual expected [key-proof value-proof]))))
   ((and (eq? (type-kind actual) 'values)
         (eq? (type-kind expected) 'values))
    (let (proofs (types-subtype-proofs (type-values-members actual)
                                       (type-values-members expected)
                                       env))
      (and proofs
           (subtype-proof "values" actual expected proofs))))
   ((and (eq? (type-kind actual) 'application)
         (eq? (type-kind expected) 'application))
    (and (equal? (type-name actual) (type-name expected))
         (let (proofs (types-subtype-proofs (type-params actual)
                                            (type-params expected)
                                            env))
           (and proofs
                (subtype-proof "application" actual expected proofs)))))
   ((and (eq? (type-kind actual) 'function)
         (eq? (type-kind expected) 'function))
    (function-subtype-proof actual expected env))
   ((and (eq? (type-kind actual) 'function-variadic)
         (eq? (type-kind expected) 'function-variadic))
    (function-variadic-subtype-proof actual expected env))
   ((and (eq? (type-kind actual) 'record)
         (eq? (type-kind expected) 'record))
    (record-subtype-proof actual expected env))
   (else #f)))

;; : (-> TypeSpec (List TypeSpec) TypeAliasEnv (Maybe TypeProof))
(def (any-type-subtype-proof actual expected-members env)
  (cond
   ((null? expected-members) #f)
   (else
    (or (type-subtype-proof* actual (car expected-members) env)
        (any-type-subtype-proof actual (cdr expected-members) env)))))

;; : (-> (List TypeSpec) TypeSpec TypeAliasEnv (Maybe (List TypeProof)))
(def (all-type-subtype-proofs actual-members expected env)
  (cond
   ((null? actual-members) [])
   (else
    (let (proof (type-subtype-proof* (car actual-members) expected env))
      (and proof
           (let (rest (all-type-subtype-proofs (cdr actual-members)
                                               expected
                                               env))
             (and rest (cons proof rest))))))))

;; : (-> (List TypeSpec) (List TypeSpec) TypeAliasEnv (Maybe (List TypeProof)))
(def (types-subtype-proofs actual expected env)
  (cond
   ((and (null? actual) (null? expected)) [])
   ((or (null? actual) (null? expected)) #f)
   (else
    (let (proof (type-subtype-proof* (car actual) (car expected) env))
      (and proof
           (let (rest (types-subtype-proofs (cdr actual) (cdr expected) env))
             (and rest (cons proof rest))))))))

;; : (-> ActualFunction ExpectedFunction TypeAliasEnv (Maybe TypeProof))
(def (function-subtype-proof actual expected env)
  (and (= (length (type-params actual)) (length (type-params expected)))
       (let (param-proofs (function-params-contravariant-proofs
                           (type-params actual)
                           (type-params expected)
                           env))
         (and param-proofs
              (let (result-proof (type-subtype-proof* (type-result actual)
                                                      (type-result expected)
                                                      env))
                (and result-proof
                     (subtype-proof "function"
                                    actual
                                    expected
                                    (append param-proofs [result-proof]))))))))

;; : (-> ActualParams ExpectedParams TypeAliasEnv (Maybe (List TypeProof)))
(def (function-params-contravariant-proofs actual expected env)
  (cond
   ((and (null? actual) (null? expected)) [])
   ((or (null? actual) (null? expected)) #f)
   (else
    (let (proof (type-subtype-proof* (car expected) (car actual) env))
      (and proof
           (let (rest (function-params-contravariant-proofs
                       (cdr actual)
                       (cdr expected)
                       env))
             (and rest (cons proof rest))))))))

;; : (-> ActualFunction ExpectedFunction TypeAliasEnv (Maybe TypeProof))
(def (function-variadic-subtype-proof actual expected env)
  (and (>= (type-function-variadic-min-arity actual)
           (type-function-variadic-min-arity expected))
       (let* ((param-proof (type-subtype-proof*
                            (type-function-variadic-param expected)
                            (type-function-variadic-param actual)
                            env))
              (result-proof (and param-proof
                                 (type-subtype-proof* (type-result actual)
                                                      (type-result expected)
                                                      env))))
         (and param-proof
              result-proof
              (subtype-proof
               "function-variadic"
               actual
               expected
               [param-proof result-proof]
               (list (cons "actualMinArity"
                           (type-function-variadic-min-arity actual))
                     (cons "expectedMinArity"
                           (type-function-variadic-min-arity expected))))))))

;; : (-> ActualRecord ExpectedRecord TypeAliasEnv (Maybe TypeProof))
(def (record-subtype-proof actual expected env)
  (let (proofs (record-fields-subtype-proofs (type-record-fields actual)
                                             (type-record-fields expected)
                                             env))
    (and proofs
         (subtype-proof "record" actual expected proofs))))

;; : (-> ActualFields ExpectedFields TypeAliasEnv (Maybe (List TypeProof)))
(def (record-fields-subtype-proofs actual-fields expected-fields env)
  (cond
   ((null? expected-fields) [])
   (else
    (let (actual-field (assoc (caar expected-fields) actual-fields))
      (and actual-field
           (let (field-proof (type-subtype-proof* (cdr actual-field)
                                                  (cdar expected-fields)
                                                  env))
             (and field-proof
                  (let (rest (record-fields-subtype-proofs
                              actual-fields
                              (cdr expected-fields)
                              env))
                    (and rest
                         (cons
                          (make-type-proof "record-field"
                                           ["record-field"
                                            (caar expected-fields)]
                                           [field-proof]
                                           [])
                          rest))))))))))

;; base-type-name?
;;   : (-> TypeSpec (List TypeName) Boolean)
;;   | doc m%
;;       `base-type-name? type names` gates Scheme-list compatibility rules to
;;       explicit base types such as `Null`, avoiding alias or variable matches.
;;     %
(def (base-type-name? type names)
  (and (eq? (type-kind type) 'base)
       (member (type-name type) names)))
