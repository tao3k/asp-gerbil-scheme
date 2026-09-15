;;; -*- Gerbil -*-
;;; Structural JSON projection for parser-owned quality-shape facts.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/protocol/support
        (only-in :std/misc/list unique)
        (only-in :std/sugar filter hash))

(export predicate-family-structural-fact-json
        field-access-pattern-structural-fact-json
        boolean-condition-structural-fact-json
        loop-driver-structural-fact-json)

;; : (-> PredicateFamilyFact Json )
(def (predicate-family-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "predicate-family"
                                   (predicate-family-fact-path fact)
                                   (predicate-family-fact-name fact)
                                   (predicate-family-fact-start fact)))
        (kind "custom")
        (source "native-parser")
        (languageKind (predicate-family-fact-kind fact))
        (name (predicate-family-fact-name fact))
        (ownerPath (predicate-family-fact-path fact))
        (location (fact-location-json (predicate-family-fact-path fact)
                                      (predicate-family-fact-start fact)
                                      (predicate-family-fact-end fact)))
        (queryKeys (predicate-family-query-keys fact))
        (fields (predicate-family-fields-json fact))))

;;; Query keys intentionally mix stable identifiers, advice text, and native
;;; evidence lists so search can surface the repair boundary without reading
;;; the source owner.
;; : (-> PredicateFamilyFact (List QueryKey) )
(def (predicate-family-query-keys fact)
  (unique
   (filter identity
           (append [(predicate-family-fact-name fact)
                    (predicate-family-fact-kind fact)
                    (predicate-family-fact-role fact)
                    (predicate-family-fact-subject fact)
                    (predicate-family-fact-path fact)
                    (predicate-family-fact-advice fact)
                    "predicate-family"
                    "field-access-pattern"
                    "gerbil-utils-combinator-style"]
                   (predicate-family-fact-predicate-names fact)
                   (predicate-family-fact-field-keys fact)
                   (predicate-family-fact-repeated-callees fact)
                   (predicate-family-fact-quality-facets fact)))))

;; : (-> PredicateFamilyFact Json )
(def (predicate-family-fields-json fact)
  (hash (role (predicate-family-fact-role fact))
        (subject (predicate-family-fact-subject fact))
        (predicateNames (predicate-family-fact-predicate-names fact))
        (predicateCount (predicate-family-fact-predicate-count fact))
        (fieldKeys (predicate-family-fact-field-keys fact))
        (repeatedCallees (predicate-family-fact-repeated-callees fact))
        (conditionCount (predicate-family-fact-condition-count fact))
        (qualityFacets (predicate-family-fact-quality-facets fact))
        (advice (predicate-family-fact-advice fact))))

;; : (-> FieldAccessPatternFact Json )
(def (field-access-pattern-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "field-access-pattern"
                                   (field-access-pattern-fact-path fact)
                                   (field-access-pattern-fact-name fact)
                                   (field-access-pattern-fact-start fact)))
        (kind "custom")
        (source "native-parser")
        (languageKind (field-access-pattern-fact-kind fact))
        (name (field-access-pattern-fact-name fact))
        (ownerPath (field-access-pattern-fact-path fact))
        (location (fact-location-json (field-access-pattern-fact-path fact)
                                      (field-access-pattern-fact-start fact)
                                      (field-access-pattern-fact-end fact)))
        (queryKeys (field-access-pattern-query-keys fact))
        (fields (field-access-pattern-fields-json fact))))

;;; Field-access projection keeps selector-helper vocabulary next to the
;;; accessors and callers that justify a future combinator rewrite.
;; : (-> FieldAccessPatternFact (List QueryKey) )
(def (field-access-pattern-query-keys fact)
  (unique
   (filter identity
           (append [(field-access-pattern-fact-name fact)
                    (field-access-pattern-fact-kind fact)
                    (field-access-pattern-fact-role fact)
                    (field-access-pattern-fact-field-key fact)
                    (field-access-pattern-fact-path fact)
                    (field-access-pattern-fact-advice fact)
                    "field-access-pattern"
                    "selector-helper"]
                   (field-access-pattern-fact-callers fact)
                   (field-access-pattern-fact-accessors fact)
                   (field-access-pattern-fact-quality-facets fact)))))

