;;; -*- Gerbil -*-
;;; Native Gerbil call extraction from syntax forms.

(import :gerbil/expander
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/support
        :asp-gerbil-scheme/src/parser/syntax-support
        (only-in :std/srfi/1 drop)
        (only-in :std/sugar cut))

(export calls-from-form
        calls-from-stxes
        calls-from-body-stxes
        calls-from-dot-def-stx
        calls-from-definition-stx
        calls-from-let-stx
        calls-from-stx
        calls-from-let-binding-stxes
        calls-from-let-binding-stx)

;; : (-> Relpath Form Datum CallsFromForm )
(def (calls-from-form relpath form datum)
  (if (declarative-top-level-datum? datum)
    '()
    (calls-from-stx relpath form (form-caller-name datum) '())))
;; : (-> Datum Boolean )
(def (declarative-top-level-datum? datum)
  (declarative-top-level-head? (top-form-datum-head datum)))
;;; Boundary:
;;; - calls-from-stxes composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Relpath Exprs String LocalTypes CallsFromStxes )
(def (calls-from-stxes relpath exprs caller local-types)
  (apply append (map (cut calls-from-stx relpath <> caller local-types) exprs)))
;; : (-> (List ExprStx) (List ExprStx) )
(def (dot-def-body-stxes items)
  (if (>= (length items) 2)
    (drop items 2)
    '()))
;; : (-> Relpath (List ExprStx) String LocalTypes CallsFromStx )
(def (calls-from-body-stxes relpath body caller local-types)
  (calls-from-stxes relpath body caller local-types))
;; : (-> Relpath ExprStx Datum String LocalTypes CallsFromStx )
(def (calls-from-dot-def-stx relpath expr-stx datum caller local-types)
  (calls-from-body-stxes relpath
                         (dot-def-body-stxes (stx-list-items expr-stx))
                         (or (form-caller-name datum) caller)
                         local-types))
;; : (-> Relpath ExprStx Head Datum String LocalTypes CallsFromStx )
(def (calls-from-definition-stx relpath expr-stx head datum caller local-types)
  (cond
   ((member head +macro-definition-heads+) '())
   ((member head '(defclass .defclass defgeneric .defgeneric)) '())
   (else
    (calls-from-body-stxes relpath
                           (stx-form-body-items expr-stx datum)
                           (or (form-caller-name datum) caller)
                           local-types))))
;; : (-> Relpath ExprStx Head Datum String LocalTypes CallsFromStx )
(def (calls-from-let-stx relpath expr-stx head datum caller local-types)
  (let* ((bindings (let-binding-datums datum))
         (body-local-types (let-body-local-types head bindings local-types)))
    (append
     (calls-from-let-binding-stxes relpath
                                   head
                                   (let-binding-stxes expr-stx head)
                                   caller
                                   local-types)
     (calls-from-body-stxes relpath
                            (let-body-stxes expr-stx head)
                            caller
                            body-local-types))))
;; : (-> Relpath ExprStx Head Datum String LocalTypes CallsFromStx )
(def (call-fact-from-stx relpath expr-stx head datum caller local-types)
  (let* ((args (cdr (stx-list-items expr-stx)))
         (arg-datums (map syntax->datum args))
         (loc (stx-source expr-stx))
         (start (source-start-line loc))
         (end (source-end-line loc)))
    (cons (make-call-fact (datum->string head)
                          (length arg-datums)
                          relpath start end
                          (map datum->string arg-datums)
                          (map (cut argument-type-name <> local-types)
                               arg-datums)
                          caller)
          (calls-from-body-stxes relpath args caller local-types))))
;;; Boundary:
;;; - calls-from-stx composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Relpath ExprStx String LocalTypes CallsFromStx )
(def (calls-from-stx relpath expr-stx caller local-types)
  (if (not (stx-pair? expr-stx))
    '()
    (let* ((items (stx-list-items expr-stx))
           (head-stx (and (pair? items) (car items)))
           (head (and head-stx (syntax->datum head-stx)))
           (datum (syntax->datum expr-stx)))
      (cond
       ((not (symbol? head))
        (calls-from-stxes relpath items caller local-types))
       ((member head '(quote quasiquote syntax quote-syntax))
        '())
       ((metadata-head? head)
        (calls-from-stxes relpath (cdr items) caller local-types))
       ((eq? head '.def)
        (calls-from-dot-def-stx relpath expr-stx datum caller local-types))
       ((member head +definition-heads+)
        (calls-from-definition-stx relpath expr-stx head datum caller local-types))
       ((let-head? head)
        (calls-from-let-stx relpath expr-stx head datum caller local-types))
       ((eq? head 'lambda)
        (calls-from-body-stxes relpath
                               (lambda-body-stxes expr-stx)
                               caller
                               local-types))
       ((eq? head 'case-lambda)
        (calls-from-body-stxes relpath
                               (case-lambda-body-stxes expr-stx)
                               caller
                               local-types))
       ((eq? head 'match)
        (calls-from-body-stxes relpath
                               (match-body-stxes expr-stx)
                               caller
                               local-types))
       ((member head '(syntax-case syntax-rules identifier-rules))
        '())
       ((member head +non-call-heads+)
        (calls-from-body-stxes relpath (cdr items) caller local-types))
       (else
        (call-fact-from-stx relpath expr-stx head datum caller local-types))))))
;; calls-from-let-binding-stxes
;;   : (-> Relpath Head (List BindingStx) String LocalTypes (List CallFact))
;;   | doc m%
;;       `calls-from-let-binding-stxes relpath head bindings caller local-types`
;;       collects call facts from let binding initializer expressions, threading
;;       local type bindings through sequential let forms.
;;
;;       # Examples
;;
;;       ```scheme
;;       (calls-from-let-binding-stxes "src/core.ss" 'let* bindings "handler" local-types)
;;       ;; => call facts
;;       ```
;;     %
(def (calls-from-let-binding-stxes relpath head bindings caller local-types)
  (cond
   ((null? bindings) '())
   ((member head '(let* let*-values))
    (cdr
     (foldl (lambda (binding state)
              (let* ((env (car state))
                     (out (cdr state))
                     (binding-calls
                      (calls-from-let-binding-stx relpath binding caller env))
                     (type-binding (binding-type (syntax->datum binding) env))
                     (next-env (if type-binding (cons type-binding env) env)))
                (cons next-env (append out binding-calls))))
            (cons local-types '())
            bindings)))
   (else
    (apply append
           (map (cut calls-from-let-binding-stx relpath <> caller local-types)
                bindings)))))
;; : (-> Relpath Binding String LocalTypes CallsFromLetBindingStx )
(def (calls-from-let-binding-stx relpath binding caller local-types)
  (let (items (stx-list-items binding))
    (if (and (pair? items) (pair? (cdr items)))
      (calls-from-stx relpath (cadr items) caller local-types)
      '())))
