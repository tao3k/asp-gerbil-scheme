;;; -*- Gerbil -*-
;;; Gerbil-native, non-expanding syntax AST and phase-aware relations.

(import :gerbil/expander
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/support
        (only-in :std/misc/list unique)
        (only-in :std/sugar foldl hash))

(export +syntax-ast-version+
        syntax-ast-from-form
        syntax-ast-template-callees
        syntax-ast-relation-projection)

;; This version names the semantics of the stable relation projection.  Native
;; syntax objects are traversed during construction and released; only compact
;; source identity and relations survive in the project index.
(def +syntax-ast-version+ "gerbil-native-syntax-relations.v2")

(def +syntax-ast-macro-definition-heads+
  '(define-syntax defsyntax defsyntax-for-match defrules defrule
    defsyntax-parameter defsyntax-parameter*
    defsyntax-for-import defsyntax-for-export defsyntax-for-import-export
    defsyntax-stx defsyntax-stx/form))

;; : (-> Relpath Syntax (Or String False) SyntaxAst)
(def (syntax-ast-from-form relpath form owner)
  (make-syntax-ast
   +syntax-ast-version+
   relpath
   owner
   (reverse
    (syntax-relations-from-stx/acc relpath form owner 0 'runtime '()
                                   0 'runtime '()))))

