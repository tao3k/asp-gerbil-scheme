;;; -*- Gerbil -*-
;;; Fast smoke for downstream-facing POO source-ref validation.

(import :gerbil/gambit
        (only-in :std/test test-suite test-case check-equal?)
        :gslph/src/extensions/poo-source-ref-validation)

(export poo-object-validation-test)

;; : SourceRef
(def source-ref
  (let (table (make-hash-table))
    (for-each (lambda (entry)
                (hash-put! table (car entry) (cdr entry)))
              '((kind . "dependency")
                (manager . "gerbil.pkg")
                (dependency . "github.com/tao3k/poo-flow")
                (repository . "github.com/tao3k/poo-flow")
                (localSource . "src/modules")
                (repositorySource . "src/modules")
                (indexHint . "poo-flow-module-object")
                (pathPolicy . "package-dependency")
                (selectorScheme . "gerbil-poo")))
    table))

;; : (-> Receipt Key Value)
(def (receipt-ref receipt key)
  (hash-get receipt key))

;; : TestSuite
(def poo-object-validation-test
  (test-suite "poo object source-ref validation smoke"
    (test-case "exports source-ref structural validation downstream"
      (let (validation
            (poo-object-source-ref-structural-validation source-ref))
        (check-equal? (receipt-ref validation 'kind)
                      "poo-pattern-structural-validation")
        (check-equal? (receipt-ref validation 'schema)
                      "poo-pattern-evidence/v1")
        (check-equal? (receipt-ref validation 'patternKind)
                      "type-validation")
        (check-equal? (receipt-ref validation 'valid) #t)))))
