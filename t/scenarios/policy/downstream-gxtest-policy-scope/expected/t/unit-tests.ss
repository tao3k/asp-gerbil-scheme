;;; -*- Gerbil -*-
(import :std/test
        :sample/downstream-gxtest-policy-scope/t/provider-entry-test
        :sample/downstream-gxtest-policy-scope/t/project-policy-test)

(export unit-tests)

(def unit-tests
  (test-suite "unit"
    provider-entry-test
    project-policy-test))
