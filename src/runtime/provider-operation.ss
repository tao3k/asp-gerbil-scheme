;;; -*- Gerbil -*-
;;; Boundary: POO-native semantic operations for the resident HTTP provider.
;;; JSON is decoded before this owner and projected after it; operation
;;; selection dispatches through the descriptor protocol, never a CLI route.
(import :gerbil/gambit
        (only-in :clan/poo/mop .defgeneric)
        (only-in :asp-gerbil-scheme/src/commands/project-resolution
                 project-resolution-request->response)
        (only-in :asp-gerbil-scheme/src/commands/projection-batch
                 project-provider-projection-batch)
        (only-in :asp-gerbil-scheme/src/exact-source-projection
                 project-provider-native-exact-request)
        (only-in :std/text/json write-json)
        "provider/interface.ss")

(export provider-operation-execute
        provider-runtime-operation-descriptors
        provider-runtime-operation-descriptor
        provider-runtime-contract-object
        provider-runtime-contract-receipt
        provider-runtime-request-object
        provider-runtime-request->response-object
        provider-runtime-request->response
        provider-runtime-projection-memo-observation
        provider-runtime-projection-memo-stats)

;; Open protocol boundary: each admitted operation owns its executable slot.
;; : (-> ProviderOperationDescriptor ProviderOperationPayload ProviderOperationResult)
(.defgeneric (provider-operation-execute descriptor payload)
  slot: execute)

;; : ProviderMemoState
(def +provider-projection-memo+
  (provider-memo-state 4 (* 64 1024) (* 256 1024)))

;; : (forall (a) (-> ProviderMemoState (-> a) a))
(def (call-with-projection-memo-lock state thunk)
  (let (lock (provider-memo-state-lock state))
    (dynamic-wind
      (lambda () (mutex-lock! lock))
      thunk
      (lambda () (mutex-unlock! lock)))))

;; : (forall (a) (-> [a] Integer [a]))
(def (take-prefix values count)
  (if (or (zero? count) (null? values))
      '()
      (cons (car values) (take-prefix (cdr values) (- count 1)))))

