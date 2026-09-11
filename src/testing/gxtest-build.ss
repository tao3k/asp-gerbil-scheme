;;; -*- Gerbil -*-
;;; Gxtest package build lifecycle helpers.

(import (only-in :std/misc/path path-directory)
        (rename-in (only-in "../build-api/native-build-spec"
                            configure-build-root!)
                   (configure-build-root! configure-native-build-root!))
        (rename-in "../build-api/native-build"
                   (compile-package-api-if-stale
                    native-compile-package-api-if-stale))
        (only-in "../build-api/native-build"
                 compile-selected-gxtest-target)
        (only-in "../build-api/package-receipt"
                 asp-gerbil-scheme-package-build-receipt-status
                 asp-gerbil-scheme-package-build-receipt-status-ref
                 asp-gerbil-scheme-package-build-receipt-write)
        (only-in "./gxtest-context"
                 package-root
                 ensure-build-root!)
        (only-in "./gxtest-discovery"
                 gxtest-selected-source-module-files
                 gxtest-selected-test-files)
        (only-in "./gxtest-receipts"
                  display-package-api-build-receipt-status
                  ensure-directory!
                  selected-gxtest-build-current?
                  selected-gxtest-build-receipt-status
                  write-selected-gxtest-build-receipt!)
        )

(export compile-package-api-if-stale
        compile-scoped-policy-engine-if-stale
        scoped-policy-engine-needs-source-build?
        compile-selected-gxtest-if-stale)

;; : (-> BuildReceiptStatus)
(def (compile-package-api-if-stale)
  (configure-native-build-root! package-root)
  (native-compile-package-api-if-stale))

;; : (-> (List Path) Alist)
(def (compile-selected-gxtest! files)
  (configure-native-build-root! package-root)
  (compile-selected-gxtest-target
   (gxtest-selected-source-module-files files)
   (gxtest-selected-test-files files)))

;; : (-> (List Path) BuildReceiptStatus)
(def (compile-selected-gxtest-if-stale files)
  (let (status (selected-gxtest-build-receipt-status files))
    (display-package-api-build-receipt-status status)
    (if (selected-gxtest-build-current? status)
      status
      ;; The selected source closure is already dependency ordered and is the
      ;; complete build input for this target.  Prebuilding the package API
      ;; here turns a one-file gxtest into a whole-package (currently hundreds
      ;; of modules) build and defeats the lightweight provider boundary.
      (let (metadata (compile-selected-gxtest! files))
        (write-selected-gxtest-build-receipt! files metadata)
        (selected-gxtest-build-receipt-status files)))))

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

(def (compile-scoped-policy-engine-if-stale source-files output-files receipt-path)
  (let (status (scoped-policy-engine-build-receipt-status
                receipt-path
                source-files
                output-files))
    (display-package-api-build-receipt-status status)
    (if (eq? (asp-gerbil-scheme-package-build-receipt-status-ref status 'status #f) 'current)
      status
      (begin
        (when (scoped-policy-engine-needs-source-build? source-files)
          (compile-package-api-if-stale))
        (write-scoped-policy-engine-build-receipt! receipt-path source-files output-files)
        (scoped-policy-engine-build-receipt-status
         receipt-path
         source-files
         output-files)))))
