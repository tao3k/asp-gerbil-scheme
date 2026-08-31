;;; -*- Gerbil -*-
;;; Parser reader fact tests for formatter-facing R7RS source boundaries.

(import :std/test
        :asp-gerbil-scheme/src/parser/facade)

(export parser-reader-test)

(def parser-reader-test
  (test-suite "gerbil scheme parser reader facts"
    (test-case "reader tracks R7RS literal and block comment boundaries"
      (let* ((state (parser-reader-initial-state))
             (string-open (parser-reader-scan-line-state "\"open" state))
             (string-closed (parser-reader-scan-line-state "close\"" string-open))
             (block-open (parser-reader-scan-line-state "#| block" state))
             (block-closed (parser-reader-scan-line-state "comment |#" block-open)))
        (check (parser-reader-literal-line? string-open) => #t)
        (check (parser-reader-literal-line? string-closed) => #f)
        (check (parser-reader-literal-line? block-open) => #t)
        (check (parser-reader-literal-line? block-closed) => #f)))
    (test-case "reader exposes indentation facts for formatter style"
      (let (scan (parser-reader-scan-line/indent
                  "(let ((x 1))"
                  (parser-reader-initial-state)))
        (check (cadr scan) => 1)
        (check (parser-reader-leading-close-count "  )))") => 3)
        (check (parser-reader-leading-whitespace-count "\t  value") => 3)
        (check (parser-reader-whitespace? #\space) => #t)))))
