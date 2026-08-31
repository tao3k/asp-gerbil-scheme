;;; -*- Gerbil -*-
;;; Gxtest expression builders for subprocess and in-process evaluation.

(import (only-in :std/srfi/13 string-join)
        (only-in "./gxtest-syntax"
                 gxtest-file-module-symbol
                 gxtest-file-exported-suite?
                 gxtest-file-self-running?
                 gxtest-file-exported-suite)
        (only-in "./gxtest-delegate"
                 gxtest-delegate-contract-supported?
                 gxtest-delegate-contract-receipt
                 gxtest-filtered-files)
        (only-in "./model"
                 testing-receipt-details)
        :gerbil/gambit)

(export gxtest-compiled-batch-expression
        gxtest-source-load-batch-expression
        gxtest-batch-expression
        gxtest-batch-label)

;; : (-> Datum String)
(def (datum-string value)
  (call-with-output-string
    (lambda (out)
      (write value out))))

;; : (-> (List Path) String)
(def (join-gxtest-args files)
  (string-join (map datum-string files) " "))

;; : (-> (List String) String String)
(def (join-strings values separator)
  (string-join values separator))

;; : (-> Path String)
(def (gxtest-compiled-import-clause file)
  (string-append "(only-in "
                 (datum-string (gxtest-file-module-symbol file))
                 " "
                 (datum-string (gxtest-file-exported-suite file))
                 ")"))

;; : (-> Path String)
(def (gxtest-compiled-run-clause file)
  (string-append " (unless (run-test-suite! "
                 (datum-string (gxtest-file-exported-suite file))
                 ") (set! ok #f))"))

;; : (-> Path String)
(def (gxtest-source-load-run-clause file)
  (if (and (gxtest-file-exported-suite? file)
           (not (gxtest-file-self-running? file)))
    (string-append
     " (let (start (current-jiffy))"
     " (unless (run-test-suite! "
     (datum-string (gxtest-file-exported-suite file))
     ") (set! ok #f))"
     " (display \"[asp-gerbil-scheme-test-file] name="
     file
     " elapsedMs=\")"
     " (display (quotient (* (- (current-jiffy) start) 1000)"
     " (jiffies-per-second)))"
     " (newline)"
     " (force-output))")
    " #!void"))

;; : (-> (List Path) (U #f GxTestDelegateContract) (List Path))
(def (gxtest-expression-files files contract)
  (let (files (gxtest-filtered-files files contract))
    (unless (gxtest-delegate-contract-supported? contract files)
      (error "unsupported gxtest delegate contract"
             (testing-receipt-details
              (gxtest-delegate-contract-receipt contract files))))
    files))

;; gxtest-compiled-batch-expression
;;   : (-> (List Path) (U #f GxTestDelegateContract) String)
;;   | doc m%
;;       `gxtest-compiled-batch-expression` lowers selected gxtest files to the
;;       compiled import form used by fast in-process and compiled subprocess
;;       runners.  Delegate contracts are checked before code is emitted.
;;
;;       # Examples
;;
;;       ```scheme
;;       (string? (gxtest-compiled-batch-expression ["t/build-install-test.ss"]))
;;       ;; => #t
;;       ```
;;     %
(def (gxtest-compiled-batch-expression files (contract #f))
  (let (files (gxtest-expression-files files contract))
    (string-append "(begin"
                   " (import :std/test "
                   (join-strings (map gxtest-compiled-import-clause files) " ")
                   ")"
                   " (let (ok #t)"
                   (join-strings (map gxtest-compiled-run-clause files) " ")
                   " ok)"
                   ")")))

;; : (-> Path String)
(def (gxtest-source-load-clause file)
  (string-append "(load " (datum-string file) ")"))

;; gxtest-source-load-batch-expression
;;   : (-> (List Path) (U #f GxTestDelegateContract) String)
;;   | doc m%
;;       `gxtest-source-load-batch-expression` lowers selected gxtest files to a
;;       source-load form.  It is the explicit fallback for files whose relative
;;       imports or local shape make compiled in-process execution unsafe.
;;     %
(def (gxtest-source-load-batch-expression files (contract #f))
  (let (files (gxtest-expression-files files contract))
    (string-append "(begin"
                   " (add-load-path! \".\")"
                   " (add-load-path! \"src\")"
                   " (add-load-path! \"t\")"
                   " (import :std/test) "
                   (join-strings (map gxtest-source-load-clause files) " ")
                   " (let (ok #t)"
                   (join-strings (map gxtest-source-load-run-clause files) " ")
                   " ok)"
                   ")")))

;; : (-> (List Path) String)
(def (gxtest-batch-label files)
  (match files
    ([] "empty")
    ([file] file)
    ([file . rest]
     (string-append file ",+" (number->string (length rest))))))

;; : (-> (List Path) String)
(def (gxtest-batch-expression files)
  (string-append "(begin"
                 " (add-load-path! \".\")"
                 " (add-load-path! \"src\")"
                 " (add-load-path! \"t\")"
                 " (import :gerbil/tools/gxtest)"
                 " (main "
                 (join-gxtest-args files)
                 "))"))
