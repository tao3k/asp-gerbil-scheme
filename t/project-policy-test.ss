;;; -*- Gerbil -*-
;;; Explicit full-project policy gate.

(import :std/test
        :asp-gerbil-scheme/src/policy/gxtest
        (only-in :asp-gerbil-scheme/src/testing/gxtest-catalog
                 gxtest-project-policy-files))
(export project-policy-test)

;; : TestSuite
(def project-policy-macro-witness-test
  (make-gxtest-policy-test "." ["t/project-policy-test.ss"]))

;; : TestSuite
(def project-policy-full-test
  (make-project-policy-test "." (gxtest-project-policy-files)))

;; : TestSuite
(def project-policy-test
  (test-suite "asp gerbil-scheme project policy gate"
    (test-case "public policy macro expands to an executable gxtest suite"
      (check (run-test-suite! project-policy-macro-witness-test) => #t))
    ;; The full project gate remains function-based because its explicit
    ;; evidence set is supplied by the native package and gxtest catalogs.
    (test-case "clan module set passes the full project policy gate"
      (check (run-test-suite! project-policy-full-test) => #t))))
