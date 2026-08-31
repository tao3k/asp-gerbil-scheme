(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/commands/project-resolution project-resolution-request->response)
        (only-in :asp-gerbil-scheme/src/commands/projection-batch project-provider-projection-batch)
        (only-in :asp-gerbil-scheme/src/exact-source-projection project-provider-native-exact-request)
        (only-in :std/sugar hash)
        (only-in :std/text/json write-json))

(def +projection-memo-entry-limit+ 4)
(def +projection-memo-key-byte-limit+ (* 64 1024))
(def +projection-memo-value-byte-limit+ (* 256 1024))
(def +projection-memo-lock+ (make-mutex 'asp-gerbil-scheme-projection-memo))
(def +projection-memo+ '())
(def +projection-memo-hit-count+ 0)
(def +projection-memo-miss-count+ 0)

(def (call-with-projection-memo-lock thunk)
  (dynamic-wind
    (lambda () (mutex-lock! +projection-memo-lock+))
    thunk
    (lambda () (mutex-unlock! +projection-memo-lock+))))

(def (take-prefix values count)
  (if (or (zero? count) (null? values))
      '()
      (cons (car values) (take-prefix (cdr values) (- count 1)))))

(def (projection-memo-ref key)
  (call-with-projection-memo-lock
   (lambda ()
     (let (entry (assoc key +projection-memo+))
       (if entry
           (begin
             (set! +projection-memo-hit-count+
                   (+ +projection-memo-hit-count+ 1))
             (cdr entry))
           (begin
             (set! +projection-memo-miss-count+
                   (+ +projection-memo-miss-count+ 1))
             #f))))))

(def (projection-memo-put! key value)
  (when (and (<= (string-length key) +projection-memo-key-byte-limit+)
             (<= (string-length (json->string value))
                 +projection-memo-value-byte-limit+))
    (call-with-projection-memo-lock
     (lambda ()
       (set! +projection-memo+
             (cons (cons key value)
                   (take-prefix +projection-memo+
                                (- +projection-memo-entry-limit+ 1))))))))

(def (provider-runtime-projection-memo-stats)
  (call-with-projection-memo-lock
   (lambda ()
     (hash ("entries" (length +projection-memo+))
           ("entryLimit" +projection-memo-entry-limit+)
           ("keyByteLimit" +projection-memo-key-byte-limit+)
           ("valueByteLimit" +projection-memo-value-byte-limit+)
           ("hits" +projection-memo-hit-count+)
           ("misses" +projection-memo-miss-count+)))))

(def (provider-runtime-response-payload operation payload)
  (if (string=? operation "projection-batch")
      (let* ((key (string-append operation ":" (json->string payload)))
             (cached (projection-memo-ref key)))
        (or cached
            (let (computed (runtime-operation operation payload))
              ;; Publication is deliberately after computation.  Concurrent
              ;; misses may duplicate pure parser work; they never serialize
              ;; behind a provider-owned single-flight authority.
              (projection-memo-put! key computed)
              computed)))
      (runtime-operation operation payload)))

(export provider-runtime-contract-receipt
        provider-runtime-request->response
        provider-runtime-projection-memo-stats)

(def +operations+
  [(hash ("operation" "projection-batch")
         ("requestSchemaId"
          "https://schemas.agent-semantic-protocols.dev/provider-language-projection-batch-request.schema.json")
         ("responseSchemaId"
          "https://schemas.agent-semantic-protocols.dev/provider-language-projection-batch-response.schema.json"))
   (hash ("operation" "project-resolution")
         ("requestSchemaId"
          "https://schemas.agent-semantic-protocols.dev/provider-project-resolution-request.schema.json")
         ("responseSchemaId"
          "https://schemas.agent-semantic-protocols.dev/provider-project-resolution-response.schema.json"))
   (hash ("operation" "query")
         ("requestSchemaId"
          "https://agent-semantic-protocols.dev/schemas/provider-native-exact-request.v1.schema.json")
         ("responseSchemaId"
          "https://agent-semantic-protocols.dev/schemas/provider-native-exact-response.v1.schema.json"))])

(def (required-environment name)
  (let (value (getenv name #f))
    (unless (and value (> (string-length value) 0))
      (error "resident Gerbil provider environment is missing" name))
    value))

(def (json->string value)
  (call-with-output-string ""
    (lambda (output) (write-json value output))))

(def (provider-runtime-contract-receipt)
  (hash ("schemaId" "agent.semantic-protocols.provider-runtime-contract-receipt")
        ("schemaVersion" "1")
        ("providerId" (required-environment "ASP_PROVIDER_ID"))
        ("languageId" (required-environment "ASP_PROVIDER_LANGUAGE_ID"))
        ("artifactDigest" (required-environment "ASP_PROVIDER_ARTIFACT_DIGEST"))
        ("registrationDigest" (required-environment "ASP_PROVIDER_REGISTRATION_DIGEST"))
        ("contractDigest" (required-environment "ASP_PROVIDER_RUNTIME_CONTRACT_DIGEST"))
        ("transport" "http-json")
        ("operations" +operations+)))

(def (runtime-operation operation payload)
  (cond
   ((string=? operation "projection-batch")
    (project-provider-projection-batch payload))
   ((string=? operation "project-resolution")
    (project-resolution-request->response payload))
   ((string=? operation "query")
    (project-provider-native-exact-request
     payload
     (required-environment "ASP_PROVIDER_ID")
     (required-payload-string payload "parserIdentityDigest")
     (required-payload-string payload "queryPackDigest")))
   (else (error "resident Gerbil provider operation is not admitted" operation))))

(def (required-payload-string payload name)
  (let (value (hash-ref payload name #f))
    (unless (and (string? value) (> (string-length value) 0))
      (error "resident Gerbil provider payload identity is missing" name))
    value))

(def (provider-runtime-request->response request)
  (let* ((request-id (hash-ref request "requestId" "invalid-request"))
         (operation (hash-ref request "operation" #f))
         (payload (hash-ref request "payload" #f)))
    (unless (and (string=? (hash-ref request "schemaId" "")
                           "agent.semantic-protocols.provider-runtime-request-frame")
                 (string=? (hash-ref request "schemaVersion" "") "1")
                 (string? request-id) (> (string-length request-id) 0)
                 (string? operation) (hash-table? payload))
      (error "resident Gerbil provider request identity is invalid"))
    (hash ("schemaId" "agent.semantic-protocols.provider-runtime-response-frame")
          ("schemaVersion" "1")
          ("requestId" request-id)
          ("outcome" "ready")
          ("payload" (provider-runtime-response-payload operation payload)))))
