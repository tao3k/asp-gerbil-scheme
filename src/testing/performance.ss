;;; -*- Gerbil -*-
;;; Framework-owned performance suite execution.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run/result)
        (only-in :asp-gerbil-scheme/src/support/time
                 monotonic-micros
                 duration-micros)
        (only-in :std/sugar cut filter foldl)
        :asp-gerbil-scheme/src/testing/model)

(export #t)

;; : (-> Datum (List Datum) Boolean)
(def (testing-performance-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else (testing-performance-member? value (cdr values)))))

;; : (-> PerformanceSuite Path Boolean)
(def (testing-performance-root? suite path)
  (testing-performance-member? path (testing-suite-roots suite)))

;; : (-> Symbol Symbol Procedure)
(def (testing-performance-resolve-binding module symbol)
  (eval `(begin
           (import ,module)
           ,symbol)))

;; : (-> PerformanceCase Alist)
(def (testing-performance-case-fixture/value case)
  (let (path (testing-performance-case-fixture-path case))
    (if path
      (call-with-input-file path read)
      (testing-performance-case-fixture case))))

;; : (-> PerformanceCase MaybeProcedure)
(def (testing-performance-case-runner/value case)
  (or (testing-performance-case-runner case)
      (let ((module (testing-performance-case-runner-module case))
            (symbol (testing-performance-case-runner-symbol case)))
        (and module
             symbol
             (testing-performance-resolve-binding module symbol)))))

;; : (-> PerformanceCase MaybeProcedure)
(def (testing-performance-case-validator/value case)
  (or (testing-performance-case-validator case)
      (let ((module (testing-performance-case-validator-module case))
            (symbol (testing-performance-case-validator-symbol case)))
        (and module
             symbol
             (testing-performance-resolve-binding module symbol)))))

;; : (-> Alist Symbol Value)
(def (testing-performance-benchmark-ref receipt key (default #f))
  (let (entry (assq key receipt))
    (if entry (cdr entry) default)))

;; : (-> String Alist List TestingReceipt)
(def (testing-benchmark-details-without details key)
  (cond
   ((null? details) '())
   ((eq? (caar details) key)
    (testing-benchmark-details-without (cdr details) key))
   (else
    (cons (car details)
          (testing-benchmark-details-without (cdr details) key)))))

(def (testing-benchmark-body-phase name receipt (details []))
  (let* ((status (if (eq? (testing-performance-benchmark-ref
                           receipt
                           'status
                           'fail)
                          'pass)
                   'ok
                   'failed))
         (elapsed-micros (testing-performance-benchmark-ref
                          receipt
                          'elapsedMicros
                          0))
         (phase (testing-performance-benchmark-ref details
                                                   'phase
                                                   'benchmark-body))
         (phase-details (testing-benchmark-details-without details 'phase)))
    (testing-receipt
     kind: 'testing-phase
     status: status
     suite: name
     elapsed-micros: elapsed-micros
     details: (append
               `((phase . ,phase)
                 (name . ,name)
                 (elapsedMs . ,(testing-performance-benchmark-ref
                                receipt
                                'elapsedMs
                                0))
                 (feature . ,(testing-performance-benchmark-ref
                              receipt
                              'feature
                              #f))
                 (rule . ,(testing-performance-benchmark-ref
                           receipt
                           'rule
                           #f)))
               phase-details))))

;; : (-> String Alist Procedure List (Values Alist Value TestingReceipt))
(def (testing-benchmark-run/result name fixture thunk (details []))
  (let-values (((receipt result)
                (benchmark-run/result fixture thunk)))
    (values receipt
            result
            (testing-benchmark-body-phase name receipt details))))

;; : (-> PerformanceSuite PerformanceCase Alist TestingReceipt)
(def (testing-performance-benchmark-body-phase suite case receipt)
  (testing-benchmark-body-phase
   (testing-suite-name suite)
   receipt
   `((case . ,(testing-performance-case-name case)))))

;; : (-> PerformanceSuite PerformanceCase TestingReceipt)
(def (testing-run-performance-case suite case)
  (let* ((started-at (monotonic-micros))
         (fixture (testing-performance-case-fixture/value case))
         (runner (testing-performance-case-runner/value case))
         (validator (testing-performance-case-validator/value case)))
    (let-values (((receipt result)
                  (if runner
                    (benchmark-run/result fixture runner)
                    (values [] #f))))
      (let* ((elapsed-micros
              (duration-micros started-at (monotonic-micros)))
             (fixture-ok? (benchmark-fixture-contract-pass? fixture))
             (receipt-ok? (and runner (benchmark-receipt-pass? receipt)))
             (result-ok? (if validator (validator result) #t))
             (status (if (and fixture-ok? receipt-ok? result-ok?)
                       'ok
                       'failed)))
        (testing-receipt
         kind: 'performance-case
         status: status
         suite: (testing-suite-name suite)
         elapsed-micros: elapsed-micros
         details: `((name . ,(testing-performance-case-name case))
                    (fixtureContract . ,fixture-ok?)
                    (receiptContract . ,receipt-ok?)
                    (resultContract . ,result-ok?)
                    (phases
                     .
                     ,(if runner
                        (list
                         (testing-performance-benchmark-body-phase
                          suite
                          case
                          receipt))
                        []))
                    (benchmark . ,receipt)
                    ,@(testing-performance-case-details case)))))))

;; : (-> (List TestingReceipt) Integer)
(def (testing-receipts-elapsed-micros receipts)
  (foldl
   (lambda (receipt elapsed)
     (+ elapsed (testing-receipt-elapsed-micros receipt)))
   0
   receipts))

;; : (-> PerformanceSuite (List String) (List PerformanceCase))
(def (testing-expand-performance-args suite args)
  (if (or (null? args)
          (testing-performance-member? (testing-suite-name suite) args)
          (testing-performance-member? #t
                                       (map (cut testing-performance-root?
                                                 suite <>)
                                            args)))
    (testing-performance-suite-cases suite)
    (filter
     (lambda (case)
       (testing-performance-member? (testing-performance-case-name case)
                                    args))
     (testing-performance-suite-cases suite))))

;; : (-> Symbol Symbol String Integer List TestingReceipt)
(def (testing-performance-phase-receipt phase status suite elapsed-micros cases)
  (testing-receipt
   kind: 'testing-phase
   status: status
   suite: suite
   elapsed-micros: elapsed-micros
   details: `((phase . ,phase)
              (cases . ,cases))))

;; : (-> TestingProject PerformanceSuite List TestingReceipt)
(def (testing-run-performance-suite project suite args)
  (let* ((cases (testing-expand-performance-args suite args))
         (receipts
          (map (lambda (case)
                 (testing-run-performance-case suite case))
               cases))
         (elapsed-micros (testing-receipts-elapsed-micros receipts))
         (status (if (andmap testing-receipt-ok? receipts) 'ok 'failed)))
    (testing-receipt
     kind: 'performance-suite
     status: status
     suite: (testing-suite-name suite)
     elapsed-micros: elapsed-micros
     children: receipts
     details: `((phases
                 .
                 ,(list
                   (testing-performance-phase-receipt
                    'delegate-performance
                    status
                    (testing-suite-name suite)
                    elapsed-micros
                    (map testing-performance-case-name cases))))))))
