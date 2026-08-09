;;; -*- Gerbil -*-
;;; Build runtime API for the asp gerbil-scheme package.

(import (only-in "../building/facade"
                  default-std-builder
                  make-std-builder-profile
                  make-std-builder-request
                  build-plan-receipts->alist
                  build-request-run!)
        (only-in "../building/declarative" std-build)
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in "./package-build"
                 gslph-package-configure-build-root!
                 gslph-package-build-active-gerbil-path
                 gslph-package-build-package-name
                 gslph-package-build-with-lock)
        (only-in "./cli-gsc-options"
                 gslph-cli-gsc-options
                 gslph-cli-gsc-options-cache-key)
        (only-in "./source-coverage"
                 gslph-source-coverage-files
                 gslph-source-coverage-runtime-roots
                 gslph-source-coverage-exclude-directories)
        (only-in "./package-receipt"
                 gslph-package-build-receipt-status
                 gslph-package-build-receipt-status-ref
                 gslph-package-build-receipt-source-output-current?
                 gslph-package-build-receipt-status-line
                 gslph-package-build-receipt-write)
        (only-in "./launcher-receipt"
                 gslph-build-module-source-file
                 gslph-build-module-output-file
                 gslph-build-module-artifact-files
                 gslph-build-module-artifact-file
                 gslph-cli-launcher-build-current?
                 gslph-cli-launcher-build-receipt-status
                 gslph-ensure-cli-launcher-inputs!
                 gslph-ensure-install-launcher-inputs!
                 gslph-install-launcher-build-current?
                 gslph-install-launcher-build-receipt-status
                 gslph-write-cli-launcher-build-receipt!
                 gslph-write-install-launcher-build-receipt!)
        (only-in "./artifact-cleanup"
                 cleanup-compile-exe-artifacts!
                 cleanup-generated-artifacts!
                 cleanup-launcher-binary-artifacts!)
        (only-in "./build-path-contract"
                 configure-build-path-root!
                 dev-launcher-binpath
                 install-launcher-binpath)
        (only-in "./package-spec"
                 gslph-package-api-spec
                 gslph-package-api-stage-specs)
        (only-in "./release-modules" cli-release-modules)
        (only-in :gerbil/gambit current-jiffy jiffies-per-second setenv))
(export clean-target
        compile-target
         install-target
         compile-spec
         cli-binary-module-spec
         cli-binary-build-spec
         configure-build-root!
        dev-launcher-binpath
        install-launcher-binpath
        package-api-build-current?
        package-api-build-output-files
        package-api-build-receipt-path
        package-api-build-receipt-status
        package-api-build-source-files
         compile-package-api-if-stale
         run-package-api-build-request!
        compile-selected-gxtest-target
        workspace-install-target
        write-package-api-build-receipt!
        package-build-spec)

