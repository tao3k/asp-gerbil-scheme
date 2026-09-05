;;; -*- Gerbil -*-
;;; Policy scenario runner shared by tests and future agent-facing fixtures.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/scenario/benchmark-contract
        (only-in :std/srfi/1 find iota)
        (only-in :std/sugar foldl hash)
        :asp-gerbil-scheme/src/support/time
        :asp-gerbil-scheme/src/types/facade)

(export make-policy-scenario
        policy-scenario-id
        policy-scenario-root
        policy-scenario-input-root
        policy-scenario-expected-root
        policy-scenario-benchmark-contract
        policy-scenario-benchmark-max-total
        policy-scenario-run
        policy-scenario-run/timed
        policy-scenario-run/checks
        policy-scenario-result-id
        policy-scenario-index
        policy-scenario-findings
        policy-scenario-required-finding
        policy-scenario-required-first-macro-fact
        policy-finding-rule?)

;;; Directory-backed policy scenarios follow the Codex-style fixture protocol:
;;; each scenario is a folder with an `input/` project tree and an `expected/`
;;; project tree. src owns execution and fact lookup; t owns only fixture data.
;; RelativePath
(def +policy-scenario-input-dir+ "input")
;; RelativePath
(def +policy-scenario-expected-dir+ "expected")
;; RelativePath
(def +policy-scenario-benchmark-file+ "benchmark.ss")

;; : (-> Id ScenarioRoot PolicyScenario )
(def (make-policy-scenario id root)
  (list id root))

;; : (-> PolicyScenario String )
(def (policy-scenario-id scenario)
  (list-ref scenario 0))

;; : (-> PolicyScenario String )
(def (policy-scenario-root scenario)
  (list-ref scenario 1))

;; : (-> PolicyScenario String )
(def (policy-scenario-input-root scenario)
  (string-append (policy-scenario-root scenario)
                 "/"
                 +policy-scenario-input-dir+))

;; : (-> PolicyScenario String )
(def (policy-scenario-expected-root scenario)
  (string-append (policy-scenario-root scenario)
                 "/"
                 +policy-scenario-expected-dir+))

;; : (-> PolicyScenario Relpath )
(def (policy-scenario-benchmark-path scenario)
  (string-append (policy-scenario-root scenario)
                 "/"
                 +policy-scenario-benchmark-file+))

;;; Fixture benchmark contract:
;;; - A scenario must carry benchmark.ss beside input/ and expected/.
;;; - The file is data, not code: an alist such as ((max_total . 1s)).
;;; - Feature metadata stays fixture-owned so later optimization passes can
;;;   group receipts by policy rule, input shape, and repair family.
;; : (-> PolicyScenario BenchmarkContract )
(def (policy-scenario-benchmark-contract scenario)
  (scenario-benchmark-contract/path
   (policy-scenario-id scenario)
   (policy-scenario-benchmark-path scenario)))

;;; Performance gate boundary:
;;; - #f means the scenario records timing without enforcing a ceiling.
;;; - benchmark.ss remains the owner for configured time budgets.
;; : (-> BenchmarkContract (U Integer False) )
(def (policy-scenario-benchmark-max-total contract)
  (scenario-benchmark-max-total contract))

;;; Runner:
;;; - input/ is the failing project shape.
;;; - expected/ is the repaired project shape.
;;; - Callers can snapshot either findings or parser facts without duplicating
;;;   collect/run/filter boilerplate.
;; : (-> PolicyScenario PolicyScenarioResult )
(def (policy-scenario-run scenario)
  (let* ((before-index (collect-project (policy-scenario-input-root scenario)))
         (after-index (collect-project (policy-scenario-expected-root scenario))))
    (list (policy-scenario-id scenario)
          before-index
          after-index
          (run-agent-policy before-index)
          (run-agent-policy after-index))))

