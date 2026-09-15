;;; -*- Gerbil -*-
;;; Policy scenario runner shared by tests and future agent-facing fixtures.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        (only-in :asp-gerbil-scheme/src/benchmark/statistics
                 benchmark-statistics-ref
                 benchmark-sample-statistics
                 benchmark-select-sample)
        :asp-gerbil-scheme/src/scenario/benchmark-contract
        (only-in :clan/timestamp call-with-timing)
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
         (sample-count
          (policy-scenario-benchmark-sample-count benchmark-contract))
         (samples
          (map (lambda (sample-index)
                 (policy-scenario-run/timed/once
                  scenario
                  benchmark-contract
                  sample-index
                  sample-count))
               (iota sample-count)))
         (admission
          (benchmark-select-sample samples
                                   95
                                   (lambda (sample)
                                     (hash-get sample 'cpuTotalNs)))))
    (policy-scenario-timing-with-samples! admission samples)))

;;; Timing sample boundary:
;;; - Keep collect/policy before-and-after phases in one measured sample.
;;; - Counterbalance input/expected execution order across samples so process
;;;   position and post-GC effects do not belong systematically to one side.
;;; - The multi-sample caller selects nearest-rank p95 without losing phase
;;;   evidence for parser, policy, or expected-tree regressions.
;; : (-> Path String (Tuple ProjectIndex Findings Timing Timing))
(def (policy-scenario-side/timed root suffix)
  (let* ((index-step
          (policy-scenario-timed-step
           (string-append "collect-" suffix)
           (lambda () (collect-project root))))
         (index (car index-step))
         (index-timing (cdr index-step))
         (policy-step
          (policy-scenario-timed-step
           (string-append "policy-" suffix)
           (lambda () (run-agent-policy index)))))
    (list index (car policy-step) index-timing (cdr policy-step))))

;;; Counterbalanced side schedule:
;;; - The schedule is a pure value, separate from timing side effects.
;;; - Each specification retains its semantic role so result projection never
;;;   depends on whether that role ran first or second in the sample.
;; : (-> PolicyScenario Integer (List (Tuple Symbol Path String)))
(def (policy-scenario-side-specifications scenario sample-index)
  (let ((input-spec
         (list 'input (policy-scenario-input-root scenario) "before"))
        (expected-spec
         (list 'expected (policy-scenario-expected-root scenario) "after")))
    (if (even? sample-index)
      (list input-spec expected-spec)
      (list expected-spec input-spec))))

;; : (-> (Tuple Symbol Path String) (Pair Symbol PolicyScenarioSide))
(def (policy-scenario-side-specification/timed specification)
  (match specification
    ([role root suffix]
     (cons role (policy-scenario-side/timed root suffix)))))

;;; Measured-side lookup boundary:
;;; - Role lookup is centralized so the timed runner does not repeat alist
;;;   traversal or couple result meaning to the counterbalanced run order.
;;; - Missing roles invalidate the receipt instead of becoming empty evidence.
;; : (-> (List (Pair Symbol PolicyScenarioSide)) Symbol PolicyScenarioSide)
(def (policy-scenario-measured-side measured-sides role)
  (let (entry (assq role measured-sides))
    (if entry
      (cdr entry)
      (error "policy scenario measured side is missing" role))))

;; : (-> PolicyScenarioSide ProjectIndex)
(def (policy-scenario-side-index side)
  (list-ref side 0))

;; : (-> PolicyScenarioSide Findings)
(def (policy-scenario-side-findings side)
  (list-ref side 1))

;; : (-> PolicyScenarioSide Timing)
(def (policy-scenario-side-index-timing side)
  (list-ref side 2))

;; : (-> PolicyScenarioSide Timing)
(def (policy-scenario-side-policy-timing side)
  (list-ref side 3))

;;; Single-sample admission boundary:
;;; - Collection order is counterbalanced, while before/after semantics are
;;;   restored by role before computing phase totals and the scenario result.
;;; - All timing data comes from this live sample; fixture data owns budgets,
;;;   never static observations.
;; : (-> PolicyScenario BenchmarkContract Integer Integer TimingReceipt)
(def (policy-scenario-run/timed/once scenario benchmark-contract sample-index sample-count)
  (##gc)
  (let* ((side-specifications
          (policy-scenario-side-specifications scenario sample-index))
         (measured-sides
          (map policy-scenario-side-specification/timed side-specifications))
         (before-side (policy-scenario-measured-side measured-sides 'input))
         (after-side (policy-scenario-measured-side measured-sides 'expected))
         (measurement-order (map car measured-sides))
         (before-index (policy-scenario-side-index before-side))
         (after-index (policy-scenario-side-index after-side))
         (before-findings (policy-scenario-side-findings before-side))
         (after-findings (policy-scenario-side-findings after-side))
         (before-index-timing (policy-scenario-side-index-timing before-side))
         (after-index-timing (policy-scenario-side-index-timing after-side))
         (before-policy-timing (policy-scenario-side-policy-timing before-side))
         (after-policy-timing (policy-scenario-side-policy-timing after-side))
         (timings [before-index-timing
                   after-index-timing
                   before-policy-timing
                   after-policy-timing])
         (total-ns (policy-scenario-timings-total-ns timings))
         (cpu-total-ns
          (policy-scenario-timings-total-by timings 'cpuDurationNs))
         (input-total-ns
          (+ (hash-get before-index-timing 'durationNs)
             (hash-get before-policy-timing 'durationNs)))
         (expected-total-ns
          (+ (hash-get after-index-timing 'durationNs)
             (hash-get after-policy-timing 'durationNs)))
         (input-cpu-total-ns
          (+ (hash-get before-index-timing 'cpuDurationNs)
             (hash-get before-policy-timing 'cpuDurationNs)))
         (expected-cpu-total-ns
          (+ (hash-get after-index-timing 'cpuDurationNs)
             (hash-get after-policy-timing 'cpuDurationNs)))
         (input-expected-comparison
          (policy-scenario-input-expected-comparison
           input-cpu-total-ns
           expected-cpu-total-ns
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
          (schemaVersion "5")
          (timingSource ":gerbil/gambit#cpu-time")
          (wallTimingSource ":clan/timestamp#call-with-timing")
          (admissionClock 'process-cpu)
          (gcPrecondition ":gerbil/gambit###gc")
          (measurementOrder measurement-order)
          (scenarioId (policy-scenario-id scenario))
          (totalNs total-ns)
          (total (duration-nanos->text total-ns))
          (cpuTotalNs cpu-total-ns)
          (cpuTotal (duration-nanos->text cpu-total-ns))
          (schedulerDelayNs (max 0 (- total-ns cpu-total-ns)))
          (schedulerDelay
           (duration-nanos->text (max 0 (- total-ns cpu-total-ns))))
          (inputTotalNs input-total-ns)
          (inputTotal (duration-nanos->text input-total-ns))
          (expectedTotalNs expected-total-ns)
          (expectedTotal (duration-nanos->text expected-total-ns))
          (inputCpuTotalNs input-cpu-total-ns)
          (inputCpuTotal (duration-nanos->text input-cpu-total-ns))
          (expectedCpuTotalNs expected-cpu-total-ns)
          (expectedCpuTotal (duration-nanos->text expected-cpu-total-ns))
          (expectedOverInputNs
           (- expected-cpu-total-ns input-cpu-total-ns))
          (expectedOverInput
           (duration-nanos->text
            (- expected-cpu-total-ns input-cpu-total-ns)))
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
          (target_total (hash-get benchmark-contract 'target_total))
          (regression_budget (hash-get benchmark-contract 'regression_budget))
          (targetRationale (hash-get benchmark-contract 'targetRationale))
          (sampleIndex sample-index)
          (sampleCount sample-count)
          (targetStatus
           (policy-scenario-performance-status
            cpu-total-ns
            (hash-get benchmark-contract 'target_total)))
          (wallTargetStatus
           (policy-scenario-performance-status
            total-ns
            (hash-get benchmark-contract 'target_total)))
          (performanceStatus
           (policy-scenario-performance-status cpu-total-ns max-total))
          (wallPerformanceStatus
           (policy-scenario-performance-status total-ns max-total))
          (result result))))

;; : (-> BenchmarkContract Integer)
(def (policy-scenario-benchmark-sample-count benchmark-contract)
  (let (sample-count (hash-get benchmark-contract 'sampleCount))
    (if (and (integer? sample-count) (>= sample-count 20))
      sample-count
      (error "scenario benchmark requires at least twenty samples for p95 admission"
             sample-count))))

;; : (-> TimingReceipt TimingSampleSummary)
(def (policy-scenario-timing-sample-summary timing)
  (hash (sampleIndex (hash-get timing 'sampleIndex))
        (measurementOrder (hash-get timing 'measurementOrder))
        (totalNs (hash-get timing 'totalNs))
        (total (hash-get timing 'total))
        (cpuTotalNs (hash-get timing 'cpuTotalNs))
        (cpuTotal (hash-get timing 'cpuTotal))
        (schedulerDelayNs (hash-get timing 'schedulerDelayNs))
        (schedulerDelay (hash-get timing 'schedulerDelay))
        (performanceStatus (hash-get timing 'performanceStatus))
        (wallPerformanceStatus (hash-get timing 'wallPerformanceStatus))
        (inputTotalNs (hash-get timing 'inputTotalNs))
        (inputTotal (hash-get timing 'inputTotal))
        (expectedTotalNs (hash-get timing 'expectedTotalNs))
        (expectedTotal (hash-get timing 'expectedTotal))
        (inputCpuTotalNs (hash-get timing 'inputCpuTotalNs))
        (inputCpuTotal (hash-get timing 'inputCpuTotal))
        (expectedCpuTotalNs (hash-get timing 'expectedCpuTotalNs))
        (expectedCpuTotal (hash-get timing 'expectedCpuTotal))
        (timings (hash-get timing 'timings))))

;;; Admission projection mutates only the selected p95 receipt after every
;;; raw sample and both independently aggregated sides are available.
;; : (-> TimingReceipt (List TimingReceipt) TimingReceipt)
(def (policy-scenario-timing-with-samples! admission samples)
  (let* ((wall-input-statistics
          (benchmark-sample-statistics
           (map (lambda (sample) (hash-get sample 'inputTotalNs)) samples)))
         (wall-expected-statistics
          (benchmark-sample-statistics
           (map (lambda (sample) (hash-get sample 'expectedTotalNs)) samples)))
         (cpu-input-statistics
          (benchmark-sample-statistics
           (map (lambda (sample) (hash-get sample 'inputCpuTotalNs)) samples)))
         (cpu-expected-statistics
          (benchmark-sample-statistics
           (map (lambda (sample) (hash-get sample 'expectedCpuTotalNs)) samples)))
         (wall-statistics
          (benchmark-sample-statistics
           (map (lambda (sample) (hash-get sample 'totalNs)) samples)))
         (cpu-statistics
          (benchmark-sample-statistics
           (map (lambda (sample) (hash-get sample 'cpuTotalNs)) samples)))
         (benchmark-contract (hash-get admission 'benchmarkContract))
         (comparison
          (policy-scenario-input-expected-comparison
           (benchmark-statistics-ref cpu-input-statistics 'p95Ns)
           (benchmark-statistics-ref cpu-expected-statistics 'p95Ns)
           (hash-get benchmark-contract 'expected_over_input_budget)
           (hash-get benchmark-contract 'expected_over_input_note)
           (hash-get benchmark-contract 'targetRationale)))
         (wall-comparison
          (policy-scenario-input-expected-comparison
           (benchmark-statistics-ref wall-input-statistics 'p95Ns)
           (benchmark-statistics-ref wall-expected-statistics 'p95Ns)
           (hash-get benchmark-contract 'expected_over_input_budget)
           (hash-get benchmark-contract 'expected_over_input_note)
           (hash-get benchmark-contract 'targetRationale)))
         (max-total
          (policy-scenario-benchmark-max-total benchmark-contract)))
    (hash-put! comparison 'statistic 'independent-p95)
    (hash-put! comparison 'clock 'process-cpu)
    (hash-put! wall-comparison 'statistic 'independent-p95)
    (hash-put! wall-comparison 'clock 'monotonic-wall)
    (hash-put! admission 'admissionStatistic 'p95)
    (hash-put! admission 'admissionClock 'process-cpu)
    (hash-put! admission 'inputExpectedStatistic 'independent-p95)
    (hash-put! admission 'inputExpectedClock 'process-cpu)
    (hash-put! admission 'inputSampleStatistics cpu-input-statistics)
    (hash-put! admission 'expectedSampleStatistics cpu-expected-statistics)
    (hash-put! admission 'wallInputSampleStatistics wall-input-statistics)
    (hash-put! admission 'wallExpectedSampleStatistics wall-expected-statistics)
    (hash-put! admission 'inputExpectedStatus
               (hash-get comparison 'status))
    (hash-put! admission 'inputExpectedComparison comparison)
    (hash-put! admission 'wallInputExpectedComparison wall-comparison)
    (hash-put! admission 'sampleStatistics cpu-statistics)
    (hash-put! admission 'wallSampleStatistics wall-statistics)
    (hash-put! admission 'schedulerDelaySamplesNs
               (map (lambda (sample)
                      (hash-get sample 'schedulerDelayNs))
                    samples))
    (hash-put! admission 'performanceStatus
               (policy-scenario-performance-status
                (benchmark-statistics-ref cpu-statistics 'p95Ns)
                max-total))
    (hash-put! admission 'wallPerformanceStatus
               (policy-scenario-performance-status
                (benchmark-statistics-ref wall-statistics 'p95Ns)
                max-total))
    (hash-put! admission 'targetStatus
               (policy-scenario-performance-status
                (benchmark-statistics-ref cpu-statistics 'p95Ns)
                (hash-get benchmark-contract 'target_total)))
    (hash-put! admission 'wallTargetStatus
               (policy-scenario-performance-status
                (benchmark-statistics-ref wall-statistics 'p95Ns)
                (hash-get benchmark-contract 'target_total)))
    (hash-put! admission 'samples
               (map policy-scenario-timing-sample-summary samples))
    admission))

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
            (schemaVersion "2")
            (relation
             (if (< expected-total-ns input-total-ns)
               "expected-faster"
               "expected-not-faster"))
            (inputTotalNs input-total-ns)
            (inputTotal (duration-nanos->text input-total-ns))
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
  (let (cpu-start-ns (policy-scenario-cpu-nanos))
    (let-values (((duration-ns value)
                  (call-with-timing thunk)))
      (let (cpu-duration-ns
            (- (policy-scenario-cpu-nanos) cpu-start-ns))
        (unless (and (integer? duration-ns) (> duration-ns 0)
                     (integer? cpu-duration-ns) (> cpu-duration-ns 0))
          (error "policy scenario timing source returned non-positive duration"
                 name
                 duration-ns
                 cpu-duration-ns))
        (cons value
              (hash (name name)
                    (timingSource ":clan/timestamp#call-with-timing")
                    (durationNs duration-ns)
                    (duration (duration-nanos->text duration-ns))
                    (cpuTimingSource ":gerbil/gambit#cpu-time")
                    (cpuDurationNs cpu-duration-ns)
                    (cpuDuration (duration-nanos->text cpu-duration-ns))
                    (schedulerDelayNs
                     (max 0 (- duration-ns cpu-duration-ns)))
                    (schedulerDelay
                     (duration-nanos->text
                      (max 0 (- duration-ns cpu-duration-ns))))))))))

;; : (-> Unit Integer)
(def (policy-scenario-cpu-nanos)
  (inexact->exact (floor (* 1000000000.0 (cpu-time)))))

;;; Total timing boundary:
;;; - Sum phase receipts without re-running scenario work.
;;; - An empty timing list cannot substantiate an observation.
;; : (-> (List Timing) Integer )
(def (policy-scenario-timings-total-ns timings)
  (policy-scenario-timings-total-by timings 'durationNs))

;; : (-> (List Timing) Symbol Integer)
(def (policy-scenario-timings-total-by timings field)
  (unless (pair? timings)
    (error "policy scenario timing receipt requires measured phases"))
  (foldl (lambda (timing total)
           (+ total (hash-get timing field)))
         0
         timings))

;;; Full policy runner:
;;; - Use this when a scenario validates the complete provider policy runner.
;;; - run-policy-checks includes modularity and agent rules without package filters.
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
