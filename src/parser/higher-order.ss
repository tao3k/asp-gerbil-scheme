;;; -*- Gerbil -*-
;;; Parser-owned higher-order syntax fact extraction.

(import :gerbil/expander
        :asp-gerbil-scheme/src/parser/formals
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/support
        :asp-gerbil-scheme/src/parser/syntax
        (only-in :std/misc/list unique))

(export higher-order-facts-from-form
        higher-order-quality-facets)
;;; Feature taxonomy:
;;; - This table is parser-owned evidence for gerbil-utils style, not a style-only keyword list.
;;; - Keep heads grouped by semantic role so guide/search can explain why an agent should study the sample.
;; (List HigherOrderFact)
(def +higher-order-heads+
  '(lambda case-lambda
    match match* with with*
    lambda-match λ-match lambda-ematch λ-ematch
    cut cute
    curry rcurry compose compose1 rcompose !> !!> chain
    funcall constantly iterate-function iterated-function
    fun fn defn %app
    stx-apply stx-call stx-lambda def-stx defsyntax-stx defsyntax-stx/form
    generating<-for-each generating<-list generating<-vector
    generating-reverse<-vector generating<-iter
    list<-generating vector<-generating
    generating-map generating-fold generating-partition
    generating<-cothread in-cothread in-cothread/peekable
    :peekable-iter peekable-iterator-peek peekable-iterator-next!
    for/fold for*/fold
    map filter filter-map append-map
    andmap ormap every any
    find list-index
    fold foldl foldr fold-left fold-right
    with-list-builder))
