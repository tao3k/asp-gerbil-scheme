;;; -*- Gerbil -*-
(import (only-in :clan/poo/object .slot?)
        (only-in :asp-gerbil-scheme/src/protocol/provider-operation-catalog
                 provider-operation-contracts)
        :asp-gerbil-scheme/src/protocol/registry
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/13 string-contains)
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
               => "agent.semantic-protocols.asp-gerbil-scheme-info")
        (check (hash-get schema 'schemaVersion) => "1")
        (check (hash-get schema 'path)
               => "schemas/semantic-asp-gerbil-scheme-info.v1.schema.json")))
    (test-case "command discovery projects a static POO contract catalog"
      (let* ((registry (language-registry "."))
             (language (car (hash-get registry 'languages)))
             (methods (hash-get language 'methods))
             (descriptors (hash-get language 'methodDescriptors)))
        (check methods
               => '("projection-batch" "project-resolution" "query"))
        (check (length descriptors) => 3)
        (check (hash-ref (car descriptors) "operation")
               => "projection-batch")
        (check (.slot? (car provider-operation-contracts) 'execute) => #f)))
    (test-case "command and registry source do not import runtime owners"
      (let ((registry-source
             (call-with-input-file "src/protocol/registry.ss"
                                   read-all-as-string))
            (command-source
             (call-with-input-file "src/commands/agent.ss"
                                   read-all-as-string)))
        (check (string-contains registry-source "/runtime/") => #f)
        (check (string-contains command-source "/runtime/") => #f)))))
