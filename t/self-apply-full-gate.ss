;;; -*- Gerbil -*-
;;; Explicit slow self-apply policy gate for this harness.

(import :asp-gerbil-scheme/src/build-api/source-coverage
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :policy/fixtures
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/policy/repair-calibration
        :asp-gerbil-scheme/src/snapshot/facade
        :std/sugar
        :asp-gerbil-scheme/src/types/facade)
(export self-apply-full-test)

;; ConfigConstant
(def +self-apply-finding-budgets+
  '())
;; SelfApplyIndexCache
(def +self-apply-index-cache+ #f)
;; SelfApplyFindingsCache
(def +self-apply-findings-cache+ #f)
;; SelfApplyRepairProbeRoot
(def +self-apply-agent-repair-probe-root+
  ".run/self-apply-agent-repair-probe")

;;; Probe shape:
;;; - paths match real source owners so calibration proves current source repair.
;;; - contents are intentionally weak and exist only to make agentRepair active.
;; : (-> Root Unit)
(def (write-self-apply-agent-repair-probe! root)
  (let* ((src (string-append root "/src"))
         (types (string-append src "/types"))
         (policy (string-append src "/policy")))
    (reset-fixture-root root)
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir types)
    (ensure-dir policy)
    (write-text
     (string-append root "/gerbil.pkg")
     "(package: self-apply-agent-repair-probe)\n")
    (write-text
     (string-append types "/validation.ss")
     ";;; -*- Gerbil -*-\n(package: self-apply/probe/types)\n(export type-spec-valid?)\n;; type-spec-valid?\n;;   : (-> TypeSpec ValidationResult)\n;;   | type ValidationResult = Boolean\n;;   | doc m%\n;;       `type-spec-valid? type` returns whether a parsed TypeSpec is valid.\n;;     %\n(def (type-spec-valid? type)\n  (if type #t #f))\n")
    (write-text
     (string-append policy "/repair-calibration.ss")
     ";;; -*- Gerbil -*-\n(package: self-apply/probe/policy)\n(export agent-repair-calibration-report)\n(def (agent-repair-calibration-report report index findings)\n  (let loop ((rest findings) (out '()))\n    (if (null? rest)\n      (reverse out)\n      (loop (cdr rest) (cons (car rest) out)))))\n")))

;; : (-> ProjectIndex )
(def (self-apply-index)
  (or +self-apply-index-cache+
      (begin
        (reset-fixture-root +self-apply-agent-repair-probe-root+)
        (asp-gerbil-scheme-load-source-coverage ".")
        (let (index (collect-source-scope
                     "."
                     (asp-gerbil-scheme-source-coverage-files ".")))
        (set! +self-apply-index-cache+ index)
          index))))
;; : (-> (List PolicyFinding) )
(def (self-apply-findings)
  (or +self-apply-findings-cache+
      (let (findings (run-policy-checks (self-apply-index)))
        (set! +self-apply-findings-cache+ findings)
        findings)))
;; : (-> (List PolicyFinding) SelfApplyDebtViolations )
(def (self-apply-debt-violations findings)
  (let (counts (finding-rule-counts findings))
    (append (unexpected-self-apply-rule-violations counts)
            (over-budget-self-apply-rule-violations counts))))
;; : (-> (List PolicyFinding) Integer )
(def (finding-rule-counts findings)
  (foldl (lambda (finding counts)
           (increment-rule-count counts (type-finding-rule-id finding)))
         '()
         findings))
;; : (-> Counts RuleId Integer )
(def (increment-rule-count counts rule-id)
  (cond
   ((null? counts) (list (list rule-id 1)))
   ((equal? rule-id (rule-count-rule (car counts)))
    (cons (list rule-id (+ 1 (rule-count-count (car counts))))
          (cdr counts)))
   (else
    (cons (car counts)
          (increment-rule-count (cdr counts) rule-id)))))
;; : (-> Entry Integer )
(def (rule-count-rule entry)
  (car entry))
;; : (-> Entry Integer )
(def (rule-count-count entry)
  (cadr entry))
;; : (-> Counts UnexpectedSelfApplyRuleViolations )
(def (unexpected-self-apply-rule-violations counts)
  (filter-map
   (lambda (entry)
     (let (rule-id (rule-count-rule entry))
       (and (not (self-apply-budget-limit rule-id))
            (list 'unexpectedRule rule-id (rule-count-count entry)))))
   counts))
;; : (-> Counts OverBudgetSelfApplyRuleViolations )
(def (over-budget-self-apply-rule-violations counts)
  (filter-map
   (lambda (entry)
     (let* ((rule-id (rule-count-rule entry))
            (count (rule-count-count entry))
            (limit (self-apply-budget-limit rule-id)))
       (and limit
            (> count limit)
            (list 'overBudget rule-id count limit))))
   counts))
;; : (-> RuleId Integer )
(def (self-apply-budget-limit rule-id)
  (self-apply-budget-limit* rule-id +self-apply-finding-budgets+))
;; : (-> RuleId Budgets Integer )
(def (self-apply-budget-limit* rule-id budgets)
  (cond
   ((null? budgets) #f)
   ((equal? rule-id (car (car budgets))) (cadr (car budgets)))
   (else (self-apply-budget-limit* rule-id (cdr budgets)))))
;; : (-> (List PolicyFinding) Boolean )
(def (self-apply-debt-clear? findings)
  (let (violations (self-apply-debt-violations findings))
    (check violations => '())
    (null? violations)))

;;; Source-repair receipt:
;;; - before report is generated by the real policy report path.
;;; - after evidence is the current source tree, not the probe fixture.
;; : (-> Json)
(def (self-apply-agent-repair-source-receipt)
  (let* ((current-index (self-apply-index))
         (current-findings (self-apply-findings))
         (_ (write-self-apply-agent-repair-probe!
             +self-apply-agent-repair-probe-root+))
         (before-report
          (project-policy-report +self-apply-agent-repair-probe-root+))
         (calibration
          (agent-repair-calibration-report
           before-report
           current-index
           current-findings)))
    (reset-fixture-root +self-apply-agent-repair-probe-root+)
    (hash (beforeAgentRepairStatus
           (hash-get (hash-get before-report 'agentRepair) 'status))
          (beforeRepairableFindings
           (hash-get (hash-get before-report 'agentRepair) 'repairableFindings))
          (currentFindingCount (length current-findings))
          (calibrationStatus (hash-get calibration 'status))
          (calibrationFailureCount (hash-get calibration 'failureCount))
          (calibrationAssertionCount (hash-get calibration 'assertionCount))
          (calibrationAssertions (hash-get calibration 'assertions)))))

;; : (-> (List Json) OwnerPath Boolean)
(def (self-apply-source-repair-target-covered? assertions owner-path)
  (not
   (not
    (find (lambda (assertion)
            (and (equal? (hash-get assertion 'status) "pass")
                 (equal? (hash-get assertion 'ownerPath) owner-path)))
          assertions))))

;; SelfApplyFullTest
(def self-apply-full-test
  (test-suite "gerbil scheme harness full self apply"
    (test-case "current harness findings match snapshot and debt budgets"
      (let* ((findings (self-apply-findings))
             (debt-clear? (self-apply-debt-clear? findings)))
        (when debt-clear?
          (let ((snapshot (self-apply-findings-snapshot findings))
                (expected (snapshot-load "t/snapshots/self-apply-findings.ss")))
            (check snapshot => expected)))))
    (test-case "current harness check report matches snapshot"
      (let* ((index (self-apply-index))
             (findings (self-apply-findings))
             (debt-clear? (null? (self-apply-debt-violations findings))))
        (when debt-clear?
          (let ((snapshot (check-report-snapshot index findings))
                (expected (snapshot-load "t/snapshots/self-apply-check-report.ss")))
            (check snapshot => expected)))))
    (test-case "agent repair report calibrates current source repairs"
      (let* ((receipt (self-apply-agent-repair-source-receipt))
             (assertions (hash-get receipt 'calibrationAssertions)))
        (check (hash-get receipt 'beforeAgentRepairStatus) => "active")
        (check (> (hash-get receipt 'beforeRepairableFindings) 0) => #t)
        (check (hash-get receipt 'currentFindingCount) => 0)
        (check (hash-get receipt 'calibrationStatus) => "pass")
        (check (hash-get receipt 'calibrationFailureCount) => 0)
        (check (> (hash-get receipt 'calibrationAssertionCount) 4) => #t)
        (check (self-apply-source-repair-target-covered?
                assertions
                "src/policy/repair-calibration.ss")
               => #t)
        (check (self-apply-source-repair-target-covered?
                assertions
                "src/types/validation.ss")
               => #t)))))
