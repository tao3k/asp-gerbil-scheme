;;; -*- Gerbil -*-
;;; Lightweight support for agent POO guidance policy tests.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/facade
        (only-in :asp-gerbil-scheme/src/policy/agent-poo
                 poo-direct-writeenv-findings
                 poo-io-runtime-witness-findings
                 poo-object-model-findings
                 poo-method-shape-findings
                 poo-prototype-fixed-point-findings
                 poo-construction-performance-findings
                 poo-clone-override-loop-performance-findings
                 poo-materialization-loop-performance-findings
                 poo-composition-loop-performance-findings
                 poo-validation-loop-performance-findings
                 poo-lens-loop-performance-findings
                 poo-object-construction-loop-performance-findings
                 poo-type-construction-loop-performance-findings
                 poo-debug-instrumentation-loop-performance-findings
                 poo-slot-spec-mutation-loop-performance-findings
                 poo-slot-predicate-loop-performance-findings
                 poo-documentation-usage-findings)
        :asp-gerbil-scheme/src/types/facade)

(export #t)

(def +poo-real-dashboard-workflow-rule-ids+
  '("GERBIL-SCHEME-AGENT-POLICY-028"
    "GERBIL-SCHEME-AGENT-POLICY-029"
    "GERBIL-SCHEME-AGENT-POLICY-030"
    "GERBIL-SCHEME-AGENT-POLICY-031"
    "GERBIL-SCHEME-AGENT-POLICY-033"
    "GERBIL-SCHEME-AGENT-POLICY-035"
    "GERBIL-SCHEME-AGENT-POLICY-037"))

(def +policy-scenario-input-dir+ "input")
(def +policy-scenario-expected-dir+ "expected")

;; : (-> String String PolicyScenario)
(def (make-policy-scenario id root)
  (list id root))

;; : (-> PolicyScenario String)
(def (policy-scenario-id scenario)
  (list-ref scenario 0))

;; : (-> PolicyScenario String)
(def (policy-scenario-root scenario)
  (list-ref scenario 1))

;; : (-> PolicyScenario String)
(def (policy-scenario-input-root scenario)
  (string-append (policy-scenario-root scenario)
                 "/"
                 +policy-scenario-input-dir+))

;; : (-> PolicyScenario String)
(def (policy-scenario-expected-root scenario)
  (string-append (policy-scenario-root scenario)
                 "/"
                 +policy-scenario-expected-dir+))

;; : (-> PolicyScenarioResult Symbol String (List TypeFinding))
(def (policy-scenario-findings result phase rule-id)
  (filter (lambda (finding)
            (equal? (type-finding-rule-id finding) rule-id))
          (case phase
            ((before) (list-ref result 3))
            ((after) (list-ref result 4))
            (else (error "unknown policy scenario phase" phase)))))

;; : (-> PolicyScenarioResult Symbol (List String) (List TypeFinding))
(def (policy-scenario-findings/rules result phase rule-ids)
  (apply append
         (map (lambda (rule-id)
                (policy-scenario-findings result phase rule-id))
              rule-ids)))

