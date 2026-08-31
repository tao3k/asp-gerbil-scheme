;;; -*- Gerbil -*-
;;; Gerbil contract projection helpers for typed comments.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/parser/typed-contract-token
                 typed-contract-token-char?
                 typed-contract-arrow-count
                 typed-contract-group-count)
        (only-in :asp-gerbil-scheme/src/types/model
                 parse-type-sexpr
                 type->string
                 type-kind
                 type-name
                 type-params
                 type-result
                 type-record-required)
        (only-in :asp-gerbil-scheme/src/types/validation
                 type-validation-diagnostic-facts
                 type-validation-diagnostic-code
                 type-validation-diagnostic-path
                 type-validation-diagnostic-category
                 type-validation-diagnostic-message
                 type-spec-valid?
                 type-validation-diagnostics)
        (only-in :std/srfi/13
                 string-empty?
                 string-ref
                 string-trim-both)
        (only-in :std/srfi/1 drop-right)
        (only-in :std/sugar cut filter foldl hash))

(export scheme-contract-output
        scheme-contract-inputs
        scheme-contract-projection
        scheme-type-signature-analysis
        scheme-type-signature-json
        scheme-type-expression-text-json
        scheme-type-expression-json
        scheme-predicate-expression-json
        split-top-level-type-exprs
        typed-contract-token-char?
        typed-contract-arrow-count
        typed-contract-group-count)

;;; Gerbil contract output extraction parses `;; : (-> Input Output)` comments
;;; for the canonical typed-comment contract owner.
;; scheme-contract-output
;;   : (-> SignatureContract (Maybe TypeExpr))
;;   | doc m%
;;       `scheme-contract-output contract` returns the final output position of
;;       a Gerbil contract arrow signature for typed-comment facts.
;;
;;       # Examples
;;       ```scheme
;;       (scheme-contract-output "(-> String Integer Boolean)")
;;       ;; => "Boolean"
;;       ```
;;     %
(def (scheme-contract-output contract)
  (let (projection (scheme-contract-projection contract))
    (and projection (car projection))))

;;; Input extraction uses the parsed arrow items and drops the final output
;;; position.  This keeps Gerbil contract projections aligned with the
;;; canonical typed-comment fact shape without duplicating parser logic.
;; scheme-contract-inputs
;;   : (-> SignatureContract (Maybe (List TypeExpr)))
;;   | doc m%
;;       `scheme-contract-inputs contract` returns arrow input positions from a
;;       Gerbil contract signature projection for typed-comment facts.
;;
;;       # Examples
;;       ```scheme
;;       (scheme-contract-inputs "(-> String Integer Boolean)")
;;       ;; => ("String" "Integer")
;;       ```
;;     %
(def (scheme-contract-inputs contract)
  (let (projection (scheme-contract-projection contract))
    (and projection (cadr projection))))

;; : (-> SignatureContract (Maybe (Tuple TypeExpr (List TypeExpr))))
(def (scheme-contract-projection contract)
  (let (datum (scheme-contract-datum contract))
    (and datum
         (scheme-contract-projection/arrow
          (scheme-contract-arrow-datum datum)))))

;; : (-> (Maybe ArrowDatum) (Maybe (Tuple TypeExpr (List TypeExpr))))
(def (scheme-contract-projection/arrow arrow)
  (and arrow
       (let (items (cdr arrow))
         (and (pair? items)
              [(datum->type-string (typed-contract-last items))
               (map datum->type-string
                    (scheme-arrow-input-type-datums
                     (drop-right items 1)))]))))

;;; Boundary:
;;; - JSON preserves arrow fields for existing consumers.
;;; - Structural shape lives in the richer typed-comment fact.
;;; - Diagnostics are parser-owned repair facts.
;;; - Callers should consume diagnostics instead of reparsing raw comments.
;;; Invariant:
;;; - The entrypoint parses the signature datum once.
;;; - Every public JSON field is derived from that datum.
;;; - Malformed syntax stays a distinct repair cause.
;;; - Arrow shape stays a distinct repair cause.
;;; - Child type errors stay distinct repair causes.
;; scheme-type-signature-json
;;   : (-> SignatureContract Json)
;;   | doc m%
;;       `scheme-type-signature-json contract` parses the `;; :` surface into
;;       parser-owned type facts for agent guidance.
;;       Diagnostics stay in the same JSON packet.
;;
;;       # Examples
;;       ```scheme
;;       (hash-get (scheme-type-signature-json "(-> String Boolean)") 'valid)
;;       ;; => #t
;;       ```
;;     %
(def (scheme-type-signature-json contract)
  (car (scheme-type-signature-analysis contract)))

