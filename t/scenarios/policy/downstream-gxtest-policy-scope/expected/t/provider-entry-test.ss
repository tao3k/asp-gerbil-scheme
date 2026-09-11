;;; -*- Gerbil -*-
(import :std/test
        :sample/downstream-gxtest-policy-scope/src/provider-entry)

(export provider-entry-test)

(def provider-entry-test
  (test-suite "provider entry"
    (test-case "total"
      (check (total [1 2 3]) => 6))))
