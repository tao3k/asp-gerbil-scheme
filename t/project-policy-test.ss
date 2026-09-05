;;; -*- Gerbil -*-
;;; Explicit full-project policy gate.

(import :asp-gerbil-scheme/src/policy/gxtest)
(export project-policy-test)

;; : TestSuite
(def project-policy-test
  (make-project-policy-test "."))
