;;; -*- Gerbil -*-
(import :std/test)

(export delta-test)

(def delta-test
  (test-suite "upstream delta"
    (test-case "ordinary native suite"
      (check (reverse '(a b c)) => '(c b a)))))
