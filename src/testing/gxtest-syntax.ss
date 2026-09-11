;;; -*- Gerbil -*-
;;; Source-form and suite syntax facts for gxtest discovery.

(import (only-in :std/misc/path path-expand)
        (only-in :std/srfi/1 append-map every find)
        (only-in :std/srfi/13 string-suffix?)
        (only-in :std/sugar filter-map hash-get hash-put!)
        (only-in "./gxtest-context"
                 package-root
                 package-name
                 ensure-build-root!
                 module-path-stem)
        :gerbil/gambit)

(export gxtest-export-symbols
        gxtest-file-forms-path
        gxtest-file-forms
        gxtest-file-exported-symbols
        gxtest-file-exported-suite?
        gxtest-file-exported-suite
        gxtest-file-self-running?
        gxtest-file-local-suite?
        gxtest-files-local-suite?
        gxtest-file-module-symbol)

;; : (-> Datum (List Symbol))
(def (gxtest-export-symbols form)
  (if (and (pair? form)
           (eq? (car form) 'export))
    (filter-map (lambda (item)
                  (and (symbol? item) item))
                (cdr form))
    []))

;; : (-> Port (List Datum))
(def (gxtest-read-forms port)
  (read-all port))

;; : HashTable
(def +gxtest-file-forms-cache+
  (make-hash-table))

;; : (-> Path Path)
(def (gxtest-file-forms-path file)
  (ensure-build-root!)
  (path-expand file package-root))

;; gxtest-file-forms
;;   : (-> Path (List Datum))
;;   | doc m%
;;       `gxtest-file-forms` reads a package-relative Gerbil source file once
;;       and caches its raw forms for syntax-level discovery.  Downstream
;;       callers use this as a source fact, not as a policy decision.
;;
;;       # Examples
;;
;;       ```scheme
;;       (pair? (gxtest-file-forms "t/package-build-contract-test.ss"))
;;       ;; => #t
;;       ```
;;     %
(def (gxtest-file-forms file)
  (let* ((path (gxtest-file-forms-path file))
         (cached (hash-get +gxtest-file-forms-cache+ path)))
    (if cached
      cached
      (let (forms
            (call-with-input-file path gxtest-read-forms))
        (hash-put! +gxtest-file-forms-cache+ path forms)
        forms))))

;; : (-> Symbol Boolean)
(def (gxtest-suite-symbol? symbol)
  (string-suffix? "-test" (symbol->string symbol)))

;; : (-> Path (List Symbol))
(def (gxtest-file-exported-symbols file)
  (append-map gxtest-export-symbols
              (gxtest-file-forms file)))

;; : (-> Path Boolean)
(def (gxtest-file-exported-suite? file)
  (if (pair? (gxtest-file-exported-symbols file)) #t #f))

;; gxtest-file-exported-suite
;;   : (-> Path Symbol)
;;   | doc m%
;;       `gxtest-file-exported-suite` selects the suite binding exported by a
;;       gxtest file.  A `*-test` export wins; otherwise the first exported
;;       symbol remains the compatibility surface for existing tests.
;;
;;       # Examples
;;
;;       ```scheme
;;       (symbol? (gxtest-file-exported-suite "t/package-build-contract-test.ss"))
;;       ;; => #t
;;       ```
;;     %
(def (gxtest-file-exported-suite file)
  (let* ((symbols (gxtest-file-exported-symbols file))
         (suite (or (find gxtest-suite-symbol? symbols)
                    (and (pair? symbols) (car symbols)))))
    (or suite
        (error "gxtest file must export a test suite" file))))

;; : (-> Datum Boolean)
(def (gxtest-self-running-form? form)
  (and (pair? form)
       (eq? (car form) 'run-tests!)))

;; : (-> Path Boolean)
(def (gxtest-file-self-running? file)
  (if (find gxtest-self-running-form? (gxtest-file-forms file)) #t #f))

;; : (-> Datum (U Symbol False))
(def (gxtest-def-symbol form)
  (and (pair? form)
       (eq? (car form) 'def)
       (pair? (cdr form))
       (let (head (cadr form))
         (cond
          ((symbol? head) head)
          ((and (pair? head) (symbol? (car head))) (car head))
          (else #f)))))

;; : (-> Path (List Symbol))
(def (gxtest-file-local-def-symbols file)
  (filter-map gxtest-def-symbol
              (gxtest-file-forms file)))

;; gxtest-file-local-suite?
;;   : (-> Path Boolean)
;;   | doc m%
;;       `gxtest-file-local-suite?` checks whether a gxtest file's exported
;;       suite is defined locally.  The runner uses this fact to choose the fast
;;       compiled in-process path without guessing from file names.
;;     %
(def (gxtest-file-local-suite? file)
  (and (gxtest-file-exported-suite? file)
       (member (gxtest-file-exported-suite file)
               (gxtest-file-local-def-symbols file))))

;; : (-> (List Path) Boolean)
(def (gxtest-files-local-suite? files)
  (if (every gxtest-file-local-suite? files) #t #f))

;; : (-> Path Symbol)
(def (gxtest-file-module-symbol file)
  (unless package-name
    (error "gerbil.pkg must declare package: for gxtest module import"))
  (string->symbol
   (string-append ":"
                  package-name
                  "/"
                  (module-path-stem file))))
