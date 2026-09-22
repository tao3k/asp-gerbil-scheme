;;; -*- Gerbil -*-
;;; Expected: use Gambit numeric lanes when the domain is fixed.
(package: scenario/gambit-fixnum-flonum-arithmetic-boundary/expected)
(import :gerbil/runtime/gambit)
(export sum-samples)

;; sum-samples
;;   : (-> (List Flonum) Pair)
;;   | type Pair = (Pair Integer Flonum)
;;   | warning fx/fl primitive calls stay inside the numeric hot loop
;;   | doc m%
;;       `sum-samples samples` returns the sample count and flonum total while
;;       keeping fixnum and flonum arithmetic visible to the optimizer.
;;
;;       # Examples
;;
;;       ```scheme
;;       (sum-samples '(1.0 2.0))
;;       ;; => (2 . 3.0)
;;       ```
;;     %
(def (sum-samples samples)
  (let loop ((rest samples)
             (count 0)
             (total 0.0))
    (if (null? rest)
      (cons count total)
      (loop (cdr rest)
            (fx+ count 1)
            (fl+ total (car rest))))))