;; : (-> SignatureContract (Tuple Json (Maybe (Tuple TypeExpr (List TypeExpr)))))
(def (scheme-type-signature-analysis contract)
  (let (datum (scheme-contract-datum contract))
    (if datum
      (let* ((body (scheme-type-signature-body datum))
             (arrow (scheme-contract-arrow-datum body))
             (forall-vars (scheme-type-signature-forall-vars datum))
             (signature-type-spec
              (type-spec-json (parse-type-sexpr datum)))
             (diagnostics
              (append (scheme-type-signature-diagnostics datum body arrow)
                      (scheme-type-expression-diagnostics body forall-vars))))
        [(hash (syntax "gerbil-contract-type")
               (raw contract)
               (valid (not (pair? diagnostics)))
               (forall forall-vars)
               (shape (scheme-type-expression-json* datum forall-vars))
               (typeSpec signature-type-spec)
               (arrow (and arrow
                           (scheme-arrow-json arrow
                                              forall-vars
                                              signature-type-spec)))
               (diagnostics diagnostics))
         (scheme-contract-projection/arrow arrow)])
      [(scheme-type-signature-invalid-json contract) #f])))

;; : (-> SignatureContract Json)
(def (scheme-type-signature-invalid-json contract)
  (hash (syntax "gerbil-contract-type")
        (raw contract)
        (valid #f)
        (forall [])
        (shape #f)
        (typeSpec #f)
        (arrow #f)
        (diagnostics ["malformed-type-datum"])))

;;; Boundary:
;;; - Standalone type expressions reuse the same validator as signatures.
;;; - Invalid expressions stay representable so policy repair can cite them.
;; scheme-type-expression-text-json
;;   : (-> TypeExpr Json)
;;   | doc m%
;;       `scheme-type-expression-text-json text` parses one type expression
;;       string, preserving diagnostics instead of letting callers guess.
;;
;;       # Examples
;;       ```scheme
;;       (hash-get (scheme-type-expression-text-json "(Array a)") 'diagnostics)
;;       ;; => ["unbound-type-variable:a"]
;;       ```
;;     %
(def (scheme-type-expression-text-json text . maybe-bound-vars)
  (let (datum (scheme-contract-datum text))
    (if datum
      (let* ((bound-vars (if (pair? maybe-bound-vars)
                           (car maybe-bound-vars)
                           []))
             (diagnostics
              (scheme-type-expression-diagnostics datum bound-vars)))
        (hash (raw text)
              (valid (not (pair? diagnostics)))
              (shape (scheme-type-expression-json* datum bound-vars))
              (typeSpec (type-spec-json (parse-type-sexpr datum)))
              (diagnostics diagnostics)))
      (hash (raw text)
            (valid #f)
            (shape #f)
            (typeSpec #f)
            (diagnostics ["malformed-type-datum"])))))

;;; Boundary:
;;; - Preconditions are parsed as predicate calls, not folded into prose.
;;; - The parser preserves arguments as data so policy can cite witnesses.
;; scheme-predicate-expression-json
;;   : (-> PredicateExpr Json)
;;   | doc m%
;;       `scheme-predicate-expression-json expression` parses precondition
;;       predicates such as `(pair? xs)` for policy witness output.
;;
;;       # Examples
;;       ```scheme
;;       (hash-get (scheme-predicate-expression-json "(pair? xs)") 'name)
;;       ;; => "pair?"
;;       ```
;;     %
(def (scheme-predicate-expression-json expression)
  (let (datum (scheme-contract-datum expression))
    (cond
     ((not datum)
      (hash (syntax "scheme-predicate")
            (raw expression)
            (valid #f)
            (name #f)
            (arguments [])
            (diagnostics ["malformed-predicate-datum"])))
     ((pair? datum)
      (hash (syntax "scheme-predicate")
            (raw expression)
            (valid (symbol? (car datum)))
            (name (and (symbol? (car datum))
                       (symbol->string (car datum))))
            (arguments (map datum->type-string (cdr datum)))
            (diagnostics (if (symbol? (car datum))
                           []
                           ["predicate-head-not-symbol"]))))
     ((symbol? datum)
      (hash (syntax "scheme-predicate")
            (raw expression)
            (valid #t)
            (name (symbol->string datum))
            (arguments [])
            (diagnostics [])))
     (else
      (hash (syntax "scheme-predicate")
            (raw expression)
            (valid #f)
            (name #f)
            (arguments [])
            (diagnostics ["predicate-not-symbol-or-call"]))))))

;; : (-> SignatureContract (Maybe (List TypeDatum)))
(def (scheme-contract-arrow-items contract)
  (let (datum (scheme-contract-datum contract))
    (and datum
         (let (arrow (scheme-contract-arrow-datum datum))
           (and arrow
                (cdr arrow))))))

;;; Contract datum parsing is deliberately protected: malformed comments should
;;; degrade to token-only evidence instead of aborting the whole source file.
;; : (-> SignatureContract (Maybe Datum))
(def (scheme-contract-datum contract)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (call-with-input-string contract read))))

;; : (-> Datum (Maybe ArrowDatum))
(def (scheme-contract-arrow-datum datum)
  (cond
   ((and (pair? datum)
         (eq? (car datum) '->))
    datum)
   ((and (pair? datum)
         (eq? (car datum) 'forall)
         (pair? (cddr datum)))
    (scheme-contract-arrow-datum (caddr datum)))
   (else #f)))

;; : (-> Datum Datum)
(def (scheme-type-signature-body datum)
  (if (and (pair? datum)
           (eq? (car datum) 'forall)
           (pair? (cddr datum)))
    (caddr datum)
    datum))

;;; Intent:
;;; - Extract only explicit `(forall (vars ...) body)` binders.
;;; - Missing or malformed binders become diagnostics in the caller, not guesses.
;; : (-> Datum (List TypeVariable))
(def (scheme-type-signature-forall-vars datum)
  (if (and (pair? datum)
           (eq? (car datum) 'forall)
           (pair? (cdr datum))
           (list? (cadr datum)))
    (map datum->type-string (cadr datum))
    []))

;; : (-> Datum Datum (Maybe ArrowDatum) (List Diagnostic))
(def (scheme-type-signature-diagnostics datum body arrow)
  (append
   (if (and (pair? datum)
            (eq? (car datum) 'forall)
            (not (and (pair? (cdr datum))
                      (list? (cadr datum))
                      (pair? (cddr datum)))))
     ["forall-requires-variable-list-and-body"]
     [])
   (if (not arrow)
     ["signature-missing-arrow"]
     [])
   (if (and arrow (< (length (cdr arrow)) 1))
     ["signature-arrow-too-short"]
     [])))

;;; Boundary:
;;; - Arrow facts separate input positions from the output position.
;;; - Too-short arrows stay representable so diagnostics can guide repair.
;; : (-> ArrowDatum Json)
(def (scheme-arrow-json arrow . maybe-bound-vars)
  (let (items (cdr arrow))
    (let ((bound-vars (if (pair? maybe-bound-vars) (car maybe-bound-vars) []))
          (precomputed-type-spec
           (and (pair? maybe-bound-vars)
                (pair? (cdr maybe-bound-vars))
                (cadr maybe-bound-vars))))
      (let (inputs (if (>= (length items) 1)
                    (scheme-arrow-input-jsons (drop-right items 1) bound-vars)
                    []))
        (hash (kind "function")
              (typeSpec
               (or precomputed-type-spec
                   (type-spec-json (parse-type-sexpr arrow))))
              (inputs inputs)
              (output (if (>= (length items) 1)
                        (scheme-type-expression-json* (typed-contract-last items)
                                                      bound-vars)
                        #f))
              (inputCount (length inputs)))))))

;;; Arrow inputs are keyword-aware: `name: Type` is one named parameter, not two
;;; positional type expressions.
;; : (-> (List TypeDatum) (List TypeVariable) (List Json))
(def (scheme-arrow-input-jsons items bound-vars)
  (cond
   ((null? items) [])
   ((scheme-keyword-marker? (car items))
    (let (value (if (pair? (cdr items)) (cadr items) 'unknown))
      (cons (scheme-keyword-parameter-json (car items) value bound-vars)
            (scheme-arrow-input-jsons (if (pair? (cdr items))
                                       (cddr items)
                                       (cdr items))
                                     bound-vars))))
   (else
    (cons (scheme-type-expression-json* (car items) bound-vars)
          (scheme-arrow-input-jsons (cdr items) bound-vars)))))

;; : (-> (List TypeDatum) (List TypeDatum))
(def (scheme-arrow-input-type-datums items)
  (cond
   ((null? items) [])
   ((scheme-keyword-marker? (car items))
    (if (pair? (cdr items))
      (cons (cadr items)
            (scheme-arrow-input-type-datums (cddr items)))
      ['unknown]))
   (else
    (cons (car items)
          (scheme-arrow-input-type-datums (cdr items))))))

;; : (-> TypeDatum TypeDatum (List TypeVariable) Json)
(def (scheme-keyword-parameter-json marker value bound-vars)
  (hash (kind "keyword-parameter")
        (name (scheme-keyword-name marker))
        (type (scheme-type-expression-json* value bound-vars))))

;;; Boundary:
;;; - TypeSpec projection is the normalized semantic view used by checker code.
;;; - Shape JSON remains syntax-oriented so policy can cite the original form.
;; : (-> TypeSpec Json)
(def (type-spec-json type)
  (hash (kind (symbol->string (type-kind type)))
        (name (type-name type))
        (display (type->string type))
        (valid (type-spec-valid? type))
        (diagnostics (type-validation-diagnostics type))
        (diagnosticFacts
         (map type-validation-diagnostic-json
              (type-validation-diagnostic-facts type)))
        (params (type-spec-params-json type))
        (result (type-spec-result-json type))))

;; : (-> TypeValidationDiagnostic Json)
(def (type-validation-diagnostic-json diagnostic)
  (hash (code (type-validation-diagnostic-code diagnostic))
        (path (type-validation-diagnostic-path diagnostic))
        (category (type-validation-diagnostic-category diagnostic))
        (message (type-validation-diagnostic-message diagnostic))))

;; : (-> TypeSpec Json)
(def (type-spec-result-json type)
  (case (type-kind type)
    ((record) (type-record-required type))
    (else (and (type-result type)
               (type-spec-json (type-result type))))))

;;; Boundary:
;;; - Record parameters are named fields; other TypeSpec parameters are positional.
;;; - The map split keeps those two shapes explicit for downstream JSON consumers.
;; : (-> TypeSpec (List Json))
(def (type-spec-params-json type)
  (case (type-kind type)
    ((record) (map type-spec-field-json (type-params type)))
    (else (map type-spec-json (type-params type)))))

;; : (-> TypeField Json)
(def (type-spec-field-json field)
  (hash (name (car field))
        (type (type-spec-json (cdr field)))))

;; scheme-type-expression-json
;;   : (-> TypeDatum Json)
;;   | doc m%
;;       `scheme-type-expression-json datum` renders one Gerbil contract type
;;       expression as structured facts for containers, unions, refinements, and arrows.
;;
;;       # Examples
;;       ```scheme
;;       (hash-get (scheme-type-expression-json '(List TypeFinding)) 'kind)
;;       ;; => "container"
;;       ```
;;     %
(def (scheme-type-expression-json datum)
  (scheme-type-expression-json* datum []))

;;; Boundary:
;;; - Type expression rendering tracks forall-bound variables structurally.
;;; - Lowercase symbols are modeled as type variables before validation.
;;; - Diagnostics decide whether the enclosing forall binding is present.
;; : (-> TypeDatum (List TypeVariable) Json)
(def (scheme-type-expression-json* datum bound-vars)
  (cond
   ((symbol? datum)
    (scheme-type-symbol-json datum bound-vars))
   ((keyword? datum)
    (hash (kind "keyword-marker")
          (name (keyword->string datum))))
   ((scheme-quoted-symbol? datum)
    (hash (kind "literal-symbol")
          (name (symbol->string (cadr datum)))))
    ((pair? datum)
     (let ((head (car datum))
           (tail (cdr datum)))
       (cond
        ((scheme-list-type-shorthand? datum)
         (hash (kind "container")
               (name "List")
               (parameters [(scheme-type-expression-json* (car datum)
                                                          bound-vars)])))
        ((eq? head 'forall)
         (let (vars (if (and (pair? tail) (list? (car tail)))
                     (map datum->type-string (car tail))
                     []))
          (hash (kind "forall")
                (variables vars)
                (body (and (pair? (cdr tail))
                           (scheme-type-expression-json*
                            (cadr tail)
                            (append vars bound-vars)))))))
       ((eq? head '->)
        (scheme-arrow-json datum bound-vars))
       ((eq? head 'U)
        (hash (kind "union")
              (options (map (cut scheme-type-expression-json* <> bound-vars)
                            tail))))
       ((eq? head 'Values)
        (hash (kind "values")
              (values (map (cut scheme-type-expression-json* <> bound-vars)
                           tail))))
       ((eq? head 'Refine)
        (hash (kind "refinement")
              (base (and (pair? tail)
                         (scheme-type-expression-json* (car tail)
                                                       bound-vars)))
              (predicate (and (pair? (cdr tail))
                              (datum->type-string (cadr tail))))))
       ((scheme-container-head? head)
        (hash (kind "container")
              (name (symbol->string head))
              (parameters (map (cut scheme-type-expression-json* <> bound-vars)
                               tail))))
       ((symbol? head)
        (hash (kind "application")
              (name (symbol->string head))
              (parameters (map (cut scheme-type-expression-json* <> bound-vars)
                               tail))))
       (else
        (hash (kind "unknown")
              (raw (datum->type-string datum)))))))
   (else
    (hash (kind "literal")
          (raw (datum->type-string datum))))))

;; : (-> TypeDatum (List TypeVariable) Json)
(def (scheme-type-symbol-json datum bound-vars)
  (let* ((name (symbol->string datum))
         (variable? (scheme-type-variable-symbol? datum))
         (bound? (if (member name bound-vars) #t #f)))
    (if variable?
      (hash (kind "name")
            (name name)
            (role "type-variable")
            (bound bound?))
      (hash (kind "name")
            (name name)
            (role "type-name")))))

;;; Diagnostics describe grammar shape, not project-specific alias validity.
;;; Custom aliases remain valid names; known forms get arity checks.
;; : (-> TypeDatum (List Diagnostic))
(def (scheme-type-expression-diagnostics datum . maybe-bound-vars)
  (let (bound-vars (if (pair? maybe-bound-vars) (car maybe-bound-vars) []))
    (append (scheme-type-expression-own-diagnostics datum bound-vars)
            (scheme-type-expression-child-diagnostics datum bound-vars))))

;;; Intent:
;;; - Emit diagnostics only for built-in type forms whose arity is known.
;;; - Leave custom aliases and applications valid so local type environments work.
;; : (-> TypeDatum (List Diagnostic))
(def (scheme-type-expression-own-diagnostics datum bound-vars)
  (cond
   ((and (symbol? datum)
         (scheme-type-variable-symbol? datum)
         (not (member (symbol->string datum) bound-vars)))
    [(string-append "unbound-type-variable:" (symbol->string datum))])
   ((pair? datum)
    (let ((head (car datum))
          (tail (cdr datum)))
      (cond
       ((and (eq? head 'forall)
             (not (and (pair? tail)
                       (list? (car tail))
                       (pair? (cdr tail)))))
        ["forall-requires-variable-list-and-body"])
       ((eq? head '->)
        (append (if (< (length tail) 1)
                  ["arrow-requires-input-and-output"]
                  [])
                (scheme-arrow-keyword-diagnostics tail)))
       ((and (member head '(List Listof Array Vector Maybe))
             (not (= (length tail) 1)))
        [(string-append (symbol->string head) "-requires-one-parameter")])
       ((and (eq? head 'Hash) (not (= (length tail) 2)))
        ["Hash-requires-key-and-value"])
       ((and (eq? head 'Values) (not (pair? tail)))
        ["Values-requires-at-least-one-value"])
       ((and (eq? head 'U) (not (pair? tail)))
        ["U-requires-at-least-one-option"])
       ((and (eq? head 'Refine) (not (= (length tail) 2)))
        ["Refine-requires-base-and-predicate"])
       (else []))))
   (else [])))

;; : (-> (List TypeDatum) (List Diagnostic))
(def (scheme-arrow-keyword-diagnostics items)
  (if (>= (length items) 1)
    (scheme-arrow-keyword-input-diagnostics (drop-right items 1))
    []))

;; : (-> (List TypeDatum) (List Diagnostic))
(def (scheme-arrow-keyword-input-diagnostics items)
  (cond
   ((null? items) [])
   ((scheme-keyword-marker? (car items))
    (if (pair? (cdr items))
      (scheme-arrow-keyword-input-diagnostics (cddr items))
      [(string-append "keyword-parameter-requires-type:"
                      (scheme-keyword-name (car items)))]))
   (else
    (scheme-arrow-keyword-input-diagnostics (cdr items)))))

;; : (-> TypeDatum Boolean)
(def (scheme-keyword-marker? datum)
  (or (keyword? datum)
      (and (symbol? datum)
           (let (text (symbol->string datum))
             (and (> (string-length text) 0)
                  (eq? (string-ref text (- (string-length text) 1)) #\:))))))

;; : (-> TypeDatum KeywordName)
(def (scheme-keyword-name datum)
  (cond
   ((keyword? datum) (keyword->string datum))
   ((symbol? datum)
    (let (text (symbol->string datum))
      (if (and (> (string-length text) 0)
               (eq? (string-ref text (- (string-length text) 1)) #\:))
        (substring text 0 (- (string-length text) 1))
        text)))
   ((string? datum) datum)
   (else "unknown")))

;;; Boundary:
;;; - Recurse into child type expressions after the current node is checked.
;;; - Quoted enum symbols are terminal values, not type applications.
;; : (-> TypeDatum (List Diagnostic))
(def (scheme-type-expression-child-diagnostics datum bound-vars)
  (cond
    ((scheme-quoted-symbol? datum) [])
    ((scheme-list-type-shorthand? datum)
     (scheme-type-expression-diagnostics (car datum) bound-vars))
    ((and (pair? datum) (eq? (car datum) 'forall))
     (scheme-forall-child-diagnostics datum bound-vars))
   ((and (pair? datum) (eq? (car datum) 'Refine))
    (scheme-refine-child-diagnostics datum bound-vars))
   ((pair? datum)
    (scheme-pair-child-diagnostics datum bound-vars))
   (else [])))

;; : (-> TypeDatum (List TypeVar) (List Diagnostic))
(def (scheme-forall-child-diagnostics datum bound-vars)
  (if (scheme-forall-child-shape? datum)
    (scheme-type-expression-diagnostics
     (caddr datum)
     (append (map datum->type-string (cadr datum))
             bound-vars))
    []))

;; : (-> TypeDatum Boolean)
(def (scheme-forall-child-shape? datum)
  (and (pair? (cdr datum))
       (list? (cadr datum))
       (pair? (cddr datum))))

;; : (-> TypeDatum (List TypeVar) (List Diagnostic))
(def (scheme-refine-child-diagnostics datum bound-vars)
  (if (pair? (cdr datum))
    (scheme-type-expression-diagnostics (cadr datum) bound-vars)
    []))

;; : (-> TypeDatum (List TypeVar) (List Diagnostic))
(def (scheme-pair-child-diagnostics datum bound-vars)
  (if (pair? (cdr datum))
    (apply append
           (map (cut scheme-type-expression-diagnostics <> bound-vars)
                (cdr datum)))
    []))

;; : (-> Datum Boolean)
(def (scheme-quoted-symbol? datum)
  (and (pair? datum)
       (eq? (car datum) 'quote)
       (pair? (cdr datum))
       (symbol? (cadr datum))))

;; : (-> Datum Boolean)
(def (scheme-container-head? head)
  (and (symbol? head)
       (member head '(List Listof Array Vector Hash Maybe))))

;; : (-> Datum Boolean)
(def (scheme-list-type-shorthand? datum)
  (and (list? datum)
       (= (length datum) 1)
       (pair? (car datum))))

;;; Boundary:
;;; - Lowercase symbols in type position are type variables, not type names.
;;; - The enclosing signature must bind them with forall.
;; : (-> Datum Boolean)
(def (scheme-type-variable-symbol? datum)
  (and (symbol? datum)
       (let (text (symbol->string datum))
         (and (not (string-empty? text))
              (char-lower-case? (string-ref text 0))))))

;;; Type datum rendering delegates to the Scheme printer so nested type forms
;;; round-trip through one canonical textual representation.
;; : (-> TypeDatum TypeExpr)
(def (datum->type-string datum)
  (call-with-output-string []
    (cut write datum <>)))

;; : (forall (x) (-> (List x) x))
(def (typed-contract-last items)
  (if (null? (cdr items))
    (car items)
    (typed-contract-last (cdr items))))

;;; Boundary:
;;; - split-top-level-type-exprs is a depth-aware parser for type arguments.
;;; - Fold state tracks index, parenthesis depth, current token start, and output.
;; split-top-level-type-exprs
;;   : (-> TypeExprs (List TypeExpr) )
;;   | doc m%
;;       `split-top-level-type-exprs text` splits type argument text at
;;       top-level spaces while preserving nested type expressions.
;;
;;       # Examples
;;       ```scheme
;;       (split-top-level-type-exprs "A (List B) C")
;;       ;; => ("A" "(List B)" "C")
;;       ```
;;     %
(def (split-top-level-type-exprs text)
  (let* ((length (string-length text))
         (state
          (foldl (cut split-type-expr-step text <> <>)
                 [0 0 #f '()]
                 (string->list text))))
    (split-type-expr-state-output text state)))

;;; Boundary:
;;; - split-type-expr-step owns one-character type-parser state transitions.
;;; - Keep branch shape shallow so contract tokenization remains policy-auditable.
;; : (-> TypeExprs Character SplitTypeExprState SplitTypeExprState )
(def (split-type-expr-step text ch state)
  (let ((index (car state))
        (depth (cadr state))
        (start (caddr state))
        (out (cadddr state)))
    (if (split-type-expr-boundary? ch depth)
      (split-type-expr-close-state text index depth start out)
      [(fx1+ index)
       (split-type-expr-next-depth ch depth)
       (or start index)
       out])))

;; : (-> Character Depth Boolean )
(def (split-type-expr-boundary? ch depth)
  (and (= depth 0) (char=? ch #\space)))

;; : (-> Character Depth Depth )
(def (split-type-expr-next-depth ch depth)
  (cond
   ((char=? ch #\() (fx1+ depth))
   ((char=? ch #\)) (max 0 (fx1- depth)))
   (else depth)))

;; : (-> TypeExprs Index Depth Start (List TypeExpr) SplitTypeExprState )
(def (split-type-expr-close-state text index depth start out)
  [(fx1+ index)
   depth
   #f
   (if start
     (cons-nonblank-type-expr (substring text start index) out)
     out)])

;; : (-> TypeExprs SplitState (List TypeExpr) )
(def (split-type-expr-state-output text state)
  (let ((index (car state))
        (start (caddr state))
        (out (cadddr state)))
    (reverse
     (if start
       (cons-nonblank-type-expr (substring text start index) out)
       out))))

;; : (-> TypeExpr (List TypeExpr) (List TypeExpr) )
(def (cons-nonblank-type-expr value out)
  (let (part (string-trim-both value))
    (if (equal? part "")
      out
      (cons part out))))
