;;; -*- Gerbil -*-
;;; Batching and hot-path gates for testing project execution.

(import :gerbil/gambit
        (only-in :std/srfi/1 iota split-at)
        (only-in :std/sugar cut foldl)
        :asp-gerbil-scheme/src/testing/model)

(export #t)

;; : (-> List Integer (Values List List))
(def (testing-split-batch files batch-size)
  (if (or (null? files)
          (<= batch-size 0))
    (values [] [])
    (split-at files (min batch-size (length files)))))

;; : (-> List Integer List)
(def (testing-batch-head files batch-size)
  (let-values (((batch _rest)
                (testing-split-batch files batch-size)))
    batch))

;; : (-> List Integer List)
(def (testing-batch-tail files batch-size)
  (let-values (((_batch rest)
                (testing-split-batch files batch-size)))
    rest))

;; : (-> Integer Integer Integer)
(def (testing-batch-count file-count batch-size)
  (if (or (<= file-count 0) (<= batch-size 0))
    0
    (quotient (+ file-count batch-size -1) batch-size)))

;; : (-> Integer Integer List List)
(def (testing-batches-step batch-size _ state)
  (let-values (((batch rest)
                (testing-split-batch (car state) batch-size)))
    (list rest (cons batch (cadr state)))))

;; : (-> List Integer (List List))
(def (testing-batches files batch-size)
  (reverse
   (cadr
    (foldl (cut testing-batches-step batch-size <> <>)
           (list files [])
           (iota (testing-batch-count (length files) batch-size))))))

;; : (-> TestingProject TestingSuite List Integer)
(def (testing-effective-batch-size project suite files)
  (let ((suite-size (testing-suite-batch-size suite))
        (project-size (testing-project-batch-size project)))
    (cond
     (suite-size suite-size)
     (project-size project-size)
     ((null? files) 1)
     (else (length files)))))

;; : (-> Integer MaybeInteger Boolean)
(def (testing-under-limit? count limit)
  (or (not limit)
      (<= count limit)))

;; : (-> GxTestSuite List Integer Integer (List Symbol))
(def (testing-gxtest-suite-hot-path-diagnostics suite files selected-sources selected-outputs)
  (append
   (if (testing-under-limit? (length files)
                             (testing-suite-max-selected-files suite))
     []
     '(too-many-selected-files))
   (if (testing-under-limit? selected-sources
                             (testing-suite-max-selected-sources suite))
     []
     '(too-many-selected-sources))
   (if (testing-under-limit? selected-outputs
                             (testing-suite-max-selected-outputs suite))
     []
     '(too-many-selected-outputs))))

;; : (-> GxTestSuite List Integer Integer Boolean)
(def (testing-gxtest-suite-hot-path? suite files selected-sources selected-outputs)
  (null? (testing-gxtest-suite-hot-path-diagnostics
          suite
          files
          selected-sources
          selected-outputs)))

;; : (-> GxTestSuite List Integer Integer TestingReceipt)
(def (testing-gxtest-suite-hot-path-receipt suite files selected-sources selected-outputs)
  (let* ((diagnostics
          (testing-gxtest-suite-hot-path-diagnostics
           suite
           files
           selected-sources
           selected-outputs))
         (status (if (null? diagnostics) 'ok 'failed)))
    (testing-receipt
     kind: 'gxtest-hot-path-gate
     status: status
     suite: (testing-suite-name suite)
     files: files
     details: `((selectedFiles . ,(length files))
                (maxSelectedFiles . ,(testing-suite-max-selected-files suite))
                (selectedSources . ,selected-sources)
                (maxSelectedSources . ,(testing-suite-max-selected-sources suite))
                (selectedOutputs . ,selected-outputs)
                (maxSelectedOutputs . ,(testing-suite-max-selected-outputs suite))
                (diagnostics . ,diagnostics)))))
