;;; -*- Gerbil -*-
;;; Agent-facing branch-shape and predicate-family style policy checks.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-support
        :asp-gerbil-scheme/src/policy/detection
        :asp-gerbil-scheme/src/policy/gerbil-utils-source
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/srfi/1 take)
        (only-in :std/sugar cut filter filter-map foldl hash ormap)
        :asp-gerbil-scheme/src/types/findings)

(export controlled-branch-shape-findings
        controlled-branch-shape-finding
        predicate-family-combinator-findings
        predicate-family-combinator-finding)
;; Integer
(def +field-access-helper-evidence-min-access-count+ 8)
;; Integer
(def +field-access-helper-evidence-min-caller-count+ 3)
;; Integer
(def +projection-burst-min-access-count+ 12)
;; Integer
(def +projection-burst-min-field-count+ 4)
;; Integer
(def +projection-burst-min-emitter-count+ 2)
;; Integer
(def +boolean-condition-combinator-min-condition-count+ 5)
;; Integer
(def +controlled-branch-shape-conditional-dispatch-min-count+ 4)
;; (List CalleeName)
(def +controlled-branch-shape-stateful-callees+
  '("set!" "set-car!" "set-cdr!" "vector-set!" "hash-put!" "hash-remove!"
    "hash-clear!" "table-set!" "table-delete!" ".put!" ".slot-set!"))
;;; Source-backed repair vocabulary:
;;; - These candidates come from .data/gerbil-utils/base.ss and generator.ss evidence.
;;; - R014 may steer an agent toward this vocabulary, but the parser facts still
;;;   decide whether lambda-match, specialization, pipeline, fold, generator, or
;;;   plain helper extraction is actually applicable.
;;; Source owner anchors:
;;; - Keep these as human-readable owner strings until gerbil-utils:// selectors
;;;   are provider-owned facts.
;;; - They are emitted in details so an agent can trace the guidance to the
;;;   reference corpus instead of treating it as a local preference.
;; (List SourceOwner)
(def +controlled-branch-shape-source-backed-owners+
  ["gerbil-utils/base.ss#lambda-match/lambda-ematch"
   "gerbil-utils/base.ss#fun"
   "gerbil-utils/base.ss#cut/curry/rcurry"
   "gerbil-utils/base.ss#compose/rcompose/!>/!!>"
   "gerbil-utils/base.ss#case-lambda specializers"
   "gerbil-utils/generator.ss#compose-backed-generating-map"])
;;; Repair candidate contract:
;;; - Candidate order matters: start from the most syntax-specific idiom and
;;;   fall back to plain helpers only after parser facts rule out higher-order
;;;   Gerbil syntax.
;;; - The policy exposes choices; it does not prescribe one rewrite shape for
;;;   every R014 finding.
;; (List RepairMove)
(def +controlled-branch-shape-source-backed-repair-candidates+
  ["lambda-match/lambda-ematch for unary match destructuring"
   "fun for reusable local named lambda boundaries"
   "cut/curry/rcurry for first-class argument specialization"
   "compose/rcompose/!>/!!> for reusable expression pipelines"
   "case-lambda only when there are real arity specializations"
   "plain named helpers only when no higher-order Gerbil idiom fits"])

;;; Branch-shape entrypoint:
;;; - Emit findings only after parser-owned control-flow facts group repeated shapes.
;;; - Keep style repair bounded to one source owner at a time.
;; : (-> ProjectIndex (List TypeFinding) )
(def (controlled-branch-shape-findings index)
  (apply append
         (map (cut file-controlled-branch-shape-findings index <>)
              (project-index-files index))))

;;; Predicate-family entrypoint:
;;; - Require native predicateFamilyFacts before suggesting helper extraction.
;;; - Preserve public predicate names unless the owning policy later changes.
;; : (-> ProjectIndex (List TypeFinding) )
(def (predicate-family-combinator-findings index)
  (apply append
         (map (cut file-predicate-family-combinator-findings index <>)
              (project-index-files index))))

