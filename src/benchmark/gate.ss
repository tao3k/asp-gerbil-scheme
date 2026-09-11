;;; -*- Gerbil -*-
;;; Benchmark gate owns timing execution and typed receipt projection.
;;; Boundary: fixture data and semantic admission remain in sibling owners.

(import :asp-gerbil-scheme/src/benchmark/fixture-model
        :asp-gerbil-scheme/src/benchmark/fixture-contract
        :asp-gerbil-scheme/src/benchmark/memory
        :asp-gerbil-scheme/src/benchmark/statistics
        :asp-gerbil-scheme/src/support/time
        (only-in :clan/timestamp call-with-timing))

(export benchmark-default-max-total
        benchmark-default-kind
        benchmark-default-target-total
        benchmark-default-regression-budget
        benchmark-default-expected-over-input-budget
        benchmark-fixture-required-keys
        make-benchmark-fixture
        benchmark-fixture-ref
        benchmark-fixture-missing-keys
        benchmark-fixture-regression-budget-contract-pass?
        benchmark-fixture-kind-contract-pass?
        benchmark-fixture-scenario-duration-contract-pass?
        benchmark-fixture-contract-pass?
        benchmark-timing-source
        benchmark-elapsed-nanos
        benchmark-admission-percentile
        benchmark-run
        benchmark-run/result
        benchmark-receipt-pass?)

;; : String
(def benchmark-timing-source ":clan/timestamp#call-with-timing")

;; : Integer
(def benchmark-admission-percentile 95)

;; benchmark-elapsed-nanos
;;   : (-> (-> Value) Integer)
;;   | doc m%
;;       Measure one benchmark thunk with clan's upstream nanosecond timer.
;;     %
(def (benchmark-elapsed-nanos thunk)
  (##gc)
  (let-values (((elapsed-nanos ignored-result)
                (call-with-timing thunk)))
    (if (and (integer? elapsed-nanos) (> elapsed-nanos 0))
      elapsed-nanos
      (error "benchmark timing source returned non-positive duration"
             elapsed-nanos))))

(def (benchmark-result-attempt thunk)
  (##gc)
  (let (memory-before (benchmark-memory-usage))
    (let-values (((elapsed result)
                  (call-with-timing thunk)))
      (unless (and (integer? elapsed) (> elapsed 0))
        (error "benchmark timing source returned non-positive duration"
               elapsed))
      (let (memory-after (benchmark-memory-usage))
        (list elapsed
              result
              `((timingSource . ":clan/timestamp#call-with-timing")
                (memorySource . ,benchmark-memory-source)
                (gcPrecondition . ":gerbil/gambit###gc")
                (memoryBefore . ,memory-before)
                (memoryAfter . ,memory-after)
                (memoryDelta
                 .
                 ,(map (lambda (after-entry)
                         (let (before-entry
                               (assq (car after-entry) memory-before))
                           (cons (car after-entry)
                                 (- (cdr after-entry)
                                    (if before-entry
                                      (cdr before-entry)
                                      0)))))
                       memory-after))))))))

(def (benchmark-attempts attempts thunk)
  (if (<= attempts 0)
    (error "benchmark attempts must be positive" attempts)
    (map (lambda (_) (benchmark-result-attempt thunk))
         (iota attempts))))

(def (benchmark-attempt-statistics attempts)
  (benchmark-sample-statistics (map car attempts)))

(def (benchmark-admission-attempt attempts)
  (benchmark-select-sample attempts
                           benchmark-admission-percentile
                           car))

;; benchmark-run
;;   : (-> Alist (-> Value) Alist)
;;   | doc m%
;;       Run a fixture benchmark and return the complete receipt expected by tests.
;;     %
;; : (-> Alist Symbol Pair)
(def (benchmark-fixture-projection-field fixture key)
  (cons key (benchmark-fixture-ref fixture key)))

;; : (-> Alist (List Symbol) Alist)
(def (benchmark-fixture-projection-fields fixture keys)
  (map (lambda (key)
         (benchmark-fixture-projection-field fixture key))
       keys))

;; : (forall (v) (-> [(Pair Symbol v)] Number [(Pair Symbol v)]))
;; benchmark-receipt
;; : (-> Alist Number Alist)
(def (benchmark-receipt fixture elapsed-nanos statistics runtime-stats)
  (let* ((max-total (benchmark-fixture-ref fixture 'max_total))
         (max-total-ns (or (duration-literal->nanos max-total)
                           (error "invalid benchmark duration literal"
                                  'max_total
                                  max-total))))
    (append
     (benchmark-fixture-projection-fields
      fixture
     +benchmark-receipt-leading-fields+)
     (list (cons 'timingSource benchmark-timing-source)
           (cons 'elapsedNs elapsed-nanos)
           (cons 'elapsed (duration-nanos->text elapsed-nanos))
           (cons 'admissionStatistic 'p95)
           (cons 'runtimeStats runtime-stats)
           (cons 'max_total max-total))
     statistics
     (benchmark-fixture-projection-fields
      fixture
      +benchmark-receipt-budget-fields+)
     (list (cons 'status (if (<= elapsed-nanos max-total-ns)
                           'pass
                           'fail))))))

;; benchmark-run
;;   : (-> Alist (-> Value) Alist)
;;   | doc m%
;;       Run a fixture benchmark and return the complete receipt expected by tests.
;;     %
(def (benchmark-run fixture thunk)
  (let* ((attempts (benchmark-attempts
                    (benchmark-fixture-ref fixture 'sampleCount)
                    thunk))
         (admission-attempt (benchmark-admission-attempt attempts)))
    (benchmark-receipt fixture
                       (car admission-attempt)
                       (benchmark-attempt-statistics attempts)
                       (caddr admission-attempt))))

;; benchmark-run/result
;;   : (-> Alist (-> Value) (Values Alist Value))
;;   | doc m%
;;       Run a fixture benchmark and preserve the p95 admission attempt result.
;;     %
(def (benchmark-run/result fixture thunk)
  (let* ((attempts (benchmark-attempts
                    (benchmark-fixture-ref fixture 'sampleCount)
                    thunk))
         (admission-attempt (benchmark-admission-attempt attempts)))
    (values (benchmark-receipt fixture
                               (car admission-attempt)
                               (benchmark-attempt-statistics attempts)
                               (caddr admission-attempt))
            (cadr admission-attempt))))

;; benchmark-receipt-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Predicate used by scenario tests to keep benchmark pass/fail checks uniform.
;;     %
(def (benchmark-receipt-pass? receipt)
  (eq? (benchmark-fixture-ref receipt 'status) 'pass))