;; : (-> SyntaxAst (List String))
(def (syntax-ast-template-callees ast)
  (unique
   (map (lambda (relation)
          (datum->string (syntax-relation-name relation)))
        (filter (lambda (relation)
                  (and (eq? (syntax-relation-kind relation)
                            'application-head)
                       (memq (syntax-relation-context relation)
                             '(template quasisyntax-template))))
                (syntax-ast-relations ast)))))

;; : (-> SyntaxAst (List Json))
(def (syntax-ast-relation-projection ast)
  (map (lambda (relation)
         (hash (kind (datum->string (syntax-relation-kind relation)))
               (name (datum->string (syntax-relation-name relation)))
               (owner (or (syntax-ast-owner ast) ""))
               (path (syntax-ast-path ast))
               (start (syntax-relation-start relation))
               (end (syntax-relation-end relation))
               (phase (syntax-relation-phase relation))
               (context (datum->string (syntax-relation-context relation)))
               (structuralPath (syntax-relation-structural-path relation))))
       (syntax-ast-relations ast)))

;; The walker classifies source syntax without core-expand: expanding a
;; project definition can evaluate its transformer.  Gerbil's native stx API
;; remains the structural authority; the cases below only assign phase/context
;; to the standard quote and macro forms.
;; : (-> Relpath Syntax (Or String False) Integer Symbol (List Integer)
;;        Integer Symbol (List SyntaxRelation) (List SyntaxRelation))
(def (syntax-relations-from-stx/acc relpath stx owner phase context
                                    structural-path resume-phase resume-context
                                    out)
  (if (not (stx-pair? stx))
    out
    (let* ((items (syntax-ast-list-items stx))
           (head-stx (and (pair? items) (car items)))
           (head (and head-stx (identifier? head-stx) (stx-e head-stx)))
           (head-name (and head (datum->string head)))
           (head-out (syntax-relations-with-head/acc
                      relpath head-stx head-name owner phase context
                      structural-path out))
           (children (syntax-ast-tail items)))
      (cond
       ((not head)
        (syntax-relations-from-children/acc
         relpath items owner phase context structural-path 0
         resume-phase resume-context head-out))
       ((eq? head 'quote)
        (syntax-relations-from-children/acc
         relpath children owner phase 'quoted-data structural-path 1
         phase context head-out))
       ((eq? head 'quasiquote)
        (syntax-relations-from-children/acc
         relpath children owner phase 'quasiquoted-data structural-path 1
         phase context head-out))
       ((and (member head '(unquote unquote-splicing))
             (eq? context 'quasiquoted-data))
        (syntax-relations-from-children/acc
         relpath children owner resume-phase resume-context structural-path 1
         resume-phase resume-context head-out))
       ((member head '(syntax quote-syntax))
        (syntax-relations-from-children/acc
         relpath children owner (max 0 (- phase 1)) 'template
         structural-path 1 phase context head-out))
       ((eq? head 'quasisyntax)
        (syntax-relations-from-children/acc
         relpath children owner (max 0 (- phase 1)) 'quasisyntax-template
         structural-path 1 phase context head-out))
       ((eq? head 'syntax/loc)
        (syntax-relations-from-syntax-loc/acc
         relpath children owner phase context structural-path head-out))
       ((and (member head '(unsyntax unsyntax-splicing))
             (eq? context 'quasisyntax-template))
        (syntax-relations-from-children/acc
         relpath children owner resume-phase resume-context structural-path 1
         resume-phase resume-context head-out))
       ((eq? head 'begin-syntax)
        (syntax-relations-from-children/acc
         relpath children owner (+ phase 1) 'transformer structural-path 1
         phase context head-out))
       ((member head +syntax-ast-macro-definition-heads+)
        (syntax-relations-from-macro-definition/acc
         relpath head children owner structural-path head-out))
       ((member head '(syntax-rules identifier-rules))
        (syntax-relations-from-rules/acc
         relpath head children owner phase structural-path
         resume-phase resume-context head-out))
       ((eq? head 'syntax-case)
        (syntax-relations-from-syntax-case/acc
         relpath children owner phase structural-path
         resume-phase resume-context head-out))
       ((member head '(lambda lambda% define def define-values defvalues))
        (syntax-relations-from-binding-form/acc
         relpath children owner phase context structural-path head-out))
       ((member head '(let let* letrec letrec* let-values let*-values
                           letrec-values))
        (syntax-relations-from-let/acc
         relpath children owner phase context structural-path head-out))
       (else
        (syntax-relations-from-children/acc
         relpath children owner phase context structural-path 1
         resume-phase resume-context head-out))))))

;; : (-> Relpath Syntax (Or String False) (Or String False) Integer Symbol
;;        (List Integer) (List SyntaxRelation) (List SyntaxRelation))
(def (syntax-relations-with-head/acc relpath head-stx head-name owner phase
                                     context structural-path out)
  (if head-name
    (cons (syntax-ast-head-relation relpath head-stx owner phase
                                    context structural-path)
          out)
    out))

;; : (forall (a) (-> (List a) (List a)))
(def (syntax-ast-tail items)
  (if (pair? items) (cdr items) '()))

;; : (-> Relpath Syntax (Or String False) Integer Symbol (List Integer)
;;        SyntaxRelation)
(def (syntax-ast-head-relation _relpath head-stx _owner phase context structural-path)
  (let (loc (stx-source head-stx))
    (make-syntax-relation
     'application-head
     (stx-e head-stx)
     (source-start-line loc)
     (source-end-line loc)
     phase
     context
     structural-path)))

;; syntax/loc evaluates its source expression at the surrounding transformer
;; phase and emits only its second operand as runtime template syntax.
;; : (-> Relpath (List Syntax) (Or String False) Integer Symbol
;;        (List Integer) (List SyntaxRelation) (List SyntaxRelation))
(def (syntax-relations-from-syntax-loc/acc relpath children owner phase context
                                           structural-path out)
  (let* ((source-out
          (if (null? children)
            out
            (syntax-relations-from-stx/acc
             relpath (car children) owner phase context
             (cons 1 structural-path) phase context out)))
         (template-out
          (if (< (length children) 2)
            source-out
            (syntax-relations-from-stx/acc
             relpath (cadr children) owner (max 0 (- phase 1)) 'template
             (cons 2 structural-path) phase context source-out))))
    (syntax-relations-from-children/acc
     relpath (syntax-ast-drop children 2) owner phase context structural-path 3
     phase context template-out)))

;; Lambda/definition targets are binding syntax, never emitted applications;
;; their bodies remain in the surrounding template or transformer context.
;; : (-> Relpath (List Syntax) (Or String False) Integer Symbol
;;        (List Integer) (List SyntaxRelation) (List SyntaxRelation))
(def (syntax-relations-from-binding-form/acc relpath children owner phase context
                                             structural-path out)
  (let (binding-out
        (if (null? children)
          out
          (syntax-relations-from-stx/acc
           relpath (car children) owner phase 'binding
           (cons 1 structural-path) phase context out)))
    (syntax-relations-from-children/acc
     relpath (if (null? children) '() (cdr children)) owner phase context
     structural-path 2 phase context binding-out)))

;; Let binding names/patterns are syntax, while initializer expressions and
;; bodies can contain emitted macro applications.  Named-let adds one binding
;; identifier before the binding list.
;; : (-> Relpath (List Syntax) (Or String False) Integer Symbol
;;        (List Integer) (List SyntaxRelation) (List SyntaxRelation))
(def (syntax-relations-from-let/acc relpath children owner phase context
                                    structural-path out)
  (let* ((named? (and (pair? children) (identifier? (car children))))
         (binding-index (if named? 2 1))
         (bindings-tail (if named? (cdr children) children))
         (bindings (and (pair? bindings-tail) (car bindings-tail)))
         (body (syntax-ast-tail bindings-tail))
         (binding-out (syntax-relations-from-optional-let-bindings/acc
                       relpath bindings owner phase context binding-index
                       structural-path out)))
    (syntax-relations-from-children/acc
     relpath body owner phase context structural-path (+ binding-index 1)
     phase context binding-out)))

;; : (-> Relpath (Or Syntax False) (Or String False) Integer Symbol Integer
;;        (List Integer) (List SyntaxRelation) (List SyntaxRelation))
(def (syntax-relations-from-optional-let-bindings/acc
      relpath bindings owner phase context binding-index structural-path out)
  (if bindings
    (syntax-relations-from-let-bindings/acc
     relpath (syntax-ast-list-items bindings) owner phase context
     (cons binding-index structural-path) out)
    out))

;; : (-> Relpath (List Syntax) (Or String False) Integer Symbol
;;        (List Integer) (List SyntaxRelation) (List SyntaxRelation))
(def (syntax-relations-from-let-bindings/acc relpath bindings owner phase context
                                             structural-path out)
  (car
   (foldl
    (lambda (binding state)
      (let* ((index (cdr state))
             (prior-out (car state))
             (items (syntax-ast-list-items binding))
             (name-out
              (if (null? items)
                prior-out
                (syntax-relations-from-stx/acc
                 relpath (car items) owner phase 'binding
                 (cons 0 (cons index structural-path)) phase context
                 prior-out)))
             (value-out
              (syntax-relations-from-children/acc
               relpath (syntax-ast-tail items) owner phase context
               (cons index structural-path) 1 phase context name-out)))
        (cons value-out (+ index 1))))
    (cons out 0)
    bindings)))

;; : (-> Relpath (List Syntax) (Or String False) Integer String
;;        (List Integer) Integer Integer String (List SyntaxRelation))
(def (syntax-relations-from-children/acc relpath children owner phase context
                                         structural-path start-index
                                         resume-phase resume-context out)
  (car
   (foldl
    (lambda (child state)
      (let ((prior-out (car state))
            (index (cdr state)))
        (cons
         (syntax-relations-from-stx/acc
          relpath child owner phase context
          (cons index structural-path)
          resume-phase resume-context prior-out)
         (+ index 1))))
    (cons out start-index)
    children)))

;; : (-> Relpath Symbol (List Syntax) (Or String False) (List Integer)
;;        (List SyntaxRelation))
(def (syntax-relations-from-macro-definition/acc relpath head children owner
                                                 structural-path out)
  (cond
   ((eq? head 'defrules)
    ;; (defrules name (literal ...) clause ...)
    (syntax-relations-from-rule-list/acc
     relpath (syntax-ast-drop children 2) owner 1 structural-path 3 out))
   ((eq? head 'defrule)
    ;; (defrule (name . formals) [fender] template)
    (syntax-relations-from-single-rule-body/acc
     relpath children owner 1 structural-path 1 out))
   (else
    ;; The declaration target is child zero; remaining expressions execute at
    ;; transformer phase.  Nested syntax/syntax-rules forms reclassify emitted
    ;; templates through the generic walker.
    (syntax-relations-from-children/acc
     relpath (if (pair? children) (cdr children) '())
     owner 1 'transformer structural-path 2 1 'transformer out))))

;; : (-> Relpath Symbol (List Syntax) (Or String False) Integer
;;        (List Integer) Integer String (List SyntaxRelation))
(def (syntax-relations-from-rules/acc relpath head children owner phase
                                      structural-path resume-phase
                                      resume-context out)
  (let* ((rules (if (eq? head 'syntax-rules)
                  (syntax-ast-drop children 1)
                  children))
         (start-index (if (eq? head 'syntax-rules) 2 1)))
    (syntax-relations-from-rule-list/acc
     relpath rules owner phase structural-path start-index out)))

;; : (-> Relpath (List Syntax) (Or String False) Integer (List Integer)
;;        Integer (List SyntaxRelation))
(def (syntax-relations-from-rule-list/acc relpath rules owner phase
                                          structural-path start-index out)
  (car
   (foldl
    (lambda (rule state)
      (let ((prior-out (car state))
            (index (cdr state)))
        (cons
         (syntax-relations-from-rule/acc
          relpath rule owner phase
          (cons index structural-path) prior-out)
         (+ index 1))))
    (cons out start-index)
    rules)))

;; syntax-rules/defrules clauses have a pattern, an optional fender, and an
;; emitted template.  This mirrors the public form boundary, not Gerbil's
;; private expanded representation.
;; : (-> Relpath Syntax (Or String False) Integer (List Integer)
;;        (List SyntaxRelation))
(def (syntax-relations-from-rule/acc relpath rule owner phase structural-path
                                     out)
  (let (items (syntax-ast-list-items rule))
    (if (< (length items) 2)
      out
      (let* ((pattern-out
              (syntax-relations-from-stx/acc
               relpath (car items) owner phase 'pattern
               (cons 0 structural-path) phase 'transformer out))
             (fender-out
              (syntax-relations-from-children/acc
               relpath (syntax-ast-middle items) owner phase 'transformer
               structural-path 1 phase 'transformer pattern-out)))
        (syntax-relations-from-stx/acc
         relpath (syntax-ast-last items) owner (max 0 (- phase 1)) 'template
         (cons (- (length items) 1) structural-path)
         phase 'transformer fender-out)))))

;; defrule's declared formals are its pattern.  The optional expression before
;; the final template is a transformer-phase fender.
;; : (-> Relpath (List Syntax) (Or String False) Integer (List Integer)
;;        Integer (List SyntaxRelation))
(def (syntax-relations-from-single-rule-body/acc relpath children owner phase
                                                 structural-path start-index
                                                 out)
  (if (< (length children) 2)
    out
    (let* ((pattern-out
            (syntax-relations-from-stx/acc
             relpath (car children) owner phase 'pattern
             (cons start-index structural-path) phase 'transformer out))
           (fender-out
            (syntax-relations-from-children/acc
             relpath (syntax-ast-middle children) owner phase 'transformer
             structural-path (+ start-index 1) phase 'transformer
             pattern-out)))
      (syntax-relations-from-stx/acc
       relpath (syntax-ast-last children) owner (max 0 (- phase 1)) 'template
       (cons (+ start-index (- (length children) 1)) structural-path)
       phase 'transformer fender-out))))

;; syntax-case clause bodies execute at transformer phase.  Any emitted syntax
;; is discovered by the syntax/quote-syntax/quasisyntax cases in the generic
;; walker, so dynamic transformer calls cannot be mistaken for expansion edges.
;; : (-> Relpath (List Syntax) (Or String False) Integer (List Integer)
;;        Integer String (List SyntaxRelation))
(def (syntax-relations-from-syntax-case/acc relpath children owner phase
                                            structural-path resume-phase
                                            resume-context out)
  (let (prefix-out
        (syntax-relations-from-children/acc
         relpath (syntax-ast-take children 2) owner phase 'transformer
         structural-path 1 resume-phase resume-context out))
    (car
     (foldl
      (lambda (clause state)
        (let* ((index (cdr state))
               (prior-out (car state))
               (items (syntax-ast-list-items clause))
               (pattern-out
                (if (null? items)
                  prior-out
                  (syntax-relations-from-stx/acc
                   relpath (car items) owner phase 'pattern
                   (cons 0 (cons index structural-path))
                   phase 'transformer prior-out)))
               (body-out
                (if (null? items)
                  pattern-out
                  (syntax-relations-from-children/acc
                   relpath (syntax-ast-tail items) owner phase 'transformer
                   (cons index structural-path) 1
                   phase 'transformer pattern-out))))
          (cons body-out (+ index 1))))
      (cons prefix-out 3)
      (syntax-ast-drop children 2)))))

;; : (-> Syntax (List Syntax))
(def (syntax-ast-list-items stx)
  (if (stx-pair? stx)
    (reverse (stx-foldl (lambda (item out) (cons item out)) '() stx))
    '()))

;; : (forall (a) (-> (List a) Integer (List a)))
(def (syntax-ast-drop items count)
  (if (or (<= count 0) (null? items))
    items
    (syntax-ast-drop (cdr items) (- count 1))))

;; : (forall (a) (-> (List a) Integer (List a)))
(def (syntax-ast-take items count)
  (if (or (<= count 0) (null? items))
    '()
    (cons (car items) (syntax-ast-take (cdr items) (- count 1)))))

;; : (forall (a) (-> (List a) a))
(def (syntax-ast-last items)
  (if (null? (cdr items))
    (car items)
    (syntax-ast-last (cdr items))))

;; : (forall (a) (-> (List a) (List a)))
(def (syntax-ast-middle items)
  (if (< (length items) 3)
    '()
    (cdr (reverse (cdr (reverse items))))))
