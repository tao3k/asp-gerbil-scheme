;;; -*- Gerbil -*-
;;; Parser-owned definition and callable formal shape extraction.
;;; Boundary:
;;; - This owner is the single source for callable shape facts used by arity, typed-contract, and agent policy.
;;; - Keep extraction datum-only so macro/source traversal never leaks mutable source windows into policy evidence.
;;; Invariant:
;;; - Definition and formal recovery must stay deterministic across value, list, method, and macro-style heads.

(import :asp-gerbil-scheme/src/parser/support
        (only-in :std/misc/list unique))

(export definition-name-datums
        definition-formal-names
        definition-formal-arity
        definition-formal-datums
        formal-tail-datums)

;;; Boundary:
;;; - Definition name extraction normalizes Gerbil's value, list, method, and macro definition heads.
;;; - Keep this owner purely datum-shaped so syntax traversal can compose it without source-state coupling.
;; : (-> Datum (List Symbol) )
(def (definition-name-datums datum)
  (if (not (pair? datum))
    '()
    (let ((head (car datum))
          (second (safe-cadr datum)))
      (definition-name-datums* head second))))

;; : (-> Datum Datum (List Symbol))
(def (definition-name-datums* head second)
  (cond
   ((definition-value-name-head? head)
    (definition-value-name-datums second))
   ((eq? head 'define-values)
    (definition-values-name-datums second))
   ((definition-method-name-head? head)
    (definition-method-name-datums second))
   ((symbol? second) [second])
   (else '())))

;; : (-> Datum Boolean)
(def (definition-value-name-head? head)
  (member head '(def def* define define-type)))

;; : (-> Datum Boolean)
(def (definition-method-name-head? head)
  (member head '(defmethod defclass .defclass defgeneric .defgeneric
                 .defmethod defsyntax defsyntax-for-match
                 defsyntax-for-import defsyntax-for-export
                 defsyntax-for-import-export
                 defrules defrule
                 defn def-stx defsyntax-stx defsyntax-stx/form)))

;; : (-> Datum (List Symbol))
(def (definition-value-name-datums second)
  (cond
   ((symbol? second) [second])
   ((and (pair? second) (symbol? (car second))) [(car second)])
   (else '())))

;; : (-> Datum (List Symbol))
(def (definition-values-name-datums second)
  (if (list? second) (filter symbol? second) '()))

;;; Boundary:
;;; - Gerbil POO method heads may wrap the generic name in @method syntax.
;;; - Keep overload/name recovery here so duplicate-type and POO policy see the same generic owner.
;; : (-> Datum (List Symbol) )
(def (definition-method-name-datums datum)
  (cond
   ((symbol? datum) [datum])
   ((and (pair? datum)
         (eq? (car datum) '@method)
         (symbol? (safe-cadr datum)))
    [(safe-cadr datum)])
   ((and (pair? datum) (symbol? (car datum))) [(car datum)])
   (else '())))

;;; Boundary:
;;; - Formal names are value evidence for typed-contract alignment, not a source rendering surface.
;;; - Preserve only symbol formals so rest arguments and case-lambda clauses stay parser-owned facts.
;; : (-> Datum Symbol (List String) )
(def (definition-formal-names datum name)
  (filter-map
   (lambda (formal)
     (and (symbol? formal) (datum->string formal)))
   (definition-formal-datums datum name)))

;;; Boundary:
;;; - Arity is derived from parser-owned formal evidence so contract policy and call facts share one shape source.
;;; - Unknown or non-callable value definitions intentionally stay false instead of inventing a zero-arity contract.
;; : (-> Datum Symbol Integer )
(def (definition-formal-arity datum name)
  (let (formals (definition-formal-datums datum name))
    (and formals (length formals))))

;;; Boundary:
;;; - Callable shape must cover both list-style definitions and value-style lambda/case-lambda definitions.
;;; - Case-lambda clauses are unioned as evidence because downstream policy checks alignment, not overload dispatch.
;; : (-> Datum Symbol (List Symbol) )
(def (definition-formal-datums datum name)
  (if (not (pair? datum))
    '()
    (let ((head (car datum))
          (second (safe-cadr datum))
          (third (safe-caddr datum)))
      (cond
       ((member head '(def def* define defmethod .defmethod
                       defsyntax defsyntax-for-match
                       defsyntax-for-import defsyntax-for-export
                       defsyntax-for-import-export
                       defrule
                       defn def-stx defsyntax-stx defsyntax-stx/form))
        (cond
         ((and (pair? second) (eq? (car second) name))
          (formal-tail-datums (cdr second)))
         ((and (member head '(def def* define))
               (symbol? second)
               (eq? second name))
          (definition-value-formal-datums third))
         (else '())))
       (else '())))))

;;; Boundary:
;;; - Value-style definitions encode callable shape in the assigned expression instead of the definition head.
;;; - Lambda and case-lambda expose declared formals directly.
;;; - Cut and cute expose placeholder-driven callable arity without inventing source names.
;;; - Other value definitions intentionally return no callable shape.
;; : (-> Datum (List Symbol) )
(def (definition-value-formal-datums datum)
  (cond
   ((and (pair? datum) (eq? (car datum) 'lambda))
    (formal-tail-datums (safe-cadr datum)))
   ((and (pair? datum) (eq? (car datum) 'case-lambda))
    (unique
     (apply append
            (map (lambda (clause)
                   (formal-tail-datums (car clause)))
                 (filter pair? (safe-cdr datum))))))
   ((and (pair? datum) (member (car datum) '(cut cute)))
    (cut-placeholder-datums (safe-cdr datum)))
   (else '())))

;;; Boundary:
;;; - Cut placeholder arity belongs to the outer partial-application form.
;;; - Nested cut and cute forms own their placeholders, so outer arity ignores those subtrees.
;; : (-> Obj (List Symbol) )
(def (cut-placeholder-datums obj)
  (cond
   ((null? obj) '())
   ((and (symbol? obj) (member obj '(<> <...>))) [obj])
   ((and (pair? obj) (member (car obj) '(cut cute))) '())
   ((pair? obj)
    (append (cut-placeholder-datums (car obj))
            (cut-placeholder-datums (cdr obj))))
   (else '())))

;;; Boundary:
;;; - Formal tail extraction preserves dotted/rest and ordinary list formals as algebraic symbols.
;;; - Ellipsis is syntax shape, not a callable argument name, so it is skipped before policy alignment.
;; : (-> Obj (List Symbol) )
(def (formal-tail-datums tail)
  (cond
   ((null? tail) '())
   ((symbol? tail) [tail])
   ((pair? tail)
    (formal-tail-pair-datums (car tail) (cdr tail)))
   (else '())))

;; : (-> Datum (List Datum) (List Symbol))
(def (formal-tail-pair-datums head rest)
  (cond
   ((keyword? head) (keyword-formal-tail-datums rest))
   ((and (symbol? head) (not (eq? head '...)))
    (cons head (formal-tail-datums rest)))
   (else
    (formal-tail-datums rest))))

;; : (-> (List Datum) (List Symbol))
(def (keyword-formal-tail-datums rest)
  (if (pair? rest)
    (let (formal (keyword-formal-datum (car rest)))
      (if formal
        (cons formal (formal-tail-datums (cdr rest)))
        (formal-tail-datums rest)))
    '()))

;; : (-> Datum (Maybe Symbol))
(def (keyword-formal-datum datum)
  (cond
   ((symbol? datum) datum)
   ((and (pair? datum) (symbol? (car datum))) (car datum))
   (else #f)))