;; : (-> String (List TypeFinding) Boolean)
(def (policy-rule-present? rule-id findings)
  (if (member rule-id (map type-finding-rule-id findings)) #t #f))

;; : (-> String (List TypeFinding) (List TypeFinding))
(def (filter-rule rule-id findings)
  (filter (lambda (finding)
            (equal? (type-finding-rule-id finding) rule-id))
          findings))

(def (poo-rule-selected? rule-ids owned-rule-ids)
  (cond
   ((null? rule-ids) #f)
   ((member (car rule-ids) owned-rule-ids) #t)
   (else (poo-rule-selected? (cdr rule-ids) owned-rule-ids))))

(def +poo-performance-guidance-rule-ids+
  '("GERBIL-SCHEME-AGENT-POLICY-027"
    "GERBIL-SCHEME-AGENT-POLICY-028"
    "GERBIL-SCHEME-AGENT-POLICY-029"
    "GERBIL-SCHEME-AGENT-POLICY-030"
    "GERBIL-SCHEME-AGENT-POLICY-031"
    "GERBIL-SCHEME-AGENT-POLICY-032"
    "GERBIL-SCHEME-AGENT-POLICY-033"
    "GERBIL-SCHEME-AGENT-POLICY-034"
    "GERBIL-SCHEME-AGENT-POLICY-035"
    "GERBIL-SCHEME-AGENT-POLICY-036"
    "GERBIL-SCHEME-AGENT-POLICY-037"))

(def (run-agent-poo-performance-policy index)
  (append
   (poo-object-model-findings index)
   (poo-construction-performance-findings index)
   (poo-clone-override-loop-performance-findings index)
   (poo-materialization-loop-performance-findings index)
   (poo-composition-loop-performance-findings index)
   (poo-validation-loop-performance-findings index)
   (poo-lens-loop-performance-findings index)
   (poo-object-construction-loop-performance-findings index)
   (poo-type-construction-loop-performance-findings index)
   (poo-debug-instrumentation-loop-performance-findings index)
   (poo-slot-spec-mutation-loop-performance-findings index)
   (poo-slot-predicate-loop-performance-findings index)))

;; : (-> ProjectIndex (List TypeFinding))
(def (run-agent-poo-policy index)
  (append
   (poo-direct-writeenv-findings index)
   (poo-io-runtime-witness-findings index)
   (poo-object-model-findings index)
   (poo-method-shape-findings index)
   (poo-prototype-fixed-point-findings index)
   (poo-construction-performance-findings index)
   (poo-clone-override-loop-performance-findings index)
   (poo-materialization-loop-performance-findings index)
   (poo-composition-loop-performance-findings index)
   (poo-validation-loop-performance-findings index)
   (poo-lens-loop-performance-findings index)
   (poo-object-construction-loop-performance-findings index)
   (poo-type-construction-loop-performance-findings index)
   (poo-debug-instrumentation-loop-performance-findings index)
   (poo-slot-spec-mutation-loop-performance-findings index)
   (poo-slot-predicate-loop-performance-findings index)
   (poo-documentation-usage-findings index)))

;; : (-> ProjectIndex (List String) (List TypeFinding))
(def (run-agent-poo-policy/rules index rule-ids)
  (append
   (if (member "GERBIL-SCHEME-AGENT-POLICY-006" rule-ids)
     (poo-direct-writeenv-findings index)
     [])
   (if (member "GERBIL-SCHEME-AGENT-POLICY-007" rule-ids)
     (poo-io-runtime-witness-findings index)
     [])
   (if (member "GERBIL-SCHEME-AGENT-POLICY-008" rule-ids)
     (poo-method-shape-findings index)
     [])
   (if (poo-rule-selected? rule-ids +poo-performance-guidance-rule-ids+)
     (run-agent-poo-performance-policy index)
     [])
   (if (member "GERBIL-SCHEME-AGENT-POLICY-026" rule-ids)
     (poo-prototype-fixed-point-findings index)
     [])
   (if (member "GERBIL-SCHEME-AGENT-POLICY-038" rule-ids)
     (poo-documentation-usage-findings index)
     [])))

;; : (-> Path (List TypeFinding))
(def (run-agent-poo-policy/root root)
  (run-agent-poo-policy (collect-project root)))

;; : (-> Path (List String) (List TypeFinding))
(def (run-agent-poo-policy/root/rules root rule-ids)
  (run-agent-poo-policy/rules (collect-project root) rule-ids))

;; : (-> PolicyScenario (List String) PolicyScenarioResult)
(def (policy-scenario-run/poo-policy/rules scenario rule-ids)
  (let* ((before-index (collect-project (policy-scenario-input-root scenario)))
         (after-index (collect-project (policy-scenario-expected-root scenario))))
    (list (policy-scenario-id scenario)
          before-index
          after-index
          (run-agent-poo-policy/rules before-index rule-ids)
          (run-agent-poo-policy/rules after-index rule-ids))))

;; : (-> PolicyScenario PolicyScenarioResult)
(def (policy-scenario-run/poo-policy scenario)
  (let* ((before-index (collect-project (policy-scenario-input-root scenario)))
         (after-index (collect-project (policy-scenario-expected-root scenario))))
    (list (policy-scenario-id scenario)
          before-index
          after-index
          (run-agent-poo-policy before-index)
          (run-agent-poo-policy after-index))))
