;;; -*- Gerbil -*-
;;; CLI development linker integration contracts.

(import :gerbil/gambit
        :std/test
        (only-in :asp-gerbil-scheme/src/testing/execution-profile
                 declare-gxtest-serial)
        (only-in :asp-gerbil-scheme/src/cli-dev-linker dev-linker-run))
(export cli-dev-linker-test)

(declare-gxtest-serial shared-cli-runtime)

;; : TestSuite
(def cli-dev-linker-test
  (test-suite "gerbil scheme harness CLI dev linker"
    (test-case "dev binary rejects ASP-owned exact source projection"
      (let (rejected?
            (with-catch
             (lambda (_error) #t)
             (lambda ()
               (dev-linker-run
                ["query"
                 "--selector"
                 "gerbil-scheme://src/parser/selectors.ss#item/function/selector-from"
                 "--workspace"
                 "."
                 "--code"])
               #f)))
        (check rejected? => #t)))))