;;; Policy gate: repeated predicates must be parser-owned before agent style repair can touch them.
;; : (-> ProjectIndex SourceFile (List TypeFinding) )
(def (file-predicate-family-combinator-findings index file)
  (if (index-source-runtime-file-path? index (source-file-path file))
    (append
     (filter-map (cut predicate-family-combinator-finding file <>)
                 (source-file-predicate-family-facts file))
     (filter-map (cut field-access-helper-finding file <>)
                 (source-file-field-access-pattern-facts file))
     (filter-map (cut emitter-projection-burst-finding file <>)
                 (source-file-projection-burst-facts file))
     (filter-map (cut boolean-condition-combinator-finding file <>)
                 (source-file-boolean-condition-facts file)))
    '()))

;; : (-> SourceFile PredicateFamilyFact TypeFinding )
(def (predicate-family-combinator-finding file fact)
  (and (>= (predicate-family-fact-predicate-count fact) 3)
       (make-type-finding
        (policy-rule-id +agent-predicate-family-combinator-rule+)
        (policy-rule-severity +agent-predicate-family-combinator-rule+)
        (source-file-path file)
        (predicate-family-combinator-message fact)
        (predicate-family-fact-selector fact)
        (predicate-family-combinator-details file fact))))

;; : (-> PredicateFamilyFact Message )
(def (predicate-family-combinator-message fact)
  (string-append
   "predicate family over "
   (predicate-family-fact-subject fact)
   " repeats field/role condition helpers; keep repair policy-driven, extract selector helpers or a bounded predicate combinator before editing for style or performance"))

;;; Details deliberately preserve both the family fact and the field-access
;;; facts: the model sees why a helper/combinator rewrite is allowed, while the
;;; policy remains agnostic about exact helper names.
;; : (-> SourceFile PredicateFamilyFact PolicyDetails )
(def (predicate-family-combinator-details file fact)
  (hash (styleGuide "predicate-family-combinator")
        (styleCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style")
        (qualityReferenceCorpus "gerbil-utils")
        (qualityReference
         (gerbil-utils-source-details 'predicate-combinator))
        (evidenceSource "parser-owned predicateFamilyFacts plus fieldAccessPatternFacts")
        (subject (predicate-family-fact-subject fact))
        (predicateCount (predicate-family-fact-predicate-count fact))
        (predicateNames
         (let (names (predicate-family-fact-predicate-names fact))
           (take names (min 8 (length names)))))
        (fieldKeys (predicate-family-fact-field-keys fact))
        (repeatedCallees (predicate-family-fact-repeated-callees fact))
        (conditionCount (predicate-family-fact-condition-count fact))
        (qualityFacets (predicate-family-fact-quality-facets fact))
        (fieldAccessPatterns
         (let (patterns (map field-access-pattern-repair-evidence
                             (source-file-field-access-pattern-facts file)))
           (take patterns (min 6 (length patterns)))))
        (agentRepairStandard "rewrite toward learned Gerbil predicate style: keep predicate names stable, extract role/field selector helpers, and compose small expression-returning predicates")
        (agentRepairEnvelope
         (hash (flexibility "agent may choose helper names, role-set tables, or predicate combinator shape")
               (constraints ["preserve public predicate behavior"
                             "stay in the same owner unless exports require a facade change"
                             "do not rewrite IO/runtime/macro boundaries without witness"])))
        (next "guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style")))

;; : (-> SourceFile FieldAccessPatternFact TypeFinding )
(def (field-access-helper-finding file fact)
  (let (detection (field-access-helper-detection fact))
    (and detection
         (make-type-finding
          (policy-rule-id +agent-predicate-family-combinator-rule+)
          (policy-rule-severity +agent-predicate-family-combinator-rule+)
          (source-file-path file)
          (field-access-helper-message fact)
          (detection-result-selector detection
                                     (field-access-pattern-fact-selector fact))
          (field-access-helper-details fact detection)))))

;; : (-> FieldAccessPatternFact Boolean )
(def (field-access-helper-evidence-complete? fact)
  (if (field-access-helper-detection fact) #t #f))

;;; Detector boundary:
;;; - R016 field-access warnings require two independent parser-owned groups.
;;; - The all-of prototype exposes that decision as data for agent repair.
;; : (-> FieldAccessPatternFact MaybeDetectionResult )
(def (field-access-helper-detection fact)
  (run-detection-prototype fact (field-access-helper-detection-prototype)))

;;; Prototype shape:
;;; - Keep the thresholds named, but make the trigger an all-of combinator.
;;; - Future field-access evidence can extend this descriptor without changing
;;;   the finding assembly path.
;; DetectionPrototype
(def (field-access-helper-detection-prototype)
  (detection-prototype-extend
   +all-of-detection-prototype+
   (gerbil-utils-source-detection-overlay 'predicate-combinator)
   (detection-prototype
    "field-access-helper-all-of"
    'all-of
    [field-access-count-evidence
     field-access-caller-spread-evidence]
    0
    ["high-field-access-count" "cross-caller-field-access"]
    "field access helper repair requires high access count and cross-caller spread")))

;;; Evidence boundary:
;;; - Access-count evidence is one independent group in the all-of detector.
;;; - Selector ownership remains on the parser fact that exposed the field key.
;; : (-> FieldAccessPatternFact MaybeEvidenceGroup )
(def (field-access-count-evidence fact)
  (and (>= (field-access-pattern-fact-access-count fact)
           +field-access-helper-evidence-min-access-count+)
       (evidence-group
        "high-field-access-count"
        (field-access-pattern-fact-access-count fact)
        (field-access-pattern-fact-selector fact))))

;;; Evidence boundary:
;;; - Caller-spread evidence is separate from raw access frequency.
;;; - Keeping it as another EvidenceGroup prevents single-caller hot code from
;;;   becoming a style warning.
;; : (-> FieldAccessPatternFact MaybeEvidenceGroup )
(def (field-access-caller-spread-evidence fact)
  (let (caller-count (length (field-access-pattern-fact-callers fact)))
    (and (>= caller-count +field-access-helper-evidence-min-caller-count+)
         (evidence-group
          "cross-caller-field-access"
          caller-count
          (field-access-pattern-fact-selector fact)))))

;; : (-> FieldAccessPatternFact Message )
(def (field-access-helper-message fact)
  (string-append
   "field access "
   (field-access-pattern-fact-field-key fact)
   " repeats "
   (number->string (field-access-pattern-fact-access-count fact))
   " times across "
   (number->string (length (field-access-pattern-fact-callers fact)))
   " callers; extract a small selector helper before adding more hash/field reads"))

;;; Details boundary:
;;; - Detection metadata is copied through so agents see the all-of gate.
;;; - Field-specific repair evidence stays attached to the original parser fact.
;; : (-> FieldAccessPatternFact DetectionResult PolicyDetails )
(def (field-access-helper-details fact detection)
  (let (details (detection-result-details detection))
    (hash (styleGuide "predicate-family-combinator")
          (styleCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style")
          (qualityReference "gerbil-utils")
          (evidenceSource "parser-owned fieldAccessPatternFacts")
          (policySignals (hash-get details 'evidenceGroups))
          (detectionCombiner (hash-get details 'detectionCombiner))
          (detectionPrototype (hash-get details 'detectionPrototype))
          (detectionCombinerKind (hash-get details 'detectionCombinerKind))
          (detectionThreshold (hash-get details 'detectionThreshold))
          (detectionDescription (hash-get details 'detectionDescription))
          (detectionSourcePattern (hash-get details 'detectionSourcePattern))
          (detectionSourceOwners (hash-get details 'detectionSourceOwners))
          (detectionQualitySignals (hash-get details 'detectionQualitySignals))
          (detectionWitness (hash-get details 'detectionWitness))
          (requiredGroups (hash-get details 'requiredGroups))
          (missingGroups (hash-get details 'missingGroups))
          (evidenceGroups (hash-get details 'evidenceGroups))
          (evidenceCounts (hash-get details 'evidenceCounts))
          (evidenceSelectors (hash-get details 'evidenceSelectors))
          (accessCountGate +field-access-helper-evidence-min-access-count+)
          (callerCountGate +field-access-helper-evidence-min-caller-count+)
          (fieldAccessPattern (field-access-pattern-repair-evidence fact))
          (agentRepairStandard
           "extract a local selector helper only after native parser evidence shows both high access count and cross-caller spread; keep packet keys stable and preserve caller behavior")
          (next "guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style"))))

;; : (-> FieldAccessPatternFact (List PolicySignal) )
(def (field-access-helper-policy-signals fact)
  ["high-field-access-count"
   "cross-caller-field-access"])

;; : (-> FieldAccessPatternFact RepairEvidence )
(def (field-access-pattern-repair-evidence fact)
  (hash (fieldKey (field-access-pattern-fact-field-key fact))
        (accessCount (field-access-pattern-fact-access-count fact))
        (accessors (field-access-pattern-fact-accessors fact))
        (callers
         (let (callers (field-access-pattern-fact-callers fact))
           (take callers (min 8 (length callers)))))
        (selector (field-access-pattern-fact-selector fact))
        (advice (field-access-pattern-fact-advice fact))))

;; : (-> SourceFile BooleanConditionFact TypeFinding )
(def (boolean-condition-combinator-finding file fact)
  (and (boolean-condition-combinator-actionable? fact)
       (make-type-finding
        (policy-rule-id +agent-predicate-family-combinator-rule+)
        (policy-rule-severity +agent-predicate-family-combinator-rule+)
        (source-file-path file)
        (boolean-condition-combinator-message fact)
        (boolean-condition-fact-selector fact)
        (boolean-condition-combinator-details fact))))

;;; Boolean predicate warnings are parser-owned and count-based: this catches
;;; generated nested `and`/`or` predicate scaffolds without matching names or
;;; rendered source text.
;; : (-> BooleanConditionFact Boolean )
(def (boolean-condition-combinator-actionable? fact)
  (and (equal? (boolean-condition-fact-role fact) "predicate-condition")
       (>= (boolean-condition-fact-condition-count fact)
           +boolean-condition-combinator-min-condition-count+)))

;; : (-> BooleanConditionFact Message )
(def (boolean-condition-combinator-message fact)
  (string-append
   "boolean predicate "
   (boolean-condition-fact-caller fact)
   " carries "
   (number->string (boolean-condition-fact-condition-count fact))
   " inline condition calls; extract small predicate helpers or compose matchers before extending nested and/or branches"))

;;; Details keep the repair target narrow: agents may choose helper names and
;;; composition shape, but the proof must stay on the parser-owned predicate
;;; span and preserve behavior.
;; : (-> BooleanConditionFact PolicyDetails )
(def (boolean-condition-combinator-details fact)
  (hash (styleGuide "predicate-family-combinator")
        (styleCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style")
        (qualityReferenceCorpus "gerbil-utils")
        (qualityReference
         (gerbil-utils-source-details 'predicate-combinator))
        (evidenceSource "parser-owned booleanConditionFacts")
        (caller (boolean-condition-fact-caller fact))
        (formals (boolean-condition-fact-formals fact))
        (conditionCallees (boolean-condition-fact-condition-callees fact))
        (fieldKeys (boolean-condition-fact-field-keys fact))
        (conditionCount (boolean-condition-fact-condition-count fact))
        (qualityFacets (boolean-condition-fact-quality-facets fact))
        (booleanCondition (boolean-condition-repair-evidence fact))
        (agentRepairStandard
         "replace nested boolean scaffolds with named expression-returning predicates or a bounded higher-order matcher list; keep short-circuit behavior explicit and do not hide IO/runtime boundaries")
        (agentRepairEnvelope
         (hash (flexibility "agent may choose local predicate names, lambda/cut matchers, or a compact helper table")
               (constraints ["preserve predicate truth table"
                             "keep the repair inside the owning source file unless exports demand a facade change"
                             "use parser-owned boolean evidence rather than string suffix or name matching"])))
        (next "guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style")))

;; : (-> BooleanConditionFact RepairEvidence )
(def (boolean-condition-repair-evidence fact)
  (hash (caller (boolean-condition-fact-caller fact))
        (selector (boolean-condition-fact-selector fact))
        (conditionCallees (boolean-condition-fact-condition-callees fact))
        (fieldKeys (boolean-condition-fact-field-keys fact))
        (conditionCount (boolean-condition-fact-condition-count fact))
        (qualityFacets (boolean-condition-fact-quality-facets fact))
        (advice (boolean-condition-fact-advice fact))))

;; : (-> SourceFile ProjectionBurstFact TypeFinding )
(def (emitter-projection-burst-finding file fact)
  (let (detection (emitter-projection-burst-detection fact))
    (and detection
         (make-type-finding
          (policy-rule-id +agent-predicate-family-combinator-rule+)
          (policy-rule-severity +agent-predicate-family-combinator-rule+)
          (source-file-path file)
          (emitter-projection-burst-message fact)
          (detection-result-selector detection
                                     (projection-burst-fact-selector fact))
          (emitter-projection-burst-details fact detection)))))

;;; Detector boundary:
;;; - Projection bursts require access density, key spread, and emitter evidence.
;;; - The C3 profile keeps thresholds/data extensible without editing assembly.
;; : (-> ProjectionBurstFact MaybeDetectionResult )
(def (emitter-projection-burst-detection fact)
  (run-detection-prototype fact (emitter-projection-burst-detection-prototype)))

;; DetectionPrototype
(def (emitter-projection-burst-detection-prototype)
  (detection-prototype-extend
   +all-of-detection-prototype+
   (gerbil-utils-source-detection-overlay 'projection-builder)
   (detection-prototype
    "emitter-projection-burst-all-of"
    'all-of
    [projection-access-count-evidence
     projection-field-spread-evidence
     projection-emitter-count-evidence]
    0
    ["high-projection-access-count"
     "multi-field-projection"
     "emitter-output-boundary"]
    "emitter projection repair requires access density, field spread, and output boundary evidence")))

;; : (-> ProjectionBurstFact MaybeEvidenceGroup )
(def (projection-access-count-evidence fact)
  (and (>= (projection-burst-fact-access-count fact)
           +projection-burst-min-access-count+)
       (evidence-group
        "high-projection-access-count"
        (projection-burst-fact-access-count fact)
        (projection-burst-fact-selector fact))))

;; : (-> ProjectionBurstFact MaybeEvidenceGroup )
(def (projection-field-spread-evidence fact)
  (and (>= (projection-burst-fact-accessor-count fact)
           +projection-burst-min-field-count+)
       (evidence-group
        "multi-field-projection"
        (projection-burst-fact-accessor-count fact)
        (projection-burst-fact-selector fact))))

;; : (-> ProjectionBurstFact MaybeEvidenceGroup )
(def (projection-emitter-count-evidence fact)
  (and (>= (projection-burst-fact-emitter-count fact)
           +projection-burst-min-emitter-count+)
       (evidence-group
        "emitter-output-boundary"
        (projection-burst-fact-emitter-count fact)
        (projection-burst-fact-selector fact))))

;; : (-> ProjectionBurstFact Message )
(def (emitter-projection-burst-message fact)
  (string-append
   "emitter "
   (projection-burst-fact-caller fact)
   " mixes "
   (number->string (projection-burst-fact-access-count fact))
   " field projections with "
   (number->string (projection-burst-fact-emitter-count fact))
   " output calls; split selectors, line builders, and traversal before adding more hash-get/display scaffolding"))

;;; Boundary:
;;; - Detail packets expose the multiple-detection evidence behind R016.
;;; - Agent-facing repair guidance must stay tied to parser-owned projection facts.
;; : (-> ProjectionBurstFact DetectionResult PolicyDetails )
(def (emitter-projection-burst-details fact detection)
  (let (details (detection-result-details detection))
    (hash (styleGuide "predicate-family-combinator")
          (styleCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style")
          (qualityReference "gerbil-utils")
          (evidenceSource "parser-owned projectionBurstFacts")
          (policySignals (hash-get details 'evidenceGroups))
          (detectionCombiner (hash-get details 'detectionCombiner))
          (detectionPrototype (hash-get details 'detectionPrototype))
          (detectionCombinerKind (hash-get details 'detectionCombinerKind))
          (detectionThreshold (hash-get details 'detectionThreshold))
          (detectionDescription (hash-get details 'detectionDescription))
          (detectionSourcePattern (hash-get details 'detectionSourcePattern))
          (detectionSourceOwners (hash-get details 'detectionSourceOwners))
          (detectionQualitySignals (hash-get details 'detectionQualitySignals))
          (detectionWitness (hash-get details 'detectionWitness))
          (detectionProfilePrecedence
           (hash-get details 'detectionProfilePrecedence))
          (requiredGroups (hash-get details 'requiredGroups))
          (missingGroups (hash-get details 'missingGroups))
          (evidenceGroups (hash-get details 'evidenceGroups))
          (evidenceCounts (hash-get details 'evidenceCounts))
          (evidenceSelectors (hash-get details 'evidenceSelectors))
          (projectionBurst (projection-burst-repair-evidence fact))
          (agentRepairStandard
           "extract selector helpers and line builders before changing output behavior; keep traversal and formatting separately testable")
          (next "guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style"))))

;; : (-> ProjectionBurstFact RepairEvidence )
(def (projection-burst-repair-evidence fact)
  (hash (caller (projection-burst-fact-caller fact))
        (fieldKeys (projection-burst-fact-field-keys fact))
        (accessCount (projection-burst-fact-access-count fact))
        (accessorCount (projection-burst-fact-accessor-count fact))
        (emitterCount (projection-burst-fact-emitter-count fact))
        (accessors (projection-burst-fact-accessors fact))
        (emitters (projection-burst-fact-emitters fact))
        (qualityFacets (projection-burst-fact-quality-facets fact))
        (selector (projection-burst-fact-selector fact))
        (advice (projection-burst-fact-advice fact))))

;;; Runtime-source gate:
;;; - Only source-runtime owners participate in branch-shape repair.
;;; - Test and generated owners can still expose facts without style findings.
;; : (-> ProjectIndex SourceFile (List TypeFinding) )
(def (file-controlled-branch-shape-findings index file)
  (if (index-source-runtime-file-path? index (source-file-path file))
    (filter-map (cut controlled-branch-shape-finding file <>)
                (controlled-branch-shape-groups
                 (filter controlled-branch-shape-control-flow?
                         (source-file-control-flow-forms file))))
    '()))

;; : (-> ControlFlowFact Boolean )
(def (pattern-branch-control-flow? fact)
  (equal? (control-flow-fact-role fact) "pattern-branch"))

;; : (-> ControlFlowFact Boolean )
(def (manual-loop-control-flow? fact)
  (equal? (control-flow-fact-role fact) "manual-loop"))

;; : (-> ControlFlowFact Boolean )
(def (conditional-branch-control-flow? fact)
  (equal? (control-flow-fact-role fact) "conditional-branch"))

;;; Shape classifier:
;;; - Keep the branch/loop predicate list explicit so policies can add roles safely.
;;; - Avoid broad style findings when parser facts have not classified control flow.
;; : (-> ControlFlowFact Boolean )
(def (controlled-branch-shape-control-flow? fact)
  (ormap (lambda (predicate) (predicate fact))
         [pattern-branch-control-flow?
          manual-loop-control-flow?
          conditional-branch-control-flow?]))

;;; Grouping reducer:
;;; - Fold by caller so repeated branch shapes are repaired within one behavior boundary.
;;; - Preserve all facts for the later message and details packet.
;; : (-> (List ControlFlowFact) (List ControlFlowGroup) )
(def (controlled-branch-shape-groups facts)
  (foldl (lambda (fact groups)
           (add-control-flow-shape-group groups fact))
         '()
         facts))

;; : (-> (List ControlFlowGroup) ControlFlowFact (List ControlFlowGroup) )
(def (add-control-flow-shape-group groups fact)
  (let* ((key (control-flow-shape-group-key fact))
         (prior (assoc key groups)))
    (if prior
      (cons (cons key (cons fact (cdr prior)))
            (remove-control-flow-shape-group key groups))
      (cons (cons key [fact]) groups))))

;;; Group replacement helper:
;;; - Remove the prior caller group before consing the updated group.
;;; - This keeps foldl output deterministic without mutating the accumulator.
;; : (-> ControlFlowCaller (List ControlFlowGroup) (List ControlFlowGroup) )
(def (remove-control-flow-shape-group key groups)
  (filter (lambda (group) (not (equal? (car group) key))) groups))

;; : (-> ControlFlowFact (List ControlFlowFact) )
(def (control-flow-shape-group-key fact)
  (or (control-flow-fact-caller fact) "<top-level>"))

;;; Shape decision:
;;; - Repeated pattern branches and stateful selector loops are distinct repairs.
;;; - Return #f for single-branch or low-evidence groups so advice stays quiet.
;; : (-> ControlFlowGroup String )
(def (controlled-branch-shape-kind group)
  (let* ((facts (cdr group))
         (pattern-facts (filter pattern-branch-control-flow? facts))
         (manual-loop-facts (filter state-selector-manual-loop? facts))
         (conditional-branch-facts
          (filter conditional-branch-control-flow? facts)))
    (cond
     ((> (length pattern-facts) 1) "repeated-pattern-branch")
     ((and (pair? pattern-facts) (pair? manual-loop-facts))
      "pattern-branch-with-manual-loop")
     ((>= (length conditional-branch-facts)
          +controlled-branch-shape-conditional-dispatch-min-count+)
      "nested-conditional-dispatch")
     (else #f))))

;; : (-> ControlFlowFact Boolean )
(def (state-selector-manual-loop? fact)
  (and (manual-loop-control-flow? fact)
       (>= (control-flow-fact-binding-count fact) 4)
       (<= (control-flow-fact-line-span fact) 24)))

;; : (-> ControlFlowFact Integer )
(def (control-flow-fact-line-span fact)
  (fx1+ (- (control-flow-fact-end fact)
           (control-flow-fact-start fact))))

;;; Finding assembly:
;;; - Use the earliest control-flow fact as selector anchor for stable repair.
;;; - Preserve all grouped facts in details instead of choosing rewrite shape here.
;; : (-> SourceFile ControlFlowGroup TypeFinding )
(def (controlled-branch-shape-finding file group)
  (let (shape-kind (controlled-branch-shape-kind group))
    (and shape-kind
         (not (controlled-branch-shape-stateful-caller?
               file
               (car group)
               shape-kind))
         (let* ((caller (car group))
                (facts (cdr group))
                (pattern-facts (filter pattern-branch-control-flow? facts))
                (manual-loop-facts (filter state-selector-manual-loop? facts))
                (conditional-branch-facts
                 (filter conditional-branch-control-flow? facts))
                (first-fact (earliest-control-flow-fact facts)))
           (make-type-finding
            (policy-rule-id +agent-controlled-branch-shape-rule+)
            (policy-rule-severity +agent-controlled-branch-shape-rule+)
            (source-file-path file)
            (controlled-branch-shape-message caller shape-kind)
            (control-flow-fact-selector first-fact)
            (controlled-branch-shape-details
             caller
             shape-kind
             pattern-facts
             manual-loop-facts
             conditional-branch-facts
             first-fact))))))

;;; Stateful hot paths often need explicit branch shape to keep allocation and
;;; mutation boundaries visible; R014 remains focused on pure dispatch drift.
;; : (-> SourceFile Caller ShapeKind Boolean)
(def (controlled-branch-shape-stateful-caller? file caller shape-kind)
  (and (equal? shape-kind "nested-conditional-dispatch")
       (ormap (lambda (call)
                (and (equal? (or (call-fact-caller call) "") caller)
                     (member (call-fact-callee call)
                             +controlled-branch-shape-stateful-callees+)))
              (source-file-calls file))))

;;; Details packet boundary:
;;; - Preserve parser-owned counts separately from source-backed repair choices.
;;; - The agent receives Gerbil idiom candidates, but this policy still avoids
;;;   picking a concrete rewrite without matching parser evidence.
;; : (-> String String ControlFlowFacts ControlFlowFacts ControlFlowFacts ControlFlowFact PolicyDetails )
(def (controlled-branch-shape-details caller shape-kind pattern-facts manual-loop-facts conditional-branch-facts first-fact)
  (hash (caller caller)
        (shape shape-kind)
        (matchCount (length pattern-facts))
        (manualLoopCount (length manual-loop-facts))
        (conditionalBranchCount (length conditional-branch-facts))
        (conditionalDispatchGate +controlled-branch-shape-conditional-dispatch-min-count+)
        (selector (control-flow-fact-selector first-fact))
        (evidence "parser-owned controlFlowFacts role=pattern-branch, manual-loop bindingCount>=4, or conditional-branch count>=4")
        (advice "do not refactor opportunistically; wait for this policy finding, preserve behavior, and use guide code for controlled branch shape")
        (styleGuide "controlled-branch-shape")
        (styleCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-014 --intent style")
        (rewriteScope "same caller or extracted helper only")
        (qualityReferenceCorpus "gerbil-utils")
        (qualityReference
         (gerbil-utils-source-details 'higher-order-expression))
        (sourceBackedOwners
         +controlled-branch-shape-source-backed-owners+)
        (sourceBackedRepairCandidates
         +controlled-branch-shape-source-backed-repair-candidates+)
        (functionShape "source-backed Gerbil idioms first: lambda-match/lambda-ematch for unary match destructuring, fun for reusable local lambdas, cut/curry/rcurry for specialization, compose/rcompose/!>/!!> for pipelines")
        (agentRepairStandard "rewrite toward learned Gerbil style: choose the least powerful reference-backed higher-order idiom that preserves behavior; use plain helper extraction only when parser evidence shows no lambda-match, specialization, pipeline, fold, or generator shape")
        (expressionLevelRewrite "turn repeated branch or dispatch shape into lambda-match/lambda-ematch, fun, cut/curry/rcurry, compose/rcompose/!>/!!>, fold/filter-map, generator combinator, or a named helper in that order of evidence")
        (next "guide --code --rule GERBIL-SCHEME-AGENT-POLICY-014 --intent style")))

;; : (-> String String Message )
(def (controlled-branch-shape-message caller shape-kind)
  (cond
   ((equal? shape-kind "pattern-branch-with-manual-loop")
    (string-append "caller " caller
                   " combines match state destructuring with a named-let loop; keep the repair policy-driven and choose a source-backed Gerbil idiom such as lambda-match, fun, fold/filter-map, or a bounded pipeline before editing for style or performance"))
   ((equal? shape-kind "nested-conditional-dispatch")
    (string-append "caller " caller
                   " has nested conditional dispatch; keep the repair policy-driven and choose source-backed Gerbil idioms such as fun, cut/curry/rcurry, compose/rcompose, or named fallback helpers before editing for style or performance"))
   (else
    (string-append "caller " caller
                   " has repeated match branches; keep the repair policy-driven and prefer lambda-match/lambda-ematch, fun, or a bounded selector pipeline before editing for style or performance"))))

;;; Earliest selector reducer:
;;; - The first source span is the least surprising repair anchor for an agent.
;;; - The fold preserves the full grouped evidence for details.
;; : (-> (NonEmptyList ControlFlowFact) ControlFlowFact )
(def (earliest-control-flow-fact facts)
  (foldl (lambda (fact earliest)
           (if (< (control-flow-fact-start fact)
                  (control-flow-fact-start earliest))
             fact
             earliest))
         (car facts)
         (cdr facts)))
