;;; -*- Gerbil -*-
;;; Policy build and adapter snapshot projections.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios)
(import :unit/snapshot/policy-support)
(export macro-controlled-helper-policy-snapshot
        predicate-family-combinator-policy-snapshot
        build-runtime-shell-template-policy-snapshot
        package-build-shell-pipeline-policy-snapshot
        package-build-canonical-shape-policy-snapshot
        package-build-std-build-script-policy-snapshot
        package-build-std-make-ssi-policy-snapshot
        dependency-manual-object-adapter-policy-snapshot
        dependency-protocol-adapter-policy-snapshot)

(def (macro-controlled-helper-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "macro-controlled-helper"
           "t/scenarios/policy/macro-controlled-helper"))
         (result (policy-scenario-run scenario)))
    (let* ((after-findings
            (policy-scenario-findings
             result
             'after
             "GERBIL-SCHEME-AGENT-POLICY-011"))
           (before-finding
            (policy-scenario-required-finding
             result
             'before
             "GERBIL-SCHEME-AGENT-POLICY-011"))
           (before-details (type-finding-details before-finding))
           (after-macro
            (policy-scenario-required-first-macro-fact result 'after)))
      (list 'policyScenario
            (list 'id (policy-scenario-result-id result))
            (list 'before
                  (list 'finding (finding-snapshot before-finding))
                  (list 'guidance
                        (macro-controlled-helper-guidance-snapshot
                         before-details)))
            (list 'after
                  (list 'r011Findings
                        (map finding-snapshot after-findings))
                  (list 'macroFact
                        (macro-fact-snapshot after-macro)))))))

(def (predicate-family-combinator-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "predicate-family-combinator"
           "t/scenarios/policy/predicate-family-combinator"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-016"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-016")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'profile
                      (predicate-combinator-profile-snapshot
                       before-details)))
          (list 'after
                (list 'r016Findings
                      (map finding-snapshot after-findings))))))

(def (build-runtime-shell-template-policy-snapshot)
  (build-runtime-quality-policy-snapshot
   "build-runtime-shell-template"
   "t/scenarios/policy/build-runtime-shell-template"))

(def (package-build-shell-pipeline-policy-snapshot)
  (build-runtime-quality-policy-snapshot
   "package-build-shell-pipeline"
   "t/scenarios/policy/package-build-shell-pipeline"))

(def (package-build-canonical-shape-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "package-build-canonical-shape"
           "t/scenarios/policy/package-build-canonical-shape"))
         (result (policy-scenario-run scenario))
         (before-finding
          (policy-scenario-required-finding
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-025"))
         (before-details (type-finding-details before-finding))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-025")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'finding (finding-snapshot before-finding))
                (list 'buildShape
                      (package-build-canonical-shape-snapshot
                       before-details)))
          (list 'after
                (list 'r025Findings
                      (map finding-snapshot after-findings))))))

(def (package-build-std-build-script-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "package-build-std-build-script"
           "t/scenarios/policy/package-build-std-build-script"))
         (result (policy-scenario-run scenario))
         (before-findings
          (policy-scenario-findings
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-025"))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-025")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'r025Findings
                      (map finding-snapshot before-findings)))
          (list 'after
                (list 'r025Findings
                      (map finding-snapshot after-findings))))))

(def (package-build-std-make-ssi-policy-snapshot)
  (let* ((scenario
          (make-policy-scenario
           "package-build-std-make-ssi"
           "t/scenarios/policy/package-build-std-make-ssi"))
         (result (policy-scenario-run scenario))
         (before-findings
          (policy-scenario-findings
           result
           'before
           "GERBIL-SCHEME-AGENT-POLICY-025"))
         (after-findings
          (policy-scenario-findings
           result
           'after
           "GERBIL-SCHEME-AGENT-POLICY-025")))
    (list 'policyScenario
          (list 'id (policy-scenario-result-id result))
          (list 'before
                (list 'r025Findings
                      (map finding-snapshot before-findings)))
          (list 'after
                (list 'r025Findings
                      (map finding-snapshot after-findings))))))

(def (dependency-manual-object-adapter-policy-snapshot)
  (dependency-adapter-policy-snapshot
   "dependency-manual-object-adapter"
   "t/scenarios/policy/dependency-manual-object-adapter"))

(def (dependency-protocol-adapter-policy-snapshot)
  (dependency-adapter-policy-snapshot
   "dependency-protocol-adapter"
   "t/scenarios/policy/dependency-protocol-adapter"))
