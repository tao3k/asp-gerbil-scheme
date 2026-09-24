;;; -*- Gerbil -*-
;;; V19 list-order regression at the ASP support boundary.

(import :std/test
        (only-in :asp-gerbil-scheme/src/support/list append-map unique))

(export support-list-test)

(def support-list-test
  (test-suite "ordered list support"
    (test-case "append-map preserves item and input order"
      (check (append-map (lambda (value) (list value (* value 10)))
                         '(1 2 3))
             => '(1 10 2 20 3 30))
      (check (append-map (lambda (value)
                           (if (even? value) '() (list value)))
                         '(1 2 3 4 5))
             => '(1 3 5))
      (check (append-map list '()) => '()))
    (test-case "unique preserves first occurrence"
      (check (unique '(a b a c b)) => '(a b c)))))
