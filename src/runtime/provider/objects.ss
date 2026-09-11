;;; -*- Gerbil -*-
;;; Boundary: POO prototypes, constructors, accessors, and closed JSON
;;; projections for the resident provider runtime.

(import :gerbil/gambit
        (only-in :clan/poo/object .cc .def .o .ref)
        (only-in :std/sugar hash)
        (only-in "../../object-family/syntax"
                 defpoo-object-family
                 poo-family-ref)
        "types.ss")

(export provider-schema-reference-prototype
        provider-operation-descriptor-prototype
        provider-operation-payload-prototype
        provider-operation-result-prototype
        provider-runtime-request-prototype
        provider-runtime-response-prototype
        provider-runtime-contract-prototype
        provider-memo-state-prototype
        provider-memo-observation-prototype
        provider-request-stream-state-prototype
        provider-http-runtime-state-prototype
        provider-schema-reference
        provider-operation-descriptor
        provider-operation-payload
        provider-operation-result
        provider-runtime-request
        provider-runtime-ready-response
        provider-runtime-error-response
        provider-runtime-contract
        provider-memo-state
        provider-memo-observation
        provider-request-stream-state
        provider-request-stream-advance
        provider-http-runtime-state
        provider-schema-reference-schema-id
        provider-schema-reference-schema-version
        provider-operation-descriptor-operation
        provider-operation-descriptor-request-schema
        provider-operation-descriptor-response-schema
        provider-operation-descriptor-memoizable?
        provider-operation-payload-operation
        provider-operation-payload-wire-value
        provider-operation-result-operation
        provider-operation-result-wire-value
        provider-runtime-request-id
        provider-runtime-request-operation
        provider-runtime-request-payload
        provider-runtime-response-request-id
        provider-runtime-response-outcome
        provider-runtime-response-payload
        provider-runtime-response-error
        provider-runtime-contract-provider-id
        provider-runtime-contract-language-id
        provider-runtime-contract-artifact-digest
        provider-runtime-contract-registration-digest
        provider-runtime-contract-contract-digest
        provider-runtime-contract-transport
        provider-runtime-contract-operations
        provider-memo-state-lock
        provider-memo-state-entries-cell
        provider-memo-state-hits-cell
        provider-memo-state-misses-cell
        provider-memo-state-entry-limit
        provider-memo-state-key-byte-limit
        provider-memo-state-value-byte-limit
        provider-memo-observation-entries
        provider-memo-observation-entry-limit
        provider-memo-observation-key-byte-limit
        provider-memo-observation-value-byte-limit
        provider-memo-observation-hits
        provider-memo-observation-misses
        provider-request-stream-id
        provider-request-stream-frame-count
        provider-request-stream-next-index
        provider-request-stream-chunks
        provider-http-runtime-server
        provider-http-runtime-stream-lock
        provider-http-runtime-streams-cell
        provider-http-runtime-frame-limit
        provider-schema-reference->json
        provider-operation-descriptor->json
        provider-operation-payload->json
        provider-operation-result->json
        provider-runtime-response->json
        provider-runtime-contract->json
        provider-memo-observation->json)

