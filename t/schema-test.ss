;;; -*- Gerbil -*-
(import :std/test
  "./unit/schema/bundle"
  "./unit/schema/conformance")
(export schema-test)
;; SchemaTest
(def schema-test
  (test-suite "gerbil scheme schema bundle"
    (test-case "tracked schema files exist locally"
      (check (missing-schema-files +schema-files+) => '()))
    (test-case "local schema refs resolve without remote fetch"
      (let (refs (schema-ref-closure))
        (check refs => +local-schema-refs+)
        (check (missing-schema-files refs) => '())))
    (test-case "info json packet exposes provider-local steering contract"
      (check-info-json-schema-conformance))
    (test-case "language evidence json packet conforms to local schema contract"
      (check-language-evidence-json-schema-conformance))))
