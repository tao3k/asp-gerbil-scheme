;;; -*- Gerbil -*-
;;; Downstream-facing validation facade for POO object field contracts.
;;; Boundary:
;;; - Thin TypeSpec modules own parsing and semantic validation.
;;; - This module owns runtime object contract validation for downstream module
;;;   systems without importing agent-facing pattern registries.

(import :gerbil/gambit
        (only-in :std/sugar hash)
        (only-in :asp-gerbil-scheme/src/extensions/poo-source-ref-validation
                 poo-object-source-ref-structural-validation)
        (only-in :asp-gerbil-scheme/src/types/model
                 parse-type-sexpr
                 type->string)
        (only-in :asp-gerbil-scheme/src/types/validation
                 type-spec-valid?
                 type-validation-diagnostics))

(export poo-object-type-spec-validation
        poo-object-source-ref-structural-validation
        poo-object-field-contract-validation
        poo-object-field-contracts-validation
        poo-object-contract-validation
        poo-object-validation-valid?)

(def +poo-object-contract-validation-schema+
  "poo-object-contract-validation/v1")

(def +poo-object-field-merge-kinds+
  '(override append prepend remove node-extend node-remove))

;; : (-> Dyn String)
;;; Boundary: diagnostics must preserve the original datum spelling without
;;; evaluating it. `write` gives stable Scheme-readable evidence for symbols,
;;; lists, strings, and unexpected dynamic values.
(def (value->string value)
  (call-with-output-string ""
    (lambda (out) (write value out))))

;; : (-> String Dyn)
;;; Boundary: downstream contracts may encode type expressions as strings.
;;; Failed reads intentionally fall back to the original string so validation
;;; reports an unparseable type instead of raising out of the policy path.
(def (string->datum value)
  (with-catch
   (lambda (_) value)
   (lambda ()
     (call-with-input-string value read))))

;; : (-> Dyn Dyn)
(def (type-expression-datum value)
  (cond
   ((symbol? value) value)
   ((string? value) (string->datum value))
   (else value)))

;; association-entry?
;;   : (-> Dyn Boolean)
;;   | doc m%
;;       `association-entry? value` keeps field metadata validation focused on
;;       alist shape only. It does not interpret metadata keys or values.
;;     %
(def (association-entry? value)
  (pair? value))

;; metadata-list?
;;   : (-> Dyn Boolean)
;;   | doc m%
;;       `metadata-list? value` accepts the POO field metadata shape consumed by
;;       downstream object contracts: an empty list or a list of association
;;       pairs. Hash tables and vectors are rejected before they reach JSON
;;       diagnostics so agents get a precise repair signal.
;;
;;       The `andmap` composition is intentional: empty metadata is valid, and
;;       every non-empty element must satisfy the same pair-shaped predicate.
;;     %
(def (metadata-list? value)
  (and (list? value)
       (andmap association-entry? value)))

;; : (-> Symbol Boolean)
(def (merge-kind? value)
  (memq value +poo-object-field-merge-kinds+))

;; : (-> Dyn (Maybe Symbol))
(def (base-type-name value-kind)
  (cond
   ((symbol? value-kind) value-kind)
   ((string? value-kind)
    (let (datum (string->datum value-kind))
      (and (symbol? datum) datum)))
   (else #f)))

;; : (-> Dyn Dyn Boolean)
(def (default-matches-type? value-kind value)
  (or (not value)
      (case (base-type-name value-kind)
        ((Any) #t)
        ((Symbol) (symbol? value))
        ((String) (string? value))
        ((List) (list? value))
        ((Boolean) (boolean? value))
        ((Number) (number? value))
        (else #t))))

;; : (-> Dyn Dyn Dyn Dyn Dyn (List String))
(def (field-contract-diagnostics field value-kind merge default metadata)
  (append
   (if (merge-kind? merge)
     []
     [(string-append "field:" (value->string field) ":unsupported-merge:"
                     (value->string merge))])
   (if (metadata-list? metadata)
     []
     [(string-append "field:" (value->string field)
                     ":metadata-not-association-list")])
   (if (default-matches-type? value-kind default)
     []
     [(string-append "field:" (value->string field)
                     ":default-not-compatible-with-type:"
                     (value->string value-kind))])))

;; : (-> Dyn Json)
(def (poo-object-type-spec-validation value-kind)
  (let* ((datum (type-expression-datum value-kind))
         (type-spec (parse-type-sexpr datum))
         (diagnostics
          (if type-spec
            (type-validation-diagnostics type-spec)
            [(string-append "type-expression:unparseable:"
                            (value->string value-kind))])))
    (hash (kind "poo-object-type-spec-validation")
          (schema +poo-object-contract-validation-schema+)
          (valueKind (value->string value-kind))
          (typeDisplay (and type-spec (type->string type-spec)))
          (valid (and type-spec
                      (type-spec-valid? type-spec)
                      (not (pair? diagnostics))))
          (diagnostics diagnostics))))

;; : (-> HashTable Symbol Dyn Dyn)
(def (hash-ref/default table key default)
  (let (value (hash-get table key))
    (if value value default)))

;; : (-> Dyn Symbol Dyn Dyn)
(def (field-contract-ref field key . maybe-default)
  (let (default (if (null? maybe-default) #f (car maybe-default)))
    (cond
     ((hash-table? field) (hash-ref/default field key default))
     ((list? field)
      (let (entry (assoc key field))
        (if entry (cdr entry) default)))
     (else default))))

;; : (-> Dyn Dyn)
(def (field-contract-id field)
  (or (field-contract-ref field 'field)
      (field-contract-ref field 'id)
      (field-contract-ref field 'identity)
      'unknown-field))

;; : (-> Dyn Dyn Dyn Json)
;;; Boundary: this is the single-field adapter between POO structural evidence
;;; and TypeSpec validation. It keeps field shape, type validation, and default
;;; compatibility as separate checkedSignals so agent repairs can target the
;;; failing layer instead of rewriting the object contract wholesale.
(def (poo-object-field-contract-validation object field source-ref)
  (let* ((field-id (field-contract-id field))
         (value-kind (field-contract-ref field 'valueKind
                                         (field-contract-ref field 'value-kind
                                                             'Any)))
         (merge (field-contract-ref field 'merge 'override))
         (default (field-contract-ref field 'default #f))
         (metadata (field-contract-ref field 'metadata '()))
         (type-validation (poo-object-type-spec-validation value-kind))
         (structural-validation
          (poo-object-source-ref-structural-validation source-ref))
         (diagnostics
          (append (hash-get type-validation 'diagnostics)
                  (field-contract-diagnostics field-id
                                              value-kind
                                              merge
                                              default
                                              metadata))))
    (hash (kind "poo-object-field-contract-validation")
          (schema +poo-object-contract-validation-schema+)
          (object object)
          (field field-id)
          (valueKind (value->string value-kind))
          (merge merge)
          (typeValidation type-validation)
          (structuralValidation structural-validation)
          (valid (and (hash-get type-validation 'valid)
                      (hash-get structural-validation 'valid)
                      (not (pair? diagnostics))))
          (diagnostics diagnostics)
          (checkedSignals
           ["poo-pattern-structural-validation"
            "typespec-validation"
            "field-merge-kind"
            "field-default-kind"
            "field-metadata-shape"]))))

;; : (-> Json Boolean)
(def (poo-object-validation-valid? validation)
  (and (hash-table? validation)
       (hash-get validation 'valid)))

;; : (-> (List Json) Boolean)
;;; Combinator boundary: aggregate validity is the conjunction of independent
;;; field validation packets. `andmap` keeps that invariant visible and avoids
;;; a hand-rolled recursive loop over JSON facts.
(def (validations-valid? validations)
  (andmap poo-object-validation-valid? validations))

;; : (-> (List (List Dyn)) (List Dyn))
(def (append-lists lists)
  (if (null? lists)
    []
    (apply append lists)))

;; : (-> Dyn (List Dyn) Dyn Json)
;;; Data-flow boundary: field contracts are validated independently, then their
;;; diagnostics are flattened without interpreting the field payloads again.
;;; This keeps per-field evidence stable for snapshot and agent-facing output.
(def (poo-object-field-contracts-validation object fields source-ref)
  (let* ((validations
          (map (lambda (field)
                 (poo-object-field-contract-validation object field source-ref))
               fields))
         (diagnostics
          (append-lists (map (lambda (validation)
                               (hash-get validation 'diagnostics))
                             validations))))
    (hash (kind "poo-object-field-contracts-validation")
          (schema +poo-object-contract-validation-schema+)
          (object object)
          (fieldValidations validations)
          (valid (validations-valid? validations))
          (diagnostics diagnostics))))

;; : (-> Dyn (List Dyn) Dyn Json)
(def (poo-object-contract-validation object fields source-ref)
  (let* ((structural-validation
          (poo-object-source-ref-structural-validation source-ref))
         (field-contracts-validation
          (poo-object-field-contracts-validation object fields source-ref))
         (diagnostics
          (append (hash-get structural-validation 'diagnostics)
                  (hash-get field-contracts-validation 'diagnostics))))
    (hash (kind "poo-object-contract-validation")
          (schema +poo-object-contract-validation-schema+)
          (object object)
          (structuralValidation structural-validation)
          (fieldContractsValidation field-contracts-validation)
          (valid (and (hash-get structural-validation 'valid)
                      (hash-get field-contracts-validation 'valid)
                      (not (pair? diagnostics))))
          (diagnostics diagnostics)
          (checkedSignals
           ["poo-pattern-structural-validation"
            "field-contracts-validation"]))))
