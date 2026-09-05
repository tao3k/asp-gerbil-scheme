;;; -*- Gerbil -*-
;;; Scoped policy build boundary regression tests.

(import :gerbil/gambit
        (only-in :gerbil/expander import-module)
        :std/test
        (only-in :std/srfi/13 string-contains))

(export scoped-policy-engine-test)

(def (policy-engine-api)
  (import-module ':asp-gerbil-scheme/src/testing/gxtest-context #f #t)
  (import-module ':asp-gerbil-scheme/src/testing/gxtest-policy #f #t)
  ((eval 'asp-gerbil-scheme/src/testing/gxtest-context#ensure-build-root!))
  [(eval 'asp-gerbil-scheme/src/testing/gxtest-policy#scoped-policy-engine-source-files)
   (eval 'asp-gerbil-scheme/src/testing/gxtest-policy#scoped-policy-engine-source-module-files)
   (eval 'asp-gerbil-scheme/src/testing/gxtest-policy#scoped-policy-engine-output-files)
   (eval 'asp-gerbil-scheme/src/testing/gxtest-policy#scoped-policy-engine-receipt-path)])

(def scoped-policy-engine-test
  (test-suite "gerbil scheme scoped policy engine build boundary"
    (test-case "scoped policy prepare is policy-engine scoped"
      (match (policy-engine-api)
        ([source-files source-modules output-files receipt-path]
         (let ((sources (source-files))
               (modules (source-modules))
               (outputs (output-files))
               (receipt (receipt-path)))
           (check (length modules) => (length sources))
           (check (length outputs) => (length sources))
           (check (member "policy/gxtest-report.ss" modules) ? true)
           (check (member "commands/check.ss" modules) => #f)
           (check (and (string-contains receipt "scoped-policy-engine.receipt") #t)
                  => #t)))))))
