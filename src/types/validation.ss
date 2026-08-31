;;; -*- Gerbil -*-
;;; Formal TypeSpec validation and compatibility checks.
;;; Boundary: this module validates normalized TypeSpec ASTs after parsing.
;;; Parser syntax errors stay outside this layer; this layer owns semantic
;;; diagnostics, alias arity checks, and conservative compatibility.

(import :gerbil/gambit
        (only-in :std/sugar cut)
        :asp-gerbil-scheme/src/types/model
        :asp-gerbil-scheme/src/types/subtyping)

(export make-type-alias-env
        type-alias-env-bind
        type-alias-env-bind-type
        type-alias-env-lookup
        type-expand-aliases
        type-alias-equivalent?
        type-alias-equivalence-proof
        make-type-proof
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
        make-type-validation-diagnostic
        type-validation-diagnostic-code
        type-validation-diagnostic-path
        type-validation-diagnostic-category
        type-validation-diagnostic-message
        type-validation-diagnostic-facts
        type-validation-diagnostics
        type-spec-valid?
        simplify-union
        type-subtype-proof
        type-subtype?
        type-compatible-proof
        type-compatible?)

;; TypeValidationDiagnostic
(defstruct type-validation-diagnostic (code path category message))

;; make-type-alias-env
;;   : (-> TypeAliasEnv)
;;   | doc m%
;;       `make-type-alias-env` creates the explicit alias-arity environment used
;;       by TypeSpec validation.  Empty environments keep custom applications
;;       valid until a caller provides local alias evidence.
;;     %
(def (make-type-alias-env)
  '())

;; type-alias-env-bind
;;   : (-> TypeAliasEnv TypeName Arity TypeAliasEnv)
;;   | doc m%
;;       `type-alias-env-bind env name arity` records one local type alias
;;       constructor arity without hard-coding project-specific type names.
;;     %
(def (type-alias-env-bind env name arity)
  (cons (cons (validation-name name) arity) env))

;; type-alias-env-bind-type
;;   : (-> TypeAliasEnv TypeName (List TypeVariable) TypeSpec TypeAliasEnv)
;;   | doc m%
;;       `type-alias-env-bind-type env name parameters body` records a local
;;       alias definition that can be expanded and compared structurally.
;;     %
(def (type-alias-env-bind-type env name parameters body)
  (cons (cons (validation-name name)
              (alias-entry (length parameters)
                           (map validation-name parameters)
                           body))
        env))

;; type-alias-env-lookup
;;   : (-> TypeAliasEnv TypeName (Maybe Arity))
;;   | doc m%
;;       `type-alias-env-lookup env name` returns known alias arity evidence for
;;       application validation, leaving unknown aliases unrestricted.
;;     %
(def (type-alias-env-lookup env name)
  (let (entry (type-alias-env-entry env name))
    (and entry (alias-entry-arity entry))))

;; : (-> TypeAliasEnv TypeName (Maybe AliasEntry))
(def (type-alias-env-entry env name)
  (let (found (assoc (validation-name name) env))
    (and found (cdr found))))

;; : (-> Arity (List TypeVariable) TypeSpec AliasEntry)
(def (alias-entry arity parameters body)
  [arity parameters body])

;; : (-> AliasEntry Arity)
(def (alias-entry-arity entry)
  (if (pair? entry) (car entry) entry))

;; : (-> AliasEntry (List TypeVariable))
(def (alias-entry-parameters entry)
  (if (and (pair? entry) (pair? (cdr entry))) (cadr entry) []))

;; : (-> AliasEntry (Maybe TypeSpec))
(def (alias-entry-body entry)
  (and (pair? entry) (pair? (cdr entry)) (pair? (cddr entry)) (caddr entry)))

;; : (-> DiagnosticCode DiagnosticPath DiagnosticCategory DiagnosticDetail TypeValidationDiagnostic)
(def (type-diagnostic code path category detail)
  (make-type-validation-diagnostic
   code
   path
   category
   (diagnostic-message-text code path detail)))

;; : (-> DiagnosticPrefix TypeValidationDiagnostic TypeValidationDiagnostic)
(def (diagnostic-prepend-path prefix diagnostic)
  (make-type-validation-diagnostic
   (type-validation-diagnostic-code diagnostic)
   (cons prefix (type-validation-diagnostic-path diagnostic))
   (type-validation-diagnostic-category diagnostic)
   (string-append prefix ":"
                  (type-validation-diagnostic-message diagnostic))))

;; : (-> DiagnosticCode DiagnosticPath DiagnosticDetail DiagnosticMessage)
(def (diagnostic-message-text code path detail)
  (let (base (if (equal? detail "")
              code
              (string-append code ":" detail)))
    (if (null? path)
      base
      (string-append (diagnostic-path-text path) ":" base))))

;; : (-> DiagnosticPath DiagnosticPathText)
(def (diagnostic-path-text path)
  (cond
   ((null? path) "")
   ((null? (cdr path)) (car path))
   (else
    (string-append (car path) ":" (diagnostic-path-text (cdr path))))))

;; type-validation-diagnostics
;;   : (-> TypeSpec (List Diagnostic))
;;   | doc m%
;;       `type-validation-diagnostics type` validates a parsed TypeSpec as a
;;       structured contract AST.  Parser syntax diagnostics stay separate; this
;;       pass checks normalized semantic nodes and known alias arities.
;;     %
(def (type-validation-diagnostics type . maybe-env)
  (map type-validation-diagnostic-message
       (type-validation-diagnostic-facts* type (optional-alias-env maybe-env))))

;; type-validation-diagnostic-facts
;;   : (-> TypeSpec (List TypeValidationDiagnostic))
;;   | doc m%
;;       `type-validation-diagnostic-facts type` returns structured diagnostics
;;       with stable code, path, category, and display message fields.
;;     %
(def (type-validation-diagnostic-facts type . maybe-env)
  (type-validation-diagnostic-facts* type (optional-alias-env maybe-env)))

;; type-spec-valid?
;;   : (-> TypeSpec ValidationResult)
;;   | type ValidationResult = Boolean
;;   | doc m%
;;       `type-spec-valid? type` is the boolean projection of validation
;;       diagnostics for callers that need a predicate instead of the full list.
;;     %
(def (type-spec-valid? type . maybe-env)
  (null? (type-validation-diagnostic-facts* type (optional-alias-env maybe-env))))

;; simplify-union
;;   : (-> UnionMembers TypeSpec)
;;   | type UnionMembers = (List TypeSpec)
;;   | doc m%
;;       `simplify-union members` flattens nested unions, removes duplicate
;;       members, and returns the single member directly when only one remains.
;;     %
(def (simplify-union members)
  (let (unique (unique-types (flatten-union-members members) []))
    (cond
     ((null? unique) (make-type-union []))
     ((null? (cdr unique)) (car unique))
     (else (make-type-union unique)))))

;; type-expand-aliases
;;   : (-> TypeSpec TypeAliasEnv TypeSpec)
;;   | doc m%
;;       `type-expand-aliases type env` expands application nodes whose
;;       constructor is backed by a local alias body in the validation env.
;;     %
(def (type-expand-aliases type env)
  (type-expand-aliases* type env []))

;; type-alias-equivalent?
;;   : (-> TypeSpec TypeSpec TypeAliasEnv Boolean)
;;   | doc m%
;;       `type-alias-equivalent? left right env` compares two types after local
;;       alias expansion, preserving structural equality as the final relation.
;;     %
(def (type-alias-equivalent? left right env)
  (and (type-alias-equivalence-proof left right env) #t))

;; type-alias-equivalence-proof
;;   : (-> TypeSpec TypeSpec TypeAliasEnv (Maybe TypeProof))
;;   | doc m%
;;       `type-alias-equivalence-proof left right env` returns a positive
;;       derivation witness when local alias expansion makes the two TypeSpec
;;       values structurally equal.  Failure remains `#f`; counterexample
;;       explanation belongs to a later diagnostic layer.
;;     %
(def (type-alias-equivalence-proof left right env)
  (let* ((expanded-left (type-expand-aliases left env))
         (expanded-right (type-expand-aliases right env)))
    (and (type=? expanded-left expanded-right)
         (relation-proof
          "alias-equivalent"
          "alias-equivalent"
          left
          right
          []
          (list (cons "leftExpanded" (type->string expanded-left))
                (cons "rightExpanded" (type->string expanded-right)))))))

;; type-subtype?
;;   : (-> ActualType ExpectedType Boolean)
;;   | doc m%
;;       `type-subtype? actual expected` implements conservative structural
;;       subtyping over TypeSpec values.  Refinements are subtypes of their base,
;;       records are width-subtyped, and unions accept matching alternatives.
;;     %
(def (type-subtype? actual expected . maybe-env)
  (let (env (optional-alias-env maybe-env))
    (and (type-subtype-proof* (type-expand-aliases actual env)
                              (type-expand-aliases expected env)
                              env)
         #t)))

;; type-subtype-proof
;;   : (-> ActualType ExpectedType (Maybe TypeAliasEnv) (Maybe TypeProof))
;;   | doc m%
;;       `type-subtype-proof actual expected [env]` is the internal lightweight
;;       proof witness for conservative structural subtyping.  The boolean
;;       `type-subtype?` API is its projection.
;;     %
(def (type-subtype-proof actual expected . maybe-env)
  (let (env (optional-alias-env maybe-env))
    (type-subtype-proof* (type-expand-aliases actual env)
                         (type-expand-aliases expected env)
                         env)))

;; type-compatible?
;;   : (-> ActualType ExpectedType Boolean)
;;   | doc m%
;;       `type-compatible? actual expected` is the checker-facing relation.
;;       Unknown, Any, and type variables remain permissive to avoid speculative
;;       findings; concrete shapes use formal subtyping.
;;     %
(def (type-compatible? actual expected . maybe-env)
  (and (apply type-compatible-proof actual expected maybe-env) #t))

;; type-compatible-proof
;;   : (-> ActualType ExpectedType (Maybe TypeAliasEnv) (Maybe TypeProof))
;;   | doc m%
;;       `type-compatible-proof actual expected [env]` explains successful
;;       checker-facing compatibility.  Open types are explicit compatibility
;;       rules; concrete cases delegate to subtyping proof.
;;     %
(def (type-compatible-proof actual expected . maybe-env)
  (let* ((env (optional-alias-env maybe-env))
         (expanded-actual (type-expand-aliases actual env))
         (expanded-expected (type-expand-aliases expected env)))
    (cond
     ((type-open? expanded-actual)
      (relation-proof "compatible-open-actual"
                      "compatible"
                      expanded-actual
                      expanded-expected
                      []))
     ((type-open? expanded-expected)
      (relation-proof "compatible-open-expected"
                      "compatible"
                      expanded-actual
                      expanded-expected
                      []))
     (else
      (let (proof (type-subtype-proof* expanded-actual expanded-expected env))
        (and proof
             (relation-proof "compatible-subtype"
                             "compatible"
                             expanded-actual
                             expanded-expected
                             [proof])))))))

;; optional-alias-env
;;   : (-> (List TypeAliasEnv) TypeAliasEnv)
;;   | doc m%
;;       `optional-alias-env maybe-env` gives public variadic validation entry
;;       points a single explicit default for omitted alias evidence.
;;     %
(def (optional-alias-env maybe-env)
  (if (pair? maybe-env) (car maybe-env) (make-type-alias-env)))

;; : (-> Boolean TypeValidationDiagnostic (List TypeValidationDiagnostic) )
(def (type-diagnostic-when condition diagnostic)
  (if condition [diagnostic] []))
;; : (-> TypeSpec TypeAliasEnv (List TypeValidationDiagnostic) )
(def (values-type-diagnostics type env)
  (append
   (type-diagnostic-when
    (not (pair? (type-values-members type)))
    (type-diagnostic "values-requires-at-least-one-value" [] "arity" ""))
   (children-type-diagnostics "values-member"
                              (type-values-members type)
                              env)))
;; : (-> TypeSpec TypeAliasEnv (List TypeValidationDiagnostic) )
(def (refine-type-diagnostics type env)
  (append
   (type-diagnostic-when
    (equal? (type-refine-predicate type) "unknown")
    (type-diagnostic "refine-requires-predicate" [] "arity" ""))
   (child-type-diagnostics "refine-base"
                           (type-refine-base type)
                           env)))
;; : (-> TypeSpec TypeAliasEnv (List TypeValidationDiagnostic) )
(def (function-variadic-type-diagnostics type env)
  (append
   (type-diagnostic-when
    (not (and (integer? (type-function-variadic-min-arity type))
              (>= (type-function-variadic-min-arity type) 0)))
    (type-diagnostic "function-variadic-min-arity-invalid" [] "arity" ""))
   (child-type-diagnostics "function-variadic-parameter"
                           (type-function-variadic-param type)
                           env)
   (child-type-diagnostics "function-variadic-result"
                           (type-result type)
                           env)))
;; : (-> TypeSpec TypeAliasEnv (List TypeValidationDiagnostic) )
(def (union-type-diagnostics type env)
  (append
   (type-diagnostic-when
    (not (pair? (type-union-members type)))
    (type-diagnostic "union-requires-at-least-one-member" [] "arity" ""))
   (children-type-diagnostics "union-member"
                              (type-union-members type)
                              env)))

;;; Validation dispatcher boundary: every TypeSpec variant delegates to the
;;; smallest helper that owns that shape's invariant.
;; : (-> TypeSpec TypeAliasEnv (List TypeValidationDiagnostic))
(def (type-validation-diagnostic-facts* type env)
  (case (type-kind type)
    ((unknown)
     [(type-diagnostic "unknown-type" [] "shape" "")])
    ((any variable base literal-symbol)
     [])
    ((pair)
     (append (child-type-diagnostics "pair-car" (type-pair-car type) env)
             (child-type-diagnostics "pair-cdr" (type-pair-cdr type) env)))
    ((list)
     (child-type-diagnostics "list-element" (type-list-elem type) env))
    ((vector)
     (child-type-diagnostics "vector-element" (type-vector-elem type) env))
    ((maybe)
     (child-type-diagnostics "maybe-element" (type-list-elem type) env))
    ((hash)
     (append (child-type-diagnostics "hash-key" (type-hash-key type) env)
             (child-type-diagnostics "hash-value" (type-hash-value type) env)))
    ((values)
     (values-type-diagnostics type env))
    ((refine)
     (refine-type-diagnostics type env))
    ((application)
     (append (application-arity-diagnostics type env)
             (children-type-diagnostics "application-parameter"
                                        (type-params type)
                                        env)))
    ((function)
     (append (children-type-diagnostics "function-parameter"
                                        (type-params type)
                                        env)
             (child-type-diagnostics "function-result"
                                     (type-result type)
                                     env)))
    ((keyword-parameter)
     (child-type-diagnostics "keyword-parameter"
                             (type-keyword-parameter-type type)
                             env))
    ((function-variadic)
     (function-variadic-type-diagnostics type env))
    ((union)
     (union-type-diagnostics type env))
    ((record)
     (append (record-field-diagnostics (type-record-fields type) env)
             (record-required-diagnostics
              (type-record-required type)
              (type-record-fields type))))
    (else
     [(type-diagnostic "unsupported-type-kind"
                       []
                       "shape"
                       (symbol->string (type-kind type)))])))

;;; Child diagnostics preserve the parent path in each message so nested type
;;; errors stay actionable without allocating a separate tree structure.
;; : (-> DiagnosticPrefix TypeSpec TypeAliasEnv (List Diagnostic))
(def (child-type-diagnostics prefix type env)
  (map (lambda (diagnostic)
         (diagnostic-prepend-path prefix diagnostic))
       (type-validation-diagnostic-facts* type env)))

;; : (-> DiagnosticPrefix (List TypeSpec) TypeAliasEnv (List Diagnostic))
(def (children-type-diagnostics prefix types env)
  (children-type-diagnostics* prefix types 0 env))

;; : (-> DiagnosticPrefix (List TypeSpec) Integer TypeAliasEnv (List Diagnostic))
(def (children-type-diagnostics* prefix types index env)
  (if (null? types)
    []
    (append
     (child-type-diagnostics
      (string-append prefix "[" (number->string index) "]")
      (car types)
      env)
     (children-type-diagnostics* prefix (cdr types) (fx1+ index) env))))

;; : (-> TypeSpec TypeAliasEnv (List Diagnostic))
(def (application-arity-diagnostics type env)
  (let (expected (type-alias-env-lookup env (type-name type)))
    (if (and expected (not (= expected (length (type-params type)))))
      [(type-diagnostic
        "application-arity-mismatch"
        []
        "arity"
        (string-append (type-name type)
                       ":expected="
                       (number->string expected)
                       ":actual="
                       (number->string (length (type-params type)))))]
      [])))

;; : (-> TypeFields TypeAliasEnv (List Diagnostic))
(def (record-field-diagnostics fields env)
  (append (record-duplicate-field-diagnostics fields [])
          (record-field-type-diagnostics fields env)))

;; : (-> TypeFields (List FieldName) (List Diagnostic))
(def (record-duplicate-field-diagnostics fields seen)
  (cond
   ((null? fields) [])
   ((member (caar fields) seen)
    (cons (type-diagnostic "record-duplicate-field"
                           []
                           "shape"
                           (caar fields))
          (record-duplicate-field-diagnostics (cdr fields) seen)))
   (else
    (record-duplicate-field-diagnostics
     (cdr fields)
     (cons (caar fields) seen)))))

;; : (-> TypeFields TypeAliasEnv (List Diagnostic))
(def (record-field-type-diagnostics fields env)
  (if (null? fields)
    []
    (append
     (child-type-diagnostics
      (string-append "record-field:" (caar fields))
      (cdar fields)
      env)
     (record-field-type-diagnostics (cdr fields) env))))

;; : (-> (List FieldName) TypeFields (List Diagnostic))
(def (record-required-diagnostics required fields)
  (cond
   ((null? required) [])
   ((assoc (car required) fields)
    (record-required-diagnostics (cdr required) fields))
   (else
    (cons (type-diagnostic "record-required-field-missing"
                           []
                           "shape"
                           (car required))
          (record-required-diagnostics (cdr required) fields)))))

;;; Alias expansion is a pure TypeSpec transform.  It rewrites only known
;;; application aliases and leaves arity-mismatched or cyclic aliases visible.
;; : (-> TypeSpec TypeAliasEnv (List TypeName) TypeSpec)
(def (type-expand-aliases* type env seen)
  (case (type-kind type)
    ((pair)
     (make-type-pair (type-expand-aliases* (type-pair-car type) env seen)
                     (type-expand-aliases* (type-pair-cdr type) env seen)))
    ((list)
     (make-type-list (type-expand-aliases* (type-list-elem type) env seen)))
    ((vector)
     (make-type-vector (type-expand-aliases* (type-vector-elem type) env seen)))
    ((maybe)
     (make-type-maybe (type-expand-aliases* (type-list-elem type) env seen)))
    ((hash)
     (make-type-hash (type-expand-aliases* (type-hash-key type) env seen)
                     (type-expand-aliases* (type-hash-value type) env seen)))
    ((values)
     (make-type-values (map (cut type-expand-aliases* <> env seen)
                            (type-values-members type))))
    ((refine)
     (make-type-refine (type-expand-aliases* (type-refine-base type) env seen)
                       (type-refine-predicate type)))
    ((application)
     (expand-application-alias type env seen))
    ((function)
     (make-type-function (map (cut type-expand-aliases* <> env seen)
                              (type-params type))
                         (type-expand-aliases* (type-result type) env seen)))
    ((function-variadic)
     (make-type-function-variadic
      (type-expand-aliases* (type-function-variadic-param type) env seen)
      (type-expand-aliases* (type-result type) env seen)
      (type-function-variadic-min-arity type)))
    ((union)
     (simplify-union (map (cut type-expand-aliases* <> env seen)
                          (type-union-members type))))
    ((record)
     (make-type-record
      (map (lambda (field)
             (cons (car field)
                   (type-expand-aliases* (cdr field) env seen)))
           (type-record-fields type))
      (type-record-required type)))
    (else type)))

;;; Alias application boundary:
;;; - Arity mismatch and cycles stay visible as application nodes.
;;; - Only complete local alias evidence rewrites the TypeSpec tree.
;; : (-> TypeSpec TypeAliasEnv (List TypeName) TypeSpec)
(def (expand-application-alias type env seen)
  (let* ((name (type-name type))
         (entry (type-alias-env-entry env name))
         (expanded-params (map (cut type-expand-aliases* <> env seen)
                               (type-params type)))
         (body (and entry (alias-entry-body entry))))
    (cond
     ((not body)
      (make-type-application name expanded-params))
     ((member name seen)
      (make-type-application name expanded-params))
     ((not (= (alias-entry-arity entry) (length expanded-params)))
      (make-type-application name expanded-params))
     (else
      (type-expand-aliases*
       (type-substitute-alias-parameters
        body
        (alias-parameter-bindings (alias-entry-parameters entry)
                                  expanded-params))
       env
       (cons name seen))))))

;; : (-> (List TypeVariable) (List TypeSpec) AliasParameterBindings)
(def (alias-parameter-bindings parameters values)
  (cond
   ((and (null? parameters) (null? values)) [])
   ((or (null? parameters) (null? values)) [])
   (else
    (cons (cons (car parameters) (car values))
          (alias-parameter-bindings (cdr parameters) (cdr values))))))

;;; Substitution invariant:
;;; - Replace only explicit alias type variables.
;;; - Preserve constructors and predicates so expansion does not invent grammar.
;; : (-> TypeSpec AliasParameterBindings TypeSpec)
(def (type-substitute-alias-parameters type bindings)
  (case (type-kind type)
    ((variable)
     (let (binding (assoc (type-variable-name type) bindings))
       (if binding (cdr binding) type)))
    ((pair)
     (make-type-pair
      (type-substitute-alias-parameters (type-pair-car type) bindings)
      (type-substitute-alias-parameters (type-pair-cdr type) bindings)))
    ((list)
     (make-type-list
      (type-substitute-alias-parameters (type-list-elem type) bindings)))
    ((vector)
     (make-type-vector
      (type-substitute-alias-parameters (type-vector-elem type) bindings)))
    ((maybe)
     (make-type-maybe
      (type-substitute-alias-parameters (type-list-elem type) bindings)))
    ((hash)
     (make-type-hash
      (type-substitute-alias-parameters (type-hash-key type) bindings)
      (type-substitute-alias-parameters (type-hash-value type) bindings)))
    ((values)
     (make-type-values
      (map (cut type-substitute-alias-parameters <> bindings)
           (type-values-members type))))
    ((refine)
     (make-type-refine
      (type-substitute-alias-parameters (type-refine-base type) bindings)
      (type-refine-predicate type)))
    ((application)
     (make-type-application
      (type-name type)
      (map (cut type-substitute-alias-parameters <> bindings)
           (type-params type))))
    ((function)
     (make-type-function
      (map (cut type-substitute-alias-parameters <> bindings)
           (type-params type))
      (type-substitute-alias-parameters (type-result type) bindings)))
    ((function-variadic)
     (make-type-function-variadic
      (type-substitute-alias-parameters
       (type-function-variadic-param type)
       bindings)
      (type-substitute-alias-parameters (type-result type) bindings)
      (type-function-variadic-min-arity type)))
    ((union)
     (make-type-union
      (map (cut type-substitute-alias-parameters <> bindings)
           (type-union-members type))))
    ((record)
     (make-type-record
      (map (lambda (field)
             (cons (car field)
                   (type-substitute-alias-parameters (cdr field) bindings)))
           (type-record-fields type))
      (type-record-required type)))
    (else type)))

;; flatten-union-members
;;   : (-> UnionMembers UnionMembers)
;;   | type UnionMembers = (List TypeSpec)
;;   | doc m%
;;       `flatten-union-members members` removes only nested union shells.  It
;;       preserves source-order member evidence for the duplicate-removal pass.
;;     %
(def (flatten-union-members members)
  (cond
   ((null? members) [])
   ((eq? (type-kind (car members)) 'union)
    (append (flatten-union-members (type-union-members (car members)))
            (flatten-union-members (cdr members))))
   (else
    (cons (car members) (flatten-union-members (cdr members))))))

;; unique-types
;;   : (-> UnionMembers UnionMembers UnionMembers)
;;   | type UnionMembers = (List TypeSpec)
;;   | doc m%
;;       `unique-types members out` keeps the first structural occurrence of
;;       each type while preserving the caller-facing order after reversal.
;;     %
(def (unique-types members out)
  (cond
   ((null? members) (reverse out))
   ((contains-type? (car members) out)
    (unique-types (cdr members) out))
   (else
    (unique-types (cdr members) (cons (car members) out)))))

;; contains-type?
;;   : (-> TypeSpec UnionMembers Boolean)
;;   | type UnionMembers = (List TypeSpec)
;;   | doc m%
;;       `contains-type? target members` uses TypeSpec equality, not string
;;       display text, when deciding whether union normalization has a duplicate.
;;     %
(def (contains-type? target members)
  (cond
   ((null? members) #f)
   ((type=? target (car members)) #t)
   (else (contains-type? target (cdr members)))))

;; : (-> TypeName TypeName)
(def (validation-name name)
  (cond
   ((symbol? name) (symbol->string name))
   ((string? name) name)
   (else "unknown")))