;; : (-> FieldAccessPatternFact Json )
(def (field-access-pattern-fields-json fact)
  (hash (role (field-access-pattern-fact-role fact))
        (fieldKey (field-access-pattern-fact-field-key fact))
        (callers (field-access-pattern-fact-callers fact))
        (accessCount (field-access-pattern-fact-access-count fact))
        (accessors (field-access-pattern-fact-accessors fact))
        (qualityFacets (field-access-pattern-fact-quality-facets fact))
        (advice (field-access-pattern-fact-advice fact))))

;; : (-> BooleanConditionFact Json )
(def (boolean-condition-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "boolean-condition"
                                   (boolean-condition-fact-path fact)
                                   (boolean-condition-fact-name fact)
                                   (boolean-condition-fact-start fact)))
        (kind "custom")
        (source "native-parser")
        (languageKind (boolean-condition-fact-kind fact))
        (name (boolean-condition-fact-name fact))
        (ownerPath (boolean-condition-fact-path fact))
        (location (fact-location-json (boolean-condition-fact-path fact)
                                      (boolean-condition-fact-start fact)
                                      (boolean-condition-fact-end fact)))
        (queryKeys (boolean-condition-query-keys fact))
        (fields (boolean-condition-fields-json fact))))

;;; Boolean-condition query keys keep the individual predicate repair surface
;;; discoverable even when the family-level policy is the warning owner.
;; : (-> BooleanConditionFact (List QueryKey) )
(def (boolean-condition-query-keys fact)
  (unique
   (filter identity
           (append [(boolean-condition-fact-name fact)
                    (boolean-condition-fact-kind fact)
                    (boolean-condition-fact-role fact)
                    (boolean-condition-fact-caller fact)
                    (boolean-condition-fact-path fact)
                    (boolean-condition-fact-advice fact)
                    "boolean-condition"
                    "predicate-helper"]
                   (boolean-condition-fact-formals fact)
                   (boolean-condition-fact-condition-callees fact)
                   (boolean-condition-fact-field-keys fact)
                   (boolean-condition-fact-quality-facets fact)))))

;; : (-> BooleanConditionFact Json )
(def (boolean-condition-fields-json fact)
  (hash (role (boolean-condition-fact-role fact))
        (caller (boolean-condition-fact-caller fact))
        (formals (boolean-condition-fact-formals fact))
        (conditionCallees (boolean-condition-fact-condition-callees fact))
        (fieldKeys (boolean-condition-fact-field-keys fact))
        (conditionCount (boolean-condition-fact-condition-count fact))
        (qualityFacets (boolean-condition-fact-quality-facets fact))
        (advice (boolean-condition-fact-advice fact))))

;; : (-> LoopDriverFact Json )
(def (loop-driver-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "loop-driver"
                                   (loop-driver-fact-path fact)
                                   (loop-driver-fact-name fact)
                                   (loop-driver-fact-start fact)))
        (kind "custom")
        (source "native-parser")
        (languageKind (loop-driver-fact-kind fact))
        (name (loop-driver-fact-name fact))
        (ownerPath (loop-driver-fact-path fact))
        (location (fact-location-json (loop-driver-fact-path fact)
                                      (loop-driver-fact-start fact)
                                      (loop-driver-fact-end fact)))
        (queryKeys (loop-driver-query-keys fact))
        (fields (loop-driver-fields-json fact))))

;;; Loop-driver keys expose whether a named let is pure transform drift or an
;;; IO/runtime boundary before policy decides whether to suggest a rewrite.
;; : (-> LoopDriverFact (List QueryKey) )
(def (loop-driver-query-keys fact)
  (unique
   (filter identity
           (append [(loop-driver-fact-name fact)
                    (loop-driver-fact-kind fact)
                    (loop-driver-fact-role fact)
                    (loop-driver-fact-caller fact)
                    (loop-driver-fact-driver-kind fact)
                    (loop-driver-fact-path fact)
                    (loop-driver-fact-advice fact)
                    "loop-driver"]
                   (loop-driver-fact-quality-facets fact)))))

;; : (-> LoopDriverFact Json )
(def (loop-driver-fields-json fact)
  (hash (role (loop-driver-fact-role fact))
        (caller (loop-driver-fact-caller fact))
        (driverKind (loop-driver-fact-driver-kind fact))
        (bindingCount (loop-driver-fact-binding-count fact))
        (bodyFormCount (loop-driver-fact-body-form-count fact))
        (qualityFacets (loop-driver-fact-quality-facets fact))
        (advice (loop-driver-fact-advice fact))))
