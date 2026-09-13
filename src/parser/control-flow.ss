;;; -*- Gerbil -*-
;;; Parser-owned control-flow syntax fact extraction.

(import :gerbil/expander
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/support
        :asp-gerbil-scheme/src/parser/syntax
        (only-in :std/misc/list unique)
        (only-in :std/srfi/1 drop))

(export control-flow-facts-from-form
        control-flow-quality-facets)
;; ConfigConstant
(def +protected-control-heads+ '(try with-catch))
;; ConfigConstant
(def +protected-handler-heads+ '(catch finally))
;;; Runtime boundary taxonomy:
;;; - These heads come from Gerbil runtime/control, runtime/thread, and gerbil-utils generator evidence.
;;; - Keep cleanup, continuation, actor, coroutine, and parameter semantics distinct for agent guidance.
;; ConfigConstant
(def +cleanup-control-heads+ '(dynamic-wind with-unwind-protect))
;; ConfigConstant
(def +continuation-control-heads+
  '(let/cc call/cc call-with-current-continuation
    continuation-capture ##continuation-capture ##continuation-graft))
;; String
(def +resource-scope-heads+
  '(parameterize
    call-with-input call-with-output
    call-with-input-file call-with-output-file
    call-with-input-string call-with-output-string
    with-input with-output))
;; ConfigConstant
(def +parameter-control-heads+ '(call-with-parameters make-parameter))
;; ConfigConstant
(def +builder-control-heads+ '(with-list-builder))
;; ConfigConstant
(def +conditional-branch-heads+ '(if cond case))
;; ConfigConstant
(def +actor-control-heads+
  '(spawn spawn/name spawn/group spawn-actor spawn-thread
    thread-start! thread-init! construct-actor-thread))
;; ConfigConstant
(def +coroutine-control-heads+
  '(yield cothread continue in-coroutine in-cothread in-cothread/peekable
    generating<-for-each generating<-cothread))
;;; Head groups are the control-flow taxonomy in data form. Role-specific lists
;;; stay distinct for reporting, while membership checks can remain one
;;; expression-level combinator.
;; ConfigConstant
(def (control-flow-head-groups)
  [+protected-control-heads+
   +protected-handler-heads+
   +cleanup-control-heads+
   +continuation-control-heads+
   +resource-scope-heads+
   +parameter-control-heads+
   +builder-control-heads+
   +conditional-branch-heads+
   +actor-control-heads+
   +coroutine-control-heads+])
;; ConfigConstant
(def +control-flow-heads+
  (apply append (control-flow-head-groups)))
;; ConfigConstant
(def +control-flow-scan-heads+
  (append +control-flow-heads+
          '(match let let* letrec let-values let*-values)))
;; : (-> Relpath Form Datum (List ControlFlowFact) )
(def (control-flow-facts-from-form relpath form datum)
  (if (datum-has-head? datum +control-flow-scan-heads+)
    (control-flow-facts-from-stx relpath form (form-caller-name datum))
    '()))
;; control-flow-facts-from-stxes
;;   : (-> Relpath (List ExprStx) String (List ControlFlowFact))
;;   | doc m%
;;       `control-flow-facts-from-stxes relpath exprs caller` appends
;;       control-flow facts collected from each expression syntax object.
;;
;;       # Examples
;;
;;       ```scheme
;;       (control-flow-facts-from-stxes "src/core.ss" exprs "handler")
;;       ;; => control-flow facts
;;       ```
;;     %
(def (control-flow-facts-from-stxes relpath exprs caller)
  (apply append
         (map (cut control-flow-facts-from-stx relpath <> caller)
              exprs)))
;; : (-> Head Boolean )
(def (ignored-control-flow-head? head)
  (or (member head '(quote quasiquote syntax quote-syntax))
      (metadata-head? head)
      (eq? head 'begin-syntax)
      (member head '(syntax-case syntax-rules identifier-rules))))
;; : (-> Relpath ExprStx Datum String (List ControlFlowFact) )
(def (control-flow-definition-facts relpath expr-stx datum caller)
  (let (head (car datum))
    (cond
     ((member head +macro-definition-heads+) '())
     ((member head '(defclass .defclass defgeneric .defgeneric)) '())
     (else
      (control-flow-facts-from-stxes relpath
                                     (stx-form-body-items expr-stx datum)
                                     (or (form-caller-name datum) caller))))))
;; : (-> Relpath ExprStx Head String (List ControlFlowFact) )
(def (named-let-control-flow-facts relpath expr-stx head caller)
  (if (named-let-stx? expr-stx head)
    [(named-let-control-flow-fact relpath expr-stx caller)]
    '()))
;; : (-> Relpath ExprStx Head String (List ControlFlowFact) )
(def (let-control-flow-facts relpath expr-stx head caller)
  (append
   (named-let-control-flow-facts relpath expr-stx head caller)
   (control-flow-facts-from-let-binding-stxes relpath
                                             (let-binding-stxes expr-stx head)
                                             caller)
   (control-flow-facts-from-stxes relpath
                                  (let-body-stxes expr-stx head)
                                  caller)))
;; : (-> Relpath ExprStx Head String (List ExprStx) (List ControlFlowFact) )
(def (generic-head-control-flow-facts relpath expr-stx head caller items)
  (cons (generic-control-flow-fact relpath expr-stx head caller)
        (control-flow-facts-from-stxes relpath (cdr items) caller)))
;; : (-> Relpath ExprStx String (List ControlFlowFact) )
(def (match-control-flow-facts relpath expr-stx caller)
  (cons (match-control-flow-fact relpath expr-stx caller)
        (control-flow-facts-from-stxes relpath (match-body-stxes expr-stx) caller)))
;;; Boundary:
;;; - control-flow-facts-from-stx coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> Relpath ExprStx String (List ControlFlowFact) )
(def (control-flow-facts-from-stx relpath expr-stx caller)
  (if (not (stx-pair? expr-stx))
    '()
    (let* ((items (stx-list-items expr-stx))
           (head-stx (and (pair? items) (car items)))
           (head (and head-stx (syntax->datum head-stx)))
           (datum (syntax->datum expr-stx)))
      (cond
       ((not (symbol? head))
        (control-flow-facts-from-stxes relpath items caller))
       ((ignored-control-flow-head? head)
        '())
       ((member head +definition-heads+)
        (control-flow-definition-facts relpath expr-stx datum caller))
       ((let-head? head)
        (let-control-flow-facts relpath expr-stx head caller))
       ((control-flow-head? head)
        (generic-head-control-flow-facts relpath expr-stx head caller items))
       ((eq? head 'match)
        (match-control-flow-facts relpath expr-stx caller))
       (else
        (control-flow-facts-from-stxes relpath (cdr items) caller))))))
;; control-flow-facts-from-let-binding-stxes
;;   : (-> Relpath (List Binding) String (List ControlFlowFact))
;;   | doc m%
;;       `control-flow-facts-from-let-binding-stxes relpath bindings caller`
;;       collects control-flow facts from the initializer expression of each let
;;       binding.
;;
;;       # Examples
;;
;;       ```scheme
;;       (control-flow-facts-from-let-binding-stxes "src/core.ss" bindings "handler")
;;       ;; => control-flow facts
;;       ```
;;     %
(def (control-flow-facts-from-let-binding-stxes relpath bindings caller)
  (apply append
         (map (cut control-flow-facts-from-let-binding-stx relpath <> caller)
              bindings)))
;; : (-> Relpath Binding String (List ControlFlowFact) )
(def (control-flow-facts-from-let-binding-stx relpath binding caller)
  (let (items (stx-list-items binding))
    (if (and (pair? items) (pair? (cdr items)))
      (control-flow-facts-from-stx relpath (cadr items) caller)
      '())))
;; : (-> ExprStx Head Boolean )
(def (named-let-stx? expr-stx head)
  (and (eq? head 'let)
       (let (items (stx-list-items expr-stx))
         (and (pair? (cdr items))
              (symbol? (syntax->datum (cadr items)))))))
;; : (-> Relpath ExprStx String Fact )
(def (named-let-control-flow-fact relpath expr-stx caller)
  (let* ((items (stx-list-items expr-stx))
         (name (datum->string (syntax->datum (cadr items))))
         (bindings (let-binding-stxes expr-stx 'let))
         (body (let-body-stxes expr-stx 'let))
         (loc (stx-source expr-stx)))
    (make-control-flow-fact name
                            "named-let"
                            relpath
                            (source-start-line loc)
                            (source-end-line loc)
                            "manual-loop"
                            caller
                            (length bindings)
                            (length body))))
;;; Control-flow heads are grouped by syntactic role, so membership stays
;;; table-driven and auditable.  The `ormap` form is the boundary between raw
;;; symbols and parser-owned control-flow classification.
;;; Membership detection consumes the role taxonomy above as data. This keeps
;;; the parser fact boundary stable while allowing new runtime/control heads to
;;; land in the appropriate group.
;; : (-> Head Boolean )
(def (control-flow-head? head)
  (member head +control-flow-heads+))
;;; Role taxonomy:
;;; - Existing roles stay stable for policy compatibility; new roles expose finer runtime boundaries.
;;; - Control-flow facets below carry the cross-cutting guidance terms used by search and comments.
;; : (-> Head String )
(def (control-flow-role head)
  (cond
   ((member head +protected-control-heads+) "protected-control")
   ((member head +protected-handler-heads+) "protected-handler")
   ((member head +cleanup-control-heads+) "cleanup-boundary")
   ((member head +continuation-control-heads+) "continuation-control")
   ((member head +resource-scope-heads+) "resource-scope")
   ((member head +parameter-control-heads+) "parameter-state")
   ((member head +builder-control-heads+) "builder-control")
   ((member head +conditional-branch-heads+) "conditional-branch")
   ((member head +actor-control-heads+) "actor-control")
   ((member head +coroutine-control-heads+) "coroutine-control")
   (else "control-flow")))

;;; Facet projection:
;;; - Convert precise parser roles into search/comment vocabulary without widening the fact struct.
;;; - Keep this expression-level filter so every facet remains visibly tied to one control-flow role.
;; : (-> ControlFlowFact (List QualityFacet) )
(def (control-flow-quality-facets fact)
  (unique
   (filter identity
           [(and (member (control-flow-fact-role fact)
                         '("protected-control" "cleanup-boundary"
                           "continuation-control" "resource-scope"
                           "parameter-state" "actor-control"
                           "coroutine-control"))
                 "runtime-control-boundary")
            (and (equal? (control-flow-fact-role fact) "cleanup-boundary")
                 "dynamic-cleanup-boundary")
            (and (equal? (control-flow-fact-role fact) "continuation-control")
                 "continuation-capture-boundary")
            (and (equal? (control-flow-fact-role fact) "actor-control")
                 "actor-continuation-diagnostics")
            (and (equal? (control-flow-fact-role fact) "coroutine-control")
                 "generator-control-inversion")
            (and (equal? (control-flow-fact-role fact) "parameter-state")
                 "parameter-state-boundary")
            (and (equal? (control-flow-fact-role fact) "resource-scope")
            "resource-lifecycle-boundary")
            (and (equal? (control-flow-fact-role fact) "builder-control")
                "builder-boundary")
            (and (equal? (control-flow-fact-role fact) "conditional-branch")
                "conditional-dispatch-boundary")
            (and (equal? (control-flow-fact-role fact) "pattern-branch")
                "extensible-match-dsl")
            (and (equal? (control-flow-fact-role fact) "manual-loop")
                "manual-loop-driver")])))
;; : (-> Relpath ExprStx Head String Fact )
(def (generic-control-flow-fact relpath expr-stx head caller)
  (let* ((items (stx-list-items expr-stx))
         (loc (stx-source expr-stx)))
    (make-control-flow-fact (datum->string head)
                            (datum->string head)
                            relpath
                            (source-start-line loc)
                            (source-end-line loc)
                            (control-flow-role head)
                            caller
                            0
                            (length (cdr items)))))
;; : (-> Relpath ExprStx String Fact )
(def (match-control-flow-fact relpath expr-stx caller)
  (let* ((items (stx-list-items expr-stx))
         (loc (stx-source expr-stx)))
    (make-control-flow-fact "match"
                            "match"
                            relpath
                            (source-start-line loc)
                            (source-end-line loc)
                            "pattern-branch"
                            caller
                            0
                            (length (if (>= (length items) 2)
                                      (drop items 2)
                                      '())))))