;; : (Maybe Path)
(def package-root #f)

;; : (Maybe Path)
(def source-root #f)

;; : (Maybe Datum)
(def current-package-gerbil-modules-key #f)

;; : (Maybe (List ModulePath))
(def current-package-gerbil-modules #f)

;; : (Maybe String)
(def package-name #f)

;; : (-> String Void)
(def (configure-build-root! root)
  (set! package-root (path-normalize root))
  (configure-build-path-root! package-root)
  (gslph-package-configure-build-root! package-root)
  (set! source-root (path-expand "src" package-root))
  (set! current-package-gerbil-modules-key #f)
  (set! current-package-gerbil-modules #f)
  (set! package-name (read-build-package-name package-root)))

;; : (-> Void)
(def (ensure-build-root!)
  (unless package-root
    (configure-build-root! (current-directory))))

;; : (-> Path (Maybe String))
(def (read-build-package-name root)
  (gslph-package-build-package-name root))

;; : (-> String String)
(def (package-output-prefix root-name)
  (ensure-build-root!)
  (unless package-name
    (error "gerbil.pkg must declare package: for build output prefix"))
  (string-append package-name "/" root-name))

;; : (-> String)
(def (package-root-output-prefix)
  (ensure-build-root!)
  (unless package-name
    (error "gerbil.pkg must declare package: for build output prefix"))
  package-name)

;; : (-> String)
(def (source-output-prefix)
  (package-output-prefix "src"))

;; : (-> String)
;; : (-> String)
(def (test-output-prefix)
  (package-output-prefix "t"))

;; : (List ModulePath)
(def excluded-library-files
  '("cli.ss"
    "cli-dev-linker.ss"
    "cli-install-linker.ss"
    "cli-launcher.ss"
    "cli-release-linker.ss"))

;; : (-> Boolean String (List BuildSpec))
(def (cli-exe-spec optimized? root)
  [(append (if optimized?
             [optimized-exe: root bin: "gslph"]
             [exe: root bin: "gslph"])
           (gslph-cli-gsc-options package-root))])

;; : (-> Boolean (List BuildSpec))
(def (cli-dev-spec optimized?)
  (cli-exe-spec optimized? "cli-dev-linker"))

;; : (-> Boolean (List BuildSpec))
(def (cli-release-spec optimized?)
  (cli-exe-spec optimized? "cli-release-linker"))

;; : (-> Boolean (List BuildSpec))
(def (cli-install-spec optimized?)
  (cli-exe-spec optimized? "cli-release-linker"))

;; : (-> (List BuildSpec))
(def (cli-workspace-install-spec)
  (cli-exe-spec #f "cli-install-linker"))

;; : (-> (List ModulePath))
(def (cli-install-module-spec)
  (cli-launcher-source-modules #t))

;; : (List ModulePath)
(def cli-bootstrap-modules
  '("constants.ss"
    "commands/search-prime-light-list.ss"
    "commands/search-prime-light.ss"
    "search-light-launcher.ss"
    "support/time.ss"))

;; : (List String)
(def +library-excluded-dirs+
  '("search-fast" "testing"))

;; : (List String)
(def +default-excluded-dirs+
  '("run" "t" ".git" "_darcs" ".gerbil"))

;; : (-> Boolean (List ModulePath))
(def (cli-binary-module-spec release?)
  (if release?
    (cli-release-module-spec)
    cli-bootstrap-modules))

;; : (-> (List BuildSpec))
(def (cli-release-module-spec)
  cli-release-modules)

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-exe-spec release? optimized?)
  (if release?
    (cli-release-spec optimized?)
    (cli-dev-spec optimized?)))

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-spec release? optimized?)
  (append (cli-binary-module-spec release?)
          (cli-binary-exe-spec release? optimized?)))

;; : (-> ModulePath Boolean)
(def (runtime-library-module? module)
  (and (not (member module excluded-library-files))
       (not (library-excluded-dir-module? module))))

;; : (-> ModulePath Boolean)
(def (library-excluded-dir-module? module)
  (let loop ((dirs +library-excluded-dirs+))
    (and (pair? dirs)
         (or (let (prefix-output (open-output-string))
               (display (car dirs) prefix-output)
               (write-char #\/ prefix-output)
               (string-prefix? (get-output-string prefix-output) module))
             (loop (cdr dirs))))))

;; : (-> ModulePath Boolean)
(def (library-module? module)
  (runtime-library-module? module))

;; : (-> (List BuildSpec))
(def (library-spec)
  (filter library-module? (all-package-gerbil-modules)))

;; : (-> (List BuildSpec))
(def (runtime-library-spec)
  (filter runtime-library-module? (all-package-gerbil-modules)))

;; Build a relocatable ASP artifact with sibling bin/ and lib/ roots.  The
;; launcher remains small and loads cold command modules from the library tree.
;; : (-> Path Path)
(def (workspace-install-target artifact-root)
  (configure-build-root! (current-directory))
  (setenv "GERBIL_PATH" artifact-root)
  (compile-binary-artifact
   (path-expand "bin/gslph" artifact-root)
   (runtime-library-spec)
   (cli-workspace-install-spec)
   #f #f #f #f #f))

;; : (-> (List BuildSpec))
(def (native-runtime-spec)
  '("src/build-api/install-static-modules.ss"
    "src/build-api/worker-count.ss"
    "src/build-api/cli-gsc-options.ss"
    "src/build-api/launcher-receipt.ss"
    "src/build-api/package-build.ss"
    "src/build-api/build-path-contract.ss"
    "src/testing/gxtest-smoke.ss"
    "src/testing/gxtest-runner.ss"
    "src/build-api/native-build.ss"))

;; : (-> [Path (List Path) (List String)])
(def (package-gerbil-modules-cache-key)
  (list package-root
        (gslph-source-coverage-runtime-roots)
        (coverage-excluded-directories)))

;; : (-> (List ModulePath))
(def (uncached-package-gerbil-modules)
  (apply append
         (map runtime-root-gerbil-modules
              (gslph-source-coverage-runtime-roots))))

;; : (-> (List ModulePath))
(def (all-package-gerbil-modules)
  (let (key (package-gerbil-modules-cache-key))
    (if (and current-package-gerbil-modules-key
             (equal? current-package-gerbil-modules-key key))
      current-package-gerbil-modules
      (let (modules (uncached-package-gerbil-modules))
        (set! current-package-gerbil-modules-key key)
        (set! current-package-gerbil-modules modules)
        modules))))

;; : (-> Path (Maybe ModulePath))
(def (source-runtime-module-path path)
  (let (prefix "src/")
    (and (string-prefix? prefix path)
         (substring path
                    (string-length prefix)
                    (string-length path)))))

;; : (-> (List ModulePath))
(def (source-runtime-modules)
  (filter (lambda (module) module)
          (map source-runtime-module-path
               (gslph-source-coverage-files package-root))))

;; : (-> Path (List ModulePath))
(def (runtime-root-gerbil-modules root)
  (cond
   ((string=? root "src")
    (source-runtime-modules))
   (else
    [])))

;; : (-> (List String))
(def (coverage-excluded-directories)
  (append +default-excluded-dirs+
          +library-excluded-dirs+
          (gslph-source-coverage-exclude-directories)))

;; : (-> (List BuildSpec))
(def (package-build-spec)
  (ensure-build-root!)
  (gslph-package-api-spec))

;; : (-> Path String)
(def (module-path-stem module)
  (if (string-suffix? ".ss" module)
    (substring module 0 (- (string-length module) 3))
    module))

;; : (-> PackageLibOutputRoot)
(def (package-api-output-root)
  (path-expand (source-output-prefix)
               (path-expand "lib"
                            (gslph-package-build-active-gerbil-path
                             package-root))))

;; : (-> PackageApiReceiptPath)
(def (package-api-build-receipt-path)
  (path-expand "build/package-api.receipt"
               (gslph-package-build-active-gerbil-path package-root)))

;; : (-> (List Path))
(def (build-module-source-file module)
  (gslph-build-module-source-file source-root module))

;; : (-> (List Path))
(def (build-module-output-file module)
  (gslph-build-module-output-file (package-api-output-root) module))

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
  (gslph-build-module-artifact-files (package-api-output-root) module))

;; : (-> ModulePath Path)
(def (package-api-module-output-file module)
  (gslph-build-module-artifact-file (package-api-output-root) module))

;; : (-> ModulePath Boolean)
(def (package-api-module-current? module)
  (let ((source (build-module-source-file module))
        (candidates (package-api-module-artifact-files module)))
    (let loop ((remaining candidates))
      (and (pair? remaining)
           (or (gslph-package-build-receipt-source-output-current?
                source
                (car remaining))
               (loop (cdr remaining)))))))

;; : (-> BuildReceiptStatus)
(def (package-api-build-receipt-status)
  (gslph-package-build-receipt-status
   (package-api-build-receipt-path)
   expected-sources: (package-api-build-source-files)))

;; : (-> BuildReceiptStatus Boolean)
(def (package-api-build-current? status)
  (eq? (gslph-package-build-receipt-status-ref status 'status 'unknown)
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
  (display (gslph-package-build-receipt-status-line status))
  (newline)
  (force-output))

;; : (-> Boolean String Integer Void)
(def (display-build-progress verbose phase started-jiffy)
  (when verbose
    (display "[gslph-build] phase=")
    (display phase)
    (display " elapsed-ms=")
    (display
     (quotient (* 1000 (- (current-jiffy) started-jiffy))
               (jiffies-per-second)))
    (newline)
    (force-output)))

;; : (-> Void)
;; : (-> (Maybe List) Void)
(def (write-package-api-build-receipt! (receipts #f))
  (let (stamp (package-api-build-receipt-path))
    (ensure-directory! (path-directory stamp))
    (gslph-package-build-receipt-write
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
  (let (started-jiffy (current-jiffy))
    (display-build-progress verbose "package-api/lock" started-jiffy)
    (let (result
          (gslph-package-build-with-lock
           (lambda ()
             (let (status (package-api-build-receipt-status))
               (display-package-api-build-receipt-status status)
               (let (request
                     (make-package-build-request
                      "package-api"
                      source-root
                      (source-output-prefix)
                      (gslph-package-api-stage-specs)
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
  (gslph-package-build-with-lock
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

;; : (-> (List ModulePath))
(def (install-launcher-source-modules)
  (cli-launcher-source-modules #t))

;; : (-> Boolean (List ModulePath))
(def (cli-launcher-source-modules release?)
  (append (cli-binary-module-spec release?)
          (list (if release?
                  "cli-release-linker.ss"
                  "cli-dev-linker.ss"))))

;; : (-> Boolean (List BuildSpec))
(def (build-spec release?)
  (if release?
    (cli-binary-spec #t #t)
    (library-spec)))

;; : (-> Boolean Boolean Boolean (List BuildSpec))
(def (compile-spec full? release? binary?)
  (ensure-build-root!)
  (cond
   (full? (library-spec))
   (release? (cli-binary-spec #t #t))
   (binary? (cli-binary-spec #f #f))
   (else (gslph-package-api-spec))))

;; : (-> Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean Void)
(def (compile-target verbose debug no-optimize optimized release full binary force?)
  (ensure-build-root!)
  (current-directory package-root)
  (let* ((build-optimize? (and optimized (not no-optimize)))
         (effective-release? release)
         (effective-optimized? optimized))
    (if (and (not full) (or release binary))
      (begin
        (compile-package-api-with-receipt verbose force?)
        (compile-cli-binary-if-stale (dev-launcher-binpath)
                                     verbose debug build-optimize?
                                     release effective-release? effective-optimized?))
      (if (and (not full) (not release) (not binary))
        (compile-package-api-with-receipt verbose force?)
        (make-target (compile-spec full release binary)
                     verbose debug build-optimize?
                     effective-release? effective-optimized?)))
     #!void))

;; : (-> Path Boolean Boolean Boolean Boolean Boolean Boolean BuildReceiptStatus)
(def (compile-cli-binary-if-stale binpath verbose debug build-optimize?
                                  release? effective-release?
                                  effective-optimized?)
  (let* ((inputs-path
          (gslph-ensure-cli-launcher-inputs!
           package-root
           release?
           build-optimize?
           effective-release?
           effective-optimized?
           (gslph-cli-gsc-options-cache-key)
           (gslph-cli-gsc-options package-root)))
         (status
          (gslph-cli-launcher-build-receipt-status
           package-root
           source-root
           (package-api-output-root)
           release?
           binpath
           inputs-path
           (cli-binary-module-spec release?)
           (cli-launcher-source-modules release?))))
    (display-package-api-build-receipt-status status)
    (if (gslph-cli-launcher-build-current? status)
      status
      (begin
        (compile-cli-binary binpath
                            verbose debug build-optimize?
                            release? effective-release?
                            effective-optimized?)
        (gslph-write-cli-launcher-build-receipt!
         package-root
         source-root
         (package-api-output-root)
         release?
         binpath
         inputs-path
         (cli-binary-module-spec release?)
         (cli-launcher-source-modules release?))
        (gslph-cli-launcher-build-receipt-status
         package-root
         source-root
         (package-api-output-root)
         release?
         binpath
         inputs-path
         (cli-binary-module-spec release?)
         (cli-launcher-source-modules release?))))))

(def (clean-target)
  (ensure-build-root!)
  (current-directory package-root)
  (let (binpath (dev-launcher-binpath))
    (cleanup-launcher-binary-artifacts! binpath)
    (cleanup-generated-artifacts!
     (cons (package-api-build-receipt-path)
           (package-api-build-output-files))))
  #!void)

;; : (-> Boolean Boolean Boolean Boolean Boolean Void)
;; : (-> Boolean Boolean Boolean Boolean Boolean Boolean Void)
(def (install-target verbose debug _no-optimize _optimized _release full (flag #f))
  (ensure-build-root!)
  (current-directory package-root)
  (compile-install-binary-with-receipt (install-launcher-binpath flag)
                                       verbose debug #f
                                       #f #f full)
  #!void)

;; : (-> Path Boolean Boolean Boolean Boolean Boolean Boolean BuildReceiptStatus)
(def (compile-install-binary-with-receipt binpath verbose debug build-optimize?
                                          effective-release? effective-optimized?
                                          force?)
  (let* ((inputs-path
          (gslph-ensure-install-launcher-inputs!
           package-root
           build-optimize?
           effective-release?
           effective-optimized?
           (gslph-cli-gsc-options-cache-key)
           (gslph-cli-gsc-options package-root)))
         (status
          (gslph-install-launcher-build-receipt-status
           package-root
           source-root
           (package-api-output-root)
           binpath
           inputs-path
           '()
           (install-launcher-source-modules))))
    (display-package-api-build-receipt-status status)
    (if (and (not force?)
             (gslph-install-launcher-build-current? status))
      status
      (begin (cleanup-launcher-binary-artifacts! binpath)
        (compile-install-binary binpath
                                verbose debug build-optimize?
                                effective-release? effective-optimized?)
        (gslph-write-install-launcher-build-receipt!
         package-root
         source-root
         (package-api-output-root)
         binpath
         inputs-path
         '()
         (install-launcher-source-modules))
        (gslph-install-launcher-build-receipt-status
         package-root
         source-root
         (package-api-output-root)
         binpath
         inputs-path
         '()
         (install-launcher-source-modules))))))

;; : (-> Path Boolean Boolean Boolean Boolean Boolean Path)
(def (compile-install-binary binpath verbose debug build-optimize?
                             effective-release? effective-optimized?)
  (compile-binary-artifact
    binpath
    (cli-install-module-spec)
    (cli-install-spec build-optimize?)
    verbose debug build-optimize?
    effective-release? effective-optimized?))

;; : (-> Path Boolean Boolean Boolean Boolean Boolean Boolean Path)
(def (compile-cli-binary binpath verbose debug build-optimize?
                         release? effective-release? effective-optimized?)
  (compile-binary-artifact
    binpath
    (cli-binary-module-spec release?)
    (cli-binary-exe-spec release? build-optimize?)
    verbose debug build-optimize?
    effective-release? effective-optimized?))

;; : (-> Path (List BuildSpec) (List BuildSpec) Boolean Boolean Boolean Boolean Boolean Path)
(def (compile-binary-artifact binpath module-spec exe-spec
                              verbose debug build-optimize?
                              effective-release? effective-optimized?)
  (let (started-jiffy (current-jiffy))
    (display-build-progress verbose "launcher/build" started-jiffy)
    (make-target module-spec
                 verbose debug build-optimize?
                 effective-release? effective-optimized?)
    (cleanup-compile-exe-artifacts! binpath)
    (make-target/bindir exe-spec
                        verbose debug build-optimize?
                        effective-release? effective-optimized?
                        (path-directory binpath))
    (cleanup-compile-exe-artifacts! binpath)
    (display-build-progress verbose "launcher/complete" started-jiffy)
    binpath))

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-build-spec release?)
  (cli-binary-spec release? #t))


;; : (-> HomeDirectoryPath)
(def (user-home-directory)
  (or (getenv "HOME" #f)
      (error "HOME is required to install gslph into $HOME/.local/bin")))

;; : (-> Path Void)
(def (ensure-directory! path)
  (unless (file-exists? path)
    (let (parent (path-directory path))
      (when (and parent
                 (not (string=? parent ""))
                 (not (string=? parent path)))
        (ensure-directory! parent))
      (create-directory path))))

;; : (-> (List BuildSpec) Boolean Boolean Boolean Boolean Boolean Void)
;; : (-> String List Boolean Boolean Boolean Boolean Boolean (Maybe Path) List)
(def (run-target-build! label spec verbose debug build-optimize?
                        effective-release? effective-optimized?
                        (bindir #f))
  (let* ((builder
          (default-std-builder
           source-root
           (append [verbose: #f
                    debug: (and debug 'env)
                    optimize: build-optimize?
                    build-release: effective-release?
                    build-optimized: effective-optimized?
                    prefix: (source-output-prefix)]
                   (if bindir [bindir: bindir] []))))
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

;; : (-> (List BuildSpec) Boolean Boolean Boolean Boolean Boolean Path Void)
(def (make-target/bindir spec verbose debug build-optimize?
                         effective-release? effective-optimized?
                         bindir)
  (ensure-directory! bindir)
  (run-target-build! "native-target/bindir"
                     spec
                     verbose debug build-optimize?
                     effective-release? effective-optimized?
                     bindir))
