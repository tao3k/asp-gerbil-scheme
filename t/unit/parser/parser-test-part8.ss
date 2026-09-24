;;; -*- Gerbil -*-
;;; Gerbil scheme harness parser part 8.

(import :std/test
        (only-in :std/test/base test-result-ok? test-suite!)
        "./parser-test-part8-source-contracts"
        "./parser-test-part8-comment-quality"
        "./parser-test-part8-quality-scaffolds"
        "./parser-test-part8-package-typed-contracts")
(export parser-test-part-8)

;; TestSuite
(def parser-test-part-8
  (test-suite "gerbil scheme harness parser part 8"
    (test-case "parser-test-part-8-source-contracts"
      (check (test-result-ok? (test-suite! parser-test-part-8-source-contracts)) => #t))
    (test-case "parser-test-part-8-comment-quality"
      (check (test-result-ok? (test-suite! parser-test-part-8-comment-quality)) => #t))
    (test-case "parser-test-part-8-quality-scaffolds"
      (check (test-result-ok? (test-suite! parser-test-part-8-quality-scaffolds)) => #t))
    (test-case "parser-test-part-8-package-typed-contracts"
      (check (test-result-ok? (test-suite! parser-test-part-8-package-typed-contracts)) => #t))))
