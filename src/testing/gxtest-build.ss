;;; -*- Gerbil -*-
;;; Gxtest package build lifecycle helpers.

(import (only-in :std/make make)
        (only-in "../build-api/core-capacity"
                 initialize-native-build-core-capacity!)
        (only-in :std/misc/path path-directory)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in "../build-api/package-receipt"
                 asp-gerbil-scheme-package-build-receipt-status
                 asp-gerbil-scheme-package-build-receipt-write)
        (only-in "./gxtest-context"
                 package-root
                 ensure-build-root!)
        (only-in "./gxtest-discovery"
                 gxtest-selected-source-module-files
                 gxtest-selected-test-files)
        (only-in "./gxtest-receipts"
                  display-build-receipt-status
                  ensure-directory!
                  selected-gxtest-build-receipt-status
                  write-selected-gxtest-build-receipt!)
        )

(export compile-scoped-policy-engine-if-stale
        scoped-policy-engine-needs-source-build?
        compile-selected-gxtest-if-stale)

;; : (-> (List Path) Alist)
(def (compile-selected-gxtest! files)
  (initialize-native-build-core-capacity!)
  (let (spec
        (append
         (map (lambda (module) (string-append "src/" module))
              (gxtest-selected-source-module-files files))
         (gxtest-selected-test-files files)))
    (when (pair? spec)
      (make spec srcdir: package-root))
    '((executor . "std/make")
      (freshnessOwner . "std/make"))))

;; : (-> (List Path) BuildReceiptStatus)
(def (compile-selected-gxtest-if-stale files)
  (let (status (selected-gxtest-build-receipt-status files))
    (display-build-receipt-status status)
    ;; Receipts describe the prior call but never suppress the native executor.
    ;; std/make receives the selected closure on every invocation and owns the
    ;; only freshness decision.
    (let (metadata (compile-selected-gxtest! files))
      (write-selected-gxtest-build-receipt! files metadata)
      (selected-gxtest-build-receipt-status files))))

(def +scoped-policy-engine-build-receipt-version+
  'asp-gerbil-scheme-scoped-policy-engine-build.v1)

(def (write-scoped-policy-engine-build-receipt! receipt-path source-files output-files)
  (ensure-directory! (path-directory receipt-path))
  (asp-gerbil-scheme-package-build-receipt-write
   receipt-path
   source-files
   output-files
   version: +scoped-policy-engine-build-receipt-version+))

(def (scoped-policy-engine-build-receipt-status receipt-path source-files output-files)
  (asp-gerbil-scheme-package-build-receipt-status
   receipt-path
   version: +scoped-policy-engine-build-receipt-version+
   expected-sources: source-files
   expected-outputs: output-files))

;; The dependency manager owns installed ASP modules for downstream projects.
;; Only the ASP source workspace itself has a local policy-engine source set
;; that can legitimately be rebuilt by this package API.
(def (scoped-policy-engine-needs-source-build? source-files)
  (pair? source-files))

(def (package-relative-source-file file)
  (let (prefix (if (string-suffix? "/" package-root)
                package-root
                (string-append package-root "/")))
    (if (string-prefix? prefix file)
      (substring file (string-length prefix) (string-length file))
      (error "build source is outside package root" file))))

(def (compile-scoped-policy-engine-if-stale source-files output-files receipt-path)
  (initialize-native-build-core-capacity!)
  (let (status (scoped-policy-engine-build-receipt-status
                receipt-path
                source-files
                output-files))
    (display-build-receipt-status status)
    (when (scoped-policy-engine-needs-source-build? source-files)
      (make (map package-relative-source-file source-files)
            srcdir: package-root))
    (write-scoped-policy-engine-build-receipt! receipt-path source-files output-files)
    (scoped-policy-engine-build-receipt-status
     receipt-path
     source-files
     output-files)))
