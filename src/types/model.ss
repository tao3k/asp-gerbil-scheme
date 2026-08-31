;;; -*- Gerbil -*-
;;; Native type representation for Gerbil type facts.
;;; Boundary: this module owns normalized TypeSpec data, parsing, equality, and
;;; display projection. Validation, compatibility, and proof rules live in
;;; sibling modules so the model layer stays constructor-oriented.

(import :gerbil/gambit
        (only-in :std/srfi/1 drop-right every last lset=)
        :asp-gerbil-scheme/src/utilities/functional
        (only-in :std/sugar cut filter-map ormap)
        (only-in :asp-gerbil-scheme/src/utilities/contracts
                 make-object-type-contract
                 make-slot-contract
                 object-contract-issues
                 object-contract-valid?
                 require-object-contract!)
        (only-in :asp-gerbil-scheme/src/utilities/projection
                 object-contract-report-rows
                 object-type-contract->alist)
        :asp-gerbil-scheme/src/utilities/contract-syntax)

(export make-type-unknown
        make-type-any
        make-type-base
        make-type-variable
        make-type-pair
        make-type-list
        make-type-vector
        make-type-maybe
        make-type-hash
        make-type-values
        make-type-refine
        make-type-application
        make-type-literal-symbol
        make-type-function
        make-type-keyword-parameter
        make-type-function-variadic
        make-type-union
        make-type-record
        type-kind
        type-name
        type-variable-name
        type-params
        type-result
        type-pair-car
        type-pair-cdr
        type-list-elem
        type-vector-elem
        type-hash-key
        type-hash-value
        type-values-members
        type-refine-base
        type-refine-predicate
        type-keyword-parameter-name
        type-keyword-parameter-type
        type-function-variadic-param
        type-function-variadic-min-arity
        type-union-members
        type-record-fields
        type-record-required
        record-field-type
        type=?
        +type-spec-slot-contracts+
        +type-spec-type-contract+
        require-type-spec-slots!
        type-spec-type-contract->alist
        type-spec-contract-issues
        type-spec-contract-valid?
        type-spec-contract-report-rows
        type->string
        parse-type-contract
        parse-type-sexpr)
