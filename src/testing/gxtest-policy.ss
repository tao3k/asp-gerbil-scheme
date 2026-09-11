;;; -*- Gerbil -*-
;;; Scoped policy gate support for gxtest targets.

(import (only-in :gerbil/expander import-module)
        (only-in :std/misc/path path-directory path-expand)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
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
        (only-in "../build-api/source-coverage"
                 asp-gerbil-scheme-source-coverage-files)
        (only-in "./gxtest-context"
                 ensure-build-root!
                 module-path-stem
                 package-name
                 package-root
                 source-output-prefix
                 source-root)
        (only-in "./gxtest-discovery"
                 gxtest-selected-source-files
                 gxtest-selected-test-files)
        (only-in "./gxtest-catalog"
                 gxtest-test-files)
        (only-in "./gxtest-receipts"
                 ensure-directory!
                 file-set-cache-key)
        :gerbil/gambit)

(export scoped-policy-receipt-path
        scoped-policy-phase-line
        scoped-policy-status-line
        scoped-policy-source-files
        scoped-policy-engine-owned-by-project?
        scoped-policy-target-files
        scoped-policy-engine-source-files
        scoped-policy-engine-source-module-files
        scoped-policy-engine-output-files
        scoped-policy-engine-receipt-path
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

;; : (-> Path Boolean)
(def (asp-gerbil-scheme-gerbil-source-file? path)
  (string-suffix? ".ss" path))

;; : (-> Path Boolean)
(def (scoped-policy-engine-source-file? path)
  (and (asp-gerbil-scheme-gerbil-source-file? path)
       (or (string-prefix? "src/policy/" path)
           (string-prefix? "src/parser/" path)
           (string-prefix? "src/types/" path))))

;; : (-> MaybeString Boolean)
(def (scoped-policy-engine-owned-by-project? owner)
  (and (string? owner)
       (string=? owner "asp-gerbil-scheme")))

;; : (-> (List Path))
(def (scoped-policy-engine-source-files)
  (ensure-build-root!)
  (if (scoped-policy-engine-owned-by-project? package-name)
    (map (lambda (path) (path-expand path package-root))
         (filter scoped-policy-engine-source-file?
                 (asp-gerbil-scheme-source-coverage-files package-root)))
    []))

(def (scoped-policy-engine-source-module-file path)
  (let (prefix (string-append source-root "/"))
    (if (string-prefix? prefix path)
      (substring path (string-length prefix) (string-length path))
      (error "scoped policy engine source is outside source root" path))))

(def (scoped-policy-engine-source-module-files)
  (map scoped-policy-engine-source-module-file
       (scoped-policy-engine-source-files)))

(def (scoped-policy-engine-output-file module)
  (path-expand
   (string-append (module-path-stem module) ".ssi")
   (path-expand (source-output-prefix)
                (path-expand ".gerbil/lib" package-root))))

(def (scoped-policy-engine-output-files)
  (map scoped-policy-engine-output-file
       (scoped-policy-engine-source-module-files)))

(def (scoped-policy-engine-receipt-path)
  (path-expand ".gerbil/build/scoped-policy-engine.receipt" package-root))


;; : (-> (List Path))

;; : (-> (List Path))

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
;;       selected test closure used for request reporting.  Policy admission
;;       itself consumes the package graph declared by Build API.
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

;;; Runtime cache boundary:
;;; - The Production Graph and Testing Graph are immutable projections of the
;;;   loaded Build API declarations for one package root.
;;; - Receipt validation still stats every declared source on every warm call;
;;;   only repeated import-graph expansion is memoized here.
(def +scoped-policy-source-graph-cache-lock+
  (make-mutex 'scoped-policy-source-graph-cache))
(def *scoped-policy-source-graph-cache* #f)

;; : (-> Path (List Path))
(def (scoped-policy-source-graph root)
  (with-lock
   +scoped-policy-source-graph-cache-lock+
   (lambda ()
     (if (and *scoped-policy-source-graph-cache*
              (equal? (car *scoped-policy-source-graph-cache*) root))
       (cdr *scoped-policy-source-graph-cache*)
       (let (graph
             (map (lambda (file) (path-expand file root))
                  (scoped-policy-unique-paths
                   (append
                    (asp-gerbil-scheme-source-coverage-files root)
                    (gxtest-selected-source-files (gxtest-test-files))))))
         (set! *scoped-policy-source-graph-cache* (cons root graph))
         graph)))))

;; : (-> (List Path) (List Path))
(def (scoped-policy-source-files _files)
  (ensure-build-root!)
  (scoped-policy-source-graph package-root))

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

;; : (-> BuildReceiptStatus Boolean)
(def (scoped-policy-current? status)
  (eq? (asp-gerbil-scheme-package-build-receipt-status-ref status 'status 'unknown)
       'current))

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
  (import-module ':asp-gerbil-scheme/src/policy/gxtest-runtime #f #t))

;; : (-> (List Path) Void)
(def (run-scoped-policy! files)
  (run-scoped-policy-phase "load-policy"
                           load-compiled-gxtest-policy!)
  (let* ((source-files (scoped-policy-source-files files))
         (policy-report
          (eval 'asp-gerbil-scheme/src/policy/gxtest-runtime#policy-report))
         (report
          (run-scoped-policy-phase "policy-report"
                                   (lambda ()
                                     (policy-report
                                      "."
                                      source-files
                                      files
                                      display-scoped-policy-phase)))))
    (when (pair? (or (hash-get report 'findings) []))
      (run-scoped-policy-phase
       "load-policy-display"
       (lambda ()
         (import-module ':asp-gerbil-scheme/src/policy/gxtest-report #f #t)))
      ((eval 'asp-gerbil-scheme/src/policy/gxtest-report#write-project-policy-report-packet)
       report))
    (when (not (equal? (hash-get report 'status) "pass"))
      (exit 1))))

;; : (-> (List Path) Void)
(def (run-scoped-policy-if-stale files (prepare-stale! #f))
  (let (status (scoped-policy-receipt-status files))
    (display-scoped-policy-status status)
    (unless (scoped-policy-current? status)
      (when prepare-stale!
        (run-scoped-policy-phase "prepare-stale" prepare-stale!))
      (run-scoped-policy! files)
      (run-scoped-policy-phase "write-receipt"
                               (lambda ()
                                 (write-scoped-policy-receipt! files))))))
