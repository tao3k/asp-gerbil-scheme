;;; -*- Gerbil -*-
;;; Expected: keep primitive calls lexical and direct so inline rules can see them.
(package: scenario/gerbil-inline-rule-call-shape/expected)
(import :gerbil/runtime/gambit)
(export count-small small?)

;; small?
;;   : (-> Fixnum Fixnum Boolean)
;;   | doc m%
;;       `small? value limit` is the direct lexical predicate used by the hot
;;       loop so Gerbil inline-rule visibility is preserved.
;;
;;       # Examples
;;
;;       ```scheme
;;       (small? 1 2)
;;       ;; => #t
;;       ```
;;     %
(def (small? value limit)
  (fx< value limit))

;; count-small
;;   : (-> (List Fixnum) Fixnum Fixnum)
;;   | warning helper calls stay lexical; no dynamic apply is allowed here
;;   | doc m%
;;       `count-small values limit` counts values below limit while keeping the
;;       predicate and bump operation as optimizer-visible direct calls.
;;
;;       # Examples
;;
;;       ```scheme
;;       (count-small '(1 4 2) 3)
;;       ;; => 2
;;       ```
;;     %
(def (count-small values limit)
  (let loop ((rest values)
             (count 0))
    (if (null? rest)
      count
      (let (next-count
            (if (small? (car rest) limit)
              (fx+ count 1)
              count))
        (loop (cdr rest) next-count)))))
