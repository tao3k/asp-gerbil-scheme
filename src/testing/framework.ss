;;; -*- Gerbil -*-
;;; User-friendly Gerbil testing helpers inspired by poo-flow test entrypoints.

(import :gerbil/gambit
        :gerbil/expander
        :asp-gerbil-scheme/src/benchmark/framework
        (only-in :asp-gerbil-scheme/src/support/time
                 monotonic-micros
                 duration-micros)
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/scope
        :asp-gerbil-scheme/src/testing/scenario
        :asp-gerbil-scheme/src/testing/selection
        :asp-gerbil-scheme/src/testing/batch
        :asp-gerbil-scheme/src/testing/performance
        :asp-gerbil-scheme/src/testing/commands)

(export #t
        testing-member?
        testing-normalize-path
        testing-path=?
        testing-member-path?
        testing-form-contains-symbol?
        testing-native-gxtest-form?
        testing-native-gxtest-file?
        testing-filter-map
        testing-filter
        testing-andmap
        testing-any?
        testing-string-prefix?
        testing-string-suffix?
        testing-read-test-file-imports
        testing-expand-manifest-file
        testing-suite-root?
        testing-arg-under-root?
        testing-arg-under-suite-root?
        testing-gxtest-file-in-suite?
        testing-suite-default-files
        testing-expand-suite-args
        make-policy-scenario
        policy-scenario-id
        policy-scenario-root
        policy-scenario-metadata
        policy-scenario-suite
        testing-scenario-root
        testing-scenario-id
        testing-scenario-metadata
        testing-scenario-metadata-ref
        testing-scenario-repair-details
        testing-declared-scenario-by-id
        testing-scenario-from-arg
        testing-expand-scenario-args
        testing-scenario-suite-arg?
        testing-gxtest-suite-arg?
        testing-performance-suite-arg?
        testing-suite-selected?
        testing-selected-suites
        testing-select-project
        testing-split-batch
        testing-batch-head
        testing-batch-tail
        testing-batch-count
        testing-batches-step
        testing-batches
        testing-effective-batch-size
        testing-under-limit?
        testing-gxtest-suite-hot-path-diagnostics
        testing-gxtest-suite-hot-path?
        testing-gxtest-suite-hot-path-receipt
        (import: :asp-gerbil-scheme/src/testing/commands))

;; : (-> Symbol Symbol MaybeString List List TestingReceipt)
(import :asp-gerbil-scheme/src/build-api/source-coverage
        )

