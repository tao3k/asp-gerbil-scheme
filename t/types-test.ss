;;; -*- Gerbil -*-
;;; Fast smoke for TypeSpec model APIs.

(import :std/test
        :asp-gerbil-scheme/src/types/model)

(export types-test)

;; : TestSuite
(def types-test
  (test-suite "gerbil scheme harness types smoke"
    (test-case "type model constructors expose representative facts"
      (let* ((number-type (make-type-base "Number"))
             (list-type (make-type-list number-type))
             (record-type
              (make-type-record
               (list (cons "value" number-type))
               ["value"])))
        (check (type->string list-type) => "(list Number)")
        (check (type-kind list-type) => 'list)
        (check (type->string record-type)
               => "(record ((value Number)) (value))")))))
