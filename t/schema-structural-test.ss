;;; -*- Gerbil -*-

(import :std/test
        "./unit/schema/conformance")
(export schema-structural-test)

;; SchemaStructuralTest
(def schema-structural-test
  (test-suite "gerbil scheme structural schema"
    (test-case "structural index json packet exposes native syntax facts"
      (check-structural-index-json-schema-conformance))))