;;; Invariant: TypeSpec has one compact representation for every parsed type
;;; form; constructor helpers are responsible for normalizing their own fields.
;; TypeSpecStruct
(defobject-contract type-spec
  owner: 'types
  object-kind: 'type-spec
  slots:
  ((kind Symbol symbol? required)
   (name Any (lambda (_) #t) required)
   (params Any (lambda (_) #t) required)
   (result Any (lambda (_) #t) required)))
;; TypeSpec
(def (make-type-unknown)
  (make-type-spec 'unknown "unknown" '() #f))
;; TypeSpec
(def (make-type-any)
  (make-type-spec 'any "any" '() #f))
;; : (-> TypeName TypeModel )
(def (make-type-base name)
  (make-type-spec 'base (normalize-type-name name) '() #f))
;; : (-> TypeName TypeModel )
(def (make-type-variable name)
  (make-type-spec 'variable (normalize-type-name name) '() #f))
;; : (-> CarType CdrType TypeSpec )
(def (make-type-pair car-type cdr-type)
  (make-type-spec 'pair #f [car-type cdr-type] #f))
;; : (-> ElemType TypeSpec )
(def (make-type-list elem-type)
  (make-type-spec 'list #f [elem-type] #f))
;; : (-> ElemType TypeSpec )
(def (make-type-vector elem-type)
  (make-type-spec 'vector #f [elem-type] #f))
;; : (-> ElemType TypeSpec )
(def (make-type-maybe elem-type)
  (make-type-spec 'maybe #f [elem-type] #f))
;; : (-> KeyType ValueType TypeSpec )
(def (make-type-hash key-type value-type)
  (make-type-spec 'hash #f [key-type value-type] #f))
;; : (-> Members TypeSpec )
(def (make-type-values members)
  (make-type-spec 'values #f members #f))
;; : (-> Base Predicate TypeSpec )
(def (make-type-refine base predicate)
  (make-type-spec 'refine (normalize-type-name predicate) [base] #f))
;; : (-> Constructor Params TypeSpec )
(def (make-type-application constructor params)
  (make-type-spec 'application (normalize-type-name constructor) params #f))
;; : (-> SymbolName TypeSpec )
(def (make-type-literal-symbol name)
  (make-type-spec 'literal-symbol (normalize-type-name name) '() #f))
;; : (-> Params Result TypeSpec )
(def (make-type-function params result)
  (make-type-spec 'function #f params result))
;; : (-> KeywordName KeywordType TypeSpec )
(def (make-type-keyword-parameter name param-type)
  (make-type-spec 'keyword-parameter (normalize-field-name name) [param-type] #f))
;; : (-> Param Result MaybeMinArity TypeSpec )
(def (make-type-function-variadic param result . maybe-min-arity)
  (make-type-spec 'function-variadic
                  (if (null? maybe-min-arity) 0 (car maybe-min-arity))
                  [param]
                  result))
;; : (-> Members TypeSpec )
(def (make-type-union members)
  (make-type-spec 'union #f members #f))
;;; Boundary: record construction normalizes field names and required names at
;;; the model edge so equality and validation never depend on source spelling.
;; : (-> Fields MaybeRequired TypeSpec )
(def (make-type-record fields . maybe-required)
  (make-type-spec 'record
                  #f
                  (normalize-record-fields fields)
                  (if (null? maybe-required)
                    '()
                    (map normalize-field-name (car maybe-required)))))
;; : (-> Type String )
(def (type-kind type)
  (type-spec-kind type))
;; : (-> Type TypeSpec )
(def (type-name type)
  (type-spec-name type))
;; : (-> Type TypeName )
(def (type-variable-name type)
  (type-name type))
;; : (-> Type Integer )
(def (type-params type)
  (type-spec-params type))
;; : (-> Type TypeSpec )
(def (type-result type)
  (type-spec-result type))
;; : (-> Type TypeSpec )
(def (type-pair-car type)
  (first-param-or-unknown type))
;; : (-> Type TypeSpec )
(def (type-pair-cdr type)
  (second-param-or-unknown type))
;; : (-> Type TypeSpec )
(def (type-list-elem type)
  (first-param-or-unknown type))
;; : (-> Type TypeSpec )
(def (type-vector-elem type)
  (first-param-or-unknown type))
;; : (-> Type TypeSpec )
(def (type-hash-key type)
  (first-param-or-unknown type))
;; : (-> Type TypeSpec )
(def (type-hash-value type)
  (second-param-or-unknown type))
;; : (-> Type (List TypeSpec) )
(def (type-values-members type)
  (type-params type))
;; : (-> Type TypeSpec )
(def (type-refine-base type)
  (first-param-or-unknown type))
;; : (-> Type String )
(def (type-refine-predicate type)
  (or (type-name type) "unknown"))
;; : (-> Type KeywordName )
(def (type-keyword-parameter-name type)
  (type-name type))
;; : (-> Type TypeSpec )
(def (type-keyword-parameter-type type)
  (first-param-or-unknown type))
;; : (-> Type TypeSpec )
(def (type-function-variadic-param type)
  (first-param-or-unknown type))
;; : (-> Type Integer )
(def (type-function-variadic-min-arity type)
  (type-name type))
;; : (-> Type Boolean )
(def (type-union-members type)
  (type-params type))
;; : (-> Type TypeSpec )
(def (type-record-fields type)
  (type-params type))
;; : (-> Type TypeSpec )
(def (type-record-required type)
  (or (type-result type) '()))
;;; Boundary: field lookup uses normalized record field names, matching the
;;; constructor invariant rather than source spelling or keyword punctuation.
;; : (-> Type FieldName TypeSpec )
(def (record-field-type type field-name)
  (let (found (assoc (normalize-field-name field-name) (type-record-fields type)))
    (and found (cdr found))))
;;; Invariant: TypeSpec equality is structural. Records compare required names
;;; as a set and fields by name so source order does not affect compatibility.
;; : (-> Type Type Boolean )
(def (type=? left right)
  (and (eq? (type-kind left) (type-kind right))
       (case (type-kind left)
         ((record)
          (and (lset= equal?
                       (type-record-required left)
                       (type-record-required right))
               (record-fields=? (type-record-fields left)
                                (type-record-fields right))))
         (else
          (and (equal? (type-name left) (type-name right))
               (types=? (type-params left) (type-params right))
               (type-results=? (type-result left) (type-result right)))))))
;;; Boundary: this printer is the stable TypeSpec display projection used by
;;; diagnostics and proof conclusions; parser grammar ownership stays elsewhere.
;; : (-> Type String )
(def (type->string type)
  (case (type-kind type)
    ((unknown) "unknown")
    ((any) "any")
    ((variable) (type-variable-name type))
    ((base) (type-name type))
    ((pair)
     (string-append "(pair "
                    (type->string (type-pair-car type))
                    " "
                    (type->string (type-pair-cdr type))
                    ")"))
    ((list)
     (string-append "(list "
                    (type->string (type-list-elem type))
                    ")"))
    ((vector)
     (string-append "(vector "
                    (type->string (type-vector-elem type))
                    ")"))
    ((maybe)
     (string-append "(maybe "
                    (type->string (first-param-or-unknown type))
                    ")"))
    ((hash)
     (string-append "(hash "
                    (type->string (type-hash-key type))
                    " "
                    (type->string (type-hash-value type))
                    ")"))
    ((values)
     (string-append "(values "
                    (string-join-with (map type->string (type-values-members type)) " ")
                    ")"))
    ((refine)
     (string-append "(refine "
                    (type->string (type-refine-base type))
                    " "
                    (type-refine-predicate type)
                    ")"))
    ((application)
     (string-append "("
                    (type-name type)
                    (if (pair? (type-params type))
                      (string-append " "
                                     (string-join-with (map type->string (type-params type))
                                           " "))
                      "")
                    ")"))
    ((literal-symbol)
     (string-append "'" (type-name type)))
    ((keyword-parameter)
     (string-append (type-keyword-parameter-name type)
                    ": "
                    (type->string (type-keyword-parameter-type type))))
    ((function)
     (string-append "(function ("
                    (string-join-with (map type->string (type-params type)) " ")
                    ") "
                    (type->string (type-result type))
                    ")"))
    ((function-variadic)
     (string-append "(function* "
                    (type->string (type-function-variadic-param type))
                    " "
                    (type->string (type-result type))
                    " "
                    (number->string (type-function-variadic-min-arity type))
                    ")"))
    ((union)
     (string-append "(union "
                    (string-join-with (map type->string (type-union-members type)) " ")
                    ")"))
    ((record)
     (string-append "(record ("
                    (string-join-with (map record-field->string (type-record-fields type)) " ")
                    ") ("
                    (string-join-with (type-record-required type) " ")
                    "))"))
    (else "unknown")))
;;; Boundary:
;;; - Typed comments arrive as source strings and must be read as Scheme data.
;;; - Reader failures become unknown TypeSpec values instead of checker guesses.
;; : (-> SignatureContract TypeSpec )
(def (parse-type-contract contract)
  (with-catch
   (lambda (_) (make-type-unknown))
   (lambda ()
     (call-with-input-string contract
       (lambda (port)
         (parse-type-sexpr (read port)))))))

;; : (-> Sexpr TypeSpec )
(def (parse-type-sexpr sexpr)
  (parse-type-sexpr* sexpr []))

;;; Parser boundary: this dispatcher recognizes only the Scheme-native contract
;;; grammar we project into TypeSpec. Unknown shapes stay unknown so checker
;;; policy never invents a type from display text or partial syntax.
;; : (-> Sexpr (List TypeVariable) TypeSpec )
(def (parse-type-sexpr* sexpr bound-vars)
  (cond
    ((symbol? sexpr) (parse-type-symbol sexpr bound-vars))
    ((string? sexpr) (parse-type-name sexpr bound-vars))
    ((boolean? sexpr)
     (make-type-literal-symbol (if sexpr '#t '#f)))
    ((list-type-shorthand-sexpr? sexpr)
     (make-type-list (parse-type-sexpr* (car sexpr) bound-vars)))
    ((pair? sexpr)
     (let (head (car sexpr))
       (cond
        ((eq? head 'quote)
         (make-type-literal-symbol (type-sexpr-first-operand sexpr)))
        ((eq? head 'forall)
         (parse-forall-type-sexpr sexpr bound-vars))
        ((compound-type-sexpr-parser head)
         => (lambda (parser)
              (parser sexpr bound-vars)))
        ((symbol? head)
         (make-type-application
          head
          (map (cut parse-type-sexpr* <> bound-vars) (cdr sexpr))))
        (else (make-type-unknown)))))
    (else (make-type-unknown))))

;; : (-> TypeDatum Boolean )
(def (list-type-shorthand-sexpr? sexpr)
  (and (list? sexpr)
       (= (length sexpr) 1)
       (pair? (car sexpr))))

;; : (-> TypeName (List TypeVariable) TypeSpec )
(def (parse-type-symbol symbol bound-vars)
  (parse-type-name (normalize-type-name symbol) bound-vars))

;; : (-> TypeName (List TypeVariable) TypeSpec )
(def (parse-type-name name bound-vars)
  (cond
   ((member name ["unknown" "Unknown"]) (make-type-unknown))
   ((member name ["any" "Any"]) (make-type-any))
   ((member name bound-vars) (make-type-variable name))
   (else (make-type-base name))))

;; : (-> TypeDatum Boolean )
(def (arrow-grouped-params? datum)
  (and (list? datum)
       (not (gerbil-contract-type-datum? datum))))

;; : (-> TypeDatum Boolean )
(def (gerbil-contract-type-datum? datum)
  (and (pair? datum)
       (let (head (car datum))
         (or (type-head? head '("forall"))
             (and (compound-type-sexpr-parser head) #t)))))

;;; Compound type grammar is table-driven so adding a constructor updates both
;;; parsing and contract-datum recognition through one owner-owned route.
;; : (-> TypeHead MaybeCompoundTypeParser )
(def (compound-type-sexpr-parser head)
  (find-compound-type-sexpr-parser head (compound-type-sexpr-parsers)))

;; : (-> TypeHead CompoundTypeParserEntries MaybeCompoundTypeParser )
(def (find-compound-type-sexpr-parser head entries)
  (cond
   ((null? entries) #f)
   ((type-head? head (caar entries)) (cdar entries))
   (else (find-compound-type-sexpr-parser head (cdr entries)))))

;;; Table invariant:
;;; - The head-name set is the single grammar registry for compound TypeSpec forms.
;;; - `cut` keeps unary and binary constructor handlers arity-stable without
;;;   repeating one branch per constructor in the parser dispatcher.
;; : (-> CompoundTypeParserEntries )
(def (compound-type-sexpr-parsers)
  (list
   (cons '("function" "Function" "->")
         parse-function-type-sexpr)
   (cons '("function*" "Function*" "->*")
         parse-function-variadic-type-sexpr)
   (cons '("pair" "Pair")
         (cut parse-binary-type-sexpr <> <> make-type-pair))
   (cons '("list" "List" "Listof" "Array")
         (cut parse-unary-type-sexpr <> <> make-type-list))
   (cons '("vector" "Vector")
         (cut parse-unary-type-sexpr <> <> make-type-vector))
   (cons '("maybe" "Maybe")
         (cut parse-unary-type-sexpr <> <> make-type-maybe))
   (cons '("hash" "Hash")
         (cut parse-binary-type-sexpr <> <> make-type-hash))
   (cons '("values" "Values")
         parse-values-type-sexpr)
   (cons '("refine" "Refine")
         parse-refine-type-sexpr)
   (cons '("union" "Union" "U")
         parse-union-type-sexpr)
   (cons '("record" "Record")
         parse-record-type-sexpr)))

;;; Operand access boundary:
;;; - Contract parser helpers should describe grammar slots, not cdr depth.
;;; - Missing operands degrade through the supplied default so malformed
;;;   contracts stay conservative without scattering safe-cadr variants.
;; : (-> TypeDatum Default TypeDatum )
(def (type-sexpr-first-operand sexpr . maybe-default)
  (match (cdr sexpr)
    ([value . _] value)
    (else (type-sexpr-operand-default maybe-default))))

;;; Slot invariant: the second grammar operand is present only when the tail has
;;; at least two elements; otherwise the caller-owned default preserves
;;; malformed-contract degradation.
;; : (-> TypeDatum Default TypeDatum )
(def (type-sexpr-second-operand sexpr . maybe-default)
  (match (cdr sexpr)
    ([_ value . _] value)
    (else (type-sexpr-operand-default maybe-default))))

;;; Slot invariant: the third grammar operand is reserved for optional arity
;;; metadata such as `function*`; missing metadata must not become a type name.
;; : (-> TypeDatum Default TypeDatum )
(def (type-sexpr-third-operand sexpr . maybe-default)
  (match (cdr sexpr)
    ([_ _ value . _] value)
    (else (type-sexpr-operand-default maybe-default))))

;; : (-> (List Default) TypeDatum )
(def (type-sexpr-operand-default maybe-default)
  (if (pair? maybe-default) (car maybe-default) 'unknown))

;; : (-> TypeDatum (List TypeVariable) TypeConstructor TypeSpec )
(def (parse-unary-type-sexpr sexpr bound-vars make)
  (make (parse-type-sexpr* (type-sexpr-first-operand sexpr) bound-vars)))

;; : (-> TypeDatum (List TypeVariable) TypeConstructor TypeSpec )
(def (parse-binary-type-sexpr sexpr bound-vars make)
  (make (parse-type-sexpr* (type-sexpr-first-operand sexpr) bound-vars)
        (parse-type-sexpr* (type-sexpr-second-operand sexpr) bound-vars)))

;; : (-> TypeDatum (List TypeVariable) TypeSpec )
(def (parse-function-variadic-type-sexpr sexpr bound-vars)
  (make-type-function-variadic
   (parse-type-sexpr* (type-sexpr-first-operand sexpr) bound-vars)
   (parse-type-sexpr* (type-sexpr-second-operand sexpr) bound-vars)
   (type-sexpr-third-operand sexpr 0)))

;;; Data-flow: every value member is parsed in the same lexical type-variable
;;; environment, so `(Values a b)` inside `forall` preserves bound variables.
;; : (-> TypeDatum (List TypeVariable) TypeSpec )
(def (parse-values-type-sexpr sexpr bound-vars)
  (make-type-values
   (map (cut parse-type-sexpr* <> bound-vars) (cdr sexpr))))

;; : (-> TypeDatum (List TypeVariable) TypeSpec )
(def (parse-refine-type-sexpr sexpr bound-vars)
  (make-type-refine
   (parse-type-sexpr* (type-sexpr-first-operand sexpr) bound-vars)
   (type-sexpr-second-operand sexpr)))

;;; Data-flow: union arms are independent type positions that share the caller's
;;; bound variable environment; map expresses that no arm depends on another.
;; : (-> TypeDatum (List TypeVariable) TypeSpec )
(def (parse-union-type-sexpr sexpr bound-vars)
  (make-type-union
   (map (cut parse-type-sexpr* <> bound-vars) (cdr sexpr))))

;; : (-> TypeDatum (List TypeVariable) TypeSpec )
(def (parse-record-type-sexpr sexpr bound-vars)
  (make-type-record
   (parse-record-fields* (type-sexpr-first-operand sexpr) bound-vars)
   (parse-required-fields (type-sexpr-second-operand sexpr))))

;;; Arrow parser boundary: grouped Function forms and Gerbil contract arrows
;;; normalize to parameter list plus result while preserving the caller's
;;; lexical type-variable environment for every slot.
;; : (-> ArrowDatum (List TypeVariable) TypeSpec )
(def (parse-function-type-sexpr sexpr bound-vars)
  (let (items (cdr sexpr))
    (cond
     ((and (type-head? (car sexpr) '("function" "Function"))
           (= (length items) 2)
           (arrow-grouped-params? (car items)))
     (make-type-function
       (parse-function-parameters (car items) bound-vars)
       (parse-type-sexpr* (cadr items) bound-vars)))
     ((>= (length items) 1)
      (make-type-function
       (parse-function-parameters (drop-right items 1) bound-vars)
       (parse-type-sexpr* (last items) bound-vars)))
     (else
      (make-type-function '() (make-type-unknown))))))

;;; Function parameter grammar preserves Gerbil keyword parameters as typed
;;; parameter nodes instead of treating the keyword token as a nominal type.
;; : (-> (List TypeDatum) (List TypeVariable) (List TypeSpec))
(def (parse-function-parameters items bound-vars)
  (cond
   ((null? items) [])
   ((function-keyword-marker? (car items))
    (let (value (if (pair? (cdr items)) (cadr items) 'unknown))
      (cons (make-type-keyword-parameter (function-keyword-name (car items))
                                          (parse-type-sexpr* value bound-vars))
            (parse-function-parameters (if (pair? (cdr items))
                                         (cddr items)
                                         (cdr items))
                                       bound-vars))))
   (else
    (cons (parse-type-sexpr* (car items) bound-vars)
          (parse-function-parameters (cdr items) bound-vars)))))

;; : (-> TypeDatum Boolean)
(def (function-keyword-marker? datum)
  (or (keyword? datum)
      (and (symbol? datum)
           (string-trailing-colon? (symbol->string datum)))))

;; : (-> TypeDatum KeywordName)
(def (function-keyword-name datum)
  (cond
   ((keyword? datum) (keyword->string datum))
   ((symbol? datum) (strip-trailing-colon (symbol->string datum)))
   ((string? datum) (strip-trailing-colon datum))
   (else "unknown")))

;;; Invariant:
;;; - forall extends the lexical type-variable environment only for its body.
;;; - Malformed binders collapse to unknown instead of inventing free variables.
;;; Forall parser boundary:
;;; - Newly bound variables shadow only while parsing the quantified body.
;;; - Malformed forall forms degrade to unknown instead of leaking partial bounds.
;;; - This keeps agent-facing contract diagnostics conservative.
;; : (-> ForallDatum (List TypeVariable) TypeSpec )
(def (parse-forall-type-sexpr sexpr bound-vars)
  (if (and (list? (type-sexpr-first-operand sexpr))
           (not (eq? (type-sexpr-second-operand sexpr) 'unknown)))
    (parse-type-sexpr*
     (type-sexpr-second-operand sexpr)
     (append (map normalize-type-name (type-sexpr-first-operand sexpr))
             bound-vars))
    (make-type-unknown)))
;; : (-> (Maybe Type) (Maybe Type) Boolean )
(def (type-results=? left right)
  (cond
   ((and left right) (type=? left right))
   ((or left right) #f)
   (else #t)))
;; : (-> (List Type) (List Type) Boolean )
(def (types=? left right)
  (cond
   ((and (null? left) (null? right)) #t)
   ((or (null? left) (null? right)) #f)
   (else
    (and (type=? (car left) (car right))
         (types=? (cdr left) (cdr right))))))
;;; Invariant: record field equality is structural and order-insensitive after
;;; field-name normalization; required-field set equality is checked by type=?.
;; : (-> Fields Fields Boolean )
(def (record-fields=? left right)
  (and (= (length left) (length right))
       (every (lambda (field)
                (let (found (assoc (car field) right))
                  (and found (type=? (cdr field) (cdr found)))))
              left)))
;; : (-> TypeName TypeName )
(def (normalize-type-name name)
  (cond
   ((keyword? name) (keyword->string name))
   ((symbol? name) (symbol->string name))
   ((string? name) name)
   (else "unknown")))
;; : (-> String NormalizeFieldName )
(def (normalize-field-name name)
  (strip-trailing-colon (normalize-type-name name)))
;;; Data-flow: filter-map keeps malformed field entries out of the normalized
;;; model while preserving every valid field as a name/type pair.
;; : (-> Fields NormalizeRecordFields )
(def (normalize-record-fields fields)
  (filter-map (cut parse-record-field* <> []) fields))
;; : (-> Fields ParsedData )
(def (parse-record-fields fields)
  (parse-record-fields* fields []))

;;; Data-flow: bound type variables are threaded through each parsed field so
;;; forall-scoped variables remain variables instead of becoming base types.
;; : (-> Fields (List TypeVariable) ParsedData )
(def (parse-record-fields* fields bound-vars)
  (if (list? fields)
    (filter-map (cut parse-record-field* <> bound-vars) fields)
    '()))
;;; Boundary: required-field forms normalize only names. Shape diagnostics stay
;;; in validation so the model layer remains a pure TypeSpec constructor layer.
;; : (-> Required ParsedData )
(def (parse-required-fields required)
  (if (list? required)
    (map normalize-field-name required)
    '()))
;; : (-> String ParsedData )
(def (parse-record-field field)
  (parse-record-field* field []))

;; : (-> String (List TypeVariable) ParsedData )
(def (parse-record-field* field bound-vars)
  (and (pair? field)
       (let ((name (normalize-field-name (car field)))
             (tail (cdr field)))
         (and name
              (if (type-spec? tail)
                (cons name tail)
                (cons name
                      (parse-type-sexpr*
                       (record-field-type-sexpr field)
                       bound-vars)))))))
;;; Record field shape accepts both `(name type)` and `(name . type)` forms.
;;; Pattern branches keep those two source shapes explicit while malformed
;;; fields still degrade to unknown.
;; : (-> FieldName TypeFieldSpec )
(def (record-field-type-sexpr field)
  (match field
    ([_ type . _] type)
    ([_ . tail] tail)
    (else 'unknown)))
;; : (-> String String )
(def (record-field->string field)
  (string-append "("
                 (car field)
                 " "
                 (type->string (cdr field))
                 ")"))
;;; Boundary:
;;; - Constructor matching is string-equal after Gerbil symbol normalization.
;;; - Keep this explicit so `(List Number)` stays one parameter type datum.
;; type-head?
;;   : (-> Head (List TypeName) Boolean)
;;   | doc m%
;;       `type-head? head names` checks whether a parsed Gerbil contract
;;       constructor matches one of the accepted TypeSpec constructor names.
;;
;;       # Examples
;;       ```scheme
;;       (type-head? 'List ["list" "List"])
;;       ;; => #t
;;       ```
;;     %
(def (type-head? head names)
  (let (target (normalize-type-name head))
    (ormap (cut equal? target <>) names)))
;; : (-> Type FirstParamOrUnknown )
(def (first-param-or-unknown type)
  (let (params (type-params type))
    (if (pair? params) (car params) (make-type-unknown))))
;; : (-> Type SecondParamOrUnknown )
(def (second-param-or-unknown type)
  (let (params (type-params type))
    (if (and (pair? params) (pair? (cdr params)))
      (cadr params)
      (make-type-unknown))))
;; : (-> SourceLine StripTrailingColon )
(def (strip-trailing-colon text)
  (let (size (string-length text))
    (if (and (> size 0) (eq? (string-ref text (- size 1)) #\:))
      (substring text 0 (- size 1))
      text)))
;; : (-> String Boolean)
(def (string-trailing-colon? text)
  (let (size (string-length text))
    (and (> size 0)
         (eq? (string-ref text (- size 1)) #\:))))
