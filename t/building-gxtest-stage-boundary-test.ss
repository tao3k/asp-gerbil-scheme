(export building-gxtest-stage-boundary-test)

(import :std/test
        (only-in :asp-gerbil-scheme/src/testing/execution-profile
                 declare-gxtest-serial)
        (only-in :asp-gerbil-scheme/src/testing/gxtest-context configure-build-root!)
        (only-in :asp-gerbil-scheme/src/testing/gxtest-build
                 compile-selected-gxtest-if-stale)
        (only-in :asp-gerbil-scheme/src/testing/gxtest-receipts
                 selected-gxtest-build-receipt-path))

(declare-gxtest-serial shared-package-artifacts)

(def (read-selected-gxtest-build-receipt files)
  (call-with-input-file (selected-gxtest-build-receipt-path files) read))

(def (alist-value alist key)
  (let (entry (assq key alist))
    (and entry (cdr entry))))

(def building-gxtest-stage-boundary-test
  (test-suite "asp-gerbil-scheme selected GxTest Building boundary"
    (test-case "selected target records native std make ownership"
      (let (files '("t/building-gxtest-stage-boundary-test.ss"))
        (configure-build-root! ".")
        (compile-selected-gxtest-if-stale files)
        (let (receipt (read-selected-gxtest-build-receipt files))
          (check (alist-value receipt 'executor) => "std/make")
          (check (alist-value receipt 'freshnessOwner) => "std/make")
          (check (alist-value receipt 'buildPlan) => #f))))))
