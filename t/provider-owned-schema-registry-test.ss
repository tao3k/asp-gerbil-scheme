;;; -*- Gerbil -*-
(import :gslph/src/protocol/registry
        :std/test)

(export provider-owned-schema-registry-test)

(def provider-owned-schema-registry-test
  (test-suite "provider-owned schema registry"
    (test-case "advertises only the Gerbil harness info schema"
      (let* ((registry (language-registry "."))
             (language (car (hash-get registry 'languages)))
             (schemas (hash-get language 'schemas))
             (schema (car schemas)))
        (check (length schemas) => 1)
        (check (hash-get schema 'schemaId)
               => "agent.semantic-protocols.gerbil-scheme-harness-info")
        (check (hash-get schema 'schemaVersion) => "1")
        (check (hash-get schema 'path)
               => "schemas/semantic-gerbil-scheme-harness-info.v1.schema.json")))))
