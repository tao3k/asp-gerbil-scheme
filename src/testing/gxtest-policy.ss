;;; -*- Gerbil -*-
;;; Scoped policy gate support for gxtest targets.

(import (only-in :gerbil/expander import-module)
        (only-in :std/misc/path path-directory path-expand)
        (only-in :std/sugar foldl hash-get hash-put!)
        (only-in "../support/time"
                 monotonic-micros
                 duration-micros
                 micros->nanos
                 duration-nanos->text)
        (only-in "../build-api/package-receipt"
                 asp-gerbil-scheme-package-build-receipt-status
                 asp-gerbil-scheme-package-build-receipt-status-ref
                 asp-gerbil-scheme-package-build-receipt-write)
        (only-in "./gxtest-context"
                 ensure-build-root!
                 package-root)
        (only-in "./gxtest-discovery"
                 gxtest-selected-test-files)
        (only-in "./gxtest-receipts"
                 ensure-directory!
                 file-set-cache-key)
        :gerbil/gambit)

(export scoped-policy-receipt-path
        scoped-policy-phase-line
        scoped-policy-status-line
        scoped-policy-source-files
        scoped-policy-target-files
        run-scoped-policy-if-stale)

;; : (-> (List Path) String)
(def +scoped-policy-receipt-version+ 'asp-gerbil-scheme-scoped-policy-receipt.v3)

(def (scoped-policy-cache-key files)
  (file-set-cache-key
   (cons (string-append
          "receipt-version:"
          (symbol->string +scoped-policy-receipt-version+))
         files)))

;; : (-> Path)
(def (scoped-policy-receipt-path (files []))
  (path-expand
   (string-append ".gerbil/build/scoped-policy/"
                  (scoped-policy-cache-key files)
                  ".receipt")
   "."))

;; : (-> (List Path) (List Path))
(def (scoped-policy-unique-paths files)
  (let (state
        (foldl scoped-policy-unique-path-step
               (list (make-hash-table) [])
               files))
    (reverse (cadr state))))

;; : (-> Path (Tuple HashTable (List Path)) (Tuple HashTable (List Path)))
(def (scoped-policy-unique-path-step file state)
  (let ((seen (car state))
        (out (cadr state)))
    (if (hash-get seen file)
      state
      (begin
        (hash-put! seen file #t)
        (list seen (cons file out))))))

;; scoped-policy-target-files
;;   : (-> (List Path) (List Path))
;;   | doc m%
;;       `scoped-policy-target-files` maps the selected gxtest files to the
;;       explicit runner entries used for request reporting. Policy owns only
;;       semantic expansion from those entries, never a package build graph.
;;
;;       # Examples
;;
;;       ```scheme
;;       (scoped-policy-target-files ["t/package-build-contract-test.ss"])
;;       ;; => selected test files
;;       ```
;;     %
(def (scoped-policy-target-files files)
  (let (selected (gxtest-selected-test-files files))
    (scoped-policy-unique-paths
     (if (null? selected) files selected))))

;; : (-> (List Path) (List Path))
(def (scoped-policy-source-files files)
  (ensure-build-root!)
  (map (lambda (file) (path-expand file package-root))
       (scoped-policy-target-files files)))

;; : (-> (List Path) Void)
(def (write-scoped-policy-receipt! files)
  (let (stamp (scoped-policy-receipt-path files))
    (ensure-directory! (path-directory stamp))
    (asp-gerbil-scheme-package-build-receipt-write
     stamp
     (scoped-policy-source-files files)
     [stamp]
     version: +scoped-policy-receipt-version+)))

;; : (-> (List Path) BuildReceiptStatus)
(def (scoped-policy-receipt-status files)
  (let (stamp (scoped-policy-receipt-path files))
    (asp-gerbil-scheme-package-build-receipt-status
     stamp
     version: +scoped-policy-receipt-version+
     expected-sources: (scoped-policy-source-files files)
     expected-outputs: [stamp])))

;; : (-> BuildReceiptStatus String)
(def (scoped-policy-status-line status)
  (string-append
   "[asp-gerbil-scheme-scoped-policy] status="
   (symbol->string (asp-gerbil-scheme-package-build-receipt-status-ref status
                                                           'status
                                                           'unknown))
   " reason="
   (let (reason (asp-gerbil-scheme-package-build-receipt-status-ref status 'reason #f))
     (if reason (symbol->string reason) "none"))
   " sources="
   (number->string
    (asp-gerbil-scheme-package-build-receipt-status-ref status 'sources 0))
   " outputs="
   (number->string
    (asp-gerbil-scheme-package-build-receipt-status-ref status 'outputs 0))
   "\n"))

;; : (-> BuildReceiptStatus Void)
(def (display-scoped-policy-status status)
  (display (scoped-policy-status-line status))
  (force-output))

;; : (-> String Integer String)
(def (scoped-policy-phase-line name elapsed-micros)
  (let (elapsed-nanos (micros->nanos elapsed-micros))
    (string-append "[asp-gerbil-scheme-scoped-policy-phase] name=" name
                   " elapsedNs=" (number->string elapsed-nanos)
                   " elapsed=" (duration-nanos->text elapsed-nanos)
                   "\n")))

;; : (-> String Integer Void)
(def (display-scoped-policy-phase name elapsed-micros)
  (display (scoped-policy-phase-line name elapsed-micros))
  (force-output))

;; : (forall (a) (-> String (-> a) a))
(def (run-scoped-policy-phase name thunk)
  (let (start-micros (monotonic-micros))
    (let (result (thunk))
      (display-scoped-policy-phase
       name
       (duration-micros start-micros (monotonic-micros)))
      result)))

;; : (-> Void)
(def (load-compiled-gxtest-policy!)
  (add-load-path! ".")
  (add-load-path! "src")
  (add-load-path! "t")
  (add-load-path! (path-expand ".gerbil/lib" package-root))
  (import-module ':asp-gerbil-scheme/src/policy/gxtest-report #f #t))

;; : (-> (List Path) Void)
(def (run-scoped-policy! files)
  (run-scoped-policy-phase "load-policy"
                           load-compiled-gxtest-policy!)
  (let* ((policy-report
          (eval 'asp-gerbil-scheme/src/policy/gxtest-report#policy-report))
         (report
          (run-scoped-policy-phase "policy-report"
                                   (lambda ()
                                     (policy-report
                                      "."
                                      files
                                      display-scoped-policy-phase)))))
    (when (pair? (or (hash-get report 'findings) []))
      ((eval 'asp-gerbil-scheme/src/policy/gxtest-report#write-project-policy-report-packet)
       report))
    (when (not (equal? (hash-get report 'status) "pass"))
      (exit 1))))

;; : (-> (List Path) Void)
(def (run-scoped-policy-if-stale files (prepare-stale! #f))
  (let (status (scoped-policy-receipt-status files))
    (display-scoped-policy-status status)
    ;; An explicit entry receipt cannot prove that every semantic import is
    ;; unchanged. Run policy on every request and retain the receipt only as
    ;; an observation, never as an admission shortcut.
    (when prepare-stale!
      (run-scoped-policy-phase "prepare-policy" prepare-stale!))
    (run-scoped-policy! files)
    (run-scoped-policy-phase "write-receipt"
                             (lambda ()
                               (write-scoped-policy-receipt! files)))))
