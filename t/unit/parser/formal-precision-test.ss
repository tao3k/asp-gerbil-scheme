;;; -*- Gerbil -*-
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import :std/test :gerbil/expander
 (only-in :asp-gerbil-scheme/src/parser/formals definition-name-datums definition-formal-names definition-formal-arity)
 (only-in :asp-gerbil-scheme/src/parser/typed-contract-diagnostics typed-contract-arity-alignment)
 (only-in :asp-gerbil-scheme/src/parser/syntax-calls calls-from-form)
 (only-in :asp-gerbil-scheme/src/parser/model make-definition)
 (only-in :asp-gerbil-scheme/src/parser/syntax-support macro-quality-facets))
(export formal-precision-test)
(def formal-precision-test
  (test-suite "Optional callable names and inherited record declarations"
  (test-case "full names retain defaults while legacy arity remains compatible"
   (let ((optional '(def (f x (y 1)) (+ x y)))
         (keyword '(def (f x y: (y 1)) (+ x y))))
    (for-each (lambda (form)
     (check-equal? (definition-formal-names form 'f) '("x" "y"))
     (check-equal? (definition-formal-arity form 'f) (if (equal? form optional) 1 2)))
     (list optional keyword))))
  (test-case "contracts outside the declared range still reject"
   (let (d (make-definition "f" "def" "fixture.ss" 1 2 '("x" "y") 1))
    (check-equal? (typed-contract-arity-alignment d 1 1) "aligned")
    (check-equal? (typed-contract-arity-alignment d 1 2) "aligned")
    (check-equal? (typed-contract-arity-alignment d 1 0) "input-count-mismatch")
    (check-equal? (typed-contract-arity-alignment d 1 3) "input-count-mismatch")))
  (test-case "declarative assignments are templates, procedural mutations remain visible"
   (for-each
    (lambda (head)
     (check-equal?
      (member "global-macro-state-mutation"
              (macro-quality-facets head
               (list head '(bump value) '(let ((counter value)) (set! counter (+ counter 1))))))
      #f))
    '(defrule defrules))
   (check (member "global-macro-state-mutation"
                  (macro-quality-facets 'defsyntax
                   '(defsyntax (bump stx) (set! global-counter (+ global-counter 1)) stx)))
          ? pair?))
  (test-case "record fields are declarations while real calls remain observable"
   (for-each (lambda (form)
    (check-equal? (definition-name-datums form) '(child))
    (let (syntax (call-with-input-string (object->string form) read-syntax))
     (check-equal? (calls-from-form "fixture.ss" syntax form) '())))
    '((defstruct (child parent) (field) final: #t) (defstruct child (field) final: #t)))
   (let* ((form '(effect 1)) (syntax (call-with-input-string (object->string form) read-syntax)))
    (check-equal? (length (calls-from-form "fixture.ss" syntax form)) 1)))))
