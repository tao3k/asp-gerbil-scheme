;;; -*- Gerbil -*-
;;; Policy POO snapshot projections.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios)
(import :unit/snapshot/policy-support)
(export downstream-poo-agent-policy-snapshot
        poo-prototype-fixed-point-policy-snapshot
        poo-guidance-corpus-policy-snapshot)

(def (downstream-poo-agent-policy-snapshot)
  (write-downstream-poo-agent-project ".run/snapshot-policy-downstream-poo-agent")
  (let* ((index (collect-project ".run/snapshot-policy-downstream-poo-agent"))
         (findings (run-agent-policy index)))
    (list 'policyScenario
          (list 'id "downstream-poo-agent")
          (list 'findings (map finding-snapshot findings)))))

(def (poo-prototype-fixed-point-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "poo-prototype-fixed-point"
           "t/scenarios/policy/poo-prototype-fixed-point"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-026"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-026")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot-copy before-finding))
                (list 'guidance
                      (list
                       (list 'mode (hash-get before-details 'guidanceMode))
                       (list 'trigger (hash-get before-details 'trigger))
                       (list 'allowedUse (hash-get before-details 'allowedUse))
                       (list 'repairShape (hash-get before-details 'repairShape))
                       (list 'docsPath (hash-get before-details 'docsPath))
                       (list 'preferredSyntax
                             (hash-get before-details 'preferredSyntax)))))
          (list 'after
                (list 'r026Findings
                      (map finding-snapshot-copy after-findings))))))

(def (poo-guidance-corpus-policy-snapshot)
  (list 'policyScenarioCorpus
        (list 'id "poo-guidance-corpus")
        (list 'mode "soft-guidance")
        (list 'contract
              "scenario corpus records POO parser facts and target findings without adding hard policy rules")
        (list 'scenarios
              (map (lambda (entry)
                     (poo-guidance-scenario-policy-snapshot
                      (car entry)
                      (cdr entry)))
                   +poo-guidance-corpus-scenarios+))))
