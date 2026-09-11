;;; -*- Gerbil -*-
;;; Gxtest framework runner for package test targets.

(import (only-in :std/misc/path path-expand)
        (only-in "../build-api/package-receipt"
                 asp-gerbil-scheme-package-build-receipt-status-ref)
        (only-in "./gxtest-context"
                 package-root
                 configure-build-root!
                 ensure-build-root!
                 gxtest-test-module-path)
        (only-in "./gxtest-catalog"
                 default-gxtest-test-files
                 gxtest-test-files
                 gxtest-test-spec)
        (only-in "./gxtest-build"
                 compile-package-api-if-stale
                 compile-scoped-policy-engine-if-stale
                 compile-selected-gxtest-if-stale)
        (only-in "./gxtest-discovery"
                 gxtest-file-exported-symbols
                 gxtest-file-exported-suite
                 gxtest-file-local-suite?
                 gxtest-file-module-symbol
                 gxtest-selected-source-module-files
                 gxtest-selected-test-files
                 source-isolated-gxtest-file?
                 parallel-gxtest-files
                 serial-gxtest-files)
        (only-in "./gxtest-execution"
                 test-phase-receipt-line
                 gxtest-progress-line
                 run-test-phase
                 gxtest-compiled-batch-expression
                 gxtest-source-load-batch-expression
                 gxtest-batch-label
                 gxtest-summary-line
                 gxtest-top-line
                 gxtest-failure-line)
        (only-in "./gxtest-run"
                 run-gxtest-files
                 gxtest-suite-process-isolated?)
        (only-in "./gxtest-receipts"
                 display-package-api-build-receipt-status
                 package-api-build-current?
                 package-api-build-output-files
                 package-api-build-receipt-path
                 package-api-build-receipt-status
                 package-api-build-source-files
                 selected-gxtest-build-current?
                 selected-gxtest-build-output-files
                 selected-gxtest-build-receipt-path
                 selected-gxtest-build-receipt-status
                 selected-gxtest-build-source-files
                 write-package-api-build-receipt!
                 write-selected-gxtest-build-receipt!)
        (only-in "./gxtest-policy"
                 run-scoped-policy-if-stale
                 scoped-policy-phase-line
                 scoped-policy-receipt-path
                 scoped-policy-engine-output-files
                 scoped-policy-engine-receipt-path
                 scoped-policy-engine-source-files
                 scoped-policy-source-files
                 scoped-policy-status-line
                 scoped-policy-target-files)
        (only-in "./gxtest-delegate"
                 gxtest-delegate-contract
                 gxtest-delegate-contract-filter
                 gxtest-delegate-contract-receipt
                 gxtest-delegate-contract-supported?)
        :gerbil/gambit)
(export configure-build-root!
        default-gxtest-test-files
        gxtest-test-spec
        gxtest-test-files
        gxtest-batch-label
        gxtest-compiled-batch-expression
        gxtest-delegate-contract
        gxtest-delegate-contract-filter
        gxtest-delegate-contract-receipt
        gxtest-delegate-contract-supported?
        gxtest-file-exported-symbols
        gxtest-file-exported-suite
        gxtest-file-local-suite?
        gxtest-file-module-symbol
        gxtest-source-load-batch-expression
        gxtest-selected-test-files
        gxtest-summary-line
        gxtest-top-line
        gxtest-failure-line
        asp-gerbil-scheme-package-build-receipt-status-ref
        package-api-build-current?
        package-api-build-output-files
        package-api-build-receipt-path
        package-api-build-receipt-status
        package-api-build-source-files
        parallel-gxtest-files
        serial-gxtest-files
        compile-package-api-if-stale
        scoped-policy-phase-line
        scoped-policy-receipt-path
        scoped-policy-status-line
        scoped-policy-source-files
        test-file-target
        test-full-target
        test-phase-receipt-line
        gxtest-progress-line
        test-target
        selected-gxtest-build-current?
        selected-gxtest-build-output-files
        selected-gxtest-build-receipt-path
        selected-gxtest-build-receipt-status
        selected-gxtest-build-source-files
        source-isolated-gxtest-file?
        gxtest-suite-process-isolated?
        write-package-api-build-receipt!)

;; : (-> (List Path) (List ModulePath))
(def (gxtest-files-spec files)
  (map gxtest-test-module-path files))

;; : (-> (List Path) Void)
(def (run-test-target tests)
  (ensure-build-root!)
  (current-directory package-root)
  (when (null? tests)
    (error "no top-level Gerbil test files found"))
  (run-test-phase
   "run-scoped-policy"
   (lambda ()
     (run-scoped-policy-if-stale
      tests
      (lambda ()
        (compile-scoped-policy-engine-if-stale
         (scoped-policy-engine-source-files)
         (scoped-policy-engine-output-files)
         (scoped-policy-engine-receipt-path))))))
  (run-test-phase
   "run-gxtest"
   (lambda ()
     (run-gxtest-files tests))))

;; : (-> Void)
(def (test-target)
  (run-test-target (default-gxtest-test-files)))

;; : (-> (List Path) Void)
(def (test-file-target files)
  (run-test-target files))

;; : (-> Void)
(def (test-full-target)
  (run-test-target (gxtest-test-files)))
