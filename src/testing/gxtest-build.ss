;;; -*- Gerbil -*-
;;; Gxtest package build lifecycle helpers.

(import (only-in :std/make make)
        (only-in "../build-api/core-capacity"
                 initialize-native-build-core-capacity!)
        (only-in "./gxtest-context"
                 package-root)
        (only-in "./gxtest-discovery"
                 gxtest-selected-test-files)
        (only-in "./gxtest-receipts"
                  display-build-receipt-status
                  selected-gxtest-build-receipt-status
                  write-selected-gxtest-build-receipt!)
        )

(export compile-selected-gxtest-if-stale)

;; : (-> (List Path) Alist)
(def (compile-selected-gxtest! files)
  (initialize-native-build-core-capacity!)
  (let (spec (gxtest-selected-test-files files))
    (when (pair? spec)
      (make spec srcdir: package-root))
    '((executor . "std/make")
      (freshnessOwner . "std/make")
      (graphOwner . "package-build"))))

;; : (-> (List Path) BuildReceiptStatus)
(def (compile-selected-gxtest-if-stale files)
  (let (status (selected-gxtest-build-receipt-status files))
    (display-build-receipt-status status)
    ;; Receipts describe the prior call but never suppress the native executor.
    ;; std/make receives only explicit test targets on every invocation and
    ;; owns the only freshness decision. Production modules must already have
    ;; been built by the package's real build entrypoint.
    (let (metadata (compile-selected-gxtest! files))
      (write-selected-gxtest-build-receipt! files metadata)
      (selected-gxtest-build-receipt-status files))))
