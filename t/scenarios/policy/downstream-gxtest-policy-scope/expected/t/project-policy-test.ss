;;; -*- Gerbil -*-
(import :asp-gerbil-scheme/policy-api)

(export project-policy-test)

(def project-policy-test
  (make-gxtest-policy-test "." ["t/unit-tests.ss"]))
