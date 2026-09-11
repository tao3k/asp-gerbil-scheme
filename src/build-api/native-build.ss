;;; -*- Gerbil -*-
;;; Build runtime API for the asp gerbil-scheme package.

(import (only-in "../building/facade"
                  default-std-builder
                  make-std-builder-profile
                  make-std-builder-request
                  build-plan-receipts->alist
                  build-request-run!)
        (only-in "../building/declarative" std-build)
        (only-in "../building/build-script"
                 call-with-framework-build-lease)
        (only-in :std/misc/path path-directory path-expand)
        (only-in :std/srfi/13 string-prefix?)
        (only-in "./package-build"
                 asp-gerbil-scheme-package-build-active-gerbil-path)
        (only-in "./package-receipt"
                 asp-gerbil-scheme-package-build-receipt-status
                 asp-gerbil-scheme-package-build-receipt-status-ref
                 asp-gerbil-scheme-package-build-receipt-source-output-current?
                 asp-gerbil-scheme-package-build-receipt-status-line
                 asp-gerbil-scheme-package-build-receipt-write)
        (only-in "./module-artifacts"
                 asp-gerbil-scheme-build-module-source-file
                 asp-gerbil-scheme-build-module-output-file
                 asp-gerbil-scheme-build-module-runtime-artifact-files
                 asp-gerbil-scheme-build-module-optimizer-artifact-file
                 asp-gerbil-scheme-build-module-optimizer-artifact-current?
                 asp-gerbil-scheme-build-module-artifact-files
                 asp-gerbil-scheme-build-module-artifact-file)
        (only-in "./artifact-cleanup"
                 cleanup-generated-artifacts!)
        (only-in "./native-build-spec"
                 package-root
                 source-root
                 configure-build-root!
                 ensure-build-root!
                 source-output-prefix
                 test-output-prefix
                 package-api-output-root
                 package-build-spec
                 library-spec
                 compile-spec)
        (only-in "./package-native-plan"
                 asp-gerbil-scheme-package-api-stage-specs)
        (only-in :gerbil/gambit current-jiffy jiffies-per-second))
(export clean-target
        compile-target
        package-api-build-current?
        package-api-build-output-files
        package-api-build-receipt-path
        package-api-build-receipt-status
        package-api-build-source-files
         compile-package-api-if-stale
         run-package-api-build-request!
        compile-selected-gxtest-target
        prepare-unoptimized-module-set!
        prepare-unoptimized-package-api-artifacts!
        write-package-api-build-receipt!)

;; : (-> PackageApiReceiptPath)
(def (package-api-build-receipt-path)
  (path-expand "build/package-api.receipt"
               (asp-gerbil-scheme-package-build-active-gerbil-path package-root)))

;; : (-> (List Path))
(def (build-module-source-file module)
  (asp-gerbil-scheme-build-module-source-file source-root module))

;; : (-> (List Path))
(def (build-module-output-file module)
  (asp-gerbil-scheme-build-module-output-file (package-api-output-root) module))

;; : (-> (List Path))
(def (package-api-build-source-files)
  (map build-module-source-file
       (package-build-spec)))

;; : (-> (List Path))
(def (package-api-build-output-files)
  (map package-api-module-output-file
       (package-build-spec)))

;; : (-> ModulePath (List Path))
(def (package-api-module-artifact-files module)
  (asp-gerbil-scheme-build-module-artifact-files (package-api-output-root) module))

;; : (-> ModulePath (List Path))
(def (package-api-module-runtime-artifact-files module)
  (asp-gerbil-scheme-build-module-runtime-artifact-files
   (package-api-output-root)
   module))

;; : (-> ModulePath Path)
(def (package-api-module-output-file module)
  (asp-gerbil-scheme-build-module-artifact-file (package-api-output-root) module))

;; : (-> ModulePath Boolean)
(def (package-api-module-current? module)
  (let ((source (build-module-source-file module))
        (candidates (package-api-module-runtime-artifact-files module)))
    (let loop ((remaining candidates))
      (and (pair? remaining)
           (or (asp-gerbil-scheme-package-build-receipt-source-output-current?
                source
                (car remaining))
               (loop (cdr remaining)))))))

