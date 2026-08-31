;;; -*- Gerbil -*-
;;; Gxtest build receipt paths, expected artifacts, and stamp writes.

(import (only-in :std/misc/path path-directory path-expand)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-join string-prefix? string-suffix?)
        (only-in "../build-api/package-receipt"
                 asp-gerbil-scheme-package-build-receipt-status
                 asp-gerbil-scheme-package-build-receipt-status-line
                 asp-gerbil-scheme-package-build-receipt-status-ref
                 asp-gerbil-scheme-package-build-receipt-write)
        (only-in "../build-api/package-spec"
                 asp-gerbil-scheme-package-api-spec)
        (only-in "./gxtest-context"
                 package-root
                 source-root
                 source-output-prefix
                 test-output-prefix
                 module-path-stem
                 gxtest-test-module-path
                 gxtest-source-module-path)
        (only-in "./gxtest-discovery"
                 gxtest-selected-source-files)
        :gerbil/gambit)

(export ensure-directory!
        file-set-cache-key
        package-api-build-current?
        package-api-build-output-files
        package-api-build-receipt-path
        package-api-build-receipt-status
        package-api-build-source-files
        selected-gxtest-build-current?
        selected-gxtest-build-output-files
        selected-gxtest-build-receipt-path
        selected-gxtest-build-receipt-status
        selected-gxtest-build-source-files
        display-package-api-build-receipt-status
        write-package-api-build-receipt!
        write-selected-gxtest-build-receipt!)

;; : (-> Path)
(def (package-api-output-root)
  (path-expand (source-output-prefix)
               (path-expand ".gerbil/lib" package-root)))

;; : (-> Path)
(def (package-api-build-receipt-path)
  (path-expand ".gerbil/build/package-api.receipt" package-root))

;; file-set-cache-key
;;   : (-> (List Path) String)
;;   | doc m%
;;       `file-set-cache-key` derives a stable receipt cache key from the
;;       selected relative file set.  Callers use it only for build stamps, not
;;       for cryptographic identity.
;;
;;       # Examples
;;
;;       ```scheme
;;       (string? (file-set-cache-key ["t/a-test.ss" "t/b-test.ss"]))
;;       ;; => #t
;;       ```
;;     %
(def (file-set-cache-key files)
  (let* ((scope (string-join (sort files string<?) "\n"))
         (limit 4294967296))
    (let loop ((chars (string->list scope))
               (hash 2166136261))
      (if (null? chars)
        (number->string hash 16)
        (loop (cdr chars)
              (modulo (* (bitwise-xor hash (char->integer (car chars)))
                         16777619)
                      limit))))))

;; : (-> (List Path) Path)
(def (selected-gxtest-build-receipt-path (files []))
  (path-expand
   (string-append ".gerbil/build/selected-gxtest/"
                  (file-set-cache-key files)
                  ".receipt")
   package-root))

;; : (-> (List Path))
(def (package-api-build-source-files)
  (map (lambda (module)
         (path-expand module source-root))
       (asp-gerbil-scheme-package-api-spec)))

;; : (-> (List Path))
(def (package-api-build-output-files)
  (map (lambda (module)
         (path-expand
          (string-append (module-path-stem module) ".ssi")
          (package-api-output-root)))
       (asp-gerbil-scheme-package-api-spec)))

;; : (-> (List Path) (List Path))
(def (selected-gxtest-build-source-files files)
  (map (lambda (file)
         (path-expand file package-root))
       (gxtest-selected-source-files files)))

;; : (-> (List Path) (List Path))
(def (selected-gxtest-build-output-files files)
  (map (lambda (file)
         (cond
          ((string-prefix? "src/" file)
           (path-expand
            (string-append
             (module-path-stem (gxtest-source-module-path file))
             ".ssi")
            (path-expand (source-output-prefix)
                         (path-expand ".gerbil/lib" package-root))))
          ((string-prefix? "t/" file)
           (path-expand
            (string-append
             (module-path-stem (gxtest-test-module-path file))
             ".ssi")
            (path-expand (test-output-prefix)
                         (path-expand ".gerbil/lib" package-root))))
          (else
           (error "selected gxtest source file must be under src/ or t/" file))))
       (gxtest-selected-source-files files)))

;; : (-> BuildReceiptStatus)
(def (package-api-build-receipt-status)
  (asp-gerbil-scheme-package-build-receipt-status
   (package-api-build-receipt-path)
   expected-sources: (package-api-build-source-files)
   expected-outputs: (package-api-build-output-files)))

;; : (-> (List Path) BuildReceiptStatus)
(def (selected-gxtest-build-receipt-status files)
  (asp-gerbil-scheme-package-build-receipt-status
   (selected-gxtest-build-receipt-path files)
   expected-sources: (selected-gxtest-build-source-files files)
   expected-outputs: (selected-gxtest-build-output-files files)))

;; : (-> BuildReceiptStatus Boolean)
(def (package-api-build-current? status)
  (eq? (asp-gerbil-scheme-package-build-receipt-status-ref status 'status 'unknown)
       'current))

;; : (-> BuildReceiptStatus Boolean)
(def (selected-gxtest-build-current? status)
  (eq? (asp-gerbil-scheme-package-build-receipt-status-ref status 'status 'unknown)
       'current))

;; : (-> BuildReceiptStatus Void)
(def (display-package-api-build-receipt-status status)
  (display (asp-gerbil-scheme-package-build-receipt-status-line status))
  (newline)
  (force-output))

;; : (-> Path Path)
(def (normalize-directory-path path)
  (let trim ((end (string-length path)))
    (if (and (> end 1)
             (char=? (string-ref path (- end 1)) #\/))
      (trim (- end 1))
      (substring path 0 end))))

;; : (-> Void)
(def (ensure-directory! path)
  (let (directory (normalize-directory-path path))
    (unless (file-exists? directory)
      (let (parent (path-directory directory))
        (when (and parent
                   (not (string=? parent ""))
                   (not (string=? parent directory)))
          (ensure-directory! parent))
        (create-directory directory)))))

;; : (-> Void)
(def (write-package-api-build-receipt!)
  (let (stamp (package-api-build-receipt-path))
    (ensure-directory! (path-directory stamp))
    (asp-gerbil-scheme-package-build-receipt-write
     stamp
     (package-api-build-source-files)
     (package-api-build-output-files))))

;; : (-> (List Path) [Maybe Alist] Void)
(def (write-selected-gxtest-build-receipt! files (metadata []))
  (let (stamp (selected-gxtest-build-receipt-path files))
    (ensure-directory! (path-directory stamp))
    (asp-gerbil-scheme-package-build-receipt-write
     stamp
     (selected-gxtest-build-source-files files)
     (selected-gxtest-build-output-files files)
     metadata: metadata)))
