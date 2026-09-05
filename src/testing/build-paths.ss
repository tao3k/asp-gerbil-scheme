;;; -*- Gerbil -*-
;;; Path and module-name helpers for downstream testing builds.

(import :gerbil/gambit
        (only-in :std/misc/path path-strip-directory)
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/framework)

(export #t)

;; : (-> TestingBuild Path Path)
(def (testing-build-path build relative)
  (let (root (testing-object-ref build 'root "."))
    (if (and (not (equal? root "."))
             (or (equal? relative root)
                 (testing-string-prefix?
                  (string-append root "/")
                  relative)))
      relative
      (path-expand relative root))))

;; : (-> TestingBuild Path)
(def (testing-build-contract-root build)
  (testing-object-ref build 'contractRoot
                      (testing-object-ref build 'root ".")))

;; : (-> String String)
(def (testing-build-default-import-prefix package-name)
  (string-append ":" package-name "/t/"))

;; : (-> TestingBuild MaybeString)
(def (testing-build-import-prefix build)
  (or (testing-object-ref build 'importPrefix #f)
      (let (package-name (testing-object-ref build 'packageName #f))
        (and package-name
             (testing-build-default-import-prefix package-name)))))

;; : (-> TestingBuild String MaybePath)
(def (testing-build-prefixed-import->file build module-name)
  (let (prefix (testing-build-import-prefix build))
    (and prefix
         (testing-string-prefix? prefix module-name)
         (string-append
          "t/"
          (substring module-name
                     (string-length prefix)
                     (string-length module-name))
          ".ss"))))

;; : (-> TestingBuild Datum MaybePath)
(def (testing-build-import->file build import)
  (cond
   ((string? import)
    (testing-build-path build (string-append "t/" import)))
   ((symbol? import)
    (let (file (testing-build-prefixed-import->file
                build
                (symbol->string import)))
      (and file (testing-build-path build file))))
   (else #f)))

;; : (-> Datum String)
(def (testing-build-gxtest-name spec)
  (cond
   ((string? spec) spec)
   ((and (pair? spec) (string? (car spec))) (car spec))
   (else "gxtest")))

;; : (-> Datum Path)
(def (testing-build-gxtest-root spec)
  (cond
   ((string? spec) spec)
   ((and (pair? spec) (pair? (cdr spec))) (cadr spec))
   (else spec)))

;; : (-> Path String)
(def (testing-build-basename path)
  (path-strip-directory path))

;; : (-> Path String)
(def (testing-build-file-stem file)
  (let (base (testing-build-basename file))
    (if (testing-string-suffix? ".ss" base)
      (substring base 0 (- (string-length base) 3))
      base)))

;; : (-> Path Symbol)
(def (testing-build-gxtest-suite-symbol file)
  (string->symbol (testing-build-file-stem file)))

;; : (-> Path Path)
(def (testing-build-trim-leading-dot-slash path)
  (if (testing-string-prefix? "./" path)
    (substring path 2 (string-length path))
    path))

;; : (-> Path String String Path)
(def (testing-build-replace-suffix path suffix replacement)
  (if (testing-string-suffix? suffix path)
    (string-append
     (substring path 0 (- (string-length path) (string-length suffix)))
     replacement)
    path))

;; : (-> Datum String)
(def (testing-build-datum-string datum)
  (call-with-output-string
   (lambda (port)
     (write datum port))))

;; : (-> TestingBuild Path Symbol)
(def (testing-build-gxtest-module-symbol build file)
  (let* ((package-name (testing-object-ref build 'packageName
                                           (testing-object-ref build 'name)))
         (module-path
          (testing-build-replace-suffix
           (testing-build-trim-leading-dot-slash file)
           ".ss"
           "")))
    (string->symbol
     (string-append ":" package-name "/" module-path))))

;; : (-> TestingBuild Path Symbol String)
(def (testing-build-gxtest-compiled-expression build file suite-symbol)
  (string-append
   "(begin"
   " (import :std/test (only-in "
   (testing-build-datum-string
    (testing-build-gxtest-module-symbol build file))
   " "
   (testing-build-datum-string suite-symbol)
   "))"
   " (run-test-suite! "
   (testing-build-datum-string suite-symbol)
   ")"
   ")"))