;; : (-> Path (List ModulePath) Boolean)
(def (unoptimized-module-set-has-incoherent-optimizer-artifact?
      output-root modules)
  (let loop ((remaining modules))
    (and (pair? remaining)
         (or (let (optimizer
                   (asp-gerbil-scheme-build-module-optimizer-artifact-file
                    output-root
                    (car remaining)))
               (and (file-exists? optimizer)
                    (not
                     (asp-gerbil-scheme-build-module-optimizer-artifact-current?
                      output-root
                      (car remaining)))))
             (loop (cdr remaining))))))

;; A stale SSXI file can rewrite a consumer to a specialized runtime binding
;; that an unoptimized producer no longer emits. Invalidate the complete
;; selected module set at the Build API boundary so std/make rebuilds producer
;; and consumers in one coherent artifact profile.
;; : (-> Path (List ModulePath) Boolean)
(def (prepare-unoptimized-module-set! output-root modules)
  (if (unoptimized-module-set-has-incoherent-optimizer-artifact?
       output-root
       modules)
    (begin
      (cleanup-generated-artifacts!
       (apply append
              (map (lambda (module)
                     (asp-gerbil-scheme-build-module-artifact-files
                      output-root
                      module))
                   modules)))
      #t)
    #f))

;; : (-> Boolean)
(def (prepare-unoptimized-package-api-artifacts!)
  (let (invalidated?
        (prepare-unoptimized-module-set!
         (package-api-output-root)
         (package-build-spec)))
    (when invalidated?
      (cleanup-generated-artifacts!
       [(package-api-build-receipt-path)]))
    invalidated?))

;; : (-> BuildReceiptStatus)
(def (package-api-build-receipt-status)
  (asp-gerbil-scheme-package-build-receipt-status
   (package-api-build-receipt-path)
   expected-sources: (package-api-build-source-files)))

;; : (-> BuildReceiptStatus Boolean)
(def (package-api-build-current? status)
  (eq? (asp-gerbil-scheme-package-build-receipt-status-ref status 'status 'unknown)
       'current))

;; : (-> BuildSpec (List ModulePath))
(def (package-api-stage-modules spec)
  (if (list? spec) spec [spec]))

;; : (-> BuildSpec Boolean)
(def (package-api-stage-current? spec)
  (let loop ((modules (package-api-stage-modules spec)))
    (or (null? modules)
        (and (package-api-module-current? (car modules))
             (loop (cdr modules))))))

;; : (-> BuildReceiptStatus Void)
(def (display-package-api-build-receipt-status status)
  (display (asp-gerbil-scheme-package-build-receipt-status-line status))
  (newline)
  (force-output))

;; : (-> Boolean String Integer Void)
(def (display-build-progress verbose phase started-jiffy)
  (when verbose
    (display "[asp-gerbil-scheme-build] phase=")
    (display phase)
    (display " elapsed-ms=")
    (display
     (quotient (* 1000 (- (current-jiffy) started-jiffy))
               (jiffies-per-second)))
    (newline)
    (force-output)))

;; : (-> Path Void)
(def (ensure-directory! path)
  (unless (file-exists? path)
    (let (parent (path-directory path))
      (when (and parent
                 (not (string=? parent ""))
                 (not (string=? parent path)))
        (ensure-directory! parent))
      (create-directory path))))

;; : (-> (Maybe List) Void)
(def (write-package-api-build-receipt! (receipts #f))
  (let (stamp (package-api-build-receipt-path))
    (ensure-directory! (path-directory stamp))
    (asp-gerbil-scheme-package-build-receipt-write
     stamp
     (package-api-build-source-files)
     (package-api-build-output-files)
     metadata: (if receipts
                 `((buildPlan . ,(build-plan-receipts->alist receipts)))
                 []))))

;; : (forall (s) (-> String Path String [s] (-> s Symbol Boolean) Symbol BuildRequest))
;; : (-> String Path String List Procedure Symbol BuildRequest)
(def (make-package-build-request label srcdir prefix stage-specs
                                 current-pred context)
  (std-build
   label: label
   source: srcdir
   make-options: [optimize: #f
                  prefix: prefix]
   label-of: (lambda (stage)
               (if (and (pair? stage) (string? (car stage)))
                 (car stage)
                 label))
   after: (lambda (stage context result)
            #!void)
   stage-specs: stage-specs
   current?: current-pred
   context: context))

;; : (-> Boolean Boolean BuildReceiptStatus)
(def (compile-package-api-with-receipt verbose force?)
  (ensure-build-root!)
  (current-directory package-root)
  (prepare-unoptimized-package-api-artifacts!)
  (let (started-jiffy (current-jiffy))
    (display-build-progress verbose "package-api/lock" started-jiffy)
    (let (result
          (call-with-framework-build-lease
           (lambda ()
             (let (status (package-api-build-receipt-status))
               (display-package-api-build-receipt-status status)
               (let (request
                     (make-package-build-request
                      "package-api"
                      source-root
                      (source-output-prefix)
                      (asp-gerbil-scheme-package-api-stage-specs)
                      (lambda (_spec _context)
                        (and (not force?)
                             (package-api-stage-current? _spec)))
                      'package-api))
                 (write-package-api-build-receipt!
                  (build-request-run! request))
                 (package-api-build-receipt-status))))))
      (display-build-progress verbose "package-api/complete" started-jiffy)
      result)))

;; : (-> BuildReceiptStatus)
(def (compile-package-api-if-stale)
  (compile-package-api-with-receipt #f #f))

;; : (-> BuildReceiptStatus)
(def (run-package-api-build-request!)
  (compile-package-api-if-stale))

;; : (-> Path ModulePath)
(def (gxtest-test-module-path path)
  (if (string-prefix? "t/" path)
    (substring path 2 (string-length path))
    path))

;; : (-> Path ModulePath)
(def (gxtest-source-module-path path)
  (if (string-prefix? "src/" path)
    (substring path 4 (string-length path))
    path))

;; : (forall (m p) (-> (List m) (List p) Alist))
;; : (-> (List ModulePath) (List Path) Alist)
(def (compile-selected-gxtest-target source-modules files)
  (ensure-build-root!)
  (current-directory package-root)
  (prepare-unoptimized-module-set!
   (package-api-output-root)
   (map gxtest-source-module-path source-modules))
  (prepare-unoptimized-module-set!
   (path-expand (test-output-prefix)
                (path-expand "lib"
                             (asp-gerbil-scheme-package-build-active-gerbil-path
                              package-root)))
   (map gxtest-test-module-path files))
  (call-with-framework-build-lease
   (lambda ()
     (let* ((source-request
             (make-package-build-request
              "selected-gxtest/source"
              source-root
              (source-output-prefix)
              (map gxtest-source-module-path source-modules)
              (lambda (_spec _context) #f)
              'selected-gxtest))
            (test-request
             (make-package-build-request
              "selected-gxtest/test"
              (path-expand "t" package-root)
              (test-output-prefix)
              (map gxtest-test-module-path files)
              (lambda (_spec _context) #f)
              'selected-gxtest)))
       (let (receipts
             (append (build-request-run! source-request)
                     (build-request-run! test-request)))
         `((buildPlan . ,(build-plan-receipts->alist receipts))))))))

;; : (-> Boolean Boolean Boolean Void)
(def (compile-target verbose full force?)
  (ensure-build-root!)
  (current-directory package-root)
  (if full
    (make-target (compile-spec #t) verbose #f #f #f #f)
    (compile-package-api-with-receipt verbose force?))
  #!void)

(def (clean-target)
  (ensure-build-root!)
  (current-directory package-root)
  (cleanup-generated-artifacts!
   (cons (package-api-build-receipt-path)
         (package-api-build-output-files)))
  #!void)

;; : (-> (List BuildSpec) Boolean Boolean Boolean Boolean Boolean Void)
;; : (-> String List Boolean Boolean Boolean Boolean Boolean List)
(def (run-target-build! label spec verbose debug build-optimize?
                        effective-release? effective-optimized?)
  (let* ((builder
          (default-std-builder
           source-root
           [verbose: verbose
            debug: (and debug 'env)
            optimize: build-optimize?
            build-release: effective-release?
            build-optimized: effective-optimized?
            prefix: (source-output-prefix)]))
         (profile
          (make-std-builder-profile
           builder
           (lambda (_spec) label)))
         (request
          (make-std-builder-request
           label
           profile
           (list spec)
           (lambda (_spec _context) #f)
           'native-target)))
    (build-request-run! request)))

(def (make-target spec verbose debug build-optimize?
                  effective-release? effective-optimized?)
  (run-target-build! "native-target"
                     spec
                     verbose debug build-optimize?
                     effective-release? effective-optimized?))
