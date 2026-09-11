;;; -*- Gerbil -*-
;;; Boundary: native POO contracts for the resident provider runtime.
;;; Invariant: JSON hashes are admitted only at the transport edge; runtime
;;; semantics, operation identity, state, and observations are POO objects.

(import :gerbil/gambit
        (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop Type. define-type element? validate)
        (only-in :std/srfi/1 every))

(export ProviderSchemaReference
        ProviderOperationDescriptor
        ProviderOperationPayload
        ProviderOperationResult
        ProviderRuntimeRequest
        ProviderRuntimeResponse
        ProviderRuntimeContract
        ProviderMemoState
        ProviderMemoObservation
        ProviderRequestStreamState
        ProviderHttpRuntimeState
        provider-schema-reference?
        provider-operation-descriptor?
        provider-operation-payload?
        provider-operation-result?
        provider-runtime-request?
        provider-runtime-response?
        provider-runtime-contract?
        provider-memo-state?
        provider-memo-observation?
        provider-request-stream-state?
        provider-http-runtime-state?
        provider-require-schema-reference!
        provider-require-operation-descriptor!
        provider-require-operation-payload!
        provider-require-operation-result!
        provider-require-runtime-request!
        provider-require-runtime-response!
        provider-require-runtime-contract!
        provider-require-memo-state!
        provider-require-memo-observation!
        provider-require-request-stream-state!
        provider-require-http-runtime-state!)

;; : (-> Object [Symbol] Boolean)
(def (provider-object-slots? candidate slots)
  (and (object? candidate)
       (every (lambda (slot) (.slot? candidate slot)) slots)))

;; : (-> Object Boolean)
(def (non-empty-string? value)
  (and (string? value) (> (string-length value) 0)))

;; : (-> Object Boolean)
(def (natural? value)
  (and (integer? value) (>= value 0)))

;; : (-> Object Boolean)
(def (positive-natural? value)
  (and (integer? value) (> value 0)))

