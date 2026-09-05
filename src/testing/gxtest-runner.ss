;;; -*- Gerbil -*-
;;; Gxtest framework runner for package test targets.

(import (only-in :std/misc/path path-directory path-expand)
        (only-in :std/srfi/1 fold)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in "../build-api/source-coverage"
                 asp-gerbil-scheme-source-coverage-files)
        (only-in "../build-api/builder-profile"
                 asp-gerbil-scheme-development-builder-profile
                 asp-gerbil-scheme-builder-profile-test-roots
                 asp-gerbil-scheme-builder-profile-modules/root-roots)
        (only-in "../build-api/package-receipt"
                 asp-gerbil-scheme-package-build-receipt-status-ref)
        (only-in "./gxtest-smoke"
                 asp-gerbil-scheme-default-gxtest-smoke-files)
        (only-in "./gxtest-context"
                 package-root
                 configure-build-root!
                 ensure-build-root!
                 gxtest-test-module-path)
        (only-in "./gxtest-build"
                 clean-target
                 compile-package-api-if-stale
                 compile-scoped-policy-engine-if-stale
                 compile-selected-gxtest-if-stale
                 compile-spec
                 dev-launcher-binpath
                 install-launcher-binpath)
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
(export clean-target
        compile-spec
        configure-build-root!
        default-gxtest-test-files
        dev-launcher-binpath
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
        install-launcher-binpath
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
        test-target
        selected-gxtest-build-current?
        selected-gxtest-build-output-files
        selected-gxtest-build-receipt-path
        selected-gxtest-build-receipt-status
        selected-gxtest-build-source-files
        source-isolated-gxtest-file?
        gxtest-suite-process-isolated?
        write-package-api-build-receipt!)

;; : (-> (List Path))
(def (gxtest-test-files)
  (ensure-build-root!)
  (let (buckets
        (fold gxtest-catalog-test-file-step
              (list [] [])
              (asp-gerbil-scheme-builder-profile-modules/root-roots
               asp-gerbil-scheme-development-builder-profile
               package-root
               (asp-gerbil-scheme-builder-profile-test-roots
                asp-gerbil-scheme-development-builder-profile))))
    (append (reverse (car buckets))
            (reverse (cadr buckets)))))

;; : (-> (List Path))
(def (default-gxtest-test-files)
  (asp-gerbil-scheme-default-gxtest-smoke-files))

;; : (-> (List ModulePath))
(def (gxtest-test-spec)
  (map gxtest-test-module-path (gxtest-test-files)))

;; : (-> (List Path) (List ModulePath))
(def (gxtest-files-spec files)
  (map gxtest-test-module-path files))

;; : (-> Path Boolean)
(def (explicit-project-policy-test-file? entry)
  (string=? entry "project-policy-test.ss"))

;; : (-> Path Boolean)
(def (top-level-test-file? path)
  (and (equal? (path-directory path) "t/")
       (test-file-entry?
        (substring path 2 (string-length path)))))

;; : (-> Path Boolean)
(def (policy-subdir-test-file? path)
  (and (equal? (path-directory path) "t/policy/")
       (let (entry (substring path 9 (string-length path)))
         (and (test-file-entry? entry)
              (policy-agent-poo-test-file? entry)))))

;; : (-> Path Boolean)
(def (test-file-entry? entry)
  (and (string-suffix? "-test.ss" entry)
       (not (member entry '("." "..")))
       (not (explicit-project-policy-test-file? entry))))

;; : (-> Path Boolean)
(def (policy-agent-poo-test-file? entry)
  (string-prefix? "agent-poo-" entry))

;; : (-> Path (List (List Path)) (List (List Path)))
(def (gxtest-catalog-test-file-step path buckets)
  (cond
   ((top-level-test-file? path)
    (list (cons path (car buckets)) (cadr buckets)))
   ((policy-subdir-test-file? path)
    (list (car buckets) (cons path (cadr buckets))))
   (else buckets)))

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
