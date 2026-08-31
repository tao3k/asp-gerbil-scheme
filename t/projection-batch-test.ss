(export projection-batch-test)

(import :gerbil/gambit
        :std/test
        (only-in :asp-gerbil-scheme/src/commands/projection-batch
                 project-provider-projection-batch)
        (only-in :std/sugar hash))

(def (projection-request owners)
  (hash
   ("schemaId" "agent.semantic-protocols.provider-language-projection-batch-request")
   ("schemaVersion" "1")
   ("languageId" "gerbil-scheme")
   ("providerId" "asp-gerbil-scheme")
   ("workspaceIdentity" "workspace-test")
   ("generationRootDigest" "blake3-256:generation")
   ("parserIdentityDigest" "blake3-256:parser")
   ("queryPackDigest" "blake3-256:query-pack")
   ("owners" owners)))

(def projection-batch-test
  (test-suite
   "structured resident projection batch"
   (test-case
    "native Gerbil parser projects structured owner source"
    (let* ((response
            (project-provider-projection-batch
             (projection-request
              [(hash
                ("ownerPath" "src/projected.ss")
                ("sourceLeafDigest" "blake3-256:owner")
                ("sourceText" "(def (projected value) value)\n"))])))
           (owner (vector-ref (hash-ref response "owners") 0))
           (items (hash-ref owner "items")))
      (check (hash-ref response "schemaId")
             => "agent.semantic-protocols.provider-language-projection-batch-response")
      (check (hash-ref owner "ownerPath") => "src/projected.ss")
      (check (> (vector-length items) 0) => #t)))))
