;;; -*- Gerbil -*-
;;; Pure syntax primitives for the TypeSpec reader boundary.
;;; This owner knows Scheme datum shape and spelling only; TypeSpec construction
;;; and grammar dispatch remain in model.ss.

(import :gerbil/gambit)

(export function-keyword-marker?
        function-keyword-name
        list-type-shorthand-sexpr?
        normalize-type-name
        strip-trailing-colon
        type-sexpr-first-operand
        type-sexpr-second-operand
        type-sexpr-third-operand)

;; : (-> TypeDatum Boolean )
(def (list-type-shorthand-sexpr? sexpr)
  (and (list? sexpr)
       (= (length sexpr) 1)
       (pair? (car sexpr))))

;;; Operand access boundary:
;;; - Parser helpers describe grammar slots instead of cdr depth.
;;; - Missing operands conservatively become unknown unless a caller supplies
;;;   another default.
;; : (-> TypeDatum Default TypeDatum )
(def (type-sexpr-first-operand sexpr . maybe-default)
  (match (cdr sexpr)
    ([value . _] value)
    (else (type-sexpr-operand-default maybe-default))))

;; : (-> TypeDatum Default TypeDatum )
(def (type-sexpr-second-operand sexpr . maybe-default)
  (match (cdr sexpr)
    ([_ value . _] value)
    (else (type-sexpr-operand-default maybe-default))))

;; : (-> TypeDatum Default TypeDatum )
(def (type-sexpr-third-operand sexpr . maybe-default)
  (match (cdr sexpr)
    ([_ _ value . _] value)
    (else (type-sexpr-operand-default maybe-default))))

;; : (-> (List Default) TypeDatum )
(def (type-sexpr-operand-default maybe-default)
  (if (pair? maybe-default) (car maybe-default) 'unknown))

;; : (-> TypeName TypeName )
(def (normalize-type-name name)
  (cond
   ((keyword? name) (keyword->string name))
   ((symbol? name) (symbol->string name))
   ((string? name) name)
   (else "unknown")))

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
