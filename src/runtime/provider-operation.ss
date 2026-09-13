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
        (only-in :asp-gerbil-scheme/src/protocol/provider-operation-catalog
                 provider-operation-contract-memoizable?
                 provider-operation-contract-operation
                 provider-operation-contract-request-schema-id
                 provider-operation-contract-request-schema-version
                 provider-operation-contract-response-schema-id
                 provider-operation-contract-response-schema-version
                 provider-operation-contracts)
        (only-in :std/misc/lru
                 lru-cache-get
                 lru-cache-put!
                 lru-cache-size)
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

;; : (-> ProviderMemoState Object (Maybe ProviderOperationResult))
(def (projection-memo-ref state key)
  (call-with-projection-memo-lock
   state
   (lambda ()
     (let (value (lru-cache-get (provider-memo-state-cache state) key))
       (if value
           (let (hits-cell (provider-memo-state-hits-cell state))
             (vector-set! hits-cell 0 (+ 1 (vector-ref hits-cell 0)))
             value)
           (let (misses-cell (provider-memo-state-misses-cell state))
             (vector-set! misses-cell 0 (+ 1 (vector-ref misses-cell 0)))
             #f))))))

;; : (-> ProviderMemoState Object ProviderOperationResult Void)
(def (projection-memo-put! state key value)
  (when (and (<= (string-length (json->string key))
                 (provider-memo-state-key-byte-limit state))
             (<= (string-length
                  (json->string (provider-operation-result->json value)))
                 (provider-memo-state-value-byte-limit state)))
    (call-with-projection-memo-lock
     state
     (lambda ()
       (lru-cache-put! (provider-memo-state-cache state) key value)))))

;; : (-> ProviderMemoObservation)
(def (provider-runtime-projection-memo-observation)
  (let (state +provider-projection-memo+)
    (call-with-projection-memo-lock
     state
     (lambda ()
       (provider-memo-observation
        (lru-cache-size (provider-memo-state-cache state))
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
             (key (provider-operation-memo-key operation payload))
             (cached (projection-memo-ref +provider-projection-memo+ key)))
        (or cached
            (let (computed (provider-operation-execute descriptor payload))
              ;; Concurrent misses may duplicate pure parser work. Publication
              ;; happens only after the POO operation returns successfully.
              (projection-memo-put! +provider-projection-memo+ key computed)
              computed)))
      (provider-operation-execute descriptor payload)))

;; : (-> JsonObject JsonValue)
(def (projection-batch-owner-cache-key owner)
  ;; sourceLeafDigest is the protocol identity; source text/base64 is retained
  ;; as its immutable witness so an untrusted caller cannot alias forged bytes
  ;; onto a previously admitted projection.
  (vector (hash-ref owner "ownerPath" "")
          (hash-ref owner "sourceLeafDigest" "")
          (hash-ref owner "sourceEncoding" "")
          (hash-ref owner "sourceText" "")
          (hash-ref owner "sourceBytesBase64" "")))

;; : (-> JsonObject String [JsonValue])
(def (projection-batch-owner-cache-keys wire-value field)
  (map projection-batch-owner-cache-key
       (let (owners (hash-ref wire-value field '()))
         (cond
          ((vector? owners) (vector->list owners))
          ((list? owners) owners)
          (else
           (error "provider projection owner array is invalid" field))))))

;; : (-> String ProviderOperationPayload Object)
(def (provider-operation-memo-key operation payload)
  (let (wire-value (provider-operation-payload->json payload))
    (if (string=? operation "projection-batch")
        ;; std/misc/lru owns hashing, structural equality, and eviction for the
        ;; protocol-shaped key. std/text/json is reserved for bounded admission
        ;; on cache publication, rather than repeated on every warm lookup.
        (vector operation
                (hash-ref wire-value "schemaId" "")
                (hash-ref wire-value "schemaVersion" "")
                (hash-ref wire-value "languageId" "")
                (hash-ref wire-value "providerId" "")
                (hash-ref wire-value "workspaceIdentity" "")
                (hash-ref wire-value "generationRootDigest" "")
                (hash-ref wire-value "baseGenerationRootDigest" "")
                (hash-ref wire-value "parserIdentityDigest" "")
                (hash-ref wire-value "queryPackDigest" "")
                (list->vector
                 (projection-batch-owner-cache-keys wire-value "owners"))
                (list->vector
                 (projection-batch-owner-cache-keys
                  wire-value "auxiliaryOwners")))
        (string-append operation ":" (json->string wire-value)))))

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

;; : (-> ProviderOperationContract Procedure ProviderOperationDescriptor)
(def (bind-provider-operation contract execute)
  (provider-operation-descriptor
   (provider-operation-contract-operation contract)
   (provider-schema-reference
    (provider-operation-contract-request-schema-id contract)
    (provider-operation-contract-request-schema-version contract))
   (provider-schema-reference
    (provider-operation-contract-response-schema-id contract)
    (provider-operation-contract-response-schema-version contract))
   (provider-operation-contract-memoizable? contract)
   execute))

(def +provider-operation-executors+
  `(("projection-batch" . ,execute-projection-batch)
    ("project-resolution" . ,execute-project-resolution)
    ("query" . ,execute-native-exact-query)))

(def (provider-operation-executor contract)
  (let (entry (assoc (provider-operation-contract-operation contract)
                     +provider-operation-executors+))
    (if entry
        (cdr entry)
        (error "provider operation executable binding is absent"
               (provider-operation-contract-operation contract)))))

;; The runtime binds executable behavior to the protocol-owned static catalog;
;; discovery never imports this module or any runtime state.
;; : [ProviderOperationDescriptor]
(def provider-runtime-operation-descriptors
  (map (lambda (contract)
         (bind-provider-operation contract
                                  (provider-operation-executor contract)))
       provider-operation-contracts))

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
