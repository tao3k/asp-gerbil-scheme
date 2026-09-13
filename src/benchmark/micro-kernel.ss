;;; -*- Gerbil -*-
;;; Batched micro-kernel measurement with exact nanoseconds-per-operation gates.
;;; Boundary: fixtures declare budgets; only live receipts contain observations.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/benchmark/memory
        :asp-gerbil-scheme/src/benchmark/statistics
        :asp-gerbil-scheme/src/support/time
        (only-in :clan/timestamp call-with-timing)
        (only-in :std/sugar andmap))

(export make-micro-kernel-fixture
        micro-kernel-fixture-contract-pass?
        micro-kernel-run
        micro-kernel-run/result
        micro-kernel-receipt-pass?)

;; : (List Symbol)
(def +micro-kernel-required-keys+
  '(benchmarkKind
    name
    warmupOperations
    batchOperations
    sampleCount
    minimumBatchDuration
    targetNsPerOp
    regressionBudgetNsPerOp
    maxNsPerOp
    targetRationale))

;; : (-> (Or Symbol String) Integer Integer String Alist)
(def (make-micro-kernel-fixture name target-ns-per-op
                                regression-budget-ns-per-op rationale)
  `((benchmarkKind . micro-kernel)
    (name . ,name)
    (warmupOperations . 20000)
    (batchOperations . 100000)
    ;; Twenty samples make nearest-rank p95 distinct from the maximum.
    (sampleCount . 20)
    (minimumBatchDuration . 1ms)
    (targetNsPerOp . ,target-ns-per-op)
    (regressionBudgetNsPerOp . ,regression-budget-ns-per-op)
    (maxNsPerOp . ,(+ target-ns-per-op regression-budget-ns-per-op))
    (targetRationale . ,rationale)))

;; : (forall (a) (-> Alist Symbol a))
(def (micro-kernel-ref object key)
  (let (entry (assq key object))
    (if entry
      (cdr entry)
      (error "missing micro-kernel field" key))))

;; : (-> Alist (List Symbol))
(def (micro-kernel-missing-keys fixture)
  (filter (lambda (key) (not (assq key fixture)))
          +micro-kernel-required-keys+))

;; : (-> Alist Symbol Boolean)
(def (micro-kernel-positive-integer-field? fixture key)
  (let (value (micro-kernel-ref fixture key))
    (and (integer? value) (> value 0))))

;; : (forall (a) (-> (List (Pair Symbol a)) Boolean))
;; : (-> MicroKernelFixture Boolean)
(def (micro-kernel-fixture-contract-pass? fixture)
  (and (null? (micro-kernel-missing-keys fixture))
       (eq? (micro-kernel-ref fixture 'benchmarkKind) 'micro-kernel)
       (or (symbol? (micro-kernel-ref fixture 'name))
           (string? (micro-kernel-ref fixture 'name)))
       (andmap (lambda (key)
                 (micro-kernel-positive-integer-field? fixture key))
               '(warmupOperations
                 batchOperations
                 sampleCount
                 targetNsPerOp
                 regressionBudgetNsPerOp
                 maxNsPerOp))
       (duration-literal->nanos
        (micro-kernel-ref fixture 'minimumBatchDuration))
       (>= (micro-kernel-ref fixture 'sampleCount) 20)
       (let ((target (micro-kernel-ref fixture 'targetNsPerOp))
             (regression
              (micro-kernel-ref fixture 'regressionBudgetNsPerOp))
             (maximum (micro-kernel-ref fixture 'maxNsPerOp))
             (rationale (micro-kernel-ref fixture 'targetRationale)))
         (and (= maximum (+ target regression))
              (string? rationale)
              (> (string-length rationale) 0)))))

;;; Optimization boundary: `do` keeps the hot repetition loop allocation-free;
;;; constructing an iota list for map/fold would measure list allocation rather
;;; than the supplied operation.
;; : (forall (a) (-> Integer (-> a) a))
(def (micro-kernel-repeat operations thunk)
  (do ((remaining operations (- remaining 1))
       (result #!void (thunk)))
      ((zero? remaining) result)))

;; : (-> Unit Integer)
(def (micro-kernel-cpu-nanos)
  (inexact->exact (floor (* 1000000000.0 (cpu-time)))))

;; : (forall (a) (-> Integer (-> a) (Values Integer Integer a)))
(def (micro-kernel-measure-batch operations thunk)
  (let (cpu-start-ns (micro-kernel-cpu-nanos))
    (let-values (((wall-duration-ns result)
                  (call-with-timing
                   (lambda () (micro-kernel-repeat operations thunk)))))
      (let (cpu-duration-ns
            (- (micro-kernel-cpu-nanos) cpu-start-ns))
        (unless (and (integer? wall-duration-ns) (> wall-duration-ns 0)
                     (integer? cpu-duration-ns) (> cpu-duration-ns 0))
          (error "micro-kernel timing source returned non-positive duration"
                 wall-duration-ns
                 cpu-duration-ns))
        (values wall-duration-ns cpu-duration-ns result)))))

;; : (-> Void)
(def (micro-kernel-noop) #!void)

;; : (forall (a) (-> Alist Integer (-> a) (Tuple Integer a Alist)))
(def (micro-kernel-sample fixture sample-index operation)
  (##gc)
  (let (operations (micro-kernel-ref fixture 'batchOperations))
    (let-values (((wall-baseline-before-ns baseline-before-ns ignored-before)
                  (micro-kernel-measure-batch operations micro-kernel-noop)))
      (let-values (((wall-total-ns total-ns result)
                    (micro-kernel-measure-batch operations operation)))
        (let-values (((wall-baseline-after-ns baseline-after-ns ignored-after)
                      (micro-kernel-measure-batch operations
                                                  micro-kernel-noop)))
          (let* (;; A delayed baseline leg must not over-subtract the operation
                 ;; batch. The bracket minimum is explicit in the receipt; if
                 ;; even that makes the net non-positive, measurement fails.
                 (baseline-ns
                  (min baseline-before-ns baseline-after-ns))
                 (net-ns (- total-ns baseline-ns))
                 (minimum-batch-ns
                  (duration-literal->nanos
                   (micro-kernel-ref fixture 'minimumBatchDuration))))
            (unless (>= total-ns minimum-batch-ns)
              (error "micro-kernel batch is below the declared resolution floor"
                     total-ns
                     minimum-batch-ns))
            (unless (> net-ns 0)
              (error "micro-kernel net duration is not positive"
                     total-ns
                     baseline-ns))
            (list net-ns
                  result
                  `((sampleIndex . ,sample-index)
                    (operations . ,operations)
                    (timingSource . ":gerbil/gambit#cpu-time")
                    (wallTimingSource . ":clan/timestamp#call-with-timing")
                    (totalNs . ,total-ns)
                    (wallTotalNs . ,wall-total-ns)
                    (baselineBeforeNs . ,baseline-before-ns)
                    (baselineAfterNs . ,baseline-after-ns)
                    (wallBaselineBeforeNs . ,wall-baseline-before-ns)
                    (wallBaselineAfterNs . ,wall-baseline-after-ns)
                    (baselineStatistic . bracket-min)
                    (baselineNs . ,baseline-ns)
                    (netNs . ,net-ns)
                    (schedulerDelayNs
                     . ,(max 0 (- wall-total-ns total-ns)))
                    (nsPerOpNumerator . ,net-ns)
                    (nsPerOpDenominator . ,operations)
                    (nsPerOpCeiling
                     . ,(quotient (+ net-ns (- operations 1))
                                  operations))))))))))

