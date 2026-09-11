;;; -*- Gerbil -*-
;;; Narrow runtime-memory observations for benchmark receipts.
;;; Boundary: this owner reads Gambit process statistics without loading the
;;; unrelated heap-walker foreign macros from :std/debug/heap.

(import :gerbil/gambit)

(export benchmark-memory-source
        benchmark-memory-usage)

;; : String
(def benchmark-memory-source ":gerbil/gambit###process-statistics")

;; benchmark-memory-usage
;;   : (-> Alist)
;;   | doc m%
;;       Project the five heap counters exposed by Gambit process statistics.
;;       The shape intentionally matches the upstream memory-usage observation
;;       previously used by benchmark receipts.
;;     %
(def (benchmark-memory-usage)
  (let (stats (##process-statistics))
    `((gc-heap-size
       . ,(inexact->exact (f64vector-ref stats 15)))
      (gc-alloc
       . ,(inexact->exact (f64vector-ref stats 16)))
      (gc-live
       . ,(inexact->exact (f64vector-ref stats 17)))
      (gc-movable
       . ,(inexact->exact (f64vector-ref stats 18)))
      (gc-still
       . ,(inexact->exact (f64vector-ref stats 19))))))
