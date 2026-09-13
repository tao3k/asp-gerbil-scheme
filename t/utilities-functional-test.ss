;;; -*- Gerbil -*-
;;; Functional utility tests for fold and list helpers.

(import :std/test
        :asp-gerbil-scheme/src/utilities/functional)

(export utilities-functional-test)

(def utilities-functional-test
  (test-suite "gerbil scheme functional utilities"
    (test-case "fold-state keeps accumulator order explicit"
      (check (fold-state (lambda (state value)
                           (+ state value))
                         0
                         '(1 2 3))
             => 6)
      (check (fold-state (lambda (state value)
                           (cons value state))
                         []
                         '(a b c))
             => '(c b a)))
    (test-case "drop-right-while trims only suffix values"
      (check (drop-right-while zero? '(1 0 2 0 0)) => '(1 0 2))
      (let (empty-string? (lambda (value)
                            (string=? value "")))
        (check (drop-right-while empty-string? '("a" "" "")) => '("a"))
        (check (drop-right-while empty-string? '("" "")) => [])))
    (test-case "repeat-char-string builds stable fixed-width strings"
      (check (repeat-char-string #\space 3) => "   ")
      (check (repeat-char-string #\. 0) => "")
      (check (repeat-char-string #\. -2) => ""))
    (test-case "flat-map preserves order while flattening"
      (check (flat-map (lambda (value) (list value value)) '(a b))
             => '(a a b b))
      (check (flat-map (lambda (value) []) '(a b)) => []))
    (test-case "list-intersects? returns boolean membership evidence"
      (check (list-contains? '(a b) 'b) => #t)
      (check (list-contains? '(a b) 'c) => #f)
      (check (list-intersects? '(a b) '(c b)) => #t)
      (check (list-intersects? '(a b) '(c d)) => #f))
    (test-case "non-empty-string? filters string evidence"
      (check (non-empty-string? "owner") => #t)
      (check (non-empty-string? "") => #f)
      (check (non-empty-string? 'owner) => #f))
    (test-case "string-join-with keeps render joins local"
      (check (string-join-with '("a" "b" "c") ",") => "a,b,c")
      (check (string-join-with [] ",") => ""))))
