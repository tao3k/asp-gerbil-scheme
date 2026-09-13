;;; -*- Gerbil -*-
;;; Gerbil scheme harness parser part 8.

(import :std/test
        :unit/parser/parser-test-part8-source-contracts
        :unit/parser/parser-test-part8-comment-quality
        :unit/parser/parser-test-part8-quality-scaffolds
        :unit/parser/parser-test-part8-package-typed-contracts)
(export parser-test-part-8)

;; TestSuite
(def parser-test-part-8
  (test-suite "gerbil scheme harness parser part 8"
    (test-case "parser-test-part-8-source-contracts"
      (check (run-test-suite! parser-test-part-8-source-contracts) => #t))
    (test-case "parser-test-part-8-comment-quality"
      (check (run-test-suite! parser-test-part-8-comment-quality) => #t))
    (test-case "parser-test-part-8-quality-scaffolds"
      (check (run-test-suite! parser-test-part-8-quality-scaffolds) => #t))
    (test-case "parser-test-part-8-package-typed-contracts"
      (check (run-test-suite! parser-test-part-8-package-typed-contracts) => #t))))
