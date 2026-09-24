;;; -*- Gerbil -*-
(package: sample/reports)

(import :std/string/misc)

(export render-lines)

(def (render-lines lines)
  (let loop ((remaining lines) (fragments '()))
    (if (null? remaining)
      (string-append (string-join (reverse fragments) "\n") "\n")
      (loop (cdr remaining)
            (cons (car remaining) fragments)))))
