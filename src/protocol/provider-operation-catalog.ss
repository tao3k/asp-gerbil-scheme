;;; -*- Gerbil -*-
;;; Boundary: static provider operation contracts shared by discovery and the
;;; resident runtime.  This module owns no executable dispatch, environment,
;;; memo, or transport state.

(import :gerbil/gambit
        (only-in :clan/poo/object .def .o .ref .slot? object?)
        (only-in :clan/poo/mop Type. define-type element? validate)
        (only-in :std/srfi/1 every)
        (only-in :std/sugar hash)
        (only-in "../object-family/syntax"
                 defpoo-object-family
                 poo-family-ref))

(export ProviderOperationContract
        provider-operation-contract-prototype
        provider-operation-contract
        provider-operation-contract?
        provider-require-operation-contract!
        provider-operation-contract-operation
        provider-operation-contract-request-schema-id
        provider-operation-contract-request-schema-version
        provider-operation-contract-response-schema-id
        provider-operation-contract-response-schema-version
        provider-operation-contract-memoizable?
        provider-operation-contract->json
        provider-operation-contracts
        provider-operation-contract-by-operation)

(.def provider-operation-contract-prototype
  kind: 'provider/operation-contract
  boundary: 'provider-protocol)

(defpoo-object-family
  (accessors poo-family-ref
   (required
    (provider-operation-contract-operation operation)
    (provider-operation-contract-request-schema-id request-schema-id)
    (provider-operation-contract-request-schema-version request-schema-version)
    (provider-operation-contract-response-schema-id response-schema-id)
    (provider-operation-contract-response-schema-version response-schema-version)
    (provider-operation-contract-memoizable? memoizable?))
   (optional)))

(def (non-empty-string? value)
  (and (string? value) (> (string-length value) 0)))

(def (provider-operation-contract-element? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind operation request-schema-id request-schema-version
                     response-schema-id response-schema-version memoizable?))
       (eq? (.ref value 'kind) 'provider/operation-contract)
       (every (lambda (slot) (non-empty-string? (.ref value slot)))
              '(operation request-schema-id request-schema-version
                          response-schema-id response-schema-version))
       (boolean? (.ref value 'memoizable?))))

;;; Static operation-contract invariant:
;;; - Protocol discovery validates POO slots for operation and schema identity
;;;   but deliberately admits no executable slot or runtime state.
;;; - Registry tests witness the POO object and the absence of =execute=;
;;;   provider-operation binds behavior only after entering the runtime owner.
(define-type (ProviderOperationContract @ Type.)
  .element?: provider-operation-contract-element?)

(def (provider-operation-contract? value)
  (element? ProviderOperationContract value))

(def (provider-require-operation-contract! value)
  (validate ProviderOperationContract value))

(def (provider-operation-contract operation-value
                                  request-schema-id-value
                                  request-schema-version-value
                                  response-schema-id-value
                                  response-schema-version-value
                                  memoizable-value)
  (provider-require-operation-contract!
   (.o (:: @ [provider-operation-contract-prototype])
       operation: operation-value
       request-schema-id: request-schema-id-value
       request-schema-version: request-schema-version-value
       response-schema-id: response-schema-id-value
       response-schema-version: response-schema-version-value
       memoizable?: memoizable-value)))

(def (provider-operation-contract->json contract)
  (provider-require-operation-contract! contract)
  (hash
   ("operation" (provider-operation-contract-operation contract))
   ("requestSchema"
    (hash
     ("schemaId" (provider-operation-contract-request-schema-id contract))
     ("schemaVersion"
      (provider-operation-contract-request-schema-version contract))))
   ("responseSchema"
    (hash
     ("schemaId" (provider-operation-contract-response-schema-id contract))
     ("schemaVersion"
      (provider-operation-contract-response-schema-version contract))))))

(def provider-operation-contracts
  [(provider-operation-contract
    "projection-batch"
    "agent.semantic-protocols.provider-language-projection-batch-request" "1"
    "agent.semantic-protocols.provider-language-projection-batch-response" "1"
    #t)
   (provider-operation-contract
    "project-resolution"
    "agent.semantic-protocols.provider-project-resolution-request" "1"
    "agent.semantic-protocols.provider-project-resolution-response" "1"
    #f)
   (provider-operation-contract
    "query"
    "agent.semantic-protocols.provider-native-exact-request" "1"
    "agent.semantic-protocols.provider-native-exact-projection" "1"
    #f)])

(def (provider-operation-contract-by-operation operation)
  (or (find (lambda (contract)
              (string=? operation
                        (provider-operation-contract-operation contract)))
            provider-operation-contracts)
      (error "provider operation contract is not admitted" operation)))
