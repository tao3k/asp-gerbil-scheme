;;; -*- Gerbil -*-
;;; Policy comment and dependency snapshot projections.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios)
(import :unit/snapshot/policy-support)
(export comment-quality-policy-snapshot
        harness-dependency-policy-application-policy-snapshot
        harness-dependency-policy-disable-requires-explanation-policy-snapshot)

(def (comment-quality-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "comment-quality"
           "t/scenarios/policy/comment-quality"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-015"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-015")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot-copy before-finding))
                (list 'comment
                      (comment-quality-guidance-snapshot before-details)))
          (list 'after
                (list 'r015Findings
                      (map finding-snapshot-copy after-findings))))))

(def (harness-dependency-policy-application-policy-snapshot)
  (let* ((scenario
         (make-policy-scenario
           "harness-dependency-policy-application"
           "t/scenarios/policy/harness-dependency-policy-application"))
         (result (policy-scenario-run/checks scenario))
         (before-package
          (project-index-package (policy-scenario-index result 'before)))
         (after-package
          (project-index-package (policy-scenario-index result 'after)))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-013"))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-013")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'package
                      (package-agent-policy-snapshot before-package))
                (list 'finding
                      (finding-snapshot-copy before-finding)))
          (list 'after
                (list 'package
                      (package-agent-policy-snapshot after-package))
                (list 'r013Findings
                      (map finding-snapshot-copy after-findings))))))

(def (harness-dependency-policy-disable-requires-explanation-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "harness-dependency-policy-disable-requires-explanation"
           "t/scenarios/policy/harness-dependency-policy-disable-requires-explanation"))
         (result (policy-scenario-run/checks scenario))
         (before-package
          (project-index-package (policy-scenario-index result 'before)))
         (after-package
          (project-index-package (policy-scenario-index result 'after)))
         (before-policy-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-024"))
         (before-style-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-013"))
         (after-policy-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-024"))
         (after-style-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-013")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'package
                      (package-agent-policy-snapshot before-package))
                (list 'policyFinding
                      (finding-snapshot-copy before-policy-finding))
                (list 'styleFinding
                      (finding-snapshot-copy before-style-finding)))
          (list 'after
                (list 'package
                      (package-agent-policy-snapshot after-package))
                (list 'r024Findings
                      (map finding-snapshot-copy after-policy-findings))
                (list 'r013Findings
                      (map finding-snapshot-copy after-style-findings))))))
