;;; -*- Gerbil -*-
;;; Expected: use a u8vector when the payload is bytes.
(package: scenario/gambit-specialized-vector-storage/expected)
(import :gerbil/runtime/gambit)
(export copy-bytes)

(def (copy-bytes bytes)
  (let* ((len (length bytes))
         (out (make-u8vector len 0)))
    (let loop ((i 0)
               (rest bytes))
      (if (null? rest)
        out
        (begin
          (u8vector-set! out i (car rest))
          (loop (fx+ i 1) (cdr rest)))))))
