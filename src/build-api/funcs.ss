;;; -*- Gerbil -*-
;;; Small graph combinators shared by native BuildSpec projections.

(import :gerbil/gambit
        (only-in :std/srfi/1 append-map))

(export ordered-unique
        memoized-transitive-closure)

;; : (forall (a) (-> (List a) (List a)))
(def (ordered-unique values)
  (let (seen (make-hash-table))
    (filter-map
     (lambda (value)
       (and (not (hash-get seen value))
            (begin
              (hash-put! seen value #t)
              value)))
     values)))

;; Build the transitive closure function for a directed graph.  The active set
;; cuts import cycles; memoization makes projection linear in vertices + edges.
;; : (forall (a) (-> (-> a (List a)) (-> a (List a))))
(def (memoized-transitive-closure successors)
  (let (memo (make-hash-table))
    (def (visit node active)
      (cond
       ((hash-get memo node))
       ((hash-get active node) [])
       (else
        (let (next-active (hash-copy active))
          (hash-put! next-active node #t)
          (let (result
                (ordered-unique
                 (append-map
                  (lambda (successor)
                    (cons successor (visit successor next-active)))
                  (successors node))))
            (hash-put! memo node result)
            result)))))
    (lambda (node)
      (visit node (make-hash-table)))))
