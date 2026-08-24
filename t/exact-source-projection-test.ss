;;; -*- Gerbil -*-

(import :std/test
        (only-in :std/srfi/1 find)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/text/base64 base64-encode)
        :gslph/src/exact-source-projection)

(export exact-source-projection-test)

(def +sample-source+
  "(def (sample x)\n  (let (y (+ x 1))\n    (if (> y 2)\n      y\n      (error \"small\"))))\n")

(def (native-request selector projection-kind)
  (let ((request (make-hash-table))
        (source-bytes (string->utf8 +sample-source+)))
    (for-each
     (lambda (entry)
       (hash-put! request (car entry) (cdr entry)))
     (list
      (cons "schemaId"
            "agent.semantic-protocols.provider-native-exact-request")
      (cons "schemaVersion" "1")
      (cons "languageId" "gerbil-scheme")
      (cons "providerId" "gerbil-scheme-harness")
      (cons "structuralSelector" selector)
      (cons "ownerPath" "src/sample.ss")
      (cons "projectionKind" projection-kind)
      (cons "generationIdentityDigest" "generation-digest")
      (cons "parserIdentityDigest" "parser-digest")
      (cons "queryPackDigest" "query-pack-digest")
      (cons "sourceDigest" "asp-owned-content-identity")
      (cons "sourceByteLength" (u8vector-length source-bytes))
      (cons "sourceEncoding" "base64")
      (cons "sourceBytesBase64" (base64-encode source-bytes))
      (cons "transport" "stdin-json")))
    request))

(def exact-source-projection-test
  (test-suite
   "Gerbil provider-native exact projection"
   (test-case
    "callable skeleton child selector round-trips to source"
    (let* ((root
            "gerbil-scheme://src/sample.ss#item/function/sample")
           (skeleton
            (project-provider-native-exact-request
             (native-request root "callable-skeleton")
             "gerbil-scheme-harness"
             "parser-digest"
             "query-pack-digest"))
           (payload (hash-ref skeleton 'projectionPayload))
           (branch
            (find (lambda (node)
                    (equal? (hash-ref node 'kind) "branch"))
                  (vector->list (hash-ref payload 'nodes))))
           (child-selector
            (hash-ref (hash-ref branch 'exactSelector) 'selector))
           (source
            (project-provider-native-exact-request
             (native-request child-selector "source")
             "gerbil-scheme-harness"
             "parser-digest"
             "query-pack-digest")))
      (check (hash-ref payload 'rootNodeId) => "callable:root")
      (check (not branch) => #f)
      (check (not
              (not
               (string-contains
                (hash-ref source 'projectionText)
                "(if (> y 2)")))
             => #t)))
   (test-case
    "provider echoes ASP-owned source identity without recomputing it"
    (let* ((root
            "gerbil-scheme://src/sample.ss#item/function/sample")
           (source
            (project-provider-native-exact-request
             (native-request root "source")
             "gerbil-scheme-harness"
             "parser-digest"
             "query-pack-digest")))
      (check (hash-ref source 'sourceContentDigest)
             => "asp-owned-content-identity")))))