;; : (-> Relpath Form Datum (List HigherOrderFact) )
(def (higher-order-facts-from-form relpath form datum)
  (if (datum-has-head? datum +higher-order-heads+)
    (higher-order-facts-from-stx relpath form (form-caller-name datum))
    '()))
;;; Boundary:
;;; - higher-order-facts-from-stxes composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Relpath Exprs String (List HigherOrderFact) )
(def (higher-order-facts-from-stxes relpath exprs caller)
  (apply append
         (map (cut higher-order-facts-from-stx relpath <> caller)
              exprs)))
;; : (-> Head Boolean )
(def (ignored-higher-order-head? head)
  (or (member head '(quote quasiquote syntax quote-syntax))
      (metadata-head? head)
      (member head '(syntax-case syntax-rules identifier-rules))))
;; : (-> Relpath ExprStx Head Datum String (List HigherOrderFact) )
(def (maybe-higher-order-head-fact relpath expr-stx head datum caller)
  (if (member head +higher-order-heads+)
    [(higher-order-fact-from-stx relpath expr-stx head datum caller)]
    '()))
;; : (-> Relpath ExprStx Head Datum String (List HigherOrderFact) )
(def (higher-order-definition-facts relpath expr-stx head datum caller)
  (cond
   ((member head +macro-definition-heads+) '())
   ((member head '(defclass .defclass defgeneric .defgeneric)) '())
   (else
    (append
     (maybe-higher-order-head-fact relpath expr-stx head datum caller)
     (higher-order-facts-from-stxes relpath
                                    (stx-form-body-items expr-stx datum)
                                    (or (form-caller-name datum) caller))))))
;; : (-> Relpath ExprStx Head String (List HigherOrderFact) )
(def (higher-order-let-facts relpath expr-stx head caller)
  (append
   (higher-order-facts-from-let-binding-stxes relpath
                                             (let-binding-stxes expr-stx head)
                                             caller)
   (higher-order-facts-from-stxes relpath
                                  (let-body-stxes expr-stx head)
                                  caller)))
;; : (-> Relpath ExprStx Head Datum String (List ExprStx) (List HigherOrderFact) )
(def (higher-order-head-with-body-facts relpath expr-stx head datum caller body)
  (cons (higher-order-fact-from-stx relpath expr-stx head datum caller)
        (higher-order-facts-from-stxes relpath body caller)))
;; : (-> Relpath ExprStx Head Datum String (List ExprStx) (List HigherOrderFact) )
(def (higher-order-default-facts relpath expr-stx head datum caller items)
  (append
   (maybe-higher-order-head-fact relpath expr-stx head datum caller)
   (higher-order-facts-from-stxes relpath (cdr items) caller)))
;;; Boundary:
;;; - higher-order-facts-from-stx coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> Relpath ExprStx String (List HigherOrderFact) )
(def (higher-order-facts-from-stx relpath expr-stx caller)
  (if (not (stx-pair? expr-stx))
    '()
    (let* ((items (stx-list-items expr-stx))
           (head-stx (and (pair? items) (car items)))
           (head (and head-stx (syntax->datum head-stx)))
           (datum (syntax->datum expr-stx)))
      (cond
       ((not (symbol? head))
        (higher-order-facts-from-stxes relpath items caller))
       ((ignored-higher-order-head? head)
        '())
       ((member head +definition-heads+)
        (higher-order-definition-facts relpath expr-stx head datum caller))
       ((let-head? head)
        (higher-order-let-facts relpath expr-stx head caller))
       ((eq? head 'lambda)
        (higher-order-head-with-body-facts relpath expr-stx head datum caller
                                           (lambda-body-stxes expr-stx)))
       ((eq? head 'case-lambda)
        (higher-order-head-with-body-facts relpath expr-stx head datum caller
                                           (case-lambda-body-stxes expr-stx)))
       ((eq? head 'match)
        (higher-order-head-with-body-facts relpath expr-stx head datum caller
                                           (match-body-stxes expr-stx)))
       (else
        (higher-order-default-facts relpath expr-stx head datum caller items))))))
;;; Boundary:
;;; - higher-order-facts-from-let-binding-stxes composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Relpath (List Definition) String (List HigherOrderFact) )
(def (higher-order-facts-from-let-binding-stxes relpath bindings caller)
  (apply append
         (map (cut higher-order-facts-from-let-binding-stx relpath <> caller)
              bindings)))
;; : (-> Relpath Binding String (List HigherOrderFact) )
(def (higher-order-facts-from-let-binding-stx relpath binding caller)
  (let (items (stx-list-items binding))
    (if (and (pair? items) (pair? (cdr items)))
      (higher-order-facts-from-stx relpath (cadr items) caller)
      '())))
;; : (-> Relpath ExprStx Head Datum String (List HigherOrderFact) )
(def (higher-order-fact-from-stx relpath expr-stx head datum caller)
  (let (loc (stx-source expr-stx))
    (make-higher-order-fact (datum->string head)
                            (datum->string head)
                            relpath
                            (source-start-line loc)
                            (source-end-line loc)
                            (higher-order-role head datum)
                            (higher-order-operand-count head datum)
                            (higher-order-arities head datum)
                            (higher-order-formal-names head datum)
                            caller)))
;;; Role taxonomy:
;;; - Roles are the stable agent-facing vocabulary for advanced composition and syntax-helper evidence.
;;; - Add new runtime or utils idioms here before policy consumes them.
;; : (-> Head Datum String )
(def (higher-order-role head datum)
  (cond
   ((and (eq? head 'lambda)
         (lambda-match-opportunity? datum))
    "lambda-match-opportunity")
   ((and (eq? head 'lambda)
         (eta-wrapper-lambda? datum))
    "eta-wrapper-lambda")
   ((member head '(lambda-match λ-match lambda-ematch λ-ematch))
    "pattern-matching-function")
   ((member head '(match match* with with*))
    "pattern-matching-function")
   ((eq? head 'lambda) "anonymous-function")
   ((eq? head 'case-lambda) "multi-arity-function")
   ((member head '(cut cute)) "partial-application")
   ((member head '(curry rcurry)) "function-curry")
   ((member head '(compose compose1 rcompose)) "function-composition")
   ((member head '(!> !!> chain)) "pipeline-composition")
   ((member head '(funcall constantly iterate-function iterated-function))
    "higher-order-combinator")
   ((eq? head 'fun) "named-lambda-abstraction")
   ((member head '(fn defn %app)) "autocurry-semantics")
   ((member head '(stx-apply stx-call stx-lambda def-stx
                   defsyntax-stx defsyntax-stx/form))
    "syntax-helper-dsl")
   ((member head '(generating<-for-each generating<-list generating<-vector
                   generating-reverse<-vector generating<-iter
                   list<-generating vector<-generating generating-map
                   generating-fold generating-partition))
    "generator-transform")
   ((member head '(generating<-cothread in-cothread in-cothread/peekable))
    "generator-control-inversion")
   ((member head '(:peekable-iter peekable-iterator-peek
                   peekable-iterator-next!))
    "stateful-protocol-wrapper")
   ((member head '(for/fold for*/fold)) "loop-fold")
   ((eq? head 'map) "sequence-map")
   ((eq? head 'filter) "sequence-filter")
   ((eq? head 'filter-map) "sequence-filter-map")
   ((eq? head 'append-map) "sequence-append-map")
   ((member head '(andmap ormap every any)) "sequence-predicate")
   ((member head '(find list-index)) "sequence-search")
   ((member head '(fold foldl foldr fold-left fold-right)) "sequence-fold")
   ((eq? head 'with-list-builder) "list-builder")
   (else "higher-order-call")))

;;; Quality facets expose gerbil-utils-style expression composition as parser-owned evidence.
;; : (-> HigherOrderFact (List QualityFacet) )
(def (higher-order-quality-facets fact)
  (unique
   (filter identity
           [(and (member (higher-order-fact-role fact)
                         '("sequence-map" "sequence-filter" "sequence-filter-map"
                           "sequence-append-map" "sequence-predicate"
                           "sequence-search" "sequence-fold"))
                 "expression-level-composition")
            (and (member (higher-order-fact-role fact)
                         '("partial-application" "function-curry"
                           "function-composition" "pipeline-composition"
                           "higher-order-combinator"))
                 "combinator-composition")
            (and (member (higher-order-fact-role fact)
                         '("function-composition" "pipeline-composition"))
                 "multi-value-composition")
            (and (equal? (higher-order-fact-role fact) "autocurry-semantics")
                 "autocurry-application-semantics")
            (and (equal? (higher-order-fact-role fact) "anonymous-function")
                 "lambda-local-abstraction")
            (and (equal? (higher-order-fact-role fact) "named-lambda-abstraction")
                 "lambda-local-abstraction")
            (and (equal? (higher-order-fact-role fact) "named-lambda-abstraction")
                 "named-lambda-helper")
            (and (member (higher-order-fact-role fact)
                         '("lambda-match-opportunity"
                           "pattern-matching-function"))
                 "lambda-match-destructuring")
            (and (equal? (higher-order-fact-role fact)
                         "lambda-match-opportunity")
                 "lambda-match-rewrite-opportunity")
            (and (equal? (higher-order-fact-role fact) "eta-wrapper-lambda")
                 "eta-wrapper-drift")
            (and (equal? (higher-order-fact-role fact) "eta-wrapper-lambda")
                 "function-specialization-opportunity")
            (and (and (equal? (higher-order-fact-role fact) "anonymous-function")
                      (> (higher-order-fact-operand-count fact) 0))
                 "parameterized-transform")
            (and (and (equal? (higher-order-fact-role fact) "named-lambda-abstraction")
                      (> (higher-order-fact-operand-count fact) 0))
                 "parameterized-transform")
            (and (equal? (higher-order-fact-role fact) "syntax-helper-dsl")
                 "syntax-helper-extraction")
            (and (member (higher-order-fact-role fact)
                         '("partial-application" "function-curry"))
                 "function-specialization-abstraction")
            (and (member (higher-order-fact-role fact)
                         '("function-composition" "pipeline-composition"))
                 "function-pipeline-abstraction")
            (and (member (higher-order-fact-role fact)
                         '("generator-transform" "generator-control-inversion"))
                 "generator-interface-duality")
            (and (equal? (higher-order-fact-role fact) "generator-control-inversion")
                 "continuation-or-coroutine-boundary")
            (and (equal? (higher-order-fact-role fact) "stateful-protocol-wrapper")
                 "stateful-protocol-wrapper")
            (and (equal? (higher-order-fact-role fact) "multi-arity-function")
                 "case-lambda-optimization-boundary")
            (and (equal? (higher-order-fact-role fact) "multi-arity-function")
                 "multi-arity-abstraction")
            (and (member (higher-order-fact-role fact)
                         '("loop-fold" "list-builder"))
                 "builder-or-fold-combinator")])))

;; : (-> Head Datum Integer )
(def (higher-order-operand-count head datum)
  (cond
   ((eq? head 'lambda) (length (lambda-formal-datums datum)))
   ((eq? head 'case-lambda) (length (case-lambda-clause-datums datum)))
   (else (length (safe-cdr datum)))))

;;; Gerbil-utils/base.ss provides `lambda-match` for the common case where an
;;; anonymous unary function immediately destructures its argument with `match`.
;;; Keeping this shape parser-owned prevents policy from guessing by text.
;; : (-> Datum Boolean )
(def (lambda-match-opportunity? datum)
  (let* ((formals (lambda-formal-datums datum))
         (body (safe-cddr datum))
         (body-expr (and (= (length body) 1) (car body)))
         (body-items (and body-expr (datum-list-items body-expr))))
    (and (= (length formals) 1)
         (pair? body-items)
         (eq? (car body-items) 'match)
         (equal? (safe-cadr body-items) (car formals)))))

;;; Eta-wrapper lambdas hide a reusable function value behind boilerplate.
;;; The check is deliberately strict: one body expression, symbolic callee, and
;;; arguments exactly matching the lambda formals in order.
;; : (-> Datum Boolean )
(def (eta-wrapper-lambda? datum)
  (let* ((formals (lambda-formal-datums datum))
         (body (safe-cddr datum))
         (body-expr (and (= (length body) 1) (car body)))
         (body-items (and body-expr (datum-list-items body-expr)))
         (callee (and (pair? body-items) (car body-items)))
         (args (and (pair? body-items) (cdr body-items))))
    (and (pair? formals)
         (symbol? callee)
         (not (member callee '(quote quasiquote syntax quote-syntax
                               if begin begin0 lambda case-lambda
                               let let* letrec let-values let*-values
                               cond case and or when unless match)))
         (equal? args formals))))
;;; Boundary:
;;; - higher-order-arities composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Head Datum (List HigherOrderFact) )
(def (higher-order-arities head datum)
  (cond
   ((eq? head 'lambda) [(length (lambda-formal-datums datum))])
   ((eq? head 'case-lambda)
    (map (lambda (clause)
           (length (lambda-formals-from-clause clause)))
         (case-lambda-clause-datums datum)))
   (else '())))
;;; Boundary:
;;; - higher-order-formal-names composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Head Datum (List HigherOrderFact) )
(def (higher-order-formal-names head datum)
  (cond
   ((eq? head 'lambda)
    (map datum->string (lambda-formal-datums datum)))
   ((eq? head 'case-lambda)
    (unique
     (apply append
            (map (lambda (clause)
                   (map datum->string (lambda-formals-from-clause clause)))
                 (case-lambda-clause-datums datum)))))
   (else '())))
;; : (-> Datum Integer )
(def (lambda-formal-datums datum)
  (lambda-formals-from-datum (safe-cadr datum)))
;;; Boundary:
;;; - case-lambda-clause-datums composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Datum Integer )
(def (case-lambda-clause-datums datum)
  (filter pair? (safe-cdr datum)))
;; : (-> Clause LambdaFormalsFromClause )
(def (lambda-formals-from-clause clause)
  (lambda-formals-from-datum (if (pair? clause) (car clause) '())))
;; : (-> Formals LambdaFormalsFromDatum )
(def (lambda-formals-from-datum formals)
  (cond
   ((symbol? formals) [formals])
   ((pair? formals) (formal-tail-datums formals))
   (else '())))
