;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent repair policy tests.

(import :std/test
        (only-in :std/text/json read-json)
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/policy/repair-calibration
        :policy/fixtures)

(export agent-repair-policy-test)

;; PolicyTest
(def agent-repair-policy-test
  (test-suite "gerbil scheme harness agent repair policy"
    (test-case "agent policy check json exposes lint-style diagnostics"
      (let* ((root ".run/policy-functional-idiom-check-json")
             (_ (write-functional-idiom-project root))
             (result (policy-check-output ["--json" root]))
             (packet (call-with-input-string (cdr result) read-json))
             (agent-repair (hash-get packet "agentRepair"))
             (repair-plan (hash-get agent-repair "repairPlan"))
             (finding-groups (hash-get agent-repair "findingGroups"))
             (comment-group
              (find (lambda (group)
                      (and (equal? (hash-get group "ownerPath")
                                   "src/orders/core.ss")
                           (member "GERBIL-SCHEME-AGENT-POLICY-015"
                                   (hash-get group "rules"))))
                    finding-groups))
             (comment-diagnostic (hash-get comment-group "diagnostic"))
             (comment-location (hash-get comment-diagnostic "location"))
             (comment-intent (hash-get comment-group "repairIntent"))
             (comment-phases (hash-get comment-intent "repairPhases"))
             (finding (json-finding-by-rule
                       (hash-get packet "findings")
                       "GERBIL-SCHEME-AGENT-POLICY-009"))
             (comment-finding (json-finding-by-rule
                               (hash-get packet "findings")
                               "GERBIL-SCHEME-AGENT-POLICY-015"))
             (finding-repair (hash-get finding "agentRepair"))
             (finding-diagnostic (hash-get finding-repair "diagnostic"))
             (finding-location (hash-get finding-diagnostic "location")))
        (check (car result) => 1)
        (check (hash-get agent-repair "status") => "active")
        (check (hash-get agent-repair "repairableFindings") => 3)
        (check (hash-get agent-repair "repairableWarnings") => 3)
        (check (hash-get agent-repair "repairableErrors") => 0)
        (check (hash-get agent-repair "trigger") => "warning")
        (check (hash-get agent-repair "audience") => "agent")
        (check (hash-get agent-repair "feedbackKind")
               => "policy-diagnostic")
        (check (hash-get agent-repair "diagnosticSchema")
               => "gerbil-policy-diagnostic-v1")
        (check (hash-get agent-repair "diagnosticUnit") => "findingGroup")
        (check (hash-get repair-plan "status") => "active")
        (check (hash-get repair-plan "audience") => "agent")
        (check (hash-get repair-plan "feedbackKind")
               => "policy-diagnostic")
        (check (hash-get repair-plan "diagnosticSchema")
               => "gerbil-policy-diagnostic-v1")
        (check (not (not (member "editing without guide code evidence"
                                  (hash-get repair-plan "antiPatterns"))))
               => #t)
        (check (not (not (member "gxtest policy library report returns findings=0"
                                  (hash-get repair-plan "verification"))))
               => #t)
        (check (> (hash-get repair-plan "groupCount") 0) => #t)
        (check (not (not comment-group)) => #t)
        (check (not (not (member "rerun gxtest policy after edit"
                                  (hash-get comment-group "repairHints"))))
               => #t)
        (check (not (not (member "targeted harness tests still pass"
                                  (hash-get comment-group "verification"))))
               => #t)
        (check (not (not (member "functionQualityProfile"
                                  (hash-get comment-group "requiredWitnesses"))))
               => #t)
        (check (hash-get comment-diagnostic "schema")
               => "gerbil-policy-diagnostic-v1")
        (check (hash-get comment-diagnostic "unit") => "findingGroup")
        (check (hash-get comment-diagnostic "guideRole") => "evidence-only")
        (check (hash-get comment-location "path")
               => "src/orders/core.ss")
        (check (hash-get comment-location "selector")
               => "src/orders/core.ss")
        (check (hash-get comment-group "multiPolicy") => #t)
        (check (hash-get comment-group "repairStrategy")
               => "multi-policy-structural-first")
        (check (hash-get comment-intent "strategy")
               => "multi-policy-structural-first")
        (check (hash-get comment-intent "guideRole") => "evidence-only")
        (check (length comment-phases) => 2)
        (check (hash-get (car comment-phases) "name")
               => "primary-shape")
        (check (hash-get (cadr comment-phases) "name")
               => "dependent-comment-rationale")
        (check (hash-get (cadr comment-phases) "rules")
               => ["GERBIL-SCHEME-AGENT-POLICY-015"])
        (check (hash-get comment-intent "commentRepairOrder")
               => "comment-quality repairs run after structural/style repairs when both hit the same group")
        (check (hash-get finding-repair "repairable") => #t)
        (check (hash-get finding-repair "active") => #t)
        (check (hash-get finding-repair "schema")
               => "gerbil-policy-diagnostic-v1")
        (check (hash-get finding-repair "trigger") => "warning")
        (check (hash-get finding-repair "guideTopic")
               => "functional-data-transform")
        (check (hash-get finding-repair "guideIntent") => "repair")
        (check (hash-get finding-repair "guideRole") => "evidence-only")
        (check (hash-get finding-repair "guideCommand")
               => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-009 --intent repair")
        (check (hash-get finding-diagnostic "schema")
               => "gerbil-policy-diagnostic-v1")
        (check (hash-get finding-diagnostic "unit") => "finding")
        (check (hash-get finding-location "path")
               => "src/orders/core.ss")
        (check (hash-get (hash-get comment-finding "agentRepair")
                         "guideCommand")
               => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-015 --intent style")))
    (test-case "agent repair replay calibrates repaired structural witnesses"
      (let* ((before-root ".run/policy-agent-repair-replay-input")
             (after-root ".run/policy-agent-repair-replay-after")
             (_ (write-functional-idiom-project before-root))
             (_ (write-functional-idiom-calibrated-project after-root))
             (report (project-policy-report before-root))
             (report-summary (gxtest-report-summary report))
             (after-index (collect-project after-root))
             (after-findings (run-policy-checks after-index))
             (calibration
              (agent-repair-calibration-report
               report
               after-index
               after-findings))
             (assertions (hash-get calibration 'assertions)))
        (check (gxtest-report-status report) => "fail")
        (check (gxtest-report-finding-count report)
               => (length (gxtest-report-findings report)))
        (check (hash-get report-summary 'status) => "fail")
        (check (hash-get report-summary 'findingCount)
               => (gxtest-report-finding-count report))
        (check after-findings => [])
        (check (hash-get calibration 'status) => "pass")
        (check (hash-get calibration 'groupCount) => 2)
        (check (hash-get calibration 'failureCount) => 0)
        (check (> (hash-get calibration 'assertionCount) 6) => #t)
        (check (calibration-assertion-present?
                assertions
                "repairPlanDrivesRepair"
                "repairPlan")
               => #t)
        (check (calibration-assertion-present?
                assertions
                "typedContractFactsPresent"
                "typedContractFacts")
               => #t)
        (check (calibration-assertion-present?
                assertions
                "higherOrderFactsPresent"
                "higherOrderFacts")
               => #t)
        (check (calibration-assertion-present?
                assertions
                "functionQualityProfilePresent"
                "functionQualityProfile")
               => #t)
        (check (calibration-assertion-present?
                assertions
                "commentQualityFactsStrong"
                "commentQualityFacts")
               => #t)))))

;; : (-> (List Json) AssertionName Witness Boolean)
(def (calibration-assertion-present? assertions name witness)
  (not (not
        (find (lambda (assertion)
                (and (equal? (hash-get assertion 'status) "pass")
                     (equal? (hash-get assertion 'assertion) name)
                     (equal? (hash-get assertion 'witness) witness)))
              assertions))))