;; : (-> Alist Alist Alist)
(def (micro-kernel-memory-delta before after)
  (map (lambda (after-entry)
         (let (before-entry (assq (car after-entry) before))
           (cons (car after-entry)
                 (- (cdr after-entry)
                    (if before-entry (cdr before-entry) 0)))))
       after))

;; : (forall (a) (-> Alist (List (Tuple Integer a Alist))
;;                       (Tuple Integer a Alist) Alist Alist Alist))
(def (micro-kernel-receipt fixture samples admission memory-before memory-after)
  (let* ((operations (micro-kernel-ref fixture 'batchOperations))
         (net-samples (map car samples))
         (statistics (benchmark-sample-statistics net-samples))
         ;; Micro-kernels admit on the median intrinsic cost.  The p95 and max
         ;; remain in `statistics` as scheduler/jitter diagnostics; scenario
         ;; end-to-end benchmarks use p95 admission instead.
         (p50-net-ns (car admission))
         (target-ns-per-op (micro-kernel-ref fixture 'targetNsPerOp))
         (max-ns-per-op (micro-kernel-ref fixture 'maxNsPerOp)))
    (append
     `((schemaId . "agent.semantic-protocols.gerbil-scheme-micro-kernel")
       (schemaVersion . "1")
       (benchmarkKind . micro-kernel)
       (name . ,(micro-kernel-ref fixture 'name))
       (timingSource . ":gerbil/gambit#cpu-time")
       (wallTimingSource . ":clan/timestamp#call-with-timing")
       (sampleGcPrecondition . ":gerbil/gambit###gc")
       (baselineStatistic . bracket-min)
       (admissionStatistic . p50)
       (operations . ,operations)
       (warmupOperations . ,(micro-kernel-ref fixture 'warmupOperations))
       (minimumBatchDuration
        . ,(micro-kernel-ref fixture 'minimumBatchDuration))
       (samples . ,(map caddr samples))
       (p50NetNs . ,p50-net-ns)
       (nsPerOpNumerator . ,p50-net-ns)
       (nsPerOpDenominator . ,operations)
       (nsPerOpCeiling
        . ,(quotient (+ p50-net-ns (- operations 1)) operations))
       (targetNsPerOp . ,target-ns-per-op)
       (regressionBudgetNsPerOp
        . ,(micro-kernel-ref fixture 'regressionBudgetNsPerOp))
       (maxNsPerOp . ,max-ns-per-op)
       (targetRationale . ,(micro-kernel-ref fixture 'targetRationale))
       (targetStatus
        . ,(if (<= p50-net-ns (* target-ns-per-op operations))
             'pass
             'fail))
       (status
        . ,(if (<= p50-net-ns (* max-ns-per-op operations))
             'pass
             'fail))
       (runtimeStats
        . ((memorySource . ,benchmark-memory-source)
           (gcPrecondition . ":gerbil/gambit###gc")
           (memoryBefore . ,memory-before)
           (memoryAfter . ,memory-after)
           (memoryDelta
            . ,(micro-kernel-memory-delta memory-before memory-after)))))
     statistics)))

;; : (forall (a) (-> Alist (-> a) (Values Alist a)))
;; : (-> MicroKernelFixture OperationThunk (Values MicroKernelReceipt Result))
(def (micro-kernel-run/result fixture operation)
  (unless (micro-kernel-fixture-contract-pass? fixture)
    (error "invalid micro-kernel fixture" fixture))
  (micro-kernel-repeat (micro-kernel-ref fixture 'warmupOperations) operation)
  (##gc)
  (let* ((memory-before (benchmark-memory-usage))
         (samples
          (map (lambda (sample-index)
                 (micro-kernel-sample fixture sample-index operation))
               (iota (micro-kernel-ref fixture 'sampleCount))))
         (admission
          (benchmark-select-sample samples 50 car))
         (memory-after (benchmark-memory-usage)))
    (values (micro-kernel-receipt
             fixture samples admission memory-before memory-after)
            (cadr admission))))

;; : (forall (a) (-> Alist (-> a) Alist))
(def (micro-kernel-run fixture operation)
  (let-values (((receipt ignored-result)
                (micro-kernel-run/result fixture operation)))
    receipt))

;; : (-> Alist Boolean)
(def (micro-kernel-receipt-pass? receipt)
  (eq? (micro-kernel-ref receipt 'status) 'pass))
