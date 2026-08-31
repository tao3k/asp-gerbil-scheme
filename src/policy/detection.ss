;;; -*- Gerbil -*-
;;; Policy-owned combinators for parser-owned evidence groups.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/policy/prototype
        (only-in :std/sugar filter filter-map hash ormap))

(export evidence-group
        evidence-group-name
        evidence-group-count
        evidence-group-selector
        detection-prototype
        detection-prototype-source-overlay
        detection-prototype-compose
        detection-prototype-extend
        detection-prototype-override
        detection-prototype-name
        detection-prototype-combiner
        detection-prototype-extractors
        detection-prototype-threshold
        detection-prototype-required-groups
        detection-prototype-description
        run-detection-prototype
        +threshold-detection-prototype+
        +all-of-detection-prototype+
        detection-groups
        detection-threshold
        detection-all-of
        detection-result-groups
        detection-result-combiner
        detection-result-threshold
        detection-result-required-groups
        detection-result-missing-groups
        detection-result-prototype
        detection-result-combiner-kind
        detection-result-description
        detection-result-selector
        detection-result-details)

;;; EvidenceGroup is intentionally small positional data: name, count, selector.
;;; The parser owns facts and selectors; policy combinators only compose them.
;; : (-> String Integer Selector EvidenceGroup )
(def (evidence-group name count selector)
  (list name count selector))

;; : (-> EvidenceGroup String )
(def (evidence-group-name group)
  (car group))

;; : (-> EvidenceGroup Integer )
(def (evidence-group-count group)
  (cadr group))

;; : (-> EvidenceGroup Selector )
(def (evidence-group-selector group)
  (caddr group))

