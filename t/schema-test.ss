;;; -*- Gerbil -*-
(import :std/test
  "./unit/schema/conformance")
(export schema-test)
;; SchemaTest
(def schema-test
  (test-suite "gerbil scheme provider-owned schema contracts"
    (test-case "info json packet exposes provider-local steering contract"
      (check-info-json-schema-conformance))
    (test-case "language evidence json packet conforms to local schema contract"
      (check-language-evidence-json-schema-conformance))))
