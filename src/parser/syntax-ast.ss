;;; -*- Gerbil -*-
;;; Gerbil-native, non-expanding syntax AST and phase-aware relations.

(import :gerbil/expander
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/support
        (only-in :std/misc/list unique)
        (only-in :std/sugar hash))

(export +syntax-ast-version+
        syntax-ast-from-form
        syntax-ast-template-callees
        syntax-ast-relation-projection)

;; This version names the semantics of the stable relation projection.  Native
;; syntax objects are intentionally retained only in memory and are not part of
;; the wire representation.
(def +syntax-ast-version+ "gerbil-native-syntax-relations.v1")

(def +syntax-ast-macro-definition-heads+
  '(define-syntax defsyntax defsyntax-for-match defrules defrule
    defsyntax-parameter defsyntax-parameter*
    defsyntax-for-import defsyntax-for-export defsyntax-for-import-export
    defsyntax-stx defsyntax-stx/form))

;; : (-> Relpath Syntax (Or String False) SyntaxAst)
(def (syntax-ast-from-form relpath form owner)
  (make-syntax-ast
   +syntax-ast-version+
   form
   (reverse
    (syntax-relations-from-stx/acc relpath form owner 0 "runtime" '()
                                   0 "runtime" '()))))

;; : (-> SyntaxAst (List String))
(def (syntax-ast-template-callees ast)
  (unique
   (map syntax-relation-name
        (filter (lambda (relation)
                  (and (equal? (syntax-relation-kind relation)
                               "application-head")
                       (member (syntax-relation-context relation)
                               '("template" "quasisyntax-template"))))
                (syntax-ast-relations ast)))))

;; : (-> SyntaxAst (List Json))
(def (syntax-ast-relation-projection ast)
  (map (lambda (relation)
         (hash (kind (syntax-relation-kind relation))
               (name (syntax-relation-name relation))
               (owner (or (syntax-relation-owner relation) ""))
               (path (syntax-relation-path relation))
               (start (syntax-relation-start relation))
               (end (syntax-relation-end relation))
               (phase (syntax-relation-phase relation))
               (context (syntax-relation-context relation))
               (structuralPath (syntax-relation-structural-path relation))))
       (syntax-ast-relations ast)))

;; The walker classifies source syntax without core-expand: expanding a
;; project definition can evaluate its transformer.  Gerbil's native stx API
;; remains the structural authority; the cases below only assign phase/context
;; to the standard quote and macro forms.
;; : (-> Relpath Syntax (Or String False) Integer String (List Integer)
;;        Integer String (List SyntaxRelation) (List SyntaxRelation))
(def (syntax-relations-from-stx/acc relpath stx owner phase context
                                    structural-path resume-phase resume-context
                                    out)
  (if (not (stx-pair? stx))
    out
    (let* ((items (syntax-ast-list-items stx))
           (head-stx (and (pair? items) (car items)))
           (head (and head-stx (identifier? head-stx) (stx-e head-stx)))
           (head-name (and head (datum->string head)))
           (head-out
            (if head-name
              (cons (syntax-ast-head-relation relpath head-stx owner phase
                                              context structural-path)
                    out)
              out))
           (children (if (pair? items) (cdr items) '())))
      (cond
       ((not head)
        (syntax-relations-from-children/acc
         relpath items owner phase context structural-path 0
         resume-phase resume-context head-out))
       ((eq? head 'quote)
        (syntax-relations-from-children/acc
         relpath children owner phase "quoted-data" structural-path 1
         phase context head-out))
       ((eq? head 'quasiquote)
        (syntax-relations-from-children/acc
         relpath children owner phase "quasiquoted-data" structural-path 1
         phase context head-out))
       ((and (member head '(unquote unquote-splicing))
             (equal? context "quasiquoted-data"))
        (syntax-relations-from-children/acc
         relpath children owner resume-phase resume-context structural-path 1
         resume-phase resume-context head-out))
       ((member head '(syntax quote-syntax))
        (syntax-relations-from-children/acc
         relpath children owner (max 0 (- phase 1)) "template"
         structural-path 1 phase context head-out))
       ((eq? head 'quasisyntax)
        (syntax-relations-from-children/acc
         relpath children owner (max 0 (- phase 1)) "quasisyntax-template"
         structural-path 1 phase context head-out))
       ((and (member head '(unsyntax unsyntax-splicing))
             (equal? context "quasisyntax-template"))
        (syntax-relations-from-children/acc
         relpath children owner resume-phase resume-context structural-path 1
         resume-phase resume-context head-out))
       ((eq? head 'begin-syntax)
        (syntax-relations-from-children/acc
         relpath children owner (+ phase 1) "transformer" structural-path 1
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
       (else
        (syntax-relations-from-children/acc
         relpath children owner phase context structural-path 1
         resume-phase resume-context head-out))))))

;; : (-> Relpath Syntax (Or String False) Integer String (List Integer)
;;        SyntaxRelation)
(def (syntax-ast-head-relation relpath head-stx owner phase context structural-path)
  (let (loc (stx-source head-stx))
    (make-syntax-relation
     "application-head"
     (datum->string (stx-e head-stx))
     owner
     relpath
     (source-start-line loc)
     (source-end-line loc)
     phase
     context
     structural-path)))

;; : (-> Relpath (List Syntax) (Or String False) Integer String
;;        (List Integer) Integer Integer String (List SyntaxRelation))
(def (syntax-relations-from-children/acc relpath children owner phase context
                                         structural-path start-index
                                         resume-phase resume-context out)
  (let loop ((rest children) (index start-index) (out out))
    (if (null? rest)
      out
      (loop (cdr rest)
            (+ index 1)
            (syntax-relations-from-stx/acc
             relpath (car rest) owner phase context
             (append structural-path [index])
             resume-phase resume-context out)))))

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
     owner 1 "transformer" structural-path 2 1 "transformer" out))))

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
  (let loop ((rest rules) (index start-index) (out out))
    (if (null? rest)
      out
      (loop (cdr rest)
            (+ index 1)
            (syntax-relations-from-rule/acc
             relpath (car rest) owner phase
             (append structural-path [index]) out)))))

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
               relpath (car items) owner phase "pattern"
               (append structural-path [0]) phase "transformer" out))
             (fender-out
              (syntax-relations-from-children/acc
               relpath (syntax-ast-middle items) owner phase "transformer"
               structural-path 1 phase "transformer" pattern-out)))
        (syntax-relations-from-stx/acc
         relpath (syntax-ast-last items) owner (max 0 (- phase 1)) "template"
         (append structural-path [(- (length items) 1)])
         phase "transformer" fender-out)))))

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
             relpath (car children) owner phase "pattern"
             (append structural-path [start-index]) phase "transformer" out))
           (fender-out
            (syntax-relations-from-children/acc
             relpath (syntax-ast-middle children) owner phase "transformer"
             structural-path (+ start-index 1) phase "transformer"
             pattern-out)))
      (syntax-relations-from-stx/acc
       relpath (syntax-ast-last children) owner (max 0 (- phase 1)) "template"
       (append structural-path [(+ start-index (- (length children) 1))])
       phase "transformer" fender-out))))

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
         relpath (syntax-ast-take children 2) owner phase "transformer"
         structural-path 1 resume-phase resume-context out))
    (let loop ((clauses (syntax-ast-drop children 2))
               (index 3)
               (out prefix-out))
      (if (null? clauses)
        out
        (let* ((items (syntax-ast-list-items (car clauses)))
               (pattern-out
                (if (null? items)
                  out
                  (syntax-relations-from-stx/acc
                   relpath (car items) owner phase "pattern"
                   (append structural-path [index 0])
                   phase "transformer" out)))
               (body-out
                (if (null? items)
                  pattern-out
                  (syntax-relations-from-children/acc
                   relpath (cdr items) owner phase "transformer"
                   (append structural-path [index]) 1
                   phase "transformer" pattern-out))))
          (loop (cdr clauses) (+ index 1) body-out))))))

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
