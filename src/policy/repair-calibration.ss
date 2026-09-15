;;; -*- Gerbil -*-
;;; Agent-repair replay calibration over parser-owned structural facts.

(import :asp-gerbil-scheme/src/parser/facade
        (only-in :std/srfi/1 iota take)
        :asp-gerbil-scheme/src/types/facade)

(export agent-repair-calibration-report
        agent-repair-calibration-assertions
        agent-repair-calibration-failures
        agent-repair-calibration-status)

;; agent-repair-calibration-report
;;   : (-> PolicyReport
;;         ProjectIndex
;;         (List TypeFinding)
;;         Json)
;;   | doc m%
;;       `agent-repair-calibration-report report repaired-index repaired-findings`
;;       replays the same agentRepair report against a repaired project and
;;       checks parser-owned structural witnesses instead of trusting text diffs.
;;     %
(def (agent-repair-calibration-report policy-report repaired-index repaired-findings)
  (let* ((agent-repair (policy-report-agent-repair policy-report))
         (assertions
          (agent-repair-calibration-assertions
           policy-report
           repaired-index
           repaired-findings))
         (failures (agent-repair-calibration-failures assertions)))
    (hash (schemaId "agent.semantic-protocols.gerbil-scheme-agent-repair-calibration")
          (schemaVersion "1")
          (status (agent-repair-calibration-status assertions))
          (sourceReportSchemaId (json-ref policy-report 'schemaId))
          (sourceAgentRepairStatus (json-ref agent-repair 'status))
          (groupCount (length (policy-report-finding-groups policy-report)))
          (assertionCount (length assertions))
          (failureCount (length failures))
          (assertions assertions)
          (failures failures))))

;; agent-repair-calibration-assertions
;;   : (-> PolicyReport
;;         ProjectIndex
;;         (List TypeFinding)
;;         (List Json))
;;   | doc m%
;;       `agent-repair-calibration-assertions report index findings` maps each
;;       report findingGroup to structural assertions for the repaired index.
;;
;;       The group-indexed map is the replay boundary: it preserves report
;;       ordering while preventing evidence from one finding group from making
;;       another group look repaired.
;;     %
(def (agent-repair-calibration-assertions policy-report repaired-index repaired-findings)
  (let (groups (policy-report-finding-groups policy-report))
    (apply append
           (map
            (lambda (group rank)
              (finding-group-calibration-assertions
               group
               rank
               repaired-index
               repaired-findings))
            groups
            (iota (length groups) 1)))))

;;; Failure projection stays separate so report status and tests inspect the
;;; exact same assertion set instead of recomputing pass/fail in two places.
;; : (-> (List Json) (List Json))
(def (agent-repair-calibration-failures assertions)
  (filter calibration-assertion-failed? assertions))

;;; Status is derived only from assertion failures; callers should not treat
;;; warning-level source findings as calibrated success without this pass.
;; : (-> (List Json) String)
(def (agent-repair-calibration-status assertions)
  (if (null? (agent-repair-calibration-failures assertions))
    "pass"
    "fail"))

;;; Group replay boundary:
;;; - repairPlan proves the report can drive a concrete repair command.
;;; - cleared rules prove the expected tree no longer trips the same group.
;;; - requiredWitnesses prove quality with parser-owned structural facts.
;; : (-> Json Integer ProjectIndex (List TypeFinding) (List Json))
(def (finding-group-calibration-assertions group rank repaired-index repaired-findings)
  (append [(repair-plan-assertion group rank)
           (finding-group-cleared-assertion group rank repaired-findings)]
          (map (lambda (witness)
                 (required-witness-assertion
                  group
                  rank
                  witness
                  repaired-index
                  repaired-findings))
               (json-list-ref group 'requiredWitnesses))))

;;; Report-driving assertion: this catches report packets that contain findings
;;; but no executable repair command/phase ordering for an agent to replay.
;; : (-> Json Integer Json)
(def (repair-plan-assertion group rank)
  (let* ((plan (json-ref group 'repairPlan))
         (next (json-ref plan 'nextCommand))
         (phases (json-list-ref plan 'repairPhases))
         (passed (and next
                      (not (equal? next ""))
                      (pair? phases))))
    (calibration-assertion
     group
     rank
     "repairPlanDrivesRepair"
     "repairPlan"
     passed
     [(or next "")]
     "findingGroup must carry a nextCommand and ordered repairPhases")))

;;; Clearance assertion is intentionally owner/rule scoped. Structural witness
;;; checks may pass, but the repair is not calibrated if the same group remains.
;; : (-> Json Integer (List TypeFinding) Json)
(def (finding-group-cleared-assertion group rank repaired-findings)
  (let (remaining (matching-repaired-findings group repaired-findings))
    (calibration-assertion
     group
     rank
     "findingGroupCleared"
     "policyFinding"
     (null? remaining)
     (map type-finding-rule-id remaining)
     "repaired project must not keep findings for the same owner/rules")))

;;; Witness dispatch keeps the policy report as the source of truth. Adding a
;;; new requiredWitness must add a structural assertion here or fail loudly.
;; : (-> Json Integer Witness ProjectIndex (List TypeFinding) Json)
(def (required-witness-assertion group rank witness repaired-index repaired-findings)
  (case (witness->symbol witness)
    ((policyFinding)
     (finding-group-cleared-assertion group rank repaired-findings))
    ((functionQualityProfile)
     (fact-count-assertion
      group
      rank
      "functionQualityProfilePresent"
      witness
      (matching-function-quality-profiles group repaired-index)
      function-quality-profile-name
      "repaired owner must expose functionQualityProfiles"))
    ((typedContractFacts)
     (fact-count-assertion
      group
      rank
      "typedContractFactsPresent"
      witness
      (matching-typed-contract-facts group repaired-index)
      typed-contract-fact-definition-name
      "repaired owner must expose typed contract facts"))
    ((higherOrderFacts)
     (fact-count-assertion
      group
      rank
      "higherOrderFactsPresent"
      witness
      (matching-higher-order-facts group repaired-index)
      higher-order-fact-role
      "repaired owner must expose higher-order/combinator facts"))
    ((commentQualityFacts)
     (comment-quality-assertion group rank witness repaired-index))
    ((controlFlowFacts)
     (fact-count-assertion
      group
      rank
      "controlFlowFactsPresent"
      witness
      (matching-control-flow-facts group repaired-index)
      control-flow-fact-role
      "repaired owner must expose parser control-flow facts"))
    ((predicateFamilyFacts)
     (fact-count-assertion
      group
      rank
      "predicateFamilyFactsPresent"
      witness
      (matching-predicate-family-facts group repaired-index)
      predicate-family-fact-role
      "repaired owner must expose predicate-family facts"))
    ((fieldAccessPatternFacts)
     (fact-count-assertion
      group
      rank
      "fieldAccessPatternFactsPresent"
      witness
      (matching-field-access-pattern-facts group repaired-index)
      field-access-pattern-fact-role
      "repaired owner must expose field-access pattern facts"))
    ((dependencyAdapterQualityFacts)
     (fact-count-assertion
      group
      rank
      "dependencyAdapterQualityFactsPresent"
      witness
      (matching-dependency-adapter-quality-facts group repaired-index)
      dependency-adapter-quality-fact-role
      "repaired owner must expose dependency adapter quality facts"))
    ((moduleImportFacts)
     (fact-count-assertion
      group
      rank
      "moduleImportFactsPresent"
      witness
      (matching-module-import-facts group repaired-index)
      module-import-fact-module
      "repaired owner must expose module import facts"))
    ((runtimeSourceMacroWitness)
     (fact-count-assertion
      group
      rank
      "runtimeSourceMacroWitnessPresent"
      witness
      (matching-macro-facts group repaired-index)
      macro-fact-name
      "repaired owner must keep parser-owned macro facts available"))
    (else
     (calibration-assertion
      group
      rank
      "unknownRequiredWitness"
      witness
      #f
      []
      "required witness has no calibration assertion"))))

;;; Comment witness is stronger than fact presence: required absent/weak parser
;;; comment facts still fail even when the fact extractor produced evidence.
;; : (-> Json Integer Witness ProjectIndex Json)
(def (comment-quality-assertion group rank witness repaired-index)
  (let* ((facts (matching-comment-quality-facts group repaired-index))
         (weak (filter weak-required-comment-quality-fact? facts)))
    (calibration-assertion
     group
     rank
     "commentQualityFactsStrong"
     witness
     (and (pair? facts) (null? weak))
     (map comment-quality-fact-target-name weak)
     "repaired owner must not keep required absent/weak comment-quality facts")))

;;; Assertion packets are deliberately small and stable so snapshots and
;;; downstream gxtest failures can compare structure without source diffs.
;; : (-> Json Integer AssertionName Witness Boolean Evidence Message Json)
(def (calibration-assertion group rank name witness passed evidence message)
  (hash (status (if passed "pass" "fail"))
        (groupIndex rank)
        (ownerPath (group-owner-path group))
        (selector (group-selector group))
        (primaryRule (json-ref group 'primaryRule))
        (rules (json-list-ref group 'rules))
        (assertion name)
        (witness witness)
        (evidence (take evidence (min 8 (length evidence))))
        (message message)))

;;; A one-field predicate keeps the report schema open while status semantics
;;; remain a simple pass/fail value.
;; : (-> Json Boolean)
(def (calibration-assertion-failed? assertion)
  (not (equal? (json-ref assertion 'status) "pass")))

;;; Group paths can be absent in malformed JSON input; normalize to an empty
;;; owner so malformed report packets fail by witness absence, not exceptions.
;; : (-> Json String)
(def (group-owner-path group)
  (or (json-ref group 'ownerPath) ""))

;;; Selectors stay report metadata for receipts; structural matching remains
;;; path scoped because many parser facts are file-level.
;; : (-> Json String)
(def (group-selector group)
  (or (json-ref group 'selector) ""))

;;; The calibration owner consumes both in-memory Scheme reports and JSON
;;; reports parsed back from CLI output, so key lookup must stay tolerant.
;; : (-> PolicyReport Json)
(def (policy-report-agent-repair policy-report)
  (or (json-ref policy-report 'agentRepair) (hash)))

;;; Finding groups are the only replay unit. Individual findings are already
;;; grouped by repair.ss and should not be split during calibration.
;; : (-> PolicyReport (List Json))
(def (policy-report-finding-groups policy-report)
  (json-list-ref (policy-report-agent-repair policy-report) 'findingGroups))

;;; Mixed symbol/string lookup is required because project-policy-report returns
;;; Scheme hashes while CLI JSON tests read the same report with string keys.
;; : (-> Hash Key Datum)
(def (json-ref table key)
  (cond
   ((and table (hash-key? table key))
    (hash-get table key))
   ((and table (symbol? key) (hash-key? table (symbol->string key)))
    (hash-get table (symbol->string key)))
   ((and table (string? key) (hash-key? table (string->symbol key)))
    (hash-get table (string->symbol key)))
   (else #f)))

;;; List normalization prevents malformed optional fields from masquerading as
;;; usable repair groups or witness arrays.
;; : (-> Hash Key (List Datum))
(def (json-list-ref table key)
  (let (value (json-ref table key))
    (if (list? value) value [])))

;;; Witness names are strings in JSON and may be symbols in direct Scheme tests;
;;; normalization keeps the dispatch table single-sourced.
;; : (-> Witness Symbol)
(def (witness->symbol witness)
  (if (symbol? witness) witness (string->symbol witness)))

;;; Repaired findings are matched by original owner/rules so unrelated residual
;;; warnings elsewhere do not poison this group's calibration.
;; : (-> Json (List TypeFinding) (List TypeFinding))
(def (matching-repaired-findings group findings)
  (filter (lambda (finding)
            (and (member (type-finding-rule-id finding)
                         (json-list-ref group 'rules))
                 (owner-path-match? group (type-finding-path finding))))
          findings))

;;; Function quality profiles prove the repaired owner has parser-visible
;;; function-level shape; plain source text is not accepted as evidence.
;; : (-> Json ProjectIndex (List FunctionQualityProfile))
(def (matching-function-quality-profiles group index)
  (filter (lambda (profile)
            (owner-path-match? group (function-quality-profile-path profile)))
          (project-function-quality-profiles index)))

;;; Typed contract facts prove the repair produced adjacent Scheme-native
;;; contract blocks rather than cosmetic comments.
;; : (-> Json ProjectIndex (List TypedContractFact))
(def (matching-typed-contract-facts group index)
  (filter (lambda (fact)
            (owner-path-match? group (typed-contract-fact-path fact)))
          (project-typed-contract-facts index)))

;;; Higher-order facts are the structural proof for combinator-style repair
;;; targets such as fold, curry, pipeline, lambda, or lambda-match.
;; : (-> Json ProjectIndex (List HigherOrderFact))
(def (matching-higher-order-facts group index)
  (filter (lambda (fact)
            (owner-path-match? group (higher-order-fact-path fact)))
          (project-higher-order-facts index)))

;;; Control-flow facts keep controlled-branch repairs grounded in parser output
;;; instead of checking for a particular spelling of match/cond.
;; : (-> Json ProjectIndex (List ControlFlowFact))
(def (matching-control-flow-facts group index)
  (filter (lambda (fact)
            (owner-path-match? group (control-flow-fact-path fact)))
          (project-control-flow-facts index)))

;;; Predicate-family facts calibrate repairs that replace repeated ad hoc
;;; conditionals with parser-recognized predicate groupings.
;; : (-> Json ProjectIndex (List PredicateFamilyFact))
(def (matching-predicate-family-facts group index)
  (filter (lambda (fact)
            (owner-path-match? group (predicate-family-fact-path fact)))
          (project-predicate-family-facts index)))

;;; Field-access facts ensure record/hash accessor repairs are visible as a
;;; coherent pattern, not only as isolated successful calls.
;; : (-> Json ProjectIndex (List FieldAccessPatternFact))
(def (matching-field-access-pattern-facts group index)
  (filter (lambda (fact)
            (owner-path-match? group (field-access-pattern-fact-path fact)))
          (project-field-access-pattern-facts index)))

;;; Dependency adapter facts prove a repair used provider/library protocols
;;; rather than rebuilding dependency behavior by hand.
;; : (-> Json ProjectIndex (List DependencyAdapterQualityFact))
(def (matching-dependency-adapter-quality-facts group index)
  (filter (lambda (fact)
            (owner-path-match? group
                               (dependency-adapter-quality-fact-path fact)))
          (project-dependency-adapter-quality-facts index)))

;;; Module import facts are required for dependency repairs because the import
;;; surface is the structural witness for available upstream APIs.
;; : (-> Json ProjectIndex (List ModuleImportFact))
(def (matching-module-import-facts group index)
  (filter (lambda (fact)
            (owner-path-match? group (module-import-fact-path fact)))
          (project-module-import-facts index)))

;;; Macro facts keep macro repairs bound to parser-owned syntax evidence and
;;; prevent calibration from blessing unobserved transformer edits.
;; : (-> Json ProjectIndex (List MacroFact))
(def (matching-macro-facts group index)
  (filter (lambda (fact)
            (owner-path-match? group (macro-fact-path fact)))
          (project-macro-facts index)))

;;; Comment facts are scoped to the repaired owner so comment witness failures
;;; point at the same repair group that requested them.
;; : (-> Json ProjectIndex (List CommentQualityFact))
(def (matching-comment-quality-facts group index)
  (filter (lambda (fact)
            (owner-path-match? group (comment-quality-fact-path fact)))
          (project-comment-quality-facts index)))

;;; Path matching is intentionally narrow. Calibration should not let evidence
;;; from another owner satisfy this finding group's required witnesses.
;; : (-> Json Path Boolean)
(def (owner-path-match? group path)
  (let (owner (group-owner-path group))
    (or (equal? owner "")
        (equal? owner path))))

;;; Count is a tiny abstraction because all witness checks share the same
;;; non-empty evidence predicate while evidence rendering stays caller-owned.
;; : (forall (a)
;;     (-> (List a) Integer))
(def (fact-count facts)
  (length facts))

;;; Fact-count assertions separate structural fact selection from receipt
;;; construction, keeping each witness selector small and auditable.
;; : (-> Json Integer AssertionName Witness (List Fact) EvidenceFn Message Json)
(def (fact-count-assertion group rank name witness facts evidence-fn message)
  (calibration-assertion
   group
   rank
   name
   witness
   (> (fact-count facts) 0)
   (map evidence-fn facts)
   message))

;;; Project aggregation normalizes source-file facts into the shape needed by
;;; replay checks without changing parser ownership of each fact.
;; : (-> ProjectIndex (List HigherOrderFact))
(def (project-higher-order-facts index)
  (apply append
         (map source-file-higher-order-forms (project-index-files index))))

;;; Control-flow aggregation mirrors higher-order aggregation so witness checks
;;; can stay group/path scoped.
;; : (-> ProjectIndex (List ControlFlowFact))
(def (project-control-flow-facts index)
  (apply append
         (map source-file-control-flow-forms (project-index-files index))))

;;; Import aggregation gives dependency witnesses one project-level view while
;;; retaining original source-file paths for owner matching.
;; : (-> ProjectIndex (List ModuleImportFact))
(def (project-module-import-facts index)
  (apply append
         (map source-file-module-imports (project-index-files index))))

;;; Macro aggregation is used only for witness presence; macro semantics remain
;;; in parser facts and upstream runtime-source guidance.
;; : (-> ProjectIndex (List MacroFact))
(def (project-macro-facts index)
  (apply append
         (map source-file-macros (project-index-files index))))

;;; Weak comment quality is the hard gate used by R015; calibration reuses the
;;; same absent/weak boundary so replay cannot hide comment debt.
;; : (-> CommentQualityFact Boolean)
(def (weak-required-comment-quality-fact? fact)
  (and (comment-quality-fact-required fact)
       (member (comment-quality-fact-quality fact) ["absent" "weak"])))
