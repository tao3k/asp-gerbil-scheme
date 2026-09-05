;;; -*- Gerbil -*-
;;; Testing path, manifest, and suite scope helpers.

(import :gerbil/gambit
        (only-in :std/sugar filter filter-map hash-get hash-put!)
        :asp-gerbil-scheme/src/testing/model)

(export #t)

;; : (-> Datum List Boolean)
(def (testing-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else (testing-member? value (cdr values)))))

;; : (-> Path Path)
(def (testing-normalize-path path)
  (if (and (string? path)
           (testing-string-prefix? "./" path))
    (testing-normalize-path
     (substring path 2 (string-length path)))
    path))

;; SourceFormsCache
(def +testing-scope-file-forms-cache+
  (make-hash-table))

;; : (-> Path Path)
(def (testing-scope-file-cache-key file)
  (testing-normalize-path file))

;; : (-> Path (List Datum))
(def (testing-scope-file-forms file)
  (if (file-exists? file)
    (let* ((key (testing-scope-file-cache-key file))
           (cached (hash-get +testing-scope-file-forms-cache+ key)))
      (if cached
        cached
        (let (forms (call-with-input-file file read-all))
          (hash-put! +testing-scope-file-forms-cache+ key forms)
          forms)))
    []))

;; : (-> Path Path Boolean)
(def (testing-path=? left right)
  (equal? (testing-normalize-path left)
          (testing-normalize-path right)))

