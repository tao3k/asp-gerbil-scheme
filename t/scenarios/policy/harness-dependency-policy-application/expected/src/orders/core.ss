;;; -*- Gerbil -*-
;;; Boundary:
;;; - Orders core owns pure order transformation helpers.
(package: sample/orders)
(export order-total order-totals)

;; order-total
;;   : (-> Order Money)
;;   | type Money = Number
;;   | doc m%
;;       `order-total order` returns the numeric total stored in `order`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (order-total (hash (total 12)))
;;       ;; => 12
;;       ```
;;     %
(def (order-total order)
  (hash-get order 'total 0))

;; order-totals
;;   : (-> (List Order) (List Money))
;;   | type Money = Number
;;   | doc m%
;;       `order-totals orders` maps each order to its numeric total.
;;
;;       # Examples
;;
;;       ```scheme
;;       (order-totals (list (hash (total 12)) (hash (total 4))))
;;       ;; => (12 4)
;;       ```
;;     %
(def (order-totals orders)
  (map order-total orders))
