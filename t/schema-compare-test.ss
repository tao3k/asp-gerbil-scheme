;;; -*- Gerbil -*-

(import :std/test
        "./unit/schema/conformance")
(export schema-compare-test)

;; SchemaCompareTest
(def schema-compare-test
  (test-suite "gerbil scheme compare schema"
    (test-case "compare json packet conforms to local schema contract"
      (check-compare-json-schema-conformance))))
