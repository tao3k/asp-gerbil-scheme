;;; -*- Gerbil -*-
;;; Boundary:
;;; - Match syntax owns pattern parsing and syntax errors.
;;; - Runtime predicates stay ordinary helpers.
(package: sample/match)
(export shape? shape-match)

;; shape?
;;   : (-> Datum Boolean)
;;   | doc m%
;;       `shape? value` is the runtime predicate used by the match extension.
;;     %
(def (shape? value)
  (and (pair? value) (eq? (car value) 'shape)))

;; shape-match
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       `shape-match` is a match extension surface around the runtime
;;       predicate.
;;
;;       # Examples
;;
;;       ```scheme
;;       (shape-match value)
;;       ;; => match-pattern-syntax
;;       ```
;;     %
(defsyntax-for-match shape-match
  (syntax-rules ()
    ((_ value)
     (? shape? value))))