;;; DetectionPrototype is a C3 slot profile.  Composition follows the same
;;; multiple-inheritance model as gerbil-poo objects, then materializes into
;;; plain descriptor slots at the policy boundary.
;; : (-> Name CombinerKind Extractors Threshold Required Description DetectionPrototype )
(def (detection-prototype name combiner extractors threshold required description)
  (slot-profile
   name
   [(cons 'name name)
    (cons 'combiner combiner)
    (cons 'extractors extractors)
    (cons 'threshold threshold)
    (cons 'required-groups required)
    (cons 'description description)]))

;;; Source overlays are the public escape hatch for POO provenance.  Callers
;;; pass registry-owned pattern values, while detection only stores the slots.
;; : (-> Pattern SourceOwners QualitySignals Witness DetectionPrototype )
(def (detection-prototype-source-overlay pattern source-owners quality-signals witness)
  (slot-profile
   pattern
   [(cons 'source-pattern pattern)
    (cons 'source-owners source-owners)
    (cons 'quality-signals quality-signals)
    (cons 'witness witness)]))

;;; Instantiation boundary: compose-proto* returns a prototype transformer.
;;; Policy modules consume plain descriptor data, so instantiate at this edge.
;; : (-> (List DetectionPrototype) DetectionPrototype )
(def (detection-prototype-compose prototypes)
  (slot-profile-compose "detection-prototype-composition" prototypes))

;;; Extension order follows POO source order: each overlay is placed outside the
;;; base prototype, so its slots override inherited slots during instantiation.
;; : (-> DetectionPrototype DetectionPrototype ... DetectionPrototype )
(def (detection-prototype-extend base . overlays)
  (apply slot-profile-extend base overlays))

;;; Single-overlay override is kept explicit for rules that need to replace one
;;; detector profile without introducing a new composition vocabulary.
;; : (-> DetectionPrototype DetectionPrototype DetectionPrototype )
(def (detection-prototype-override base overlay)
  (slot-profile-override base overlay))

;; : (-> DetectionPrototype String )
(def (detection-prototype-name prototype)
  (detection-prototype-slot prototype 'name "unnamed-detection"))

;; : (-> DetectionPrototype Symbol )
(def (detection-prototype-combiner prototype)
  (detection-prototype-slot prototype 'combiner 'threshold))

;; : (-> DetectionPrototype (List Extractor) )
(def (detection-prototype-extractors prototype)
  (detection-prototype-slot prototype 'extractors '()))

;; : (-> DetectionPrototype Integer )
(def (detection-prototype-threshold prototype)
  (detection-prototype-slot prototype 'threshold 1))

;; : (-> DetectionPrototype (List GroupName) )
(def (detection-prototype-required-groups prototype)
  (detection-prototype-slot prototype 'required-groups '()))

;; : (-> DetectionPrototype String )
(def (detection-prototype-description prototype)
  (detection-prototype-slot prototype 'description ""))

;; DetectionPrototype
(def +threshold-detection-prototype+
  (detection-prototype
   "threshold-detection"
   'threshold
   '()
   1
   '()
   "fires when enough independent parser-owned evidence groups align"))

;; DetectionPrototype
(def +all-of-detection-prototype+
  (detection-prototype
   "all-of-detection"
   'all-of
   '()
   0
   '()
   "fires when every required parser-owned evidence group is present"))

;;; Boundary:
;;; - A detection prototype is still plain descriptor data after composition.
;;; - POO composition owns override order; parser-owned evidence owns facts.
;;; - Policy rules only choose descriptors and repair messages.
;; : (-> Subject DetectionPrototype MaybeDetectionResult )
(def (run-detection-prototype subject prototype)
  (let* ((groups (detection-groups subject
                                   (detection-prototype-extractors prototype)))
         (combiner (detection-prototype-combiner prototype)))
    (case combiner
      ((threshold)
       (let (threshold (detection-prototype-threshold prototype))
         (and (>= (length groups) threshold)
              (prototype-detection-result prototype threshold '() '() groups))))
      ((all-of)
       (let* ((required (detection-prototype-required-groups prototype))
              (missing (missing-detection-groups required groups)))
         (and (null? missing)
              (prototype-detection-result
               prototype
               (length required)
               required
               missing
               groups))))
      (else #f))))

;;; Lookup boundary:
;;; - The shared slot-prototype layer resolves the effective POO slot.
;;; - Missing keys return the caller-owned fallback, which keeps base
;;;   prototypes partial without mutating descriptor state.
;; : (-> DetectionPrototype Symbol Value Value )
(def (detection-prototype-slot prototype key fallback)
  (slot-profile-ref prototype key fallback))

;;; Extractors are maybe-producing functions over one parser-owned subject.
;;; filter-map makes missing evidence a normal composition result.
;; : (-> Subject (List Extractor) (List EvidenceGroup) )
(def (detection-groups subject extractors)
  (filter-map (lambda (extractor) (extractor subject)) extractors))

;;; Threshold detection is the loose combinator: any enough independent groups
;;; can trigger, which leaves room for model-guided repair adaptation.
;; : (-> CombinerName Integer (List EvidenceGroup) MaybeDetectionResult )
(def (detection-threshold combiner threshold groups)
  (and (>= (length groups) threshold)
       (detection-result combiner threshold '() '() groups)))

;;; all-of detection is the strict combinator: named groups must all exist, but
;;; evidence extraction and selector ownership remain parser-owned.
;; : (-> CombinerName (List GroupName) (List EvidenceGroup) MaybeDetectionResult )
(def (detection-all-of combiner required groups)
  (let (missing (missing-detection-groups required groups))
    (and (null? missing)
         (detection-result combiner (length required) required missing groups))))

;;; Boundary:
;;; - Required group names are policy data, not parser facts.
;;; - Missing-group calculation keeps all-of detection explainable to agents.
;;; - The result is diagnostic evidence even when the combinator does not fire.
;; : (-> (List GroupName) (List EvidenceGroup) (List GroupName) )
(def (missing-detection-groups required groups)
  (filter (lambda (name) (not (detection-group-named? name groups)))
          required))

;;; Boundary:
;;; - Group membership checks evidence names only.
;;; - Selectors and counts remain attached to their original parser-owned group.
;;; - ormap preserves the open extension shape: new groups need data, not flow.
;; : (-> GroupName (List EvidenceGroup) Boolean )
(def (detection-group-named? name groups)
  (ormap (lambda (group) (equal? (evidence-group-name group) name))
         groups))

;; : (-> CombinerName Threshold Required Missing Groups DetectionResult )
(def (detection-result combiner threshold required missing groups)
  (detection-result* combiner threshold required missing groups
                     combiner "direct" ""))

;; : (-> CombinerName Threshold Required Missing Groups Prototype Kind Description DetectionResult )
(def (detection-result* combiner threshold required missing groups
                        prototype combiner-kind description)
  (list combiner threshold required missing groups
        prototype combiner-kind description '()))

;; : (-> CombinerName Threshold Required Missing Groups Prototype Kind Description Metadata DetectionResult )
(def (detection-result/metadata combiner threshold required missing groups
                                prototype combiner-kind description metadata)
  (list combiner threshold required missing groups
        prototype combiner-kind description metadata))

;; : (-> DetectionPrototype Threshold Required Missing Groups DetectionResult )
(def (prototype-detection-result prototype threshold required missing groups)
  (detection-result/metadata
   (detection-prototype-name prototype)
   threshold
   required
   missing
   groups
   (detection-prototype-name prototype)
   (detection-combiner-kind-name (detection-prototype-combiner prototype))
   (detection-prototype-description prototype)
   (detection-prototype-metadata prototype)))

;; : (-> DetectionResult (List EvidenceGroup) )
(def (detection-result-groups result)
  (list-ref result 4))

;; : (-> DetectionResult String )
(def (detection-result-combiner result)
  (list-ref result 0))

;; : (-> DetectionResult Integer )
(def (detection-result-threshold result)
  (list-ref result 1))

;; : (-> DetectionResult (List GroupName) )
(def (detection-result-required-groups result)
  (list-ref result 2))

;; : (-> DetectionResult (List GroupName) )
(def (detection-result-missing-groups result)
  (list-ref result 3))

;; : (-> DetectionResult String )
(def (detection-result-prototype result)
  (if (> (length result) 5)
    (list-ref result 5)
    (detection-result-combiner result)))

;; : (-> DetectionResult String )
(def (detection-result-combiner-kind result)
  (if (> (length result) 6)
    (list-ref result 6)
    "direct"))

;; : (-> DetectionResult String )
(def (detection-result-description result)
  (if (> (length result) 7)
    (list-ref result 7)
    ""))

;; : (-> DetectionResult Selector Selector )
(def (detection-result-selector result fallback)
  (let (groups (detection-result-groups result))
    (if (pair? groups)
      (evidence-group-selector (car groups))
      fallback)))

;; : (-> Symbol/String String )
(def (detection-combiner-kind-name combiner)
  (cond
   ((symbol? combiner) (symbol->string combiner))
   ((string? combiner) combiner)
   (else "custom")))

;;; Metadata boundary:
;;; - Source provenance is copied out of the composed prototype only after the
;;;   detector fires, so non-findings do not create synthetic evidence.
;;; - These slots are advisory steering for agents; parser-owned groups still
;;;   decide whether a policy warning exists.
;; : (-> DetectionPrototype DetectionMetadata )
(def (detection-prototype-metadata prototype)
  [(cons 'source-pattern (detection-prototype-slot prototype 'source-pattern ""))
   (cons 'source-owners (detection-prototype-slot prototype 'source-owners '()))
   (cons 'quality-signals (detection-prototype-slot prototype 'quality-signals '()))
   (cons 'witness (detection-prototype-slot prototype 'witness ""))
   (cons 'source-profile-composition
         (detection-prototype-slot prototype 'source-profile-composition ""))
   (cons 'source-profile-precedence
         (detection-prototype-slot prototype 'source-profile-precedence '()))
   (cons 'profile-precedence (slot-profile-precedence-names prototype))])

;; : (-> DetectionResult Symbol Value Value )
(def (detection-result-metadata-slot result key fallback)
  (let (metadata (if (> (length result) 8) (list-ref result 8) '()))
    (detection-prototype-slot metadata key fallback)))

;;; Details expose the combinator decision to agents without prescribing the
;;; final edit. The model gets enough evidence to adapt the repair.
;; : (-> DetectionResult PolicyDetails )
(def (detection-result-details result)
  (let (groups (detection-result-groups result))
    (hash (detectionCombiner (detection-result-combiner result))
          (detectionPrototype (detection-result-prototype result))
          (detectionCombinerKind (detection-result-combiner-kind result))
          (detectionThreshold (detection-result-threshold result))
          (requiredGroups (detection-result-required-groups result))
          (missingGroups (detection-result-missing-groups result))
          (detectionDescription (detection-result-description result))
          (detectionSourcePattern
           (detection-result-metadata-slot result 'source-pattern ""))
          (detectionSourceOwners
           (detection-result-metadata-slot result 'source-owners '()))
          (detectionQualitySignals
           (detection-result-metadata-slot result 'quality-signals '()))
          (detectionWitness
           (detection-result-metadata-slot result 'witness ""))
          (detectionSourceProfileComposition
           (detection-result-metadata-slot
            result 'source-profile-composition ""))
          (detectionSourceProfilePrecedence
           (detection-result-metadata-slot
            result 'source-profile-precedence '()))
          (detectionProfilePrecedence
           (detection-result-metadata-slot result 'profile-precedence '()))
          (evidenceGroups (map evidence-group-name groups))
          (evidenceCounts (map evidence-group-count groups))
          (evidenceSelectors (map evidence-group-selector groups)))))
