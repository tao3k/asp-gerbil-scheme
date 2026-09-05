;;; -*- Gerbil -*-
;;; Executable v1 schema bundle used by provider semantic packet tests.

(import :gerbil/gambit)

(export +schema-files+
        +local-schema-refs+
        missing-schema-files
        schema-ref-closure)

;;; Bundle boundary:
;;; - These are the schemas exercised by the local provider packet suite.
;;; - Their `$ref` edges are internal fragments, so no remote fetch or
;;;   repository-external schema authority participates in this test bundle.
(def +schema-files+
  '("semantic-asp-gerbil-scheme-info.v1.schema.json"
    "semantic-language-evidence.v1.schema.json"
    "semantic-runtime-source-acquisition.v1.schema.json"
    "semantic-type-proof.v1.schema.json"
    "semantic-extension-pattern-mapping.v1.schema.json"
    "semantic-compare-packet.v1.schema.json"
    "semantic-structural-index.v1.schema.json"
    "semantic-native-syntax-fact-index.v1.schema.json"))

(def +local-schema-refs+ '())

;; : (-> (List String) (List String))
(def (missing-schema-files files)
  (filter (lambda (file)
            (not (file-exists? (string-append "schemas/" file))))
          files))

;; : (-> (List String))
(def (schema-ref-closure)
  +local-schema-refs+)
