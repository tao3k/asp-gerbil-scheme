;;; -*- Gerbil -*-
(export total)

(def (total xs)
  (let loop ((rest xs) (acc 0))
    (if (null? rest)
      acc
      (loop (cdr rest) (+ acc (car rest))))))
