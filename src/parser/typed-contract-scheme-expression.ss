;;; -*- Gerbil -*-
;;; Gerbil type-expression diagnostics and top-level tokenization.

(import :gerbil/gambit
        (only-in :std/srfi/13 string-empty? string-ref string-trim-both)
        (only-in :std/srfi/1 drop-right)
        (only-in :std/sugar cut foldl))

(export scheme-type-expression-diagnostics
        scheme-keyword-marker?
        scheme-keyword-name
        scheme-quoted-symbol?
        scheme-container-head?
        scheme-list-type-shorthand?
        scheme-type-variable-symbol?
        datum->type-string
        typed-contract-last
        split-top-level-type-exprs)

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