;;; Timed runner:
;;; - Tests use this when policy guidance is explicitly performance-motivated.
;;; - The result keeps the normal policy-scenario-run shape and adds a compact
;;;   timing receipt so regressions fail with measured phase evidence.
;; : (-> PolicyScenario TimedPolicyScenarioResult )
(def (policy-scenario-run/timed scenario)
  (let* ((benchmark-contract
          (policy-scenario-benchmark-contract scenario))
         (iterations
          (policy-scenario-benchmark-iterations benchmark-contract)))
    (let (state
          (foldl (cut policy-scenario-timed-sample-step
                      scenario
                      benchmark-contract
                      iterations
                      <> <>)
                 (list #f [])
                 (iota iterations)))
      (policy-scenario-timing-with-samples! (car state) (reverse (cadr state))))))

(def (policy-scenario-timed-sample-step scenario benchmark-contract sample-count sample-index state)
  (let (sample
        (policy-scenario-run/timed/once
         scenario
         benchmark-contract
         sample-index
         sample-count))
    (list (policy-scenario-best-timing (car state) sample)
          (cons sample (cadr state)))))

;;; Timing sample boundary:
;;; - Keep collect/policy before-and-after phases in one measured sample.
;;; - The multi-sample caller can choose the best receipt without losing phase
;;;   evidence for parser, policy, or expected-tree regressions.
(def (policy-scenario-run/timed/once scenario benchmark-contract sample-index sample-count)
  (let* ((before-index-step
          (policy-scenario-timed-step
           "collect-before"
           (lambda ()
             (collect-project (policy-scenario-input-root scenario)))))
         (before-index (car before-index-step))
         (before-index-timing (cdr before-index-step))
         (after-index-step
          (policy-scenario-timed-step
           "collect-after"
           (lambda ()
             (collect-project (policy-scenario-expected-root scenario)))))
         (after-index (car after-index-step))
         (after-index-timing (cdr after-index-step))
         (before-policy-step
          (policy-scenario-timed-step
           "policy-before"
           (lambda ()
             (run-agent-policy before-index))))
         (before-findings (car before-policy-step))
         (before-policy-timing (cdr before-policy-step))
         (after-policy-step
          (policy-scenario-timed-step
           "policy-after"
           (lambda ()
             (run-agent-policy after-index))))
         (after-findings (car after-policy-step))
         (after-policy-timing (cdr after-policy-step))
         (timings [before-index-timing
                   after-index-timing
                   before-policy-timing
                   after-policy-timing])
         (total-ns (policy-scenario-timings-total-ns timings))
         (total-ms (duration-nanos->ms total-ns))
         (input-total-ns
          (+ (hash-get before-index-timing 'durationNs)
             (hash-get before-policy-timing 'durationNs)))
         (expected-total-ns
          (+ (hash-get after-index-timing 'durationNs)
             (hash-get after-policy-timing 'durationNs)))
         (input-expected-comparison
          (policy-scenario-input-expected-comparison
           input-total-ns
           expected-total-ns
           (hash-get benchmark-contract 'expected_over_input_budget)
           (hash-get benchmark-contract 'expected_over_input_note)
           (hash-get benchmark-contract 'targetRationale)))
         (max-total
          (policy-scenario-benchmark-max-total benchmark-contract))
         (result
          (list (policy-scenario-id scenario)
                before-index
                after-index
                before-findings
                after-findings)))
    (hash (schemaId "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
          (schemaVersion "2")
          (scenarioId (policy-scenario-id scenario))
          (totalMs total-ms)
          (totalNs total-ns)
          (total (duration-nanos->text total-ns))
          (inputTotalMs (duration-nanos->ms input-total-ns))
          (inputTotalNs input-total-ns)
          (inputTotal (duration-nanos->text input-total-ns))
          (expectedTotalMs (duration-nanos->ms expected-total-ns))
          (expectedTotalNs expected-total-ns)
          (expectedTotal (duration-nanos->text expected-total-ns))
          (expectedOverInputNs (- expected-total-ns input-total-ns))
          (expectedOverInput
           (duration-nanos->text (- expected-total-ns input-total-ns)))
          (expected_over_input_budget
           (hash-get benchmark-contract 'expected_over_input_budget))
          (expected_over_input_note
           (hash-get benchmark-contract 'expected_over_input_note))
          (inputExpectedStatus
           (hash-get input-expected-comparison 'status))
          (inputExpectedComparison input-expected-comparison)
          (timings timings)
          (benchmarkContract benchmark-contract)
          (benchmarkFeature (hash-get benchmark-contract 'feature))
          (benchmarkRule (hash-get benchmark-contract 'rule))
          (optimizationFocus (hash-get benchmark-contract 'optimizationFocus))
          (hotPathExemption (hash-get benchmark-contract 'hotPathExemption))
          (hotPathEvidence (hash-get benchmark-contract 'hotPathEvidence))
          (styleRewriteBoundary (hash-get benchmark-contract 'styleRewriteBoundary))
          (max_total max-total)
          (observed_total (hash-get benchmark-contract 'observed_total))
          (target_total (hash-get benchmark-contract 'target_total))
          (regression_budget (hash-get benchmark-contract 'regression_budget))
          (observedTimings (hash-get benchmark-contract 'observedTimings))
          (targetRationale (hash-get benchmark-contract 'targetRationale))
          (sampleIndex sample-index)
          (sampleCount sample-count)
          (targetStatus
           (policy-scenario-performance-status
            total-ns
            (hash-get benchmark-contract 'target_total)))
          (performanceStatus
           (policy-scenario-performance-status total-ns max-total))
          (result result))))

(def (policy-scenario-benchmark-iterations benchmark-contract)
  (let (iterations (hash-get benchmark-contract 'iterations))
    (if (and (integer? iterations) (> iterations 0))
      iterations
      1)))

(def (policy-scenario-best-timing best sample)
  (if (or (not best)
          (< (hash-get sample 'totalNs)
             (hash-get best 'totalNs)))
    sample
    best))

(def (policy-scenario-timing-sample-summary timing)
  (hash (sampleIndex (hash-get timing 'sampleIndex))
        (totalNs (hash-get timing 'totalNs))
        (totalMs (hash-get timing 'totalMs))
        (performanceStatus (hash-get timing 'performanceStatus))
        (inputTotalNs (hash-get timing 'inputTotalNs))
        (expectedTotalNs (hash-get timing 'expectedTotalNs))
        (timings (hash-get timing 'timings))))

(def (policy-scenario-timing-with-samples! best samples)
  (hash-put! best 'samples
             (map policy-scenario-timing-sample-summary samples))
  best)

;;; Input/expected comparison boundary:
;;; - input side measures the failing/original project shape.
;;; - expected side measures the repaired project shape.
;;; - The repaired side may be slower only inside the scenario-owned budget.
;; : (-> (U String False) (U String False) (U Pair False))
(def (policy-scenario-input-expected-annotation expected-over-input-note
                                                target-rationale)
  (cond
   ((and (string? expected-over-input-note)
         (> (string-length expected-over-input-note) 0))
    (cons 'expected_over_input_note expected-over-input-note))
   ((and (string? target-rationale)
         (> (string-length target-rationale) 0))
    (cons 'targetRationale target-rationale))
   (else #f)))

;; : (-> Nanoseconds Nanoseconds DurationLiteral (U String False) (U String False) HashTable )
(def (policy-scenario-input-expected-comparison input-total-ns
                                                expected-total-ns
                                                expected-over-input-budget
                                                expected-over-input-note
                                                target-rationale)
  (let ((delta-ns (- expected-total-ns input-total-ns))
        (budget-ns
         (duration-literal->nanos expected-over-input-budget))
        (annotation
         (policy-scenario-input-expected-annotation
          expected-over-input-note
          target-rationale)))
    (if budget-ns
      (hash (schemaId
             "agent.semantic-protocols.gerbil-scheme-input-expected-performance")
            (schemaVersion "1")
            (relation
             (if (< expected-total-ns input-total-ns)
               "expected-faster"
               "expected-not-faster"))
            (inputTotalMs (duration-nanos->ms input-total-ns))
            (inputTotalNs input-total-ns)
            (inputTotal (duration-nanos->text input-total-ns))
            (expectedTotalMs (duration-nanos->ms expected-total-ns))
            (expectedTotalNs expected-total-ns)
            (expectedTotal (duration-nanos->text expected-total-ns))
            (expectedOverInputNs delta-ns)
            (expectedOverInput (duration-nanos->text delta-ns))
            (expected_over_input_budget expected-over-input-budget)
            (annotationSource (and annotation (car annotation)))
            (annotation (and annotation (cdr annotation)))
            (status
             (cond
              ((> expected-total-ns (+ input-total-ns budget-ns))
               (string-append
                "fail expectedNs="
                (number->string expected-total-ns)
                " inputNs="
                (number->string input-total-ns)
                " budgetNs="
                (number->string budget-ns)))
              ((< expected-total-ns input-total-ns) "pass")
              (annotation "pass annotated")
              (else
               (string-append
                "fail expected-not-faster annotation=missing"
                " expectedNs="
                (number->string expected-total-ns)
                " inputNs="
                (number->string input-total-ns))))))
      (error "policy scenario benchmark invalid duration literal"
             'expected_over_input_budget
             expected-over-input-budget))))

;;; Status boundary:
;;; - Unbounded scenarios still return timing receipts.
;;; - Bounded scenarios pass when measured time does not exceed the configured
;;;   value, and fail with both measured and configured values otherwise.
;; : (-> Nanoseconds (U DurationLiteral False) String )
(def (policy-scenario-performance-status total-ns max-total)
  (cond
   ((not max-total) "unbounded")
   ((duration-literal->nanos max-total)
    => (lambda (max-total-ns)
         (if (<= total-ns max-total-ns)
           "pass"
           (string-append
           "fail durationNs="
           (number->string total-ns)
            " maxNs="
            (number->string max-total-ns)))))
   (else
    (error "policy scenario benchmark invalid duration literal"
           'max_total
           max-total))))

;;; Step timing boundary:
;;; - Each phase returns its value and a compact duration receipt.
;;; - Callers decide phase order; this helper only measures one thunk.
;; : (-> String Thunk Pair )
(def (policy-scenario-timed-step name thunk)
  (let (start (monotonic-micros))
    (let (value (thunk))
      (let* ((duration-micros
              (duration-micros start (monotonic-micros)))
             (duration-ns (micros->nanos duration-micros)))
      (cons value
            (hash (name name)
                  (durationMs (duration-nanos->ms duration-ns))
                  (durationMicros duration-micros)
                  (durationNs duration-ns)))))))

;;; Total timing boundary:
;;; - Sum phase receipts without re-running scenario work.
;;; - Empty timing lists stay valid for degenerate fixtures.
;; : (-> (List Timing) Integer )
(def (policy-scenario-timings-total-ns timings)
  (foldl (lambda (timing total)
           (+ total (hash-get timing 'durationNs)))
         0
         timings))

;;; Full policy runner:
;;; - Use this when a scenario validates user-facing package policy controls.
;;; - run-policy-checks applies gerbil.pkg rule filters; run-agent-policy does not.
;; : (-> PolicyScenario PolicyScenarioResult )
(def (policy-scenario-run/checks scenario)
  (let* ((before-index (collect-project (policy-scenario-input-root scenario)))
         (after-index (collect-project (policy-scenario-expected-root scenario))))
    (list (policy-scenario-id scenario)
          before-index
          after-index
          (run-policy-checks before-index)
          (run-policy-checks after-index))))

;;; Result tuple boundary:
;;; - Scenario result slots stay positional for lightweight fixtures.
;;; - Accessors keep tests from depending on raw list indexes.
;; : (-> PolicyScenarioResult String )
(def (policy-scenario-result-id result)
  (list-ref result 0))

;;; Phase index boundary:
;;; - Only before/after are valid parser fact phases.
;;; - Unknown phases fail early instead of returning a misleading index.
;; : (-> PolicyScenarioResult Phase ProjectIndex )
(def (policy-scenario-index result phase)
  (case phase
    ((before) (list-ref result 1))
    ((after) (list-ref result 2))
    (else (error "unknown policy scenario phase" phase))))

;;; Finding query boundary:
;;; - Scenario phases are explicit so tests cannot mix before/after policy state.
;;; - Rule filtering stays here instead of duplicated across snapshot tests.
;; : (-> PolicyScenarioResult ScenarioPhase RuleId (List TypeFinding) )
(def (policy-scenario-findings result phase rule-id)
  (filter (lambda (finding)
            (policy-finding-rule? finding rule-id))
          (case phase
            ((before) (list-ref result 3))
            ((after) (list-ref result 4))
            (else (error "unknown policy scenario phase" phase)))))

;;; Required finding boundary:
;;; - Missing evidence is a scenario failure, not an empty test assertion.
;;; - The returned finding remains the real policy object for detail checks.
;; : (-> PolicyScenarioResult ScenarioPhase RuleId TypeFinding )
(def (policy-scenario-required-finding result phase rule-id)
  (or (find (lambda (finding)
              (policy-finding-rule? finding rule-id))
            (policy-scenario-findings result phase rule-id))
      (error "missing policy scenario finding" phase rule-id)))

;;; Rule predicate boundary:
;;; - Keep rule-id matching in one helper so scenario queries stay uniform.
;;; - The predicate compares public finding rule ids only.
;; : (-> TypeFinding RuleId Boolean )
(def (policy-finding-rule? finding rule-id)
  (equal? (type-finding-rule-id finding) rule-id))

;;; Macro witness boundary:
;;; - Macro facts are collected from the selected project phase.
;;; - The helper fails loudly when a scenario stops exercising macro evidence.
;; : (-> PolicyScenarioResult ScenarioPhase MacroFact )
(def (policy-scenario-required-first-macro-fact result phase)
  (let (macros
        (apply append
               (map source-file-macros
                    (project-index-files
                     (policy-scenario-index result phase)))))
    (if (pair? macros)
      (car macros)
      (error "missing policy scenario macro fact" phase))))
