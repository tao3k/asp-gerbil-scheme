;;; -*- Gerbil -*-
;;; Boundary:
;;; - Top-level parser-test only composes smaller test owners.
;;; - Keep parser-visible test complexity below modularity thresholds.

(import :std/test
        :unit/parser/parser-test-part1
        :unit/parser/parser-test-part2
        :unit/parser/parser-test-part3
        :unit/parser/parser-test-part4
        :unit/parser/parser-test-part5
        :unit/parser/parser-test-part6
        :unit/parser/parser-test-part7
        :unit/parser/parser-test-part8)
(export parser-test)
;; TestSuite
(def parser-test
  (test-suite "gerbil scheme harness parser"
    (test-case "parser-test-part-1"
      (check (run-test-suite! parser-test-part-1) => #t))
    (test-case "parser-test-part-2"
      (check (run-test-suite! parser-test-part-2) => #t))
    (test-case "parser-test-part-3"
      (check (run-test-suite! parser-test-part-3) => #t))
    (test-case "parser-test-part-4"
      (check (run-test-suite! parser-test-part-4) => #t))
    (test-case "parser-test-part-5"
      (check (run-test-suite! parser-test-part-5) => #t))
    (test-case "parser-test-part-6"
      (check (run-test-suite! parser-test-part-6) => #t))
    (test-case "parser-test-part-7"
      (check (run-test-suite! parser-test-part-7) => #t))
    (test-case "parser-test-part-8"
      (check (run-test-suite! parser-test-part-8) => #t))))
