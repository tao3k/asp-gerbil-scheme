;;; -*- Gerbil -*-

(import :std/test
        "./unit/schema/conformance")
(export schema-extension-test)

;; SchemaExtensionTest
(def schema-extension-test
  (test-suite "gerbil scheme extension schema"
    (test-case "extension pattern json packet conforms to local schema contract"
      (check-extension-pattern-json-schema-conformance))))
