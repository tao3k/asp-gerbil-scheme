;;; -*- Gerbil -*-
;;; Reusable package build freshness receipts.

(import :gerbil/gambit
        (only-in :std/sugar with-catch))

(export asp-gerbil-scheme-package-build-receipt-version
        asp-gerbil-scheme-package-build-receipt-write
        asp-gerbil-scheme-package-build-receipt-read
        asp-gerbil-scheme-package-build-receipt-current?
        asp-gerbil-scheme-package-build-receipt-source-output-current?
        asp-gerbil-scheme-package-build-receipt-status
        asp-gerbil-scheme-package-build-receipt-status-ref
        asp-gerbil-scheme-package-build-receipt-status-line)

;; : Symbol
(def asp-gerbil-scheme-package-build-receipt-version 'asp-gerbil-scheme-package-build-receipt.v1)

;; : (forall (k v) (-> [(Pair k v)] k v v))
;; asp-gerbil-scheme-package-build-receipt-ref
;; : (-> Alist Symbol Datum Datum)
(def (asp-gerbil-scheme-package-build-receipt-ref receipt key default)
  (let (entry (assq key receipt))
    (if entry (cdr entry) default)))

;; asp-gerbil-scheme-package-build-receipt-path-list?
;;   : (-> ReceiptPathListCandidate Boolean)
;;   | doc m%
;;       `asp-gerbil-scheme-package-build-receipt-path-list?` validates the receipt path
;;       list shape before freshness checks inspect the filesystem.
;;
;;       # Examples
;;
;;       ```scheme
;;       (asp-gerbil-scheme-package-build-receipt-path-list? ["src/a.ss"])
;;       ;; => #t
;;       ```
;;     %
(def (asp-gerbil-scheme-package-build-receipt-path-list? value)
  (and (list? value)
       (andmap string? value)))

;; : (-> Path Integer)
(def (asp-gerbil-scheme-package-build-receipt-file-seconds path)
  (time->seconds (file-info-last-modification-time (file-info path))))

;; : (-> Path Path Boolean)
(def (asp-gerbil-scheme-package-build-receipt-file-newer-than? path stamp)
  (> (asp-gerbil-scheme-package-build-receipt-file-seconds path)
     (asp-gerbil-scheme-package-build-receipt-file-seconds stamp)))

;; asp-gerbil-scheme-package-build-receipt-all-exist?
;;   : (-> (List Path) Boolean)
;;   | doc m%
;;       `asp-gerbil-scheme-package-build-receipt-all-exist?` owns the output existence
;;       predicate for receipt freshness.
;;
;;       # Examples
;;
;;       ```scheme
;;       (asp-gerbil-scheme-package-build-receipt-all-exist? outputs)
;;       ;; => #t
;;       ```
;;     %
(def (asp-gerbil-scheme-package-build-receipt-all-exist? paths)
  (andmap file-exists? paths))

;; : (forall (p m) (-> p [p] [p] Symbol m Void))
;; asp-gerbil-scheme-package-build-receipt-write
;; : (-> Path (List Path) (List Path) Symbol Alist Void)
(def (asp-gerbil-scheme-package-build-receipt-write stamp sources outputs
                                        version: (version asp-gerbil-scheme-package-build-receipt-version)
                                        metadata: (metadata []))
  (call-with-output-file stamp
    (lambda (port)
      (write (append
              `((version . ,version)
                (sources . ,sources)
                (outputs . ,outputs))
              metadata)
             port)
      (newline port))))

;; : (-> Path version: Symbol (Maybe Alist))
(def (asp-gerbil-scheme-package-build-receipt-read/raw stamp
                                           version: (version asp-gerbil-scheme-package-build-receipt-version))
  (and (file-exists? stamp)
       (with-catch
        (lambda (_) #f)
        (lambda ()
          (let* ((receipt (call-with-input-file stamp read))
                 (receipt-version
                  (and (list? receipt)
                       (asp-gerbil-scheme-package-build-receipt-ref receipt 'version #f)))
                 (sources
                  (and (list? receipt)
                       (asp-gerbil-scheme-package-build-receipt-ref receipt 'sources #f)))
                 (outputs
                  (and (list? receipt)
                       (asp-gerbil-scheme-package-build-receipt-ref receipt 'outputs #f))))
            (and (eq? receipt-version version)
                 (asp-gerbil-scheme-package-build-receipt-path-list? sources)
                 (asp-gerbil-scheme-package-build-receipt-path-list? outputs)
                 receipt))))))

;; : (-> Path version: Symbol (Maybe Pair))
(def (asp-gerbil-scheme-package-build-receipt-read stamp
                                       version: (version asp-gerbil-scheme-package-build-receipt-version))
  (let (receipt (asp-gerbil-scheme-package-build-receipt-read/raw stamp version: version))
    (and receipt
         (cons (asp-gerbil-scheme-package-build-receipt-ref receipt 'sources [])
               (asp-gerbil-scheme-package-build-receipt-ref receipt 'outputs [])))))

;; : (-> (List Path) (List Path) Boolean)
(def (asp-gerbil-scheme-package-build-receipt-populated? sources outputs)
  (and (pair? sources) (pair? outputs)))

;; : (-> (List Path) (List Path) MaybePathList MaybePathList Boolean)
(def (asp-gerbil-scheme-package-build-receipt-expected-shape? sources outputs
                                                   expected-sources
                                                   expected-outputs)
  (and (or (not expected-sources) (equal? sources expected-sources))
       (or (not expected-outputs) (equal? outputs expected-outputs))))

;; : (-> Path Path Boolean)
(def (asp-gerbil-scheme-package-build-receipt-source-current? stamp source)
  (and (file-exists? source)
       (not (asp-gerbil-scheme-package-build-receipt-file-newer-than? source stamp))))

;; : (-> Path Path Boolean)
(def (asp-gerbil-scheme-package-build-receipt-source-output-current? source output)
  (and (file-exists? source)
       (file-exists? output)
       (not (asp-gerbil-scheme-package-build-receipt-file-newer-than? source output))))

;; : (-> Path (List Path) Boolean)
(def (asp-gerbil-scheme-package-build-receipt-sources-current? stamp sources)
  (cond
   ((null? sources) #t)
   ((asp-gerbil-scheme-package-build-receipt-source-current? stamp (car sources))
    (asp-gerbil-scheme-package-build-receipt-sources-current? stamp (cdr sources)))
   (else #f)))

;; asp-gerbil-scheme-package-build-receipt-current?
;;   : (-> Path Pair expected-sources: MaybePathList expected-outputs: MaybePathList Boolean)
;;   | doc m%
;;       `asp-gerbil-scheme-package-build-receipt-current?` checks receipt shape, expected
;;       source/output lists, output existence, and source freshness.
;;
;;       # Examples
;;
;;       ```scheme
;;       (asp-gerbil-scheme-package-build-receipt-current? stamp receipt)
;;       ;; => #t
;;       ```
;;     %
(def (asp-gerbil-scheme-package-build-receipt-current? stamp receipt
                                           expected-sources: (expected-sources #f)
                                           expected-outputs: (expected-outputs #f))
  (let ((sources (car receipt))
        (outputs (cdr receipt)))
    (and (asp-gerbil-scheme-package-build-receipt-populated? sources outputs)
         (asp-gerbil-scheme-package-build-receipt-expected-shape? sources
                                                      outputs
                                                      expected-sources
                                                      expected-outputs)
         (asp-gerbil-scheme-package-build-receipt-all-exist? outputs)
         (asp-gerbil-scheme-package-build-receipt-sources-current? stamp sources))))

;; : (-> Symbol Symbol Path (Maybe Pair) Alist)
(def (asp-gerbil-scheme-package-build-receipt-debug-metadata receipt)
  (if receipt
    (filter
     (lambda (entry)
       (not (memq (car entry) '(version sources outputs))))
     receipt)
    []))

;; : (-> Symbol (Maybe Symbol) Path (Maybe Pair) Alist Alist)
(def (asp-gerbil-scheme-package-build-receipt-make-status status reason stamp receipt
                                             metadata: (metadata []))
  (append
   `((status . ,status)
     (reason . ,reason)
     (sources . ,(if receipt (length (car receipt)) 0))
     (outputs . ,(if receipt (length (cdr receipt)) 0))
     (stamp . ,stamp))
   metadata))

;; : (-> Path version: Symbol expected-sources: MaybePathList expected-outputs: MaybePathList Alist)
(def (asp-gerbil-scheme-package-build-receipt-status stamp
                                         version: (version asp-gerbil-scheme-package-build-receipt-version)
                                         expected-sources: (expected-sources #f)
                                         expected-outputs: (expected-outputs #f))
  (cond
   ((not (file-exists? stamp))
    (asp-gerbil-scheme-package-build-receipt-make-status 'stale 'missing-stamp stamp #f))
   (else
    (let* ((raw-receipt
            (asp-gerbil-scheme-package-build-receipt-read/raw stamp version: version))
           (receipt
            (and raw-receipt
                 (cons (asp-gerbil-scheme-package-build-receipt-ref raw-receipt 'sources [])
                       (asp-gerbil-scheme-package-build-receipt-ref raw-receipt 'outputs []))))
           (metadata
            (asp-gerbil-scheme-package-build-receipt-debug-metadata raw-receipt)))
      (cond
       ((not receipt)
        (asp-gerbil-scheme-package-build-receipt-make-status 'stale 'invalid-stamp stamp #f))
       ((asp-gerbil-scheme-package-build-receipt-current? stamp receipt
                                             expected-sources: expected-sources
                                             expected-outputs: expected-outputs)
        (asp-gerbil-scheme-package-build-receipt-make-status
         'current #f stamp receipt metadata: metadata))
       (else
        (asp-gerbil-scheme-package-build-receipt-make-status
         'stale
         (if (or (and expected-sources (not (equal? (car receipt) expected-sources)))
                 (and expected-outputs (not (equal? (cdr receipt) expected-outputs))))
           'receipt-shape-mismatch
           'dirty-source-or-missing-output)
         stamp
         receipt
         metadata: metadata)))))))

;; : (-> Alist Symbol Value Value)
(def (asp-gerbil-scheme-package-build-receipt-status-ref status key default)
  (asp-gerbil-scheme-package-build-receipt-ref status key default))

;; : (-> Alist String)
(def (asp-gerbil-scheme-package-build-receipt-status-line status)
  (string-append
   "[asp-gerbil-scheme-package-build-receipt]"
   " status=" (symbol->string (asp-gerbil-scheme-package-build-receipt-status-ref status 'status 'unknown))
   " sources=" (number->string (asp-gerbil-scheme-package-build-receipt-status-ref status 'sources 0))
   " outputs=" (number->string (asp-gerbil-scheme-package-build-receipt-status-ref status 'outputs 0))
   " stamp=" (object->string (asp-gerbil-scheme-package-build-receipt-status-ref status 'stamp ""))))
