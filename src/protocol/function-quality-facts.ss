;;; -*- Gerbil -*-
;;; Structural JSON projection for parser-owned function quality profiles.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/protocol/support
        (only-in :std/misc/list unique))

(export function-quality-profile-structural-fact-json)

;; : (-> FunctionQualityProfile Json )
(def (function-quality-profile-structural-fact-json profile)
  (hash (id (native-syntax-fact-id "function-quality-profile"
                                   (function-quality-profile-path profile)
                                   (function-quality-profile-name profile)
                                   (function-quality-profile-start profile)))
        (kind "custom")
        (source "native-parser")
        (languageKind (function-quality-profile-kind profile))
        (name (function-quality-profile-name profile))
        (ownerPath (function-quality-profile-path profile))
        (location (fact-location-json
                   (function-quality-profile-path profile)
                   (function-quality-profile-start profile)
                   (function-quality-profile-end profile)))
        (queryKeys (function-quality-profile-query-keys profile))
        (fields (function-quality-profile-fields-json profile))))

;;; Query keys bridge agent vocabulary to protocol field names so natural
;;; "function quality" questions land on parser-owned evidence instead of
;;; broad policy or source scans.
;; : (-> FunctionQualityProfile (List QueryKey) )
(def (function-quality-profile-query-keys profile)
  (unique
   (filter identity
           (append [(function-quality-profile-name profile)
                    (function-quality-profile-kind profile)
                    (function-quality-profile-role profile)
                    (function-quality-profile-path profile)
                    (function-quality-profile-typed-contract-quality profile)
                    (function-quality-profile-comment-quality profile)
                    (function-quality-profile-suggested-repair-class profile)
                    (function-quality-profile-parser-confidence profile)
                    (function-quality-profile-advice profile)
                    "functionQualityProfile"
                    "function-quality-profile"
                    "function-quality"
                    "quality-profile"
                    "multi-layer-policy"
                    "findingGroup"
                    "finding-group"
                    "repairPlan"
                    "repair-plan"
                    "policy-correlation"
                    "agent-repair-plan"]
                   (function-quality-profile-formals profile)
                   (function-quality-profile-control-flow-roles profile)
                   (function-quality-profile-higher-order-roles profile)
                   (function-quality-profile-predicate-family-refs profile)
                   (function-quality-profile-field-access-pattern-refs profile)
                   (function-quality-profile-loop-driver-refs profile)
                   (function-quality-profile-macro-refs profile)
                   (function-quality-profile-poo-protocol-refs profile)
                   (function-quality-profile-quality-facets profile)
                   (function-quality-profile-preservation-reasons profile)))))

;;; Field projection keeps every profile signal under one JSON object.
;;; Policy/search consumers can rank repair class, confidence, and preservation
;;; reasons without rejoining parser facts.
;; : (-> FunctionQualityProfile Json )
(def (function-quality-profile-fields-json profile)
  (hash (role (function-quality-profile-role profile))
        (exported (function-quality-profile-exported profile))
        (formals (function-quality-profile-formals profile))
        (arity (function-quality-profile-arity profile))
        (typedContractQuality
         (function-quality-profile-typed-contract-quality profile))
        (commentQuality (function-quality-profile-comment-quality profile))
        (controlFlowRoles
         (function-quality-profile-control-flow-roles profile))
        (higherOrderRoles
         (function-quality-profile-higher-order-roles profile))
        (predicateFamilyRefs
         (function-quality-profile-predicate-family-refs profile))
        (fieldAccessPatternRefs
         (function-quality-profile-field-access-pattern-refs profile))
        (loopDriverRefs (function-quality-profile-loop-driver-refs profile))
        (macroRefs (function-quality-profile-macro-refs profile))
        (pooProtocolRefs (function-quality-profile-poo-protocol-refs profile))
        (qualityFacets (function-quality-profile-quality-facets profile))
        (preservationReasons
         (function-quality-profile-preservation-reasons profile))
        (suggestedRepairClass
         (function-quality-profile-suggested-repair-class profile))
        (parserConfidence (function-quality-profile-parser-confidence profile))
        (advice (function-quality-profile-advice profile))))
