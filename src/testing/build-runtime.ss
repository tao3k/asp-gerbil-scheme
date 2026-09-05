;;; -*- Gerbil -*-
;;; Runtime helpers for downstream testing-build gxtest execution.

(import :gerbil/gambit
        (only-in :std/test run-test-suite!)
        (only-in :std/srfi/1 append-map find)
        (only-in :std/srfi/13 string-suffix?)
        (only-in :std/sugar hash-get hash-put!)
        (only-in :asp-gerbil-scheme/src/policy/gxtest make-policy-test)
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/framework
        :asp-gerbil-scheme/src/testing/build-paths
        :asp-gerbil-scheme/src/testing/build-process
        :asp-gerbil-scheme/src/testing/build-support)

(export #t)

;; : (-> TestingBuild Procedure)
(def (testing-build-dry-gxtest-runner build)
  (lambda (files)
    (testing-build-record-gxtest-run! build files)
    0))

;; : (-> TestingBuild (List Path) Unit)
(def (testing-build-record-gxtest-run! build files)
  (let (runs (testing-object-ref build 'gxtestRuns []))
    (vector-set! runs 0 (cons files (vector-ref runs 0)))))

;; : (-> TestingBuild Path Symbol Boolean)
(def (testing-build-run-gxtest-file/compiled build file suite-symbol)
  (eval
   (call-with-input-string
     (testing-build-gxtest-compiled-expression build file suite-symbol)
     read)))

;; FormsCache
(def +testing-build-gxtest-file-forms-cache+
  (make-hash-table))

;; : (-> TestingBuild Path (List Datum))
(def (testing-build-gxtest-file-forms build file)
  (let* ((path (testing-build-path build file))
         (cached (hash-get +testing-build-gxtest-file-forms-cache+ path)))
    (if cached
      cached
      (let (forms (call-with-input-file path read-all))
        (hash-put! +testing-build-gxtest-file-forms-cache+ path forms)
        forms))))

;; : (-> Datum Boolean)
(def (testing-build-gxtest-export-form? form)
  (and (pair? form)
       (eq? (car form) 'export)))

;; : (-> Datum (List Symbol))
(def (testing-build-gxtest-export-symbols form)
  (if (testing-build-gxtest-export-form? form)
    (filter-map (lambda (item)
                  (and (symbol? item) item))
                (cdr form))
    []))

;; : (-> Datum Boolean)
(def (testing-build-gxtest-self-running-form? form)
  (and (pair? form)
       (eq? (car form) 'run-tests!)))

;; : (-> TestingBuild Path (List Symbol))
(def (testing-build-gxtest-file-exported-symbols build file)
  (append-map testing-build-gxtest-export-symbols
              (testing-build-gxtest-file-forms build file)))

;; : (-> Symbol Boolean)
(def (testing-build-gxtest-suite-symbol? symbol)
  (string-suffix? "-test" (symbol->string symbol)))

;; : (-> TestingBuild Path Boolean)
(def (testing-build-gxtest-file-exported-suite? build file)
  (if (testing-build-gxtest-file-exported-suite-option build file) #t #f))

;; : (-> TestingBuild Path MaybeSymbol)
(def (testing-build-gxtest-file-exported-suite-option build file)
  (let* ((symbols (testing-build-gxtest-file-exported-symbols build file))
         (suite (or (find testing-build-gxtest-suite-symbol? symbols)
                    (and (pair? symbols) (car symbols)))))
    suite))

;; : (-> TestingBuild Path Symbol)
(def (testing-build-gxtest-file-exported-suite build file)
  (let (suite (testing-build-gxtest-file-exported-suite-option build file))
    (or suite
        (error "gxtest file must export a test suite" file))))

;; : (-> TestingBuild Path Boolean)
(def (testing-build-gxtest-file-self-running? build file)
  (if (find testing-build-gxtest-self-running-form?
            (testing-build-gxtest-file-forms build file))
    #t
    #f))

;; : (-> TestingBuild Path Boolean)
(def (testing-build-gxtest-file-compiled-runnable? build file)
  (and (testing-build-gxtest-file-exported-suite-option build file)
       (not (testing-build-gxtest-file-self-running? build file))
       (testing-build-gxtest-compiled-current? build file)))

;; : (-> TestingBuild Path Boolean)
(def (testing-build-run-gxtest-file/source build file)
  (load file)
  (let (suite (testing-build-gxtest-file-exported-suite-option build file))
    (if (and suite
             (not (testing-build-gxtest-file-self-running? build file)))
      (run-test-suite! (eval suite))
      #t)))

;; : (-> TestingBuild Symbol)
(def (testing-build-output-mode build)
  (testing-object-ref build 'output 'summary))

;; : (-> TestingBuild Boolean)
(def (testing-build-verbose-output? build)
  (eq? (testing-build-output-mode build) 'verbose))

;; : (-> Integer Integer)
(def (testing-build-elapsed-ms start-jiffy)
  (quotient (* (- (current-jiffy) start-jiffy) 1000)
            (jiffies-per-second)))

;; : (-> Exception Port Void)
(def (testing-build-write-exception exn port)
  (parameterize ((dump-stack-trace? #f))
    (display-exception exn port)))

;; : (-> Procedure (Values Boolean String))
(def (testing-build-capture-run thunk)
  (let ((ok? #f)
        (port (open-output-string)))
    (parameterize ((current-output-port port)
                   (current-error-port port))
      (with-catch
       (lambda (exn)
         (set! ok? #f)
         (testing-build-write-exception exn port)
         (newline port))
       (lambda ()
         (set! ok? (thunk)))))
    (values ok? (get-output-string port))))

;; : (-> TestingBuild String Symbol String Integer Void)
(def (testing-build-display-inline-status build name kind status elapsed-ms)
  (unless (eq? (testing-build-output-mode build) 'quiet)
    (display "[asp-gerbil-scheme-test-inline] kind=")
    (display kind)
    (display " name=")
    (display name)
    (display " status=")
    (display status)
    (display " elapsedMs=")
    (display elapsed-ms)
    (newline)
    (force-output)))

;; : (-> TestingBuild String Symbol Integer String Void)
(def (testing-build-display-inline-result build name kind elapsed-ms output)
  (testing-build-display-inline-status build name kind "ok" elapsed-ms)
  (when (and (testing-build-verbose-output? build)
             (> (string-length output) 0))
    (display output)
    (force-output)))

;; : (-> TestingBuild String Symbol Integer String Void)
(def (testing-build-display-inline-failure build name kind elapsed-ms output)
  (display output)
  (testing-build-display-inline-status build name kind "failed" elapsed-ms)
  (force-output))

;; : (-> TestingBuild String Symbol Procedure Boolean)
(def (testing-build-run-captured-inline build name kind thunk)
  (let (start (current-jiffy))
    (let-values (((ok? output)
                  (testing-build-capture-run thunk)))
      (let (elapsed-ms (testing-build-elapsed-ms start))
        (if ok?
          (testing-build-display-inline-result
           build
           name
           kind
           elapsed-ms
           output)
          (testing-build-display-inline-failure
           build
           name
           kind
           elapsed-ms
           output))
        ok?))))

;; : (-> TestingBuild Path Boolean)
(def (testing-build-run-gxtest-file/inline build file)
  (let (suite-symbol
          (or (testing-build-gxtest-file-exported-suite-option build file)
              (testing-build-gxtest-suite-symbol file)))
    (testing-build-run-captured-inline
     build
     file
     'gxtest
     (lambda ()
       (if (testing-build-gxtest-file-compiled-runnable? build file)
         (testing-build-run-gxtest-file/compiled
          build
          file
          suite-symbol)
         (testing-build-run-gxtest-file/source build file))))))

;; : (-> TestingBuild [Path] Boolean Integer)
(def (testing-build-run-policy/inline build files include-policy?)
  (if (and include-policy?
           (testing-build-policy-enabled? build))
    (if (testing-build-run-captured-inline
         build
         "scoped-policy"
         'policy
         (lambda ()
           (run-test-suite!
            (make-policy-test
             (testing-build-contract-root build)
             files))))
      0
      1)
    0))

;; : (-> Path Exception Void)
(def (testing-build-display-gxtest-exception file exn)
  (display "[asp-gerbil-scheme-test-inline] kind=gxtest name=")
  (display file)
  (display " status=failed reason=exception")
  (newline)
  (testing-build-write-exception exn (current-output-port))
  (newline))

;; : (-> TestingBuild Path Integer)
(def (testing-build-run-gxtest-file/status build file)
  (with-catch
   (lambda (exn)
     (testing-build-display-gxtest-exception file exn)
     1)
   (lambda ()
     (if (testing-build-run-gxtest-file/inline build file)
       0
       1))))

;; : (-> TestingBuild [Path] Integer)
(def (testing-build-run-gxtest-files-inline build files)
  (let loop ((rest files))
    (if (null? rest)
      0
      (let (status (testing-build-run-gxtest-file/status build (car rest)))
        (if (= status 0)
          (loop (cdr rest))
          status)))))

;; : (-> TestingBuild [Path] Boolean Integer)
(def (testing-build-run-gxtest-inline build files include-policy?)
  (testing-build-record-gxtest-run! build files)
  (let (status (testing-build-run-gxtest-files-inline build files))
    (if (= status 0)
      (testing-build-run-policy/inline build files include-policy?)
      status)))

;; : (-> TestingBuild Procedure)
(def (testing-build-gxtest-runner build)
  (let (include-policy-file? #t)
    (lambda (files)
      (let (include-policy-file include-policy-file?)
        (set! include-policy-file? #f)
        (testing-build-run-gxtest-inline
         build
         files
         include-policy-file)))))
