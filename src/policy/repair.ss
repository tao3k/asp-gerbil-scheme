;;; -*- Gerbil -*-
;;; Agent repair metadata derived from policy findings.

(import :asp-gerbil-scheme/src/policy/catalog
        (only-in :std/misc/list unique)
        (only-in :std/srfi/1 take)
        (only-in :std/srfi/13 string-join)
        :asp-gerbil-scheme/src/types/findings)

(export repairable-finding?
        repairable-findings
        agent-repair-report-json
        agent-repair-summary-parts
        finding-agent-repair-json
        finding-agent-repair-parts
        finding-guide-detail-parts)

;;; Repairability is protocol-driven: a finding opts in by exposing an
;;; agent-repair projection, not by matching rule names here.
;; : (-> TypeFinding Boolean )
(def (repairable-finding? finding)
  (and (finding-agent-repair-json finding) #t))

;;; Boundary:
;;; - repairable-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypeFinding) (List TypeFinding) )
(def (repairable-findings findings)
  (filter repairable-finding? findings))

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

;;; Report JSON summarizes repair scope before expensive per-group projections
;;; so clients can decide whether to render or skip repair guidance.
;; : (-> (List TypeFinding) Json )
(def (agent-repair-report-json findings)
  (let* ((repairable (repairable-findings findings))
         (warnings (count-finding-severity repairable "warning"))
         (errors (count-finding-severity repairable "error"))
         (count (length repairable)))
    (hash (status (if (zero? count) "none" "active"))
          (audience "agent")
          (feedbackKind "policy-diagnostic")
          (diagnosticSchema "gerbil-policy-diagnostic-v1")
          (diagnosticUnit "findingGroup")
          (repairableFindings count)
          (repairableWarnings warnings)
          (repairableErrors errors)
          (trigger (repair-trigger warnings errors))
          (findingGroups (finding-groups-json repairable))
          (repairPlan (repair-plan-json repairable))
          (instruction
           "read each diagnostic location/problem/evidence/fixIntent; edit the selector owner, preserve constraints, then rerun check"))))

;; : (-> (List TypeFinding) (List RepairSummaryPart) )
(def (agent-repair-summary-parts findings)
  (let* ((repairable (repairable-findings findings))
         (warnings (count-finding-severity repairable "warning"))
         (errors (count-finding-severity repairable "error"))
         (count (length repairable)))
    (if (zero? count)
      []
      [(string-append "status=active")
       "audience=agent"
       "feedbackKind=policy-diagnostic"
       "diagnosticSchema=gerbil-policy-diagnostic-v1"
       "diagnosticUnit=findingGroup"
       (string-append "repairableFindings=" (number->string count))
       (string-append "repairableWarnings=" (number->string warnings))
       (string-append "repairableErrors=" (number->string errors))
       (string-append "trigger=" (repair-trigger warnings errors))
       (string-append "repairGroups="
                      (number->string (length (finding-groups repairable))))
       "focus=findingGroups[].diagnostic.location/problem/evidence/fixIntent"
       "verify=asp-gerbil-scheme-check-findings-zero"])))

;; : (-> (List TypeFinding) Json )
(def (repair-plan-json findings)
  (let (groups (finding-groups-json findings))
    (hash (status (if (null? groups) "none" "active"))
          (audience "agent")
          (feedbackKind "policy-diagnostic")
          (diagnosticSchema "gerbil-policy-diagnostic-v1")
          (groupCount (length groups))
          (primaryGroups (take groups (min 4 (length groups))))
          (verification (agent-repair-success-criteria))
          (antiPatterns (agent-repair-anti-patterns))
          (strategy "repair once per owner/function selector; structural/style repairs run before comment rationale repairs")
          (requires ["parser-owned functionQualityProfiles when available"
                     "findingGroup primary rule guide"
                     "gxtest/library policy and bench after grouped repair"]))))