;; : (-> Path (List Path) Boolean)
(def (testing-member-path? path values)
  (cond
   ((null? values) #f)
   ((testing-path=? path (car values)) #t)
   (else (testing-member-path? path (cdr values)))))

;; : (-> Datum Symbol Boolean)
(def (testing-form-contains-symbol? form symbol)
  (cond
   ((eq? form symbol) #t)
   ((pair? form)
    (or (testing-form-contains-symbol? (car form) symbol)
        (testing-form-contains-symbol? (cdr form) symbol)))
   (else #f)))

;; : (-> Datum Boolean)
(def (testing-native-gxtest-form? form)
  (or (testing-form-contains-symbol? form 'test-suite)
      (testing-form-contains-symbol? form 'run-tests!)))

;; testing-native-gxtest-file?
;;   : (-> Path Boolean)
;;   | doc m%
;;       `testing-native-gxtest-file?` detects whether a manifest entry already
;;       owns an executable gxtest suite, so expansion stops at that file.
;;
;;       # Examples
;;
;;       ```scheme
;;       (testing-native-gxtest-file? "t/testing-framework-test.ss")
;;       ;; => #t
;;       ```
;;     %
(def (testing-native-gxtest-file? file)
  (testing-any? testing-native-gxtest-form?
                (testing-scope-file-forms file)))

;; : (-> Procedure List List)
(def (testing-filter-map proc values)
  (filter-map proc values))

;; : (-> Procedure List List)
(def (testing-filter proc values)
  (filter proc values))

;; : (-> Procedure List Boolean)
(def (testing-andmap proc values)
  (cond
   ((null? values) #t)
   ((proc (car values)) (testing-andmap proc (cdr values)))
   (else #f)))

;; : (-> Procedure List Boolean)
(def (testing-any? proc values)
  (cond
   ((null? values) #f)
   ((proc (car values)) #t)
   (else (testing-any? proc (cdr values)))))

;; : (-> String String Boolean)
(def (testing-string-prefix? prefix value)
  (let ((prefix-length (string-length prefix))
        (value-length (string-length value)))
    (and (>= value-length prefix-length)
         (string=? (substring value 0 prefix-length) prefix))))

;; : (-> String String Boolean)
(def (testing-string-suffix? suffix value)
  (let ((suffix-length (string-length suffix))
        (value-length (string-length value)))
    (and (>= value-length suffix-length)
         (string=? (substring value
                              (- value-length suffix-length)
                              value-length)
                   suffix))))

;; : (-> Datum Boolean)
(def (testing-ss-file-arg? arg)
  (and (string? arg)
       (testing-string-suffix? ".ss" arg)))

;; : (-> GxTestSuite Datum (List Path))
(def (testing-import-form-imports suite form)
  (if (and (pair? form)
           (eq? (car form) 'import))
    (testing-filter-map
     (testing-suite-import->file suite)
     (cdr form))
    []))

;; : (-> GxTestSuite Path (List Path))
(def (testing-read-test-file-imports suite file)
  (let (forms (testing-scope-file-forms file))
    (if (pair? forms)
      (testing-import-form-imports suite (car forms))
      [])))

;; : (-> GxTestSuite (List Path) (List Path) (List Path))
(def (testing-expand-manifest-files suite files seen)
  (apply append
         (map (lambda (file)
                (testing-expand-manifest-file suite file seen))
              files)))

;; : (-> GxTestSuite Path (List Path))
(def (testing-expand-manifest-file suite file (seen []))
  (cond
   ((testing-member? file seen) (list file))
   ((testing-native-gxtest-file? file) (list file))
   (else
    (let (imported (testing-read-test-file-imports suite file))
      (if (not (null? imported))
        (testing-expand-manifest-files
         suite
         imported
         (cons file seen))
        (list file))))))

;; : (-> TestingSuite Path Boolean)
(def (testing-suite-root? suite file)
  (testing-member-path? file (testing-suite-roots suite)))

;; : (-> Path Path Boolean)
(def (testing-arg-under-root? root arg)
  (let ((root (testing-normalize-path root))
        (arg (testing-normalize-path arg)))
    (and (string? root)
         (string? arg)
         (or (equal? root arg)
             (testing-string-prefix?
              (string-append root "/")
              arg)))))

;; : (-> TestingSuite Path Boolean)
(def (testing-arg-under-suite-root? suite arg)
  (testing-any?
   (lambda (root)
     (testing-arg-under-root? root arg))
   (testing-suite-roots suite)))

;; : (-> GxTestSuite Path Boolean)
(def (testing-gxtest-file-in-suite? suite arg)
  (and (testing-string-suffix? ".ss" arg)
       (or (testing-arg-under-suite-root? suite arg)
           (testing-member-path? arg (testing-suite-default-files suite)))))

;; : (-> GxTestSuite (List Path))
(def (testing-suite-default-files suite)
  (let (files (testing-suite-files suite))
    (cond
     ((eq? files 'auto)
      (let (root (testing-suite-default-root suite))
        (if root
          (testing-expand-manifest-file suite root)
          [])))
     ((list? files) files)
     (else []))))

;; : (-> GxTestSuite Path Boolean)
(def (testing-suite-name-arg? suite arg)
  (equal? arg (testing-suite-name suite)))

;; : (-> GxTestSuite (List Path) Boolean)
(def (testing-suite-name-arg-selected? suite args)
  (testing-any? (lambda (arg)
                  (testing-suite-name-arg? suite arg))
                args))

;; : (-> GxTestSuite (List Path) (List Path))
(def (testing-suite-root-args suite args)
  (testing-filter (lambda (arg)
                    (testing-suite-root? suite arg))
                  args))

;; : (-> GxTestSuite (List Path) (List Path))
(def (testing-suite-file-args suite args)
  (testing-filter (lambda (arg)
                    (testing-gxtest-file-in-suite? suite arg))
                  args))

;; : (-> GxTestSuite (List Path) (List Path))
(def (testing-expand-suite-scoped-args suite args)
  (let (root-args (testing-suite-root-args suite args))
    (if (not (null? root-args))
      (testing-expand-manifest-files suite root-args [])
      (let (file-args (testing-suite-file-args suite args))
        (if (not (null? file-args))
          file-args
          args)))))

;; : (-> GxTestSuite (List Path) (List Path))
(def (testing-expand-suite-args suite args)
  (cond
   ((null? args)
    (testing-suite-default-files suite))
   ((testing-suite-name-arg-selected? suite args)
    (testing-suite-default-files suite))
   (else
    (testing-expand-suite-scoped-args suite args))))
