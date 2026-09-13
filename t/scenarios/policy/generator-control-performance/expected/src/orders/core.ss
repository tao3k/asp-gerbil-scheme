;;; -*- Gerbil -*-
;;; Boundary:
;;; - Generator sources stay inside a named reducer boundary instead of
;;;   hand-written pull loops at each call site.
(package: sample/orders)
(export sum-generated)

;; fold-generated
;;   : (-> (-> Number Number Number) Number (Generating Number) Number)
;;   | doc m%
;;       `fold-generated` consumes a pull generator through one local reducer
;;       protocol.
;;
;;       # Examples
;;
;;       ```scheme
;;       (fold-generated + 0 next-number)
;;       ;; => total
;;       ```
;;     %
(def (fold-generated combine seed source)
  (foldl combine seed (list<-generating source)))

;; sum-generated
;;   : (-> (Generating Number) Number)
;;   | doc m%
;;       `sum-generated` consumes a pull generator through the local reducer
;;       boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (sum-generated next-number)
;;       ;; => total
;;       ```
;;     %
(def (sum-generated source)
  (fold-generated + 0 source))
