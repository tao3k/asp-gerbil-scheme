;;; -*- Gerbil -*-
;;; Boundary:
;;; - Syntax owners keep phase/context state scoped to the transformer.
;;; - Runtime behavior stays outside the syntax reconstruction path.
(package: sample/macros)

;; order-expansion-context
;;   : (-> Integer SourceLocation OrderExpansionContext)
;;   | doc m%
;;       `order-expansion-context` records scoped macro expansion state.
;;     %
(defstruct order-expansion-context (phase source)
  final: #t transparent: #t)

;; current-order-expansion-context
;;   : Parameter
;;   | doc m%
;;       `current-order-expansion-context` scopes macro state during expansion.
;;     %
(def current-order-expansion-context
  (make-parameter #f))

;;; Boundary:
;;; - with-order-field validates syntax shape before expansion.
;;; - Source-aware failures stay on the original syntax object.
;; with-order-field
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       `with-order-field` expands a checked order binding form with scoped
;;       expansion context.
;;
;;       # Examples
;;
;;       ```scheme
;;       (with-order-field order body)
;;       ;; => expanded-syntax
;;       ```
;;     %
(defsyntax (with-order-field stx)
  (def (emit ctx order body)
    (parameterize ((current-order-expansion-context ctx))
      (with-syntax ((current #'order))
        #'(let ((current-order current)) body))))
  (syntax-case stx ()
    ((_ order body)
     (emit (make-order-expansion-context 0 (stx-source stx))
           #'order
           #'body))
    (_
     (raise-syntax-error
      #f
      "Bad syntax; expected (with-order-field order body)"
      stx))))
