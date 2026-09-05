;;; -*- Gerbil -*-
(import :asp-gerbil-scheme/src/policy/gxtest)

(export project-policy-test)

(def project-policy-test
  (make-gxtest-policy-test "." ["t/unit-tests.ss"]))