;; : (-> (List TypeFinding) String )
(def (primary-repair-next-command findings)
  (let (groups (finding-groups-json findings))
    (if (pair? groups)
      (hash-get (hash-get (car groups) 'repairPlan) 'nextCommand)
      "")))

;; : (-> (List String) )
(def (agent-repair-workflow)
  ["read primary findingGroup"
   "run repairPlan.nextCommand for guide code evidence"
   "edit only the owner or selector named by the group"
   "preserve requiredWitnesses"
   "rerun gxtest policy and targeted tests"])

;; : (-> (List String) )
(def (agent-repair-success-criteria)
  ["gxtest policy library report returns findings=0"
   "targeted harness tests still pass"
   "no unrelated source rewrites"])

;; : (-> (List String) )
(def (agent-repair-anti-patterns)
  ["treating repeated findings as separate edits"
   "editing without guide code evidence"
   "dropping parser-owned witnesses"
   "papering over warnings with comments only"])

;;; Finding groups are the agent-facing repair unit.
;;; Mapping after grouping prevents repeated warnings from becoming repeated
;;; repair instructions for the same selector.
;; : (-> (List TypeFinding) Json )
(def (finding-groups-json findings)
  (map finding-group-json (finding-groups findings)))

;;; Group findings by selector when possible, then path. This is intentionally
;;; independent from functionQualityProfiles so retired policy findings still get
;;; a repair plan while parser-level profiles come online.
;; : (-> (List TypeFinding) (List FindingGroup) )
(def (finding-groups findings)
  (reverse
   (foldl add-finding-to-group '() findings)))

;; : (-> TypeFinding (List FindingGroup) (List FindingGroup) )
(def (add-finding-to-group finding groups)
  (let* ((key (finding-group-key finding))
         (prior (assoc key groups)))
    (if prior
      (cons (cons key (cons finding (cdr prior)))
            (remove-finding-group key groups))
      (cons (cons key [finding]) groups))))

;;; Removing the prior group keeps fold state immutable.
;;; The replacement group is consed by add-finding-to-group with the new finding
;;; at the front, then reversed during JSON projection.
;; : (-> GroupKey (List FindingGroup) (List FindingGroup) )
(def (remove-finding-group key groups)
  (filter (lambda (group) (not (equal? (car group) key))) groups))

;; : (-> TypeFinding GroupKey )
(def (finding-group-key finding)
  (string-append (type-finding-path finding)
                 "|"
                 (or (type-finding-selector finding) "")))

;;; Group JSON preserves both the primary rule and suppressed dependents.
;;; Agents get one next command plus the repair order, so comment polish does
;;; not race ahead of structural/style fixes.
;; : (-> FindingGroup Json )
(def (finding-group-json group)
  (let* ((findings (reverse (cdr group)))
         (primary (primary-finding findings))
         (rules (map type-finding-rule-id findings))
         (suppressed (suppressed-dependent-rules rules))
         (repair-order (repair-order-rules rules primary suppressed))
         (strategy (repair-strategy rules suppressed))
         (phases (repair-phases repair-order suppressed))
         (guide-command (or (agent-rule-guide-next-command
                             (type-finding-rule-id primary))
                            "")))
    (hash (ownerPath (type-finding-path primary))
          (selector (or (type-finding-selector primary) ""))
          (definitionName (finding-group-definition-name findings))
          (rules rules)
          (severityMax (finding-group-severity findings))
          (primaryRule (type-finding-rule-id primary))
          (multiPolicy (repair-multi-policy-group? rules))
          (repairStrategy strategy)
          (primaryRepairClass
           (or (agent-rule-topic (type-finding-rule-id primary))
               "policy-finding"))
          (suppressedRules suppressed)
          (requiredWitnesses (finding-group-required-witnesses rules))
          (repairOrder repair-order)
          (repairPlan
           (hash (nextCommand guide-command)
                 (repairPhases phases)))
          (diagnostic
           (finding-group-diagnostic-json
            primary findings rules strategy phases guide-command))
          (repairHints (finding-group-agent-checklist primary rules))
          (verification (agent-repair-success-criteria))
          (repairIntent
           (policy-diagnostic-json<-
            (make-policy-repair-intent
             strategy: strategy
             fixIntent: (finding-group-fix-intent primary rules strategy)
             constraints: (finding-group-repair-constraints rules)
             repairPhases: phases
             guideCommand: guide-command
             guideRole: "evidence-only"
             commentRepairOrder:
             "comment-quality repairs run after structural/style repairs when both hit the same group")))
          (agentInstruction
           "treat this diagnostic group as one function-level edit boundary, not independent warning spam"))))

;; : (-> TypeFinding (List Rule) (List String) )
(def (finding-group-agent-checklist primary rules)
  [(string-append "edit selector=" (or (type-finding-selector primary) ""))
   (string-append "preserve requiredWitnesses="
                  (string-join (finding-group-required-witnesses rules) ","))
   "apply one grouped structural repair when rules share the selector"
   "rerun gxtest policy after edit"])

;;; Diagnostic JSON is a bounded projection over one grouped repair decision.
;;; The `map` preserves each raw finding evidence item while group-level fix
;;; intent and constraints are computed once for the selector boundary.
;; : (-> TypeFinding (List TypeFinding) (List Rule) String RepairPhases String Json )
(def (finding-group-diagnostic-json primary findings rules strategy phases guide-command)
  (policy-diagnostic-json<-
   (make-policy-diagnostic
    kind: "policy"
    unit: "findingGroup"
    ruleId: (type-finding-rule-id primary)
    severity: (finding-group-severity findings)
    location: (finding-location primary)
    problem: (finding-group-problem primary rules)
    evidence: (map finding-diagnostic-evidence findings)
    fixIntent: (finding-group-fix-intent primary rules strategy)
    constraints: (finding-group-repair-constraints rules)
    guideCommand: guide-command
    guideRole: "evidence-only"
    repairPhases: phases)))

;; : (-> TypeFinding PolicyDiagnosticLocation )
(def (finding-location finding)
  (make-policy-diagnostic-location
   (type-finding-path finding)
   (or (type-finding-selector finding) "")
   (finding-definition-name finding)))

;; : (-> TypeFinding PolicyDiagnosticEvidence )
(def (finding-diagnostic-evidence finding)
  (make-policy-diagnostic-evidence
   (type-finding-rule-id finding)
   (type-finding-severity finding)
   (type-finding-message finding)
   (type-finding-details finding)))

;; : (-> TypeFinding (List Rule) String )
(def (finding-group-problem primary rules)
  (if (repair-multi-policy-group? rules)
    (string-append
     "multiple policy signals converge at this selector; repair the underlying code shape behind "
     (type-finding-rule-id primary))
    (type-finding-message primary)))

;; : (-> TypeFinding (List Rule) String String )
(def (finding-group-fix-intent primary rules strategy)
  (if (repair-multi-policy-group? rules)
    (string-append
     "apply one " strategy " change at the selector so primary and dependent rules disappear together")
    (string-append
     "repair the code shape described by " (type-finding-rule-id primary)
     " without silencing the policy")))

;;; Repair constraints combine fixed guardrails with parser-required witnesses.
;;; Mapping witness names to imperative strings keeps the witness list
;;; first-class until the final agent-facing diagnostic packet.
;; : (-> (List Rule) (List String) )
(def (finding-group-repair-constraints rules)
  (append ["do not suppress the finding with unrelated comments"
           "do not edit outside the reported owner selector unless required by the same diagnostic"]
          (map (lambda (witness)
                 (string-append "preserve witness " witness))
               (finding-group-required-witnesses rules))))

;;; Primary finding selects the strongest repair class in a group.
;;; Lower numeric priority wins so structural drift controls comment-only noise.
;; : (-> (List TypeFinding) TypeFinding )
(def (primary-finding findings)
  (foldl (lambda (finding best)
           (if (< (rule-repair-priority (type-finding-rule-id finding))
                  (rule-repair-priority (type-finding-rule-id best)))
             finding
             best))
         (car findings)
         (cdr findings)))

;; : (-> RuleId Integer )
(def (rule-repair-priority rule-id)
  (cond
   ((equal? rule-id "GERBIL-SCHEME-AGENT-POLICY-017") 8)
   ((equal? rule-id "GERBIL-SCHEME-AGENT-POLICY-016") 10)
   ((equal? rule-id "GERBIL-SCHEME-AGENT-POLICY-014") 20)
   ((equal? rule-id "GERBIL-SCHEME-AGENT-POLICY-013") 30)
   ((equal? rule-id "GERBIL-SCHEME-AGENT-POLICY-015") 40)
   ((equal? rule-id "GERBIL-SCHEME-AGENT-POLICY-011") 45)
   (else 90)))

;;; Definition names are best-effort metadata for repair receipts.
;;; The group key remains selector/path based when parser facts do not expose a
;;; definition name.
;; : (-> (List TypeFinding) String )
(def (finding-group-definition-name findings)
  (or (ormap finding-definition-name findings)
      ""))

;; : (-> TypeFinding String )
(def (finding-definition-name finding)
  (or (finding-detail-field finding 'definition)
      (finding-detail-field finding 'target)
      (finding-detail-field finding 'subject)
      (finding-detail-field finding 'targetName)))

;; : (-> TypeFinding Field Value )
(def (finding-detail-field finding field)
  (let (details (type-finding-details finding))
    (and details
         (hash-key? details field)
         (hash-get details field))))

;;; Group severity is a max over member severities.
;;; Any error makes the whole repair boundary error-level for CI reporting.
;; : (-> (List TypeFinding) Severity )
(def (finding-group-severity findings)
  (if (ormap (lambda (finding)
               (equal? (type-finding-severity finding) "error"))
             findings)
    "error"
    "warning"))

;;; Suppression keeps dependent comment warnings visible but non-primary.
;;; When stronger shape rules are present, agents repair structure first and
;;; revisit comments after code shape stabilizes.
;; : (-> (List RuleId) (List RuleId) )
(def (suppressed-dependent-rules rules)
  (if (and (member "GERBIL-SCHEME-AGENT-POLICY-015" rules)
           (ormap (cut member <> rules)
                  ["GERBIL-SCHEME-AGENT-POLICY-013"
                   "GERBIL-SCHEME-AGENT-POLICY-014"
                   "GERBIL-SCHEME-AGENT-POLICY-016"
                   "GERBIL-SCHEME-AGENT-POLICY-017"]))
    ["GERBIL-SCHEME-AGENT-POLICY-015"]
    []))

;;; Required witnesses merge rule needs into a deduped checklist.
;;; The apply/map shape keeps the witness catalog rule-owned while the group
;;; owns aggregation.
;; : (-> (List RuleId) (List Witness) )
(def (finding-group-required-witnesses rules)
  (unique
   (apply append
          (map rule-required-witnesses rules))))

;; : (-> RuleId (List Witness) )
(def (rule-required-witnesses rule-id)
  (cond
   ((equal? rule-id "GERBIL-SCHEME-AGENT-POLICY-017")
    ["dependencyAdapterQualityFacts" "moduleImportFacts" "genericContractTestWitness"])
   ((equal? rule-id "GERBIL-SCHEME-AGENT-POLICY-016")
    ["predicateFamilyFacts" "fieldAccessPatternFacts" "functionQualityProfile"])
   ((equal? rule-id "GERBIL-SCHEME-AGENT-POLICY-014")
    ["controlFlowFacts" "functionQualityProfile"])
   ((equal? rule-id "GERBIL-SCHEME-AGENT-POLICY-013")
    ["typedContractFacts" "higherOrderFacts" "functionQualityProfile"])
   ((equal? rule-id "GERBIL-SCHEME-AGENT-POLICY-015")
    ["commentQualityFacts" "functionQualityProfile"])
   ((equal? rule-id "GERBIL-SCHEME-AGENT-POLICY-011")
    ["runtimeSourceMacroWitness"])
   (else ["policyFinding"])))

;;; Repair order starts with the primary rule and appends suppressed rules last.
;;; This sequence gives the agent a deterministic one-pass repair plan.
;; : (-> (List RuleId) TypeFinding (List RuleId) (List RuleId) )
(def (repair-order-rules rules primary suppressed)
  (unique
   (append [(type-finding-rule-id primary)]
           (filter (lambda (rule) (not (member rule suppressed)))
                   rules)
           suppressed)))

;;; Strategy names are derived from group shape, not from one rule id.
;;; Multi-policy groups with suppressed comment rules require shape-first repair,
;;; while simple groups keep the single guide command contract.
;; : (-> (List RuleId) (List RuleId) RepairStrategy )
(def (repair-strategy rules suppressed)
  (cond
   ((and (repair-multi-policy-group? rules) (pair? suppressed))
    "multi-policy-structural-first")
   ((repair-multi-policy-group? rules)
    "multi-policy-single-edit")
   (else "single-policy-guide")))

;;; Boolean output is JSON-visible, so agents can distinguish grouped repairs
;;; from independent one-rule warnings without re-parsing rule arrays.
;; : (-> (List RuleId) Boolean )
(def (repair-multi-policy-group? rules)
  (> (length (unique rules)) 1))

;;; Repair phases turn a grouped rule list into an ordered action packet.
;;; Suppressed comment rules become an explicit second phase instead of hidden
;;; warning noise, preserving structure-first repair.
;; : (-> (List RuleId) (List RuleId) (List RepairPhase) )
(def (repair-phases repair-order suppressed)
  (let ((primary-rules (filter (lambda (rule) (not (member rule suppressed)))
                               repair-order)))
    (filter identity
            [(and (pair? primary-rules)
                  (repair-phase
                   "primary-shape"
                   primary-rules
                   "apply-policy-triggered-repair"
                   "apply the primary structural/style repair once because this policy group fired"))
             (and (pair? suppressed)
                  (repair-phase
                   "dependent-comment-rationale"
                   suppressed
                   "repair-comment-rationale-after-shape"
                   "update engineering comments after the code shape is stable"))])))

;;; Phase packets are intentionally small: name, rules, action, instruction.
;;; The rule ids still route to the central guide catalog.
;; : (-> String (List RuleId) Action Instruction RepairPhase )
(def (repair-phase name rules action instruction)
  (hash (name name)
        (rules rules)
        (action action)
        (instruction instruction)))

;;; Boundary:
;;; - count-finding-severity composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypeFinding) Severity Integer )
(def (count-finding-severity findings severity)
  (length
   (filter (lambda (finding)
             (equal? (type-finding-severity finding) severity))
           findings)))

;; : (-> Warnings Errors RepairTrigger )
(def (repair-trigger warnings errors)
  (cond
   ((and (> warnings 0) (> errors 0)) "warning-or-error")
   ((> errors 0) "error")
   ((> warnings 0) "warning")
   (else "none")))

;; : (-> TypeFinding Json )
(def (finding-agent-repair-json finding)
  (let (route (finding-guide-route (type-finding-rule-id finding)))
    (and route
         (hash (active #t)
               (repairable #t)
               (trigger (type-finding-severity finding))
               (reason "policy-finding")
               (schema "gerbil-policy-diagnostic-v1")
               (ruleId (type-finding-rule-id finding))
               (severity (type-finding-severity finding))
               (diagnostic (finding-diagnostic-json finding route))
	               (guideTopic (car route))
	               (guideIntent (cadr route))
	               (guideCommand (caddr route))
	               (guideRole "evidence-only")
	               (instruction "diagnostic-first: fix the reported selector problem; use guideCommand only as supporting evidence")))))

;; : (-> TypeFinding GuideRoute Json )
(def (finding-diagnostic-json finding route)
  (policy-diagnostic-json<-
   (make-policy-diagnostic
    kind: "policy"
    unit: "finding"
    ruleId: (type-finding-rule-id finding)
    severity: (type-finding-severity finding)
    location: (finding-location finding)
    problem: (type-finding-message finding)
    evidence: (finding-diagnostic-evidence finding)
    fixIntent:
    (string-append
     "repair the selector so " (type-finding-rule-id finding)
     " no longer matches; keep the implementation idiomatic Gerbil Scheme")
    constraints: ["do not suppress the finding"
                  "do not make unrelated style rewrites"]
    guideCommand: (caddr route)
    guideRole: "evidence-only"
    repairPhases: [])))

;; : (-> TypeFinding FindingAgentRepairParts )
(def (finding-agent-repair-parts finding)
  (let (repair (finding-agent-repair-json finding))
    (if repair
      [(string-append "rule=" (hash-get repair 'ruleId))
       (string-append "severity=" (hash-get repair 'severity))
       "repairable=true"
       "active=true"
       (string-append "schema=" (hash-get repair 'schema))
       (string-append "trigger=" (hash-get repair 'trigger))
	       (string-append "reason=" (hash-get repair 'reason))
	       (string-append "guideTopic=" (hash-get repair 'guideTopic))
	       (string-append "guideIntent=" (hash-get repair 'guideIntent))
	       (string-append "guideCommand=" (hash-get repair 'guideCommand))
	       (string-append "guideRole=" (hash-get repair 'guideRole))
	       (string-append "instruction=" (hash-get repair 'instruction))]
      [])))

;; : (-> TypeFinding String )
(def (finding-guide-detail-parts finding)
  (let (repair (finding-agent-repair-json finding))
    (if repair
	      [(string-append "guideTopic=" (hash-get repair 'guideTopic))
	       (string-append "guideIntent=" (hash-get repair 'guideIntent))
	       (string-append "guideCommand=" (hash-get repair 'guideCommand))
	       (string-append "guideRole=" (hash-get repair 'guideRole))]
      [])))

;;; Boundary:
;;; - finding-guide-route reads the central agent rule catalog.
;;; - Keep packet shape and invariants stable.
;; : (-> Rule GuideRoute )
(def (finding-guide-route rule)
  (agent-rule-guide-route rule))
