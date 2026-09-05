;;; -*- Gerbil -*-
;;; Typed repair diagnostic objects and JSON projections.

(import :asp-gerbil-scheme/src/policy/catalog
        (only-in :std/srfi/13 string-join)
        :asp-gerbil-scheme/src/types/findings)

(export #t)

;;; Schema names are wire-level compatibility boundaries for repair clients.
(def +policy-diagnostic-schema+ "gerbil-policy-diagnostic-v1")

(defstruct policy-diagnostic-location-state (path selector definition-name))
(defstruct policy-diagnostic-evidence-state (rule-id severity message details))
(defstruct policy-repair-intent-state (strategy fix-intent constraints repair-phases guide-command guide-role comment-repair-order))
(defstruct policy-diagnostic-state (schema kind unit rule-id severity location problem evidence fix-intent constraints guide-command guide-role repair-phases))

;;; POO projection boundary:
;;; - Diagnostic helpers build object slots first, then project through .json<-.
;;; - This keeps rule evidence, location, and repair intent composable before
;;;   agent-facing JSON is materialized.
;; : (-> PolicyDiagnosticObject Json )
(def (policy-diagnostic-json<- diagnostic)
  (cond
   ((policy-diagnostic-location-state? diagnostic)
    (policy-diagnostic-location-json<- diagnostic))
   ((policy-diagnostic-evidence-state? diagnostic)
    (policy-diagnostic-evidence-json<- diagnostic))
   ((policy-repair-intent-state? diagnostic)
    (policy-repair-intent-json<- diagnostic))
   ((policy-diagnostic-state? diagnostic)
    (policy-diagnostic-json-projection diagnostic))
   (else
    (error "unknown policy diagnostic object" diagnostic))))

;;; Diagnostic object protocol:
;;; - location/evidence/intent are POO objects before they are JSON.
;;; - repair projection code composes these objects instead of hand-building
;;;   the full packet shape at each policy site.
;; : (-> Path Selector DefinitionName PolicyDiagnosticLocation )
(def (make-policy-diagnostic-location path selector definition-name)
  (make-policy-diagnostic-location-state path selector definition-name))

;;; Location JSON keeps parser selectors stable across text and JSON output.
;; : (-> PolicyDiagnosticLocation Json )
(def (policy-diagnostic-location-json<- location)
  (hash (path (policy-diagnostic-location-state-path location))
        (selector (policy-diagnostic-location-state-selector location))
        (definitionName
         (policy-diagnostic-location-state-definition-name location))))

;;; Evidence objects preserve the original policy signal without forcing agents
;;; to reverse-engineer rule details from prose.
;; : (-> Rule Severity Message Details PolicyDiagnosticEvidence )
(def (make-policy-diagnostic-evidence rule-id severity message details)
  (make-policy-diagnostic-evidence-state rule-id severity message details))

;;; Evidence JSON is intentionally shallow; nested repair context belongs in
;;; details, not in ad hoc top-level fields.
;; : (-> PolicyDiagnosticEvidence Json )
(def (policy-diagnostic-evidence-json<- evidence)
  (hash (ruleId (policy-diagnostic-evidence-state-rule-id evidence))
        (severity (policy-diagnostic-evidence-state-severity evidence))
        (message (policy-diagnostic-evidence-state-message evidence))
        (details (policy-diagnostic-evidence-state-details evidence))))

;;; Repair intent is separate from evidence so guide commands stay supporting
;;; context instead of becoming the diagnostic itself.
;; : (-> Strategy FixIntent Constraints RepairPhases GuideCommand GuideRole CommentRepairOrder PolicyRepairIntent )
(def (make-policy-repair-intent strategy: strategy
                                fixIntent: fix-intent
                                constraints: constraints
                                repairPhases: repair-phases
                                guideCommand: guide-command
                                guideRole: guide-role
                                commentRepairOrder: comment-repair-order)
  (make-policy-repair-intent-state strategy
                                   fix-intent
                                   constraints
                                   repair-phases
                                   guide-command
                                   guide-role
                                   comment-repair-order))

;;; Repair-intent JSON mirrors the object slots so agents can replay the same
;;; strategy without parsing human prose.
;; : (-> PolicyRepairIntent Json )
(def (policy-repair-intent-json<- intent)
  (hash (strategy (policy-repair-intent-state-strategy intent))
        (fixIntent (policy-repair-intent-state-fix-intent intent))
        (constraints (policy-repair-intent-state-constraints intent))
        (repairPhases (policy-repair-intent-state-repair-phases intent))
        (guideCommand (policy-repair-intent-state-guide-command intent))
        (guideRole (policy-repair-intent-state-guide-role intent))
        (commentRepairOrder
         (policy-repair-intent-state-comment-repair-order intent))))

;;; Packet boundary:
;;; - The diagnostic object owns the schema-level fields for both group and
;;;   single-finding warnings.
;;; - Callers supply domain objects; this layer alone decides the JSON packet
;;;   layout exposed to agents.
;; : (-> PolicyDiagnostic )
(def (make-policy-diagnostic kind: kind
                             unit: unit
                             ruleId: rule-id
                             severity: severity
                             location: location
                             problem: problem
                             evidence: evidence
                             fixIntent: fix-intent
                             constraints: constraints
                             guideCommand: guide-command
                             guideRole: guide-role
                             repairPhases: repair-phases)
  (make-policy-diagnostic-state +policy-diagnostic-schema+
                                kind
                                unit
                                rule-id
                                severity
                                location
                                problem
                                evidence
                                fix-intent
                                constraints
                                guide-command
                                guide-role
                                repair-phases))

;;; The projection is the durable agent-facing packet; keep every public slot
;;; explicit so schema drift is visible in review.
;; : (-> PolicyDiagnostic Json )
(def (policy-diagnostic-json-projection diagnostic)
  (hash (schema (policy-diagnostic-state-schema diagnostic))
        (kind (policy-diagnostic-state-kind diagnostic))
        (unit (policy-diagnostic-state-unit diagnostic))
        (ruleId (policy-diagnostic-state-rule-id diagnostic))
        (severity (policy-diagnostic-state-severity diagnostic))
        (location
         (policy-diagnostic-json<-
          (policy-diagnostic-state-location diagnostic)))
        (problem (policy-diagnostic-state-problem diagnostic))
        (evidence
         (policy-diagnostic-evidence-json
          (policy-diagnostic-state-evidence diagnostic)))
        (fixIntent (policy-diagnostic-state-fix-intent diagnostic))
        (constraints (policy-diagnostic-state-constraints diagnostic))
        (guideCommand (policy-diagnostic-state-guide-command diagnostic))
        (guideRole (policy-diagnostic-state-guide-role diagnostic))
        (repairPhases (policy-diagnostic-state-repair-phases diagnostic))))

;;; Evidence projection:
;;; - Group diagnostics pass a list of evidence objects; finding diagnostics
;;;   pass one object.
;;; - The map branch preserves the object protocol for each item instead of
;;;   exposing callers to list-specific JSON construction.
;;; Evidence payloads can be grouped; normalize both singleton and list forms
;;; through the same object projection path.
;; : (-> PolicyDiagnosticEvidenceOrList JsonOrList )
(def (policy-diagnostic-evidence-json evidence)
  (if (list? evidence)
    (map policy-diagnostic-json<- evidence)
    (policy-diagnostic-json<- evidence)))
