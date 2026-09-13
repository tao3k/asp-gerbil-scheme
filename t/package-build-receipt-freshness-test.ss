;;; -*- Gerbil -*-
;;; Slow freshness tests for second-granularity filesystem mtimes.

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-directory path-expand)
        "../src/build-api/package-receipt")

(export package-build-receipt-freshness-test)

;; : Path
(def +package-build-receipt-freshness-test-root+
  (path-expand ".cache/agent-semantic-protocol/test/package-build-receipt-freshness"
               (current-directory)))

;; : (-> Path Path)
(def (package-build-receipt-strip-trailing-slashes path)
  (let lp ((end (string-length path)))
    (if (and (> end 1)
             (char=? (string-ref path (- end 1)) #\/))
      (lp (- end 1))
      (substring path 0 end))))

;; : (-> Path Void)
(def (package-build-receipt-ensure-directory* path)
  (let (path (and path (package-build-receipt-strip-trailing-slashes path)))
    (when path
      (unless (or (string=? path "")
                  (string=? path ".")
                  (file-exists? path))
        (let (parent (path-directory path))
          (when (and parent (not (string=? parent path)))
            (package-build-receipt-ensure-directory* parent)))
        (unless (file-exists? path)
          (create-directory path))))))

;; : (-> Path String Void)
(def (package-build-receipt-write-file path content)
  (package-build-receipt-ensure-directory* (path-directory path))
  (call-with-output-file path
    (lambda (port)
      (display content port)
      (newline port))))

;; : (-> String Path)
(def (package-build-receipt-path name)
  (path-expand name +package-build-receipt-freshness-test-root+))

;; : (-> Void)
(def (package-build-receipt-reset!)
  (package-build-receipt-ensure-directory* +package-build-receipt-freshness-test-root+))

(def package-build-receipt-freshness-test
  (test-suite "package build receipt freshness"
    (test-case "reports stale when a source is newer than the receipt"
      (package-build-receipt-reset!)
      (let* ((source (package-build-receipt-path "dirty-source/source.ss"))
             (output (package-build-receipt-path "dirty-source/source.ssi"))
             (stamp (package-build-receipt-path "dirty-source/build.sexp")))
        (package-build-receipt-write-file source "source")
        (package-build-receipt-write-file output "output")
        (asp-gerbil-scheme-package-build-receipt-write stamp [source] [output])
        (thread-sleep! 1.1)
        (package-build-receipt-write-file source "newer source")
        (let (status (asp-gerbil-scheme-package-build-receipt-status stamp))
          (check (asp-gerbil-scheme-package-build-receipt-status-ref status 'status #f)
                 => 'stale)
          (check (asp-gerbil-scheme-package-build-receipt-status-ref status 'reason #f)
                 => 'dirty-source-or-missing-output))))))