(def (testing-phase-receipt phase status: (status 'ok)
                            suite: (suite #f)
                            files: (files [])
                            elapsed-micros: (elapsed-micros 0)
                            details: (details []))
  (testing-receipt
   kind: 'testing-phase
   status: status
   suite: suite
   files: files
   elapsed-micros: elapsed-micros
   details: (cons (cons 'phase phase) details)))

;; : (-> TestingSuite List (List TestingReceipt))
(def (testing-gate-phase-receipts suite files)
  (map (lambda (gate)
         (testing-phase-receipt
          'benchmark-assert
          suite: (testing-suite-name suite)
          files: files
          details: `((gate . ,(testing-gate-name gate))
                     (scope . ,(testing-gate-scope gate)))))
       (testing-suite-gates suite)))

;; : (-> TestingSuite List (List TestingReceipt) (List TestingReceipt))
(def (testing-suite-phase-receipts suite files phases)
  (append phases (testing-gate-phase-receipts suite files)))

(def (testing-display-policy-report! files)
  (with-catch
   (lambda (exn)
     (display "[gerbil-gxtest] policy-report-error=")
     (write exn)
     (newline))
   (lambda ()
     (add-load-path! ".")
     (add-load-path! "src")
     (add-load-path! "t")
     (add-load-path! ".gerbil/lib")
     (import-module ':asp-gerbil-scheme/src/policy/gxtest-report #f #t)
     (asp-gerbil-scheme-load-source-coverage ".")
     (let* ((policy-source-report
             (eval 'asp-gerbil-scheme/src/policy/gxtest-report#policy-source-report))
            (display-project-policy-report
             (eval 'asp-gerbil-scheme/src/policy/gxtest-report#display-project-policy-report))
            (report (policy-source-report
                     "."
                     (asp-gerbil-scheme-source-coverage-files "."))))
       (when (pair? (or (hash-get report 'findings) []))
         (display-project-policy-report report))))))

;; : (-> TestingSuite List List Integer TestingReceipt)
(def (testing-expand-manifest-phase-receipt suite files args elapsed-micros)
  (testing-phase-receipt
   'expand-manifest
   suite: (testing-suite-name suite)
   files: files
   elapsed-micros: elapsed-micros
   details: `((args . ,args))))

;; : (-> TestingSuite List Symbol List Integer TestingReceipt)
(def (testing-delegate-gxtest-phase-receipt
      suite files status receipts elapsed-micros)
  (testing-phase-receipt
   'delegate-gxtest
   status: status
   suite: (testing-suite-name suite)
   files: files
   elapsed-micros: elapsed-micros
   details: `((batches . ,(length receipts)))))

;; : (-> TestingSuite List List Symbol List Integer Integer (List TestingReceipt))
(def (testing-gxtest-suite-phase-receipts
      suite files args status receipts expand-elapsed-micros delegate-elapsed-micros)
  (testing-suite-phase-receipts
   suite
   files
   (list
    (testing-expand-manifest-phase-receipt
     suite
     files
     args
     expand-elapsed-micros)
    (testing-delegate-gxtest-phase-receipt
     suite
     files
     status
     receipts
     delegate-elapsed-micros))))

;; : (-> ScenarioSuite List List Symbol TestingReceipt)
(def (testing-delegate-policy-phase-receipt suite files scenarios status)
  (testing-phase-receipt
   'delegate-policy
   status: status
   suite: (testing-suite-name suite)
   files: files
   details: `((scenarios . ,(map testing-scenario-id scenarios))
              (repairGuidance
               .
               ,(testing-scenario-repair-guidance scenarios)))))

;; : (-> ScenarioSuite List List Symbol (List TestingReceipt))
(def (testing-scenario-suite-phase-receipts suite files scenarios status)
  (testing-suite-phase-receipts
   suite
   files
   (list
    (testing-delegate-policy-phase-receipt
     suite
     files
     scenarios
     status))))

;; : (-> TestingSuite List Procedure TestingReceipt)
(def (testing-run-batch suite files run-files)
  (let* ((started-at (monotonic-micros))
         (status (run-files files))
         (elapsed-micros (duration-micros started-at (monotonic-micros)))
         (receipt-status (if (= status 0) 'ok 'failed)))
    (testing-receipt
     kind: 'gxtest-batch
     status: receipt-status
     suite: (testing-suite-name suite)
     files: files
     elapsed-micros: elapsed-micros)))

;; : (-> (List TestingReceipt) Symbol)
(def (testing-receipts-status receipts)
  (if (testing-andmap testing-receipt-ok? receipts) 'ok 'failed))

;; : (-> TestingSuite List Procedure (List TestingReceipt))
(def (testing-run-batches suite batches run-batch)
  (map (lambda (batch)
         (run-batch suite batch))
       batches))

;; : (-> TestingProject GxTestSuite List Procedure TestingReceipt)
(def (testing-run-gxtest-suite project suite args run-files)
  (let* ((suite-started-at (monotonic-micros))
         (expand-started-at (monotonic-micros))
         (files (testing-expand-suite-args suite args))
         (expand-elapsed-micros
          (duration-micros expand-started-at (monotonic-micros)))
         (batch-size (testing-effective-batch-size project suite files))
         (delegate-started-at (monotonic-micros))
         (receipts
          (testing-run-batches
           suite
           (testing-batches files batch-size)
           (lambda (suite batch)
             (testing-run-batch suite batch run-files))))
         (delegate-elapsed-micros
          (duration-micros delegate-started-at (monotonic-micros)))
         (elapsed-micros
          (duration-micros suite-started-at (monotonic-micros)))
         (status (testing-receipts-status receipts)))
    (testing-receipt
     kind: 'gxtest-suite
     status: status
     suite: (testing-suite-name suite)
     files: files
     elapsed-micros: elapsed-micros
     children: receipts
     details: `((phases
                 .
                 ,(testing-gxtest-suite-phase-receipts
                   suite
                   files
                   args
                   status
                   receipts
                   expand-elapsed-micros
                   delegate-elapsed-micros))))))

;; : (-> ScenarioSuite Datum TestingReceipt)
(def (testing-run-scenario suite scenario)
  (let* ((started-at (monotonic-micros))
         (runner (testing-scenario-suite-runner suite))
         (_ (if runner (runner scenario) scenario))
         (elapsed-micros (duration-micros started-at (monotonic-micros))))
    (testing-receipt
     kind: 'policy-scenario
     status: 'ok
     suite: (testing-suite-name suite)
     files: (list (testing-scenario-root suite scenario))
     elapsed-micros: elapsed-micros
     details: (append
               `((id . ,(testing-scenario-id scenario)))
               (testing-scenario-repair-details scenario)))))

;; : (-> PolicyScenario MaybeAlist)
(def (testing-scenario-repair-guidance-row scenario)
  (let (details (testing-scenario-repair-details scenario))
    (and (not (null? details))
         (cons (cons 'id (testing-scenario-id scenario))
               details))))

;; : (-> ScenarioSuite List (List Path))
(def (testing-scenario-files suite scenarios)
  (testing-filter-map
   (lambda (scenario)
     (testing-scenario-root suite scenario))
   scenarios))

;; : (-> List List)
(def (testing-scenario-repair-guidance scenarios)
  (testing-filter-map testing-scenario-repair-guidance-row scenarios))

;; : (-> ScenarioSuite List TestingReceipt)
(def (testing-run-scenario-batch suite scenarios)
  (let* ((started-at (monotonic-micros))
         (receipts
          (map (lambda (scenario)
                 (testing-run-scenario suite scenario))
               scenarios))
         (files (testing-scenario-files suite scenarios))
         (elapsed-micros (duration-micros started-at (monotonic-micros)))
         (status (testing-receipts-status receipts)))
    (testing-receipt
     kind: 'policy-scenario-batch
     status: status
     suite: (testing-suite-name suite)
     files: files
     elapsed-micros: elapsed-micros
     children: receipts)))

;; : (-> TestingProject ScenarioSuite List TestingReceipt)
(def (testing-run-scenario-suite project suite args)
  (let* ((scenarios (testing-expand-scenario-args suite args))
         (files (testing-scenario-files suite scenarios))
         (batch-size (testing-effective-batch-size project suite scenarios))
         (receipts
          (testing-run-batches
           suite
           (testing-batches scenarios batch-size)
           testing-run-scenario-batch))
         (status (testing-receipts-status receipts)))
    (testing-receipt
     kind: 'scenario-suite
     status: status
     suite: (testing-suite-name suite)
     files: files
     children: receipts
     details: `((phases
                 .
                 ,(testing-scenario-suite-phase-receipts
                   suite
                   files
                   scenarios
                   status))))))

;; : (-> TestingProject TestingSuite List Procedure TestingReceipt)
(def (testing-run-suite project suite args run-files)
  (case (testing-object-kind suite)
    ((gxtest-suite)
     (testing-run-gxtest-suite project suite args run-files))
    ((scenario-suite)
     (testing-run-scenario-suite project suite args))
    ((performance-suite)
     (testing-run-performance-suite project suite args))
    (else
     (error "unknown testing suite kind" (testing-object-kind suite)))))

;; : (-> TestingSelection List)
(def (testing-selection-phase-details selection)
  (let ((args (testing-selection-args selection))
        (suites (testing-selection-suites selection)))
    (if (null? suites)
      (testing-selection-details selection)
      `((args . ,args)
        (suites . ,(map testing-suite-name suites))))))

;; : (-> TestingSelection TestingReceipt)
(def (testing-selection-phase-receipt selection)
  (testing-phase-receipt
   'select-scope
   status: (testing-selection-status selection)
   details: (testing-selection-phase-details selection)))

;; : (-> TestingSelection TestingReceipt)
(def (testing-empty-selection-receipt selection)
  (testing-receipt
   kind: 'testing-project
   status: (testing-selection-status selection)
   children: []
   details: (cons (cons 'phases
                        (list (testing-selection-phase-receipt selection)))
                  (testing-selection-details selection))))

;; : (-> TestingSelection TestingProject List List Procedure TestingReceipt)
(def (testing-run-selected-suites selection project args suites run-files)
  (let* ((receipts
          (map (lambda (suite)
                 (testing-run-suite project suite args run-files))
               suites))
         (status (testing-receipts-status receipts)))
    (testing-receipt
     kind: 'testing-project
     status: status
     children: receipts
     details: `((phases
                 .
                 ,(list (testing-selection-phase-receipt selection)))))))

;; : (-> TestingSelection Procedure TestingReceipt)
(def (testing-run-selection selection run-files)
  (let ((project (testing-selection-project selection))
        (args (testing-selection-args selection))
        (suites (testing-selection-suites selection)))
    (if (null? suites)
      (testing-empty-selection-receipt selection)
      (testing-run-selected-suites selection project args suites run-files))))

;; : (-> TestingProject List Procedure TestingReceipt)
(def (testing-run-project project args run-files)
  (testing-run-selection
   (testing-select-project project args)
   run-files))

;; : (-> PerformanceGate Boolean)
(def (testing-performance-gate-valid? gate)
  (let (root (testing-performance-gate-contract-root gate))
    (and root
         (benchmark-contract-valid/root? root))))
