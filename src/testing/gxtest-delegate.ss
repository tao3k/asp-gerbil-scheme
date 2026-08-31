;;; -*- Gerbil -*-
;;; Gxtest delegate contract projection and file filtering.

(import (only-in :asp-gerbil-scheme/src/testing/gxtest-discovery
                 gxtest-file-exported-suite)
        (only-in :asp-gerbil-scheme/src/testing/model
                 testing-object
                 testing-object-ref
                 testing-receipt
                 testing-receipt-ok?)
        :gerbil/gambit)

(export gxtest-delegate-contract
        gxtest-delegate-contract-filter
        gxtest-delegate-contract-receipt
        gxtest-delegate-contract-supported?
        gxtest-filtered-files)

(def (gxtest-delegate-contract filter: (filter #f)
                               quiet: (quiet #f)
                               features: (features []))
  (testing-object
   'gxtest-delegate-contract
   `((filter . ,filter)
     (quiet . ,quiet)
     (features . ,features))))

(def (gxtest-delegate-contract-filter contract)
  (and contract
       (testing-object-ref contract 'filter #f)))

(def (gxtest-delegate-contract-quiet? contract)
  (and contract
       (testing-object-ref contract 'quiet #f)))

(def (gxtest-delegate-contract-features contract)
  (if contract
    (testing-object-ref contract 'features [])
    []))

(def (gxtest-delegate-contract-diagnostics contract)
  (append
   (if (gxtest-delegate-contract-quiet? contract)
     '(quiet-option-unsupported)
     [])
   (if (null? (gxtest-delegate-contract-features contract))
     []
     '(feature-options-unsupported))))

(def (gxtest-delegate-contract-receipt contract files)
  (let* ((diagnostics (gxtest-delegate-contract-diagnostics contract))
         (status (if (null? diagnostics) 'ok 'failed)))
    (testing-receipt
     kind: 'gxtest-delegate-contract
     status: status
     files: files
     details: `((filter . ,(gxtest-delegate-contract-filter contract))
                (quiet . ,(gxtest-delegate-contract-quiet? contract))
                (features . ,(gxtest-delegate-contract-features contract))
                (diagnostics . ,diagnostics)))))

(def (gxtest-delegate-contract-supported? contract files)
  (testing-receipt-ok? (gxtest-delegate-contract-receipt contract files)))

(def (gxtest-filtered-files files contract)
  (let (suite-filter (gxtest-delegate-contract-filter contract))
    (if suite-filter
      (filter (lambda (file)
                (eq? (gxtest-file-exported-suite file) suite-filter))
              files)
      files)))
