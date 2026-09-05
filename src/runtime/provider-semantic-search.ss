;;; -*- Gerbil -*-
;;; Resident provider semantic-search packet projection.

(import :asp-gerbil-scheme/src/constants
        :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/language/facade
        (only-in :asp-gerbil-scheme/src/protocol/json pattern-mapping-json)
        :asp-gerbil-scheme/src/types/facade
        (only-in :std/srfi/13 string-join)
        (only-in :std/sugar hash))

(export provider-semantic-search-packet)

;; : (-> String (List String) JsonObject)
(def (semantic-packet-base schema-id namespace authority query quality
                           evidence-grade missing witness next)
  (hash (schemaId schema-id)
        (schemaVersion "1")
        (protocolId "agent.semantic-protocols.semantic-language")
        (protocolVersion "1")
        (languageId +language-id+)
        (providerId +provider-id+)
        (namespace namespace)
        (authority authority)
        (evidenceGrade evidence-grade)
        (quality quality)
        (query query)
        (missing missing)
        (witness witness)
        (next next)))

;; : (-> (List String) JsonObject)
(def (compiler-evidence-packet terms)
  (let* ((facts (compiler-evidence-facts))
         (fact (car facts))
         (packet
          (semantic-packet-base
           "agent.semantic-protocols.semantic-language-evidence"
           "compiler-evidence"
           "compiler-metadata-source"
           (string-join terms " ")
           "verified"
           "fact"
           []
           (hash-get fact 'witness)
           (hash-get fact 'next))))
    (hash-put! packet 'facts facts)
    packet))

;; : (-> (List String) JsonObject)
(def (runtime-source-packet terms)
  (let* ((facts (runtime-source-facts))
         (fact (or (find (lambda (candidate)
                           (equal? (hash-get candidate 'id)
                                   "gerbil-runtime-writeenv-source"))
                         facts)
                   (car facts)))
         (details (hash-get fact 'details))
         (packet
          (semantic-packet-base
           "agent.semantic-protocols.semantic-runtime-source-acquisition"
           "runtime-source"
           "active-runtime-version-source"
           (string-join terms " ")
           "version-matched-source-plan"
           (hash-get fact 'evidenceGrade)
           []
           (hash-get fact 'witness)
           (hash-get fact 'next))))
    ;; This specialized schema predates the semantic-language protocol id.
    (hash-put! packet 'protocolId "agent.semantic-protocols")
    (for-each
     (lambda (key)
       (hash-put! packet key (hash-get details key)))
     '(runtime sourceRef acquisition selectorResolver sourceExamples sourceComments))
    (hash-put! packet 'facts [fact])
    (hash-put! packet 'failureCases (hash-get fact 'failureCases))
    (hash-put! packet 'qualitySignals (hash-get fact 'qualitySignals))
    packet))

;; : (-> (List String) JsonObject)
(def (compare-packet terms)
  (let* ((comparisons (map compare-fact-json (matching-compare-facts terms)))
         (fact (car comparisons))
         (packet
          (semantic-packet-base
           "agent.semantic-protocols.semantic-compare-packet"
           "compare"
           "active-runtime-evidence"
           (string-join terms " ")
           "verified"
           "fact"
           []
           (hash-get fact 'witness)
           (hash-get fact 'next))))
    (hash-put! packet 'comparisons comparisons)
    packet))

;; : (-> (List String) JsonObject)
(def (extension-pattern-packet terms)
  (let* ((pattern (poo-pattern-evidence #f (cons "gerbil-poo" terms)))
         (mapping (pattern-mapping-json pattern))
         (missing (hash-get pattern 'missing))
         (quality (if (null? missing) "verified" "partial"))
         (packet
          (semantic-packet-base
           +semantic-extension-pattern-mapping-schema-id+
           "pattern"
           "executable-pattern"
           (string-join terms " ")
           quality
           "fact"
           missing
           (hash-get pattern 'witness)
           (hash-get pattern 'next))))
    (hash-put! packet 'patternMapping mapping)
    packet))

;; : (-> Void TypeProof)
(def (record-width-proof)
  (let* ((number-type (make-type-base "Number"))
         (string-type (make-type-base "String"))
         (refined-number (make-type-refine number-type "natural?"))
         (expected
          (make-type-record (list (cons "value" number-type)) ["value"]))
         (actual
          (make-type-record (list (cons "value" refined-number)
                                  (cons "tag" string-type))
                            ["value"])))
    (type-subtype-proof actual expected)))

;; : (-> (List String) JsonObject)
(def (type-proof-packet terms)
  (let* ((proof (record-width-proof))
         (compiler-fact (car (compiler-evidence-facts)))
         (packet
          (semantic-packet-base
           "agent.semantic-protocols.semantic-type-proof"
           "proof"
           "medium-weight-type-proof"
           (string-join terms " ")
           "verified"
           "fact"
           []
           "record-width-positive-derivation"
           "search compiler-evidence optimizer subtype assertion")))
    (hash-put!
     packet 'proofSystem
     (hash (id "gerbil-typespec-positive-derivation")
           (level "medium-weight")
           (engine "asp-gerbil-scheme-types")
           (model "TypeSpec")
           (claim "positive-derivation-witness")
           (relations ["alias-equivalent" "subtype" "compatible"])
           (ruleCatalog (type-proof-rules proof))
           (openTypePolicy "unknown-types-do-not-prove-subtyping")
           (sourceBoundary "provider-owned-typespec-engine")
           (compilerEvidenceNamespace "compiler-evidence")
           (notA ["complete-proof-assistant" "runtime-type-checker"])))
    (hash-put!
     packet 'proofs
     [(hash (id "record-width-subtype")
            (relation "subtype")
            (terms terms)
            (profile (type-proof-profile-json proof))
            (proof (type-proof-json proof)))])
    (hash-put!
     packet 'compilerEvidence
     (hash (namespace "compiler-evidence")
           (authority "compiler-metadata-source")
           (nextCommand "search compiler-evidence optimizer subtype assertion")
           (selectors (map (lambda (selector)
                             (hash-get selector 'selector))
                           (hash-get compiler-fact 'selectors)))
           (boundary "compiler metadata supports but does not replace TypeSpec proofs")))
    (hash-put! packet 'failureCases (hash-get compiler-fact 'failureCases))
    (hash-put! packet 'qualitySignals
               ["positive-derivation" "recursive-proof-tree"
                "compiler-evidence-boundary"])
    packet))

;;; Dispatch boundary:
;;; - Namespace selection is explicit and exhaustive for the v1 semantic
;;;   packets served by the resident provider.
;;; - The CLI transports a typed request and never invokes this module.
;; : (-> String (List String) JsonObject)
(def (provider-semantic-search-packet namespace terms)
  (case (string->symbol namespace)
    ((compiler-evidence) (compiler-evidence-packet terms))
    ((runtime-source) (runtime-source-packet terms))
    ((pattern) (extension-pattern-packet terms))
    ((compare) (compare-packet terms))
    ((proof) (type-proof-packet terms))
    (else (error "resident semantic-search namespace is not admitted"
                 namespace))))
