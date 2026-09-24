;;; -*- Gerbil -*-
;;; Gerbil scheme harness parser part 8 package typed contracts.

(import :std/test
        (only-in :std/test/base test-result-ok? test-suite!)
        "./parser-test-part8-package-scope"
        "./parser-test-part8-typed-comment-blocks")
(export parser-test-part-8-package-typed-contracts)

;; TestSuite
(def parser-test-part-8-package-typed-contracts
  (test-suite "gerbil scheme harness parser part 8 package typed contracts"
    (test-case "parser-test-part-8-package-scope"
      (check (test-result-ok? (test-suite! parser-test-part-8-package-scope)) => #t))
    (test-case "parser-test-part-8-typed-comment-blocks"
      (check (test-result-ok? (test-suite! parser-test-part-8-typed-comment-blocks)) => #t))))
