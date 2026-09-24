;;; -*- Gerbil -*-

(import :std/test
        "./unit/schema/conformance")
(export schema-runtime-test)

;; SchemaRuntimeTest
(def schema-runtime-test
  (test-suite "gerbil scheme runtime-source schema"
    (test-case "runtime-source json packet conforms to local schema contract"
      (check-runtime-source-json-schema-conformance))))
