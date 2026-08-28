(export projection-batch-test)

(import :gerbil/gambit
        :std/test
        (only-in :gslph/src/commands/projection-batch
                 project-provider-projection-batch)
        (only-in :std/sugar hash hash-put!))

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

(def (projection-request-with-auxiliary owners auxiliary-owners)
  (let (request (projection-request owners))
    (hash-put! request "auxiliaryOwners" auxiliary-owners)
    request))

(def projection-batch-test
  (test-suite
   "structured resident projection batch"
   (test-case
    "owner-local projection does not resolve imported libraries"
    (let* ((response
            (project-provider-projection-batch
             (projection-request
              [(hash
                ("ownerPath" "src/independent.ss")
                ("sourceLeafDigest" "blake3-256:independent-owner")
                ("sourceEncoding" "utf8")
                ("sourceText"
                 "(import :workspace/module-that-is-not-in-this-frame)\n(def independent 1)\n"))])))
           (owner (vector-ref (hash-ref response "owners") 0))
           (items (hash-ref owner "items")))
      (check (vector-length items) => 1)
      (check (hash-ref (vector-ref items 0) "selector")
             => "gerbil-scheme://src/independent.ss#item/function/independent")))
   (test-case
    "native Gerbil parser projects structured owner source"
    (let* ((response
            (project-provider-projection-batch
             (projection-request
              [(hash
                ("ownerPath" "src/projected.ss")
                ("sourceLeafDigest" "blake3-256:owner")
                ("sourceEncoding" "utf8")
                ("sourceText" "(def (projected value) value)\n"))])))
           (owner (vector-ref (hash-ref response "owners") 0))
           (items (hash-ref owner "items")))
      (check (hash-ref response "schemaId")
             => "agent.semantic-protocols.provider-language-projection-batch-response")
      (check (hash-ref owner "ownerPath") => "src/projected.ss")
      (check (> (vector-length items) 0) => #t)))
   (test-case
    "empty source is a valid projected owner"
    (let* ((response
            (project-provider-projection-batch
             (projection-request
              [(hash
                ("ownerPath" "src/empty.ss")
                ("sourceLeafDigest" "blake3-256:empty-owner")
                ("sourceEncoding" "utf8")
                ("sourceText" ""))])))
           (owner (vector-ref (hash-ref response "owners") 0)))
      (check (hash-ref owner "ownerPath") => "src/empty.ss")
      (check (hash-ref owner "sourceLeafDigest")
             => "blake3-256:empty-owner")
      (check (vector-length (hash-ref owner "items")) => 0)))
   (test-case
    "base64 source preserves non-UTF-8 owner bytes"
    (let* ((response
            (project-provider-projection-batch
             (projection-request
              [(hash
                ("ownerPath" "src/non-utf8.scm")
                ("sourceLeafDigest" "blake3-256:non-utf8-owner")
                ("sourceEncoding" "base64")
                ("sourceBytesBase64" "KCLtoIAiKQ=="))])))
           (owner (vector-ref (hash-ref response "owners") 0)))
      (check (hash-ref owner "ownerPath") => "src/non-utf8.scm")
      (check (hash-ref owner "sourceLeafDigest")
             => "blake3-256:non-utf8-owner")))
   (test-case
    "redefinitions publish only the last active binding"
    (let* ((response
            (project-provider-projection-batch
             (projection-request
              [(hash
                ("ownerPath" "src/redefined.ss")
                ("sourceLeafDigest" "blake3-256:redefined-owner")
                ("sourceEncoding" "utf8")
                ("sourceText" "(def a 1)\n(def a 2)\n"))])))
           (owner (vector-ref (hash-ref response "owners") 0))
           (items (hash-ref owner "items"))
           (item (vector-ref items 0)))
      (check (vector-length items) => 1)
      (check (hash-ref item "selector")
             => "gerbil-scheme://src/redefined.ss#item/function/a")
      (check (hash-ref item "sourceByteStart") => 10)))
   (test-case
    "R4RS named character literals are case-insensitive"
    (let* ((response
            (project-provider-projection-batch
             (projection-request
              [(hash
                ("ownerPath" "src/r4rs-characters.scm")
                ("sourceLeafDigest" "blake3-256:r4rs-characters")
                ("sourceEncoding" "utf8")
                ("sourceText"
                 "(def uppercase-space #\\Space)\n(def uppercase-newline #\\Newline)\n(def uppercase-character #\\A)\n"))])))
           (owner (vector-ref (hash-ref response "owners") 0))
           (items (hash-ref owner "items")))
      (check (vector-length items) => 3)
      (check (hash-ref (vector-ref items 0) "sourceByteStart") => 0)))
   (test-case
    "URI-encoded Gerbil definition kinds normalize structurally"
    (let* ((response
            (project-provider-projection-batch
             (projection-request
              [(hash
                ("ownerPath" "src/star-definition.ss")
                ("sourceLeafDigest" "blake3-256:star-definition")
                ("sourceEncoding" "utf8")
                ("sourceText" "(def* compile-e 1)\n"))])))
           (owner (vector-ref (hash-ref response "owners") 0))
           (items (hash-ref owner "items")))
      (check (vector-length items) => 1)
      (check (hash-ref (vector-ref items 0) "selector")
             => "gerbil-scheme://src/star-definition.ss#item/function/compile-e")))
   (test-case
    "parser definition heads map to canonical selector kinds"
    (let* ((response
            (project-provider-projection-batch
             (projection-request
              [(hash
                ("ownerPath" "src/macro-kinds.ss")
                ("sourceLeafDigest" "blake3-256:macro-kinds")
                ("sourceEncoding" "utf8")
                ("sourceText" "(defsyntax-parameter* @message 1)\n"))])))
           (owner (vector-ref (hash-ref response "owners") 0))
           (items (hash-ref owner "items")))
      (check (vector-length items) => 1)
      (check (hash-ref (vector-ref items 0) "selector")
             => "gerbil-scheme://src/macro-kinds.ss#item/macro/%40message")))
   (test-case
    "owner path URI delimiters are encoded without flattening directories"
    (let* ((response
            (project-provider-projection-batch
             (projection-request
              [(hash
                ("ownerPath" "src/hash#query%?.scm")
                ("sourceLeafDigest" "blake3-256:owner-delimiters")
                ("sourceEncoding" "utf8")
                ("sourceText" "(define encoded-owner 1)\n"))])))
           (owner (vector-ref (hash-ref response "owners") 0))
           (item (vector-ref (hash-ref owner "items") 0)))
      (check (hash-ref item "selector")
             => "gerbil-scheme://src/hash%23query%25%3F.scm#item/function/encoded-owner")))
   (test-case
    "overlong native location recovers a monotonic owner-bounded range"
    (let* ((source
            (string-append "(define long-item (list "
                           (make-string 20000 #\space)
                           "))\n"))
           (response
            (project-provider-projection-batch
             (projection-request
              [(hash
                ("ownerPath" "src/overlong-line.scm")
                ("sourceLeafDigest" "blake3-256:overlong-line")
                ("sourceEncoding" "utf8")
                ("sourceText" source))])))
           (owner (vector-ref (hash-ref response "owners") 0))
           (item (vector-ref (hash-ref owner "items") 0)))
      (check (hash-ref item "sourceByteStart") => 0)
      (check (hash-ref item "sourceByteEnd")
             => (u8vector-length (string->utf8 source)))))
   (test-case
    "owner-local native reader dispatches #lang owners"
    (let* ((response
            (project-provider-projection-batch
             (projection-request-with-auxiliary
              [(hash
                ("ownerPath" "src/lang-owner.ss")
                ("sourceLeafDigest" "blake3-256:lang-owner")
                ("sourceEncoding" "utf8")
                ("sourceText" "#lang :test/prelude\n(def lang-owner 1)\n"))]
              [(hash
                ("ownerPath" "src/test/prelude.ss")
                ("sourceLeafDigest" "blake3-256:test-prelude")
                ("sourceEncoding" "utf8")
                ("sourceText"
                 "(import :gerbil/core :test/prelude-helper)\n(export (import: :gerbil/core))\n"))
               (hash
                ("ownerPath" "src/test/prelude-helper.ss")
                ("sourceLeafDigest" "blake3-256:test-prelude-helper")
                ("sourceEncoding" "utf8")
                ("sourceText" "(export #t)\n(def helper-value 1)\n"))])))
           (owner (vector-ref (hash-ref response "owners") 0))
           (items (hash-ref owner "items")))
      (check (vector-length items) => 1)
      (check (hash-ref (vector-ref items 0) "selector")
             => "gerbil-scheme://src/lang-owner.ss#item/function/lang-owner")))))
