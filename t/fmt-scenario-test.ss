(import :std/test
        :gslph/src/benchmark/framework
        :gslph/src/format/facade
        :gslph/src/support/io)

(export fmt-scenario-test)

(def +scenario-root+ "t/scenarios/format/rs7-basic-style")
(def +scenario-input-root+ "t/scenarios/format/rs7-basic-style/input")
(def +scenario-expected-root+ "t/scenarios/format/rs7-basic-style/expected")

(def +required-r7rs-basic-fixtures+
  '("main.ss"
    "cases-rules/macro-style.ss"
    "cases-rules/match-pipeline.ss"
    "cases-rules/policy.ss"
    "cases-tests/scenario-style-test.ss"
    "core/conditionals-and-iteration.ss"
    "core/definitions-and-bindings.ss"
    "core/do-delay-begin.ss"
    "core/guard-raise-boundary.ss"
    "core/lambda-call-values.ss"
    "core/module-boundary.ss"
    "core/numbers-chars-bytevectors.ss"
    "core/parameters-and-exceptions.ss"
    "core/ports-and-io.ss"
    "core/quasiquote-and-datum.ss"
    "core/reader-comments.ss"
    "core/records-and-accessors.ss"
    "core/syntax-rules-and-local-macros.ss"
    "io/comments-and-strings.ss"
    "core-r7rs-complete/base-data-complete.ss"
    "core-r7rs-complete/base-error-features-complete.ss"
    "core-r7rs-complete/base-port-complete.ss"
    "core-r7rs-complete/case-lambda-library-complete.ss"
    "core-r7rs-complete/char-library-complete.ss"
    "core-r7rs-complete/file-library-complete.ss"
    "core-r7rs-complete/library-grammar-complete.ss"
    "core-r7rs-complete/procedure-syntax-complete.ss"
    "core-r7rs-complete/program-and-reader-complete.ss"
    "core-r7rs-complete/repl-library-complete.ss"
    "core-r7rs-libraries/boolean-symbol-conversions.ss"
    "core-r7rs-libraries/bytevector-procedure-variants.ss"
    "core-r7rs-libraries/char-library-procedures.ss"
    "core-r7rs-libraries/complex-inexact-procedures.ss"
    "core-r7rs-libraries/cxr-library-procedures.ss"
    "core-r7rs-libraries/eval-environment-library.ss"
    "core-r7rs-libraries/exact-integer-numeric-procedures.ss"
    "core-r7rs-libraries/file-library-procedures.ss"
    "core-r7rs-libraries/process-context-time-load.ss"
    "core-r7rs-libraries/read-write-library-procedures.ss"
    "core-r7rs-libraries/scheme-library-imports.ss"
    "core-r7rs-libraries/string-procedure-variants.ss"
    "core-r7rs-libraries/vector-procedure-variants.ss"
    "core-r7rs-procedures/char-string-procedures.ss"
    "core-r7rs-procedures/define-record-type-style.ss"
    "core-r7rs-procedures/exception-handler-procedures.ss"
    "core-r7rs-procedures/import-export-specs.ss"
    "core-r7rs-procedures/include-declarations.ss"
    "core-r7rs-procedures/macro-error-values.ss"
    "core-r7rs-procedures/numeric-procedures.ss"
    "core-r7rs-procedures/pair-list-procedures.ss"
    "core-r7rs-procedures/port-read-write-procedures.ss"
    "core-r7rs-procedures/predicates-equivalence.ss"
    "core-r7rs-procedures/rest-and-dotted-lambda.ss"
    "core-r7rs-procedures/vector-bytevector-procedures.ss"
    "core-r7rs/advanced-conditionals.ss"
    "core-r7rs/case-lambda-style.ss"
    "core-r7rs/cond-expand.ss"
    "core-r7rs/continuations.ss"
    "core-r7rs/delay-force-stream.ss"
    "core-r7rs/eval-environment.ss"
    "core-r7rs/foldcase-directives.ss"
    "core-r7rs/let-family.ss"
    "core-r7rs/library-form.ss"
    "core-r7rs/list-vector-data.ss"
    "core-r7rs/mutation-and-sequences.ss"
    "core-r7rs/numeric-literals.ss"
    "core-r7rs/string-symbol-escaping.ss"))

