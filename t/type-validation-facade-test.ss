;;; -*- Gerbil -*-
;;; Tests for downstream-facing TypeSpec validation exports.

(import :std/test
        (only-in :asp-gerbil-scheme/src/types/model
                 make-type-unknown
                 make-type-any
                 make-type-base
                 make-type-variable
                 make-type-pair
                 make-type-list
                 make-type-vector
                 make-type-maybe
                 make-type-hash
                 make-type-values
                 make-type-refine
                 make-type-application
                 make-type-literal-symbol
                 make-type-function
                 make-type-keyword-parameter
                 make-type-function-variadic
                 make-type-union
                 make-type-record
                 type-kind
                 parse-type-contract)
        (only-in :asp-gerbil-scheme/src/types/validation
                 type-validation-diagnostic-code
                 type-validation-diagnostic-path
                 type-validation-diagnostic-category
                 type-validation-diagnostic-message
                 type-validation-diagnostic-facts
                 type-validation-diagnostics
                 type-spec-valid?))

(export type-validation-facade-test)

(def type-validation-facade-test
  (test-suite "type validation facade"
    (test-case "exports all TypeSpec shapes downstream"
      (let* ((number-type (make-type-base "Number"))
             (string-type (make-type-base "String"))
             (type-shapes
              [(make-type-any)
               number-type
               (make-type-variable "a")
               (make-type-pair string-type number-type)
               (make-type-list number-type)
               (make-type-vector string-type)
               (make-type-maybe number-type)
               (make-type-hash string-type number-type)
               (make-type-values [string-type number-type])
               (make-type-refine number-type "natural?")
               (make-type-application "NonEmptyList" [number-type])
               (make-type-literal-symbol 'ready)
               (make-type-function [number-type] string-type)
               (make-type-keyword-parameter "timeout" number-type)
               (make-type-function-variadic number-type string-type 1)
               (make-type-union [string-type number-type])
               (make-type-record (list (cons "value" number-type))
                                 ["value"])]))
        (check (map type-kind type-shapes)
               => (list 'any 'base 'variable 'pair 'list 'vector 'maybe 'hash
                        'values 'refine 'application 'literal-symbol 'function
                        'keyword-parameter 'function-variadic 'union 'record))
        (check (map type-spec-valid? type-shapes)
               => [#t #t #t #t #t #t #t #t #t #t #t #t #t #t #t #t #t])
        (check (type-validation-diagnostics (make-type-unknown))
               => ["unknown-type"])))

    (test-case "exports existing structured diagnostic APIs downstream"
      (let* ((bad-hash (parse-type-contract "(Hash String)"))
             (diagnostics (type-validation-diagnostics bad-hash))
             (facts (type-validation-diagnostic-facts bad-hash))
             (diagnostic (car facts)))
        (check (type-spec-valid? bad-hash) => #f)
        (check diagnostics => ["hash-value:unknown-type"])
        (check (type-validation-diagnostic-code diagnostic)
               => "unknown-type")
        (check (type-validation-diagnostic-path diagnostic)
               => ["hash-value"])
        (check (type-validation-diagnostic-category diagnostic)
               => "shape")
        (check (type-validation-diagnostic-message diagnostic)
               => "hash-value:unknown-type")))))
