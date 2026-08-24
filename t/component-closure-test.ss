;;; Intent:
;;; - Component receipts prove the checked POO subset is deterministic and complete.
;;; - Tests compare generated evidence to the versioned manifest, not incidental filesystem order.
(import (only-in :std/test test-suite test-case check)
        (only-in :std/srfi/1 list-index)
        (only-in :std/sugar hash-get with-catch)
        (only-in :std/text/json read-json)
        :gslph/src/build-api/component-closure)

(export component-closure-test)

(def component-closure-test
  (test-suite
   "GSLPH component source closure"

   (test-case "poo-flow closure is deterministic and strict"
     (let* ((entries (gslph-component-entry-files 'poo-flow))
            (sources (gslph-component-source-files 'poo-flow))
            (receipt (gslph-component-receipt 'poo-flow)))
    (check (gslph-component-source-files "poo-flow") => sources)
    (check (andmap (lambda (entry) (member entry sources)) entries) => #t)
    (check (andmap (lambda (required) (member required entries))
                   '("src/extensions/poo-object-validation.ss"
                     "src/testing/build.ss"))
           => #t)
    (check (hash-get receipt 'schema)
              => "gslph.component-source-closure.v1")
       (check (hash-get receipt 'outcome) => "valid")
       (check (hash-get receipt 'strictSubset) => #t)
       (check (hash-get receipt 'sourceCount) => (length sources))
       (check (< (hash-get receipt 'sourceCount)
                 (hash-get receipt 'fullSourceCount))
              => #t)))

   (test-case "unknown components are rejected"
     (check (with-catch
             (lambda (_) #t)
             (lambda ()
               (gslph-component-entry-files 'missing-component)
               #f))
            => #t))

   (test-case "workspace source order emits dependencies before importers"
     (let* ((observability "src/building/observability.ss")
            (facade "src/building/facade.ss")
            (ordered (gslph-source-dependency-order
                      (current-directory)
                      (list facade))))
       (check (< (list-index (lambda (source)
                              (equal? source observability))
                            ordered)
                 (list-index (lambda (source)
                              (equal? source facade))
                            ordered))
              => #t)))

   (test-case "checked poo-flow manifest matches the generated closure"
     (let ((generated (gslph-component-receipt 'poo-flow))
           (checked (call-with-input-file "components/poo-flow.json" read-json)))
       (check (member "src/building/build-script-body.inc"
                      (hash-get generated 'supportFiles))
              ? true)
       (for-each
        (lambda (field)
          (check (hash-get checked (symbol->string field))
                 => (hash-get generated field)))
        '(schema outcome component entryFiles supportFiles sourceFiles
                 sourceCount fullSourceCount strictSubset))))))