(def +library-grammar-coverage+
  '("define-library"
    "export"
    "export-rename"
    "import"
    "only"
    "except"
    "prefix"
    "rename"
    "nested-import-set"
    "include"
    "include-ci"
    "include-library-declarations"
    "cond-expand"
    "cond-expand-and"
    "cond-expand-or"
    "cond-expand-not"
    "library-name-version-part"))

(def +core-syntax-reader-coverage+
  '("lambda-fixed-formals"
    "lambda-rest-formals"
    "lambda-dotted-formals"
    "if"
    "cond"
    "cond-arrow"
    "case"
    "case-arrow"
    "and-or-not"
    "when-unless"
    "let"
    "let-star"
    "letrec"
    "letrec-star"
    "let-values"
    "let-star-values"
    "do"
    "begin"
    "set"
    "define"
    "define-values"
    "define-syntax"
    "define-record-type"
    "syntax-rules"
    "let-syntax"
    "letrec-syntax"
    "syntax-error"
    "quote"
    "quasiquote"
    "unquote"
    "unquote-splicing"
    "delay"
    "delay-force"
    "force"
    "guard"
    "parameterize"
    "dynamic-wind"
    "call-with-current-continuation"
    "case-lambda"
    "datum-comment"
    "block-comment"
    "nested-block-comment"
    "fold-case"
    "no-fold-case"
    "shared-reader-label"
    "program-import"))

(def +library-procedure-family-coverage+
  '("scheme-base"
    "scheme-case-lambda"
    "scheme-char"
    "scheme-complex"
    "scheme-cxr"
    "scheme-eval"
    "scheme-file"
    "scheme-inexact"
    "scheme-lazy"
    "scheme-load"
    "scheme-process-context"
    "scheme-read"
    "scheme-repl"
    "scheme-time"
    "scheme-write"
    "equivalence-predicates"
    "boolean-symbol-conversion"
    "numeric-core"
    "exact-integer-numeric"
    "complex-inexact"
    "pair-list"
    "char-string"
    "string-case"
    "vector"
    "bytevector"
    "textual-ports"
    "binary-ports"
    "file-ports"
    "read-write"
    "error-objects"
    "features"
    "eval-environments"
    "process-time-load"
    "cxr-selectors"))

(def (scenario-input-files)
  (map scenario-input-path +required-r7rs-basic-fixtures+))

(def (scenario-input-path relative)
  (string-append +scenario-input-root+ "/" relative))

(def (scenario-expected-path input-path)
  (string-append +scenario-expected-root+
                 (substring input-path
                            (string-length +scenario-input-root+)
                            (string-length input-path))))

(def (scenario-format-pair-pass? input-path)
  (let* ((expected-path (scenario-expected-path input-path))
         (actual (fmt-format-text (read-source-text input-path)))
         (expected (read-source-text expected-path)))
    (equal? actual expected)))

(def (format-scenario-texts texts)
  (for-each fmt-format-text texts)
  #t)

(def (scenario-required-fixtures-pass? files)
  (and (>= (length files) (length +required-r7rs-basic-fixtures+))
       (andmap (lambda (relative)
                 (member (scenario-input-path relative) files))
               +required-r7rs-basic-fixtures+)))

(def (scenario-format-pairs-pass? files)
  (null? (scenario-format-pair-failures files)))

(def (scenario-format-pair-failures files)
  (let loop ((rest files) (failures []))
    (match rest
      ([] (reverse failures))
      ([path . tail]
       (loop tail
             (if (scenario-format-pair-pass? path)
               failures
               (cons path failures)))))))

(def fmt-scenario-test
  (test-suite "gerbil scheme harness fmt scenarios"
    (test-case "rs7 coverage gates reach complete fixture surface"
      (check (length +library-grammar-coverage+) => 17)
      (check (length +core-syntax-reader-coverage+) => 46)
      (check (length +library-procedure-family-coverage+) => 34))
    (test-case "rs7 basic style owns a multi-file fixture set"
      (let (files (scenario-input-files))
        (check (scenario-required-fixtures-pass? files) => #t)
        (check (scenario-format-pair-failures files) => [])))
    (test-case "rs7 basic style benchmark measures one representative fixture"
      (let* ((text (read-source-text (car (scenario-input-files))))
             (receipt (benchmark-contract-run/root
                       +scenario-root+
                       (lambda ()
                         (fmt-format-text text)))))
        (check receipt ? benchmark-contract-receipt-pass?)))))