;; : (-> Object Boolean)
(def (provider-schema-reference-element? value)
  (and (provider-object-slots? value '(kind schema-id schema-version))
       (eq? (.ref value 'kind) 'provider/schema-reference)
       (non-empty-string? (.ref value 'schema-id))
       (non-empty-string? (.ref value 'schema-version))))

;;; Schema-reference protocol invariant:
;;; - A runtime schema identity is non-empty and versioned before any operation
;;;   descriptor may retain it.
;;; - Provider type tests exercise both accepted POO values and rejected hashes.
(define-type (ProviderSchemaReference @ Type.)
  .element?: provider-schema-reference-element?)

;; : (-> Object Boolean)
(def (provider-operation-descriptor-element? value)
  (and (provider-object-slots?
        value
        '(kind operation request-schema response-schema memoizable? execute))
       (eq? (.ref value 'kind) 'provider/operation)
       (non-empty-string? (.ref value 'operation))
       (element? ProviderSchemaReference (.ref value 'request-schema))
       (element? ProviderSchemaReference (.ref value 'response-schema))
       (boolean? (.ref value 'memoizable?))
       (procedure? (.ref value 'execute))))

;;; Operation-descriptor protocol boundary:
;;; - Request and response schemas are validated POO references, while execute
;;;   remains the only callable behavior slot.
;;; - Provider contract tests witness operation identity and schema mismatch.
(define-type (ProviderOperationDescriptor @ Type.)
  .element?: provider-operation-descriptor-element?)

;; The wire value remains opaque to the provider protocol.  Giving it a POO
;; identity here prevents raw JSON hashes from becoming the runtime's public
;; operation API; operation adapters unwrap it only at their schema-owned ABI.
(def (provider-operation-payload-element? value)
  (and (provider-object-slots? value '(kind operation wire-value))
       (eq? (.ref value 'kind) 'provider/operation-payload)
       (non-empty-string? (.ref value 'operation))
       (hash-table? (.ref value 'wire-value))))

;;; Payload ABI boundary:
;;; - The wire hash stays opaque behind an operation-tagged POO value so it
;;;   cannot become the public runtime object model.
;;; - Provider operation tests witness payload validation before dispatch.
(define-type (ProviderOperationPayload @ Type.)
  .element?: provider-operation-payload-element?)

(def (provider-operation-result-element? value)
  (and (provider-object-slots? value '(kind operation wire-value))
       (eq? (.ref value 'kind) 'provider/operation-result)
       (non-empty-string? (.ref value 'operation))
       (hash-table? (.ref value 'wire-value))))

;;; Result ABI boundary:
;;; - Operation identity travels with the opaque wire value and must match the
;;;   descriptor selected by the runtime.
;;; - Provider operation tests witness validation before response projection.
(define-type (ProviderOperationResult @ Type.)
  .element?: provider-operation-result-element?)

;; : (-> Object Boolean)
(def (provider-runtime-request-element? value)
  (and (provider-object-slots? value '(kind request-id operation payload))
       (eq? (.ref value 'kind) 'provider/runtime-request)
       (non-empty-string? (.ref value 'request-id))
       (element? ProviderOperationDescriptor (.ref value 'operation))
       (element? ProviderOperationPayload (.ref value 'payload))
       (string=? (.ref (.ref value 'operation) 'operation)
                 (.ref (.ref value 'payload) 'operation))))

;;; Runtime-request invariant:
;;; - Descriptor and payload operation identities must agree before execution;
;;;   transport hashes are admitted only after this POO validation boundary.
;;; - Provider request tests exercise both matching and mismatched operations.
(define-type (ProviderRuntimeRequest @ Type.)
  .element?: provider-runtime-request-element?)

;; : (-> Object Boolean)
(def (provider-runtime-response-element? value)
  (and (provider-object-slots? value '(kind request-id outcome payload error))
       (eq? (.ref value 'kind) 'provider/runtime-response)
       (non-empty-string? (.ref value 'request-id))
       (memq (.ref value 'outcome) '(ready error))
       (case (.ref value 'outcome)
         ((ready) (element? ProviderOperationResult (.ref value 'payload)))
         ((error) (non-empty-string? (.ref value 'error)))
         (else #f))))

;;; Runtime-response sum boundary:
;;; - Ready outcomes require a typed result and error outcomes require a
;;;   non-empty diagnostic, preventing ambiguous partially populated responses.
;;; - Provider response tests witness both branches of the closed outcome set.
(define-type (ProviderRuntimeResponse @ Type.)
  .element?: provider-runtime-response-element?)

;; : (-> Object Boolean)
(def (provider-runtime-contract-element? value)
  (and (provider-object-slots?
        value
        '(kind provider-id language-id artifact-digest registration-digest
               contract-digest transport operations))
       (eq? (.ref value 'kind) 'provider/runtime-contract)
       (every non-empty-string?
              (map (lambda (slot) (.ref value slot))
                   '(provider-id language-id artifact-digest registration-digest
                     contract-digest transport)))
       (list? (.ref value 'operations))
       (every provider-operation-descriptor-element?
              (.ref value 'operations))))

;;; Resident-contract invariant:
;;; - Provider identity, artifact digests, transport, and operation descriptors
;;;   form one validated POO capability surface before server startup.
;;; - Runtime contract tests witness rejection of incomplete registrations.
(define-type (ProviderRuntimeContract @ Type.)
  .element?: provider-runtime-contract-element?)

;; : (-> Object Boolean)
(def (single-cell? value)
  (and (vector? value) (= (vector-length value) 1)))

;; : (-> Object Boolean)
(def (provider-memo-state-element? value)
  (and (provider-object-slots?
        value
        '(kind lock entries-cell hits-cell misses-cell entry-limit
               key-byte-limit value-byte-limit))
       (eq? (.ref value 'kind) 'provider/memo-state)
       (mutex? (.ref value 'lock))
       (every single-cell?
              (map (lambda (slot) (.ref value slot))
                   '(entries-cell hits-cell misses-cell)))
       (list? (vector-ref (.ref value 'entries-cell) 0))
       (natural? (vector-ref (.ref value 'hits-cell) 0))
       (natural? (vector-ref (.ref value 'misses-cell) 0))
       (every positive-natural?
              (map (lambda (slot) (.ref value slot))
                   '(entry-limit key-byte-limit value-byte-limit)))))

;;; Memo-state ownership boundary:
;;; - One mutex protects the three mutable cells, while positive limits bound
;;;   every admitted cache entry and serialized value.
;;; - Memo tests exercise state validation and bounded update behavior.
(define-type (ProviderMemoState @ Type.)
  .element?: provider-memo-state-element?)

;; : (-> Object Boolean)
(def (provider-memo-observation-element? value)
  (and (provider-object-slots?
        value
        '(kind entries entry-limit key-byte-limit value-byte-limit hits misses))
       (eq? (.ref value 'kind) 'provider/memo-observation)
       (every natural?
              (map (lambda (slot) (.ref value slot))
                   '(entries hits misses)))
       (every positive-natural?
              (map (lambda (slot) (.ref value slot))
                   '(entry-limit key-byte-limit value-byte-limit)))))

;;; Memo-observation boundary:
;;; - Snapshots expose natural counters and positive configured limits without
;;;   leaking the mutable state cells or lock.
;;; - Memo observation tests witness the immutable projection contract.
(define-type (ProviderMemoObservation @ Type.)
  .element?: provider-memo-observation-element?)

;; : (-> Object Boolean)
(def (provider-request-stream-state-element? value)
  (and (provider-object-slots?
        value '(kind stream-id frame-count next-index chunks))
       (eq? (.ref value 'kind) 'provider/request-stream)
       (non-empty-string? (.ref value 'stream-id))
       (positive-natural? (.ref value 'frame-count))
       (natural? (.ref value 'next-index))
       (<= (.ref value 'next-index) (.ref value 'frame-count))
       (list? (.ref value 'chunks))
       (every string? (.ref value 'chunks))))

;;; Request-stream state invariant:
;;; - Frame count, next index, and ordered chunks are validated together so a
;;;   stream cannot advance beyond its declared frame domain.
;;; - Streaming tests witness ordered assembly and invalid-index rejection.
(define-type (ProviderRequestStreamState @ Type.)
  .element?: provider-request-stream-state-element?)

;; : (-> Object Boolean)
(def (provider-http-runtime-state-element? value)
  (and (provider-object-slots?
        value '(kind server stream-lock streams-cell frame-limit))
       (eq? (.ref value 'kind) 'provider/http-runtime-state)
       (.ref value 'server)
       (mutex? (.ref value 'stream-lock))
       (vector? (.ref value 'streams-cell))
       (= (vector-length (.ref value 'streams-cell)) 1)
       (list? (vector-ref (.ref value 'streams-cell) 0))
       (positive-natural? (.ref value 'frame-limit))))

;;; HTTP runtime-state boundary:
;;; - Server capability, stream lock, single state cell, and positive frame
;;;   limit remain one POO object owned by the resident transport runtime.
;;; - HTTP provider tests witness construction before request handling begins.
(define-type (ProviderHttpRuntimeState @ Type.)
  .element?: provider-http-runtime-state-element?)

(def (provider-schema-reference? value)
  (element? ProviderSchemaReference value))
(def (provider-operation-descriptor? value)
  (element? ProviderOperationDescriptor value))
(def (provider-operation-payload? value)
  (element? ProviderOperationPayload value))
(def (provider-operation-result? value)
  (element? ProviderOperationResult value))
(def (provider-runtime-request? value)
  (element? ProviderRuntimeRequest value))
(def (provider-runtime-response? value)
  (element? ProviderRuntimeResponse value))
(def (provider-runtime-contract? value)
  (element? ProviderRuntimeContract value))
(def (provider-memo-state? value)
  (element? ProviderMemoState value))
(def (provider-memo-observation? value)
  (element? ProviderMemoObservation value))
(def (provider-request-stream-state? value)
  (element? ProviderRequestStreamState value))
(def (provider-http-runtime-state? value)
  (element? ProviderHttpRuntimeState value))

(def (provider-require-schema-reference! value)
  (validate ProviderSchemaReference value))
(def (provider-require-operation-descriptor! value)
  (validate ProviderOperationDescriptor value))
(def (provider-require-operation-payload! value)
  (validate ProviderOperationPayload value))
(def (provider-require-operation-result! value)
  (validate ProviderOperationResult value))
(def (provider-require-runtime-request! value)
  (validate ProviderRuntimeRequest value))
(def (provider-require-runtime-response! value)
  (validate ProviderRuntimeResponse value))
(def (provider-require-runtime-contract! value)
  (validate ProviderRuntimeContract value))
(def (provider-require-memo-state! value)
  (validate ProviderMemoState value))
(def (provider-require-memo-observation! value)
  (validate ProviderMemoObservation value))
(def (provider-require-request-stream-state! value)
  (validate ProviderRequestStreamState value))
(def (provider-require-http-runtime-state! value)
  (validate ProviderHttpRuntimeState value))
