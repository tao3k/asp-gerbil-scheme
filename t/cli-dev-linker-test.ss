;;; -*- Gerbil -*-
;;; CLI development linker integration contracts.

(import :gerbil/gambit
        :std/test
        (only-in :std/srfi/13 string-contains)
        (only-in :asp-gerbil-scheme/src/testing/execution-profile
                 declare-gxtest-serial)
        (only-in :asp-gerbil-scheme/src/cli-dev-linker dev-linker-run))
(export cli-dev-linker-test)

(declare-gxtest-serial shared-cli-runtime)

;; : TestSuite
(def cli-dev-linker-test
  (test-suite "gerbil scheme harness CLI dev linker"
    (test-case "dev binary routes structural selectors through parser query"
      (let (status #f)
        (let (output
              (with-output-to-string
                (lambda ()
                  (set! status
                    (dev-linker-run
                     ["query"
                      "--selector"
                      "gerbil-scheme://src/parser/selectors.ss#item/function/selector-from"
                      "--workspace"
                      "."
                      "--code"])))))
          (check status => 0)
          (check (and (string-contains
                       output
                       "(def (selector-from")
                      #t)
                 => #t))))))
