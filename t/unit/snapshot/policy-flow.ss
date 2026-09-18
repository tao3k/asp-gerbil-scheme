;;; -*- Gerbil -*-
;;; Policy flow snapshot projections.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios)
(import :unit/snapshot/policy-support)
(export functional-idiom-policy-snapshot
        real-agent-basic-syntax-policy-snapshot
        controlled-branch-shape-policy-snapshot
        controlled-branch-conditional-dispatch-policy-snapshot)

(def (functional-idiom-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "functional-idiom"
           "t/scenarios/policy/functional-idiom"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-009"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-009")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'guidance
                      (functional-idiom-guidance-snapshot
                       before-details)))
          (list 'after
                (list 'r009Findings
                      (map finding-snapshot after-findings))))))

(def (real-agent-basic-syntax-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "real-agent-basic-syntax"
           "t/scenarios/policy/real-agent-basic-syntax"))
         (result (policy-scenario-run scenario))
         (before-r009
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-009"))
         (before-r014
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-014"))
         (before-r028
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-028"))
         (r009-details (type-finding-details before-r009))
         (r014-details (type-finding-details before-r014)))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'findings
                      (list (finding-snapshot-copy before-r009)
                            (finding-snapshot-copy before-r014)
                            (finding-snapshot-copy before-r028)))
                (list 'functional
                      (functional-idiom-guidance-snapshot r009-details))
                (list 'branch
                      (controlled-branch-shape-guidance-snapshot
                       r014-details)))
          (list 'after
                (list 'r009Findings
                      (map finding-snapshot-copy
                           (policy-scenario-findings
                            result
                            'after
                            "GERBIL-SCHEME-AGENT-POLICY-009")))
                (list 'r014Findings
                      (map finding-snapshot-copy
                           (policy-scenario-findings
                            result
                            'after
                            "GERBIL-SCHEME-AGENT-POLICY-014")))
                (list 'r028Findings
                      (map finding-snapshot-copy
                           (policy-scenario-findings
                            result
                            'after
                            "GERBIL-SCHEME-AGENT-POLICY-028")))))))

(def (controlled-branch-shape-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "controlled-branch-shape"
           "t/scenarios/policy/controlled-branch-shape"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-014"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-014")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'shape
                      (controlled-branch-shape-guidance-snapshot
                       before-details)))
          (list 'after
                (list 'r014Findings
                      (map finding-snapshot after-findings))))))

(def (controlled-branch-conditional-dispatch-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "controlled-branch-conditional-dispatch"
           "t/scenarios/policy/controlled-branch-conditional-dispatch"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-014"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-014")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'shape
                      (controlled-branch-shape-guidance-snapshot
                       before-details)))
          (list 'after
                (list 'r014Findings
                      (map finding-snapshot after-findings))))))
