;;; -*- Gerbil -*-
(import :asp-gerbil-scheme/src/protocol/registry
        :std/test)

(export provider-owned-schema-registry-test)

(def provider-owned-schema-registry-test
  (test-suite "provider-owned schema registry"
  (test-case "advertises the Gerbil harness info schema"
      (let* ((registry (language-registry "."))
             (language (car (hash-get registry 'languages)))
             (schemas (hash-get language 'schemas))
             (schema (car schemas)))
   (check (> (length schemas) 0) => #t)
        (check (hash-get schema 'schemaId)
               => "agent.semantic-protocols.asp-gerbil-scheme-info")
        (check (hash-get schema 'schemaVersion) => "1")
        (check (hash-get schema 'path)
               => "schemas/semantic-asp-gerbil-scheme-info.v1.schema.json")))))
