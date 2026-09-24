;;; -*- Gerbil -*-

(import :std/test
        "./unit/schema/conformance")
(export schema-type-proof-test)

;; SchemaTypeProofTest
(def schema-type-proof-test
  (test-suite "gerbil scheme type-proof schema"
    (test-case "type proof json packet conforms to local schema contract"
      (check-type-proof-json-schema-conformance))))
