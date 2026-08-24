(export projection-batch-scenario-test)

(import :gerbil/gambit
        :std/test
        (only-in :gslph/src/commands/projection-batch
                 project-provider-projection-batch)
        (only-in :std/sugar hash))

(def (scenario-owner index)
  (hash
   ("ownerPath" (string-append "src/owner-" (number->string index) ".ss"))
   ("sourceLeafDigest" (string-append "blake3-256:owner-" (number->string index)))
   ("sourceText" (string-append "(def owner-" (number->string index) " "
                                (number->string index) ")\n"))))

(def projection-batch-scenario-test
  (test-suite
   "structured resident projection scenario"
   (test-case
    "one resident request projects a multi-owner corpus"
    (let* ((owners (list->vector (map scenario-owner (iota 32))))
           (response
            (project-provider-projection-batch
             (hash
              ("schemaId" "agent.semantic-protocols.provider-language-projection-batch-request")
              ("schemaVersion" "1")
              ("languageId" "gerbil-scheme")
              ("providerId" "asp-gerbil-scheme")
              ("workspaceIdentity" "workspace-scenario")
              ("generationRootDigest" "blake3-256:generation")
              ("parserIdentityDigest" "blake3-256:parser")
              ("queryPackDigest" "blake3-256:query-pack")
              ("owners" owners)))))
      (check (vector-length (hash-ref response "owners")) => 32)))))