(.def provider-schema-reference-prototype
  kind: 'provider/schema-reference
  boundary: 'provider-protocol)

(.def provider-operation-descriptor-prototype
  kind: 'provider/operation
  boundary: 'provider-operation
  memoizable?: #f
  execute: #f)

(.def provider-operation-payload-prototype
  kind: 'provider/operation-payload
  boundary: 'provider-operation-adapter)

(.def provider-operation-result-prototype
  kind: 'provider/operation-result
  boundary: 'provider-operation-adapter)

(.def provider-runtime-request-prototype
  kind: 'provider/runtime-request
  boundary: 'provider-operation)

(.def provider-runtime-response-prototype
  kind: 'provider/runtime-response
  boundary: 'provider-operation
  payload: #f
  error: #f)

(.def provider-runtime-contract-prototype
  kind: 'provider/runtime-contract
  boundary: 'provider-observability
  transport: "http-json")

(.def provider-memo-state-prototype
  kind: 'provider/memo-state
  boundary: 'provider-runtime-state)

(.def provider-memo-observation-prototype
  kind: 'provider/memo-observation
  boundary: 'provider-observability)

(.def provider-request-stream-state-prototype
  kind: 'provider/request-stream
  boundary: 'provider-http-runtime)

(.def provider-http-runtime-state-prototype
  kind: 'provider/http-runtime-state
  boundary: 'provider-http-runtime)

(defpoo-object-family
  (accessors poo-family-ref
   (required
    (provider-schema-reference-schema-id schema-id)
    (provider-schema-reference-schema-version schema-version)
    (provider-operation-descriptor-operation operation)
    (provider-operation-descriptor-request-schema request-schema)
    (provider-operation-descriptor-response-schema response-schema)
    (provider-operation-descriptor-memoizable? memoizable?)
    (provider-operation-payload-operation operation)
    (provider-operation-payload-wire-value wire-value)
    (provider-operation-result-operation operation)
    (provider-operation-result-wire-value wire-value)
    (provider-runtime-request-id request-id)
    (provider-runtime-request-operation operation)
    (provider-runtime-request-payload payload)
    (provider-runtime-response-request-id request-id)
    (provider-runtime-response-outcome outcome)
    (provider-runtime-response-payload payload)
    (provider-runtime-response-error error)
    (provider-runtime-contract-provider-id provider-id)
    (provider-runtime-contract-language-id language-id)
    (provider-runtime-contract-artifact-digest artifact-digest)
    (provider-runtime-contract-registration-digest registration-digest)
    (provider-runtime-contract-contract-digest contract-digest)
    (provider-runtime-contract-transport transport)
    (provider-runtime-contract-operations operations)
    (provider-memo-state-lock lock)
    (provider-memo-state-entries-cell entries-cell)
    (provider-memo-state-hits-cell hits-cell)
    (provider-memo-state-misses-cell misses-cell)
    (provider-memo-state-entry-limit entry-limit)
    (provider-memo-state-key-byte-limit key-byte-limit)
    (provider-memo-state-value-byte-limit value-byte-limit)
    (provider-memo-observation-entries entries)
    (provider-memo-observation-entry-limit entry-limit)
    (provider-memo-observation-key-byte-limit key-byte-limit)
    (provider-memo-observation-value-byte-limit value-byte-limit)
    (provider-memo-observation-hits hits)
    (provider-memo-observation-misses misses)
    (provider-request-stream-id stream-id)
    (provider-request-stream-frame-count frame-count)
    (provider-request-stream-next-index next-index)
    (provider-request-stream-chunks chunks)
    (provider-http-runtime-server server)
    (provider-http-runtime-stream-lock stream-lock)
    (provider-http-runtime-streams-cell streams-cell)
    (provider-http-runtime-frame-limit frame-limit))
   (optional)))

;; : (-> String String ProviderSchemaReference)
(def (provider-schema-reference schema-id-value schema-version-value)
  (provider-require-schema-reference!
   (.o (:: @ [provider-schema-reference-prototype])
       schema-id: schema-id-value
       schema-version: schema-version-value)))

;; : (-> String ProviderSchemaReference ProviderSchemaReference Boolean Procedure
;;        ProviderOperationDescriptor)
(def (provider-operation-descriptor operation-value request-schema-value
                                    response-schema-value memoizable-value
                                    execute-value)
  (provider-require-operation-descriptor!
   (.o (:: @ [provider-operation-descriptor-prototype])
       operation: operation-value
       request-schema: request-schema-value
       response-schema: response-schema-value
       memoizable?: memoizable-value
       execute: execute-value)))

;; : (-> String JsonObject ProviderOperationPayload)
(def (provider-operation-payload operation-value wire-value-value)
  (provider-require-operation-payload!
   (.o (:: @ [provider-operation-payload-prototype])
       operation: operation-value
       wire-value: wire-value-value)))

;; : (-> String JsonObject ProviderOperationResult)
(def (provider-operation-result operation-value wire-value-value)
  (provider-require-operation-result!
   (.o (:: @ [provider-operation-result-prototype])
       operation: operation-value
       wire-value: wire-value-value)))

;; : (-> String ProviderOperationDescriptor ProviderOperationPayload
;;        ProviderRuntimeRequest)
(def (provider-runtime-request request-id-value operation-value payload-value)
  (provider-require-runtime-request!
   (.o (:: @ [provider-runtime-request-prototype])
       request-id: request-id-value
       operation: operation-value
       payload: payload-value)))

;; : (-> String ProviderOperationResult ProviderRuntimeResponse)
(def (provider-runtime-ready-response request-id-value payload-value)
  (provider-require-runtime-response!
   (.o (:: @ [provider-runtime-response-prototype])
       request-id: request-id-value
       outcome: 'ready
       payload: payload-value)))

;; : (-> String String ProviderRuntimeResponse)
(def (provider-runtime-error-response request-id-value error-value)
  (provider-require-runtime-response!
   (.o (:: @ [provider-runtime-response-prototype])
       request-id: request-id-value
       outcome: 'error
       error: error-value)))

;; : (-> String String String String String [ProviderOperationDescriptor]
;;        ProviderRuntimeContract)
(def (provider-runtime-contract provider-id-value language-id-value
                                artifact-digest-value registration-digest-value
                                contract-digest-value operations-value)
  (provider-require-runtime-contract!
   (.o (:: @ [provider-runtime-contract-prototype])
       provider-id: provider-id-value
       language-id: language-id-value
       artifact-digest: artifact-digest-value
       registration-digest: registration-digest-value
       contract-digest: contract-digest-value
       operations: operations-value)))

;; : (-> Natural Natural Natural ProviderMemoState)
(def (provider-memo-state entry-limit-value key-byte-limit-value
                          value-byte-limit-value)
  (provider-require-memo-state!
   (.o (:: @ [provider-memo-state-prototype])
       lock: (make-mutex 'provider-projection-memo)
       entries-cell: (vector '())
       hits-cell: (vector 0)
       misses-cell: (vector 0)
       entry-limit: entry-limit-value
       key-byte-limit: key-byte-limit-value
       value-byte-limit: value-byte-limit-value)))

;; : (-> Natural Natural Natural Natural Natural Natural ProviderMemoObservation)
(def (provider-memo-observation entries-value entry-limit-value
                                key-byte-limit-value value-byte-limit-value
                                hits-value misses-value)
  (provider-require-memo-observation!
   (.o (:: @ [provider-memo-observation-prototype])
       entries: entries-value
       entry-limit: entry-limit-value
       key-byte-limit: key-byte-limit-value
       value-byte-limit: value-byte-limit-value
       hits: hits-value
       misses: misses-value)))

;; : (-> String Natural Natural [String] ProviderRequestStreamState)
(def (provider-request-stream-state stream-id-value frame-count-value
                                    next-index-value chunks-value)
  (provider-require-request-stream-state!
   (.o (:: @ [provider-request-stream-state-prototype])
       stream-id: stream-id-value
       frame-count: frame-count-value
       next-index: next-index-value
       chunks: chunks-value)))

;; : (-> ProviderRequestStreamState String ProviderRequestStreamState)
(def (provider-request-stream-advance state chunk)
  (provider-require-request-stream-state!
   (.cc state
        'next-index (+ 1 (provider-request-stream-next-index state))
        'chunks (cons chunk (provider-request-stream-chunks state)))))

;; : (-> HttpServer Mutex Vector Natural ProviderHttpRuntimeState)
(def (provider-http-runtime-state server-value stream-lock-value
                                  streams-cell-value frame-limit-value)
  (provider-require-http-runtime-state!
   (.o (:: @ [provider-http-runtime-state-prototype])
       server: server-value
       stream-lock: stream-lock-value
       streams-cell: streams-cell-value
       frame-limit: frame-limit-value)))

;; : (-> ProviderSchemaReference JsonObject)
(def (provider-schema-reference->json schema)
  (provider-require-schema-reference! schema)
  (hash ("schemaId" (provider-schema-reference-schema-id schema))
        ("schemaVersion" (provider-schema-reference-schema-version schema))))

;; : (-> ProviderOperationDescriptor JsonObject)
(def (provider-operation-descriptor->json descriptor)
  (provider-require-operation-descriptor! descriptor)
  (hash ("operation" (provider-operation-descriptor-operation descriptor))
        ("requestSchema"
         (provider-schema-reference->json
          (provider-operation-descriptor-request-schema descriptor)))
        ("responseSchema"
         (provider-schema-reference->json
          (provider-operation-descriptor-response-schema descriptor)))))

;; Explicit schema adapter projections.  Runtime callers exchange POO values;
;; only transport and schema-owned legacy functions receive the wire hash.
(def (provider-operation-payload->json payload)
  (provider-require-operation-payload! payload)
  (provider-operation-payload-wire-value payload))

(def (provider-operation-result->json result)
  (provider-require-operation-result! result)
  (provider-operation-result-wire-value result))

;; : (-> ProviderRuntimeResponse JsonObject)
(def (provider-runtime-response->json response)
  (provider-require-runtime-response! response)
  (let (base
        (hash ("schemaId" "agent.semantic-protocols.provider-runtime-response-frame")
              ("schemaVersion" "1")
              ("requestId" (provider-runtime-response-request-id response))
              ("outcome"
               (symbol->string (provider-runtime-response-outcome response)))))
    (case (provider-runtime-response-outcome response)
      ((ready)
       (hash-put! base "payload"
                  (provider-operation-result->json
                   (provider-runtime-response-payload response))))
      ((error)
       (hash-put! base "error" (provider-runtime-response-error response))))
    base))

;; : (-> ProviderRuntimeContract JsonObject)
(def (provider-runtime-contract->json contract)
  (provider-require-runtime-contract! contract)
  (hash ("schemaId" "agent.semantic-protocols.provider-runtime-contract-receipt")
        ("schemaVersion" "1")
        ("providerId" (provider-runtime-contract-provider-id contract))
        ("languageId" (provider-runtime-contract-language-id contract))
        ("artifactDigest"
         (provider-runtime-contract-artifact-digest contract))
        ("registrationDigest"
         (provider-runtime-contract-registration-digest contract))
        ("contractDigest"
         (provider-runtime-contract-contract-digest contract))
        ("transport" (provider-runtime-contract-transport contract))
        ("operations"
         (map provider-operation-descriptor->json
              (provider-runtime-contract-operations contract)))))

;; : (-> ProviderMemoObservation JsonObject)
(def (provider-memo-observation->json observation)
  (provider-require-memo-observation! observation)
  (hash ("entries" (provider-memo-observation-entries observation))
        ("entryLimit" (provider-memo-observation-entry-limit observation))
        ("keyByteLimit"
         (provider-memo-observation-key-byte-limit observation))
        ("valueByteLimit"
         (provider-memo-observation-value-byte-limit observation))
        ("hits" (provider-memo-observation-hits observation))
        ("misses" (provider-memo-observation-misses observation))))
