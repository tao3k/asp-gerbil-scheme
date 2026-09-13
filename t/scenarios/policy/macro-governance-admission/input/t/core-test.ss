;;; -*- Gerbil -*-
(import :std/test ../src/core)

(def core-test
  (test-suite "macro governance"
    (test-case "define value"
      (check (define-value answer 42) => 42))))