;; : (-> ProviderMemoState String (Maybe ProviderOperationResult))
(def (projection-memo-ref state key)
  (call-with-projection-memo-lock
   state
   (lambda ()
     (let* ((entries-cell (provider-memo-state-entries-cell state))
            (entry (assoc key (vector-ref entries-cell 0))))
       (if entry
           (let (hits-cell (provider-memo-state-hits-cell state))
             (vector-set! hits-cell 0 (+ 1 (vector-ref hits-cell 0)))
             (cdr entry))
           (let (misses-cell (provider-memo-state-misses-cell state))
             (vector-set! misses-cell 0 (+ 1 (vector-ref misses-cell 0)))
             #f))))))

;; : (-> ProviderMemoState String ProviderOperationResult Void)
(def (projection-memo-put! state key value)
  (when (and (<= (string-length key)
                 (provider-memo-state-key-byte-limit state))
             (<= (string-length
                  (json->string (provider-operation-result->json value)))
                 (provider-memo-state-value-byte-limit state)))
    (call-with-projection-memo-lock
     state
     (lambda ()
       (let* ((entries-cell (provider-memo-state-entries-cell state))
              (entries (vector-ref entries-cell 0)))
         (vector-set!
          entries-cell 0
          (cons (cons key value)
                (take-prefix
                 entries
                 (- (provider-memo-state-entry-limit state) 1)))))))))

;; : (-> ProviderMemoObservation)
(def (provider-runtime-projection-memo-observation)
  (let (state +provider-projection-memo+)
    (call-with-projection-memo-lock
     state
     (lambda ()
       (provider-memo-observation
        (length (vector-ref (provider-memo-state-entries-cell state) 0))
        (provider-memo-state-entry-limit state)
        (provider-memo-state-key-byte-limit state)
        (provider-memo-state-value-byte-limit state)
        (vector-ref (provider-memo-state-hits-cell state) 0)
        (vector-ref (provider-memo-state-misses-cell state) 0))))))

;; : (-> JsonObject)
(def (provider-runtime-projection-memo-stats)
  (provider-memo-observation->json
   (provider-runtime-projection-memo-observation)))

;; : (-> ProviderOperationDescriptor ProviderOperationPayload ProviderOperationResult)
(def (provider-runtime-execute-payload descriptor payload)
  (provider-require-operation-payload! payload)
  (if (provider-operation-descriptor-memoizable? descriptor)
      (let* ((operation
              (provider-operation-descriptor-operation descriptor))
             (key
              (string-append
               operation ":"
               (json->string (provider-operation-payload->json payload))))
             (cached (projection-memo-ref +provider-projection-memo+ key)))
        (or cached
            (let (computed (provider-operation-execute descriptor payload))
              ;; Concurrent misses may duplicate pure parser work. Publication
              ;; happens only after the POO operation returns successfully.
              (projection-memo-put! +provider-projection-memo+ key computed)
              computed)))
      (provider-operation-execute descriptor payload)))

;; : (-> String String)
(def (required-environment name)
  (let (value (getenv name #f))
    (unless (and value (> (string-length value) 0))
      (error "resident Gerbil provider environment is missing" name))
    value))

;; : (-> JsonValue String)
(def (json->string value)
  (call-with-output-string ""
    (lambda (output) (write-json value output))))

;; : (-> JsonObject String String)
(def (required-payload-string payload name)
  (let (value (hash-ref payload name #f))
    (unless (and (string? value) (> (string-length value) 0))
      (error "resident Gerbil provider payload identity is missing" name))
    value))

;; : (-> String ProviderOperationPayload JsonObject)
(def (operation-payload-wire-value operation payload)
  (provider-require-operation-payload! payload)
  (unless (string=? operation
                    (provider-operation-payload-operation payload))
    (error "resident Gerbil provider operation payload identity drift"
           operation
           (provider-operation-payload-operation payload)))
  (provider-operation-payload->json payload))

;; : (-> ProviderOperationPayload ProviderOperationResult)
(def (execute-projection-batch payload)
  (provider-operation-result
   "projection-batch"
   (project-provider-projection-batch
    (operation-payload-wire-value "projection-batch" payload))))

;; : (-> ProviderOperationPayload ProviderOperationResult)
(def (execute-project-resolution payload)
  (provider-operation-result
   "project-resolution"
   (project-resolution-request->response
    (operation-payload-wire-value "project-resolution" payload))))

;; : (-> ProviderOperationPayload ProviderOperationResult)
(def (execute-native-exact-query payload)
  (let (wire-value (operation-payload-wire-value "query" payload))
    (provider-operation-result
     "query"
     (project-provider-native-exact-request
      wire-value
      (required-environment "ASP_PROVIDER_ID")
      (required-payload-string wire-value "parserIdentityDigest")
      (required-payload-string wire-value "queryPackDigest")))))

;; : (-> String String ProviderSchemaReference)
(def (schema-reference schema-id schema-version)
  (provider-schema-reference schema-id schema-version))

;; : [ProviderOperationDescriptor]
(def provider-runtime-operation-descriptors
  [(provider-operation-descriptor
    "projection-batch"
    (schema-reference
     "agent.semantic-protocols.provider-language-projection-batch-request" "1")
    (schema-reference
     "agent.semantic-protocols.provider-language-projection-batch-response" "1")
    #t execute-projection-batch)
   (provider-operation-descriptor
    "project-resolution"
    (schema-reference
     "agent.semantic-protocols.provider-project-resolution-request" "1")
    (schema-reference
     "agent.semantic-protocols.provider-project-resolution-response" "1")
    #f execute-project-resolution)
   (provider-operation-descriptor
    "query"
    (schema-reference
     "agent.semantic-protocols.provider-native-exact-request" "1")
    (schema-reference
     "agent.semantic-protocols.provider-native-exact-projection" "1")
    #f execute-native-exact-query)])

;; : (-> String ProviderOperationDescriptor)
(def (provider-runtime-operation-descriptor operation)
  (or (find (lambda (descriptor)
              (string=?
               operation
               (provider-operation-descriptor-operation descriptor)))
            provider-runtime-operation-descriptors)
      (error "resident Gerbil provider operation is not admitted" operation)))

;; : (-> ProviderRuntimeContract)
(def (provider-runtime-contract-object)
  (provider-runtime-contract
   (required-environment "ASP_PROVIDER_ID")
   (required-environment "ASP_PROVIDER_LANGUAGE_ID")
   (required-environment "ASP_PROVIDER_ARTIFACT_DIGEST")
   (required-environment "ASP_PROVIDER_REGISTRATION_DIGEST")
   (required-environment "ASP_PROVIDER_RUNTIME_CONTRACT_DIGEST")
   provider-runtime-operation-descriptors))

;; : (-> JsonObject)
(def (provider-runtime-contract-receipt)
  (provider-runtime-contract->json (provider-runtime-contract-object)))

;; : (-> JsonObject ProviderRuntimeRequest)
(def (provider-runtime-request-object request)
  (unless (and (hash-table? request)
               (string=? (hash-ref request "schemaId" "")
                         "agent.semantic-protocols.provider-runtime-request-frame")
               (string=? (hash-ref request "schemaVersion" "") "1"))
    (error "resident Gerbil provider request schema identity is invalid"))
  (let ((request-id (hash-ref request "requestId" #f))
        (operation (hash-ref request "operation" #f))
        (payload (hash-ref request "payload" #f)))
    (unless (and (string? request-id) (> (string-length request-id) 0)
                 (string? operation) (> (string-length operation) 0)
                 (hash-table? payload))
      (error "resident Gerbil provider request identity is invalid"))
    (provider-runtime-request
     request-id
     (provider-runtime-operation-descriptor operation)
     (provider-operation-payload operation payload))))

;; : (-> JsonObject ProviderRuntimeResponse)
(def (provider-runtime-request->response-object request)
  (let* ((request-object (provider-runtime-request-object request))
         (descriptor (provider-runtime-request-operation request-object))
         (payload (provider-runtime-request-payload request-object)))
    (provider-runtime-ready-response
     (provider-runtime-request-id request-object)
     (provider-runtime-execute-payload descriptor payload))))

;; : (-> JsonObject JsonObject)
(def (provider-runtime-request->response request)
  (provider-runtime-response->json
   (provider-runtime-request->response-object request)))
