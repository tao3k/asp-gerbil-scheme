;;; -*- Gerbil -*-
;;; Reusable benchmark.ss framework helpers for downstream gxtest gates.

(import :gerbil/gambit
        (only-in :std/sort sort)
        :asp-gerbil-scheme/src/benchmark/gate)

(export #t)

(def +benchmark-contract-file+ "benchmark.ss")

;; : (-> Path Path)
(def (benchmark-contract-path root)
  (path-expand +benchmark-contract-file+ root))

;; : (-> Path Alist)
(def (benchmark-contract-read path)
  (call-with-input-file path read))

;; : (-> Path Alist)
(def (benchmark-contract-read/root root)
  (benchmark-contract-read (benchmark-contract-path root)))

;; : (-> Alist Symbol Value)
(def (benchmark-contract-value datum key)
  (let loop ((rest datum))
    (cond
     ((null? rest) #f)
     ((eq? (caar rest) key) (cdar rest))
     (else (loop (cdr rest))))))

;; : (-> Path Boolean)
(def (benchmark-contract-valid? path)
  (benchmark-fixture-contract-pass?
   (benchmark-contract-read path)))

;; : (-> Path Boolean)
(def (benchmark-contract-valid/root? root)
  (benchmark-contract-valid? (benchmark-contract-path root)))

;; : (-> Path (-> Value) Alist)
(def (benchmark-contract-run path thunk)
  (benchmark-run (benchmark-contract-read path) thunk))

;; : (-> Path (-> Value) Alist)
(def (benchmark-contract-run/root root thunk)
  (benchmark-contract-run (benchmark-contract-path root) thunk))

;; : (-> Alist Boolean)
(def (benchmark-contract-receipt-pass? receipt)
  (benchmark-receipt-pass? receipt))

;; : (-> Path Boolean)
(def (benchmark-contract-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

;; : (-> String Boolean)
(def (benchmark-contract-directory-entry? entry)
  (not (or (equal? entry ".")
           (equal? entry ".."))))

;; : (-> Path Boolean)
(def (benchmark-contract-path? path)
  (or (equal? path +benchmark-contract-file+)
      (benchmark-string-suffix?
       path
       (string-append "/" +benchmark-contract-file+))))

;; : (-> Path Path)
(def (benchmark-contract-root-for-path path)
  (if (benchmark-string-suffix?
       path
       (string-append "/" +benchmark-contract-file+))
    (substring path
               0
               (- (string-length path)
                  (+ 1 (string-length +benchmark-contract-file+))))
    path))

;; : (-> Path (List Path))
(def (benchmark-contract-paths/root root)
  (let (paths [])
    (def (walk dir)
      (for-each
       (lambda (entry)
         (let (path (path-expand entry dir))
           (cond
            ((not (benchmark-contract-directory-entry? entry))
             #!void)
            ((benchmark-contract-directory? path)
             (walk path))
            ((equal? entry +benchmark-contract-file+)
             (set! paths (cons path paths)))
            (else #!void))))
       (sort (directory-files dir) string<?)))
    (walk root)
    (reverse paths)))

;; : (-> Path Boolean)
(def (benchmark-contract-input-expected-pass? benchmark-path)
  (let (root (benchmark-contract-root-for-path benchmark-path))
    (and (benchmark-contract-directory? (path-expand "input" root))
         (benchmark-contract-directory? (path-expand "expected" root)))))

;; : (-> String (List String) Boolean)
(def (benchmark-string-list-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else (benchmark-string-list-member? value (cdr values)))))

;; : (-> String String Boolean)
(def (benchmark-string-contains-fragment? text fragment)
  (if (string-contains text fragment)
    #t
    #f))

;; : (-> String (List String) Boolean)
(def (benchmark-string-contains-any-fragment? text fragments)
  (cond
   ((null? fragments) #f)
   ((benchmark-string-contains-fragment? text (car fragments)) #t)
   (else (benchmark-string-contains-any-fragment? text (cdr fragments)))))

;; : (-> Path Boolean)
(def (benchmark-source-directory? path)
  (benchmark-contract-directory? path))

;; : (-> String Boolean)
(def (benchmark-source-directory-entry? entry)
  (benchmark-contract-directory-entry? entry))

;; : (-> String String Boolean)
(def (benchmark-string-suffix? text suffix)
  (let ((text-length (string-length text))
        (suffix-length (string-length suffix)))
    (and (>= text-length suffix-length)
         (string=? (substring text
                              (- text-length suffix-length)
                              text-length)
                   suffix))))

;; : (-> Path (List Path))
(def (benchmark-source-files root)
  (let (paths [])
    (def (walk dir)
      (for-each
       (lambda (entry)
         (let (path (path-expand entry dir))
           (cond
            ((not (benchmark-source-directory-entry? entry))
             #!void)
            ((benchmark-source-directory? path)
             (walk path))
            ((benchmark-string-suffix? entry ".ss")
             (set! paths (cons path paths)))
            (else #!void))))
       (sort (directory-files dir) string<?)))
    (walk root)
    (reverse paths)))

;; : (-> Path String)
(def (benchmark-read-source-file path)
  (call-with-input-file path
    (lambda (port)
      (call-with-output-string
       []
       (lambda (out)
         (let loop ()
           (let (line (read-line port))
             (unless (eof-object? line)
               (display line out)
               (newline out)
               (loop)))))))))

;; : (-> Path String)
(def (benchmark-source-tree-text root)
  (apply string-append
         (map benchmark-read-source-file
              (benchmark-source-files root))))
