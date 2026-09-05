;;; -*- Gerbil -*-
;;; Benchmark gate owns timing execution and typed receipt projection.
;;; Boundary: fixture data and semantic admission remain in sibling owners.

(import :asp-gerbil-scheme/src/benchmark/fixture-model
        :asp-gerbil-scheme/src/benchmark/fixture-contract
        :asp-gerbil-scheme/src/support/time
        (only-in :std/sugar andmap ormap foldl))

(export benchmark-default-max-total
        benchmark-default-max-collect-ms
        benchmark-default-max-parse-ms
        benchmark-default-max-file-ms
        benchmark-default-max-phase-ms
        benchmark-default-observed-collect-ms
        benchmark-default-observed-parse-ms
        benchmark-default-observed-file-ms
        benchmark-default-observed-phase-ms
        benchmark-default-observed-total
        benchmark-default-target-total
        benchmark-default-regression-budget
        benchmark-default-expected-over-input-budget
        benchmark-default-max-rss-mb
        benchmark-default-memory-metric
        benchmark-default-memory-unit
        benchmark-fixture-required-keys
        make-benchmark-fixture
        benchmark-fixture-ref
        benchmark-fixture-missing-keys
        benchmark-fixture-memory-contract-pass?
        benchmark-fixture-observed-timings-contract-pass?
        benchmark-fixture-input-expected-comparison-pass?
        benchmark-fixture-integration-scope?
        benchmark-fixture-timing-class-contract-pass?
        benchmark-fixture-contract-pass?
        benchmark-elapsed-micros
        benchmark-elapsed-ms
        benchmark-best-elapsed-micros
        benchmark-best-elapsed-ms
        benchmark-run
        benchmark-run/result
        benchmark-receipt-pass?)

;; benchmark-elapsed-micros
;;   : (-> (-> Value) Integer)
;;   | doc m%
;;       Measure one benchmark thunk with microsecond precision.
;;     %
(def (benchmark-elapsed-micros thunk)
  (let (start-micros (monotonic-micros))
    (thunk)
    (duration-micros start-micros (monotonic-micros))))

;; benchmark-elapsed-micros/result
;;   : (-> (-> Value) (Values Integer Value))
;;   | doc m%
;;       Measure one benchmark thunk and preserve its result for semantic gates.
;;     %
(def (benchmark-elapsed-micros/result thunk)
  (let* ((start-micros (monotonic-micros))
         (result (thunk))
         (elapsed-micros (duration-micros start-micros
                                          (monotonic-micros))))
    (values elapsed-micros result)))

;; benchmark-elapsed-ms
;;   : (-> (-> Value) Number)
;;   | doc m%
;;       Return elapsed milliseconds while preserving sub-millisecond observations.
;;     %
(def (benchmark-elapsed-ms thunk)
  (/ (benchmark-elapsed-micros thunk) 1000.0))

;; benchmark-best-elapsed-micros
;;   : (-> Integer (-> Value) Integer)
;;   | doc m%
;;       Return the best elapsed microseconds across positive attempts.
;;     %
;; : (forall (r) (-> Integer (-> r) (Maybe Number)))
;; benchmark-best-elapsed-micros
;; : (-> Integer Procedure (Maybe Number))
(def (benchmark-best-elapsed-micros attempts thunk)
  (if (<= attempts 0)
    (error "benchmark attempts must be positive" attempts)
    (apply min
           (map (lambda (_) (benchmark-elapsed-micros thunk))
                (iota attempts)))))

;; benchmark-best-elapsed-micros/result
;;   : (-> Integer (-> Value) (Values Integer Value))
;;   | doc m%
;;       Return the best elapsed microseconds and its corresponding result.
;;     %
(def (benchmark-result-attempt thunk)
  (let-values (((elapsed result)
                (benchmark-elapsed-micros/result thunk)))
    (cons elapsed result)))

;; benchmark-better-attempt
;;   : (-> MaybePair Pair Pair)
;;   | doc m%
;;       Keep the attempt pair with the lower elapsed microsecond value.
;;     %
(def (benchmark-better-attempt best attempt)
  (cond
   ((not best) attempt)
   ((< (car attempt) (car best)) attempt)
   (else best)))

;; : (forall (r) (-> Integer (-> r) (Values Number r)))
;; benchmark-best-elapsed-micros/result
;; : (-> Integer Procedure Values)
(def (benchmark-best-elapsed-micros/result attempts thunk)
  (if (<= attempts 0)
    (error "benchmark attempts must be positive" attempts)
    (let (best
          (foldl
           (lambda (_ best)
             (benchmark-better-attempt
              best
              (benchmark-result-attempt thunk)))
           #f
           (iota attempts)))
      (values (car best) (cdr best)))))

;; benchmark-best-elapsed-ms
;;   : (-> Integer (-> Value) Number)
;;   | doc m%
;;       Return the best elapsed milliseconds across positive attempts.
;;     %
(def (benchmark-best-elapsed-ms attempts thunk)
  (/ (benchmark-best-elapsed-micros attempts thunk) 1000.0))

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
(def (benchmark-receipt fixture elapsed-micros)
  (let* ((elapsed-nanos (micros->nanos elapsed-micros))
         (elapsed-ms (/ elapsed-micros 1000.0))
         (max-total (benchmark-fixture-ref fixture 'max_total))
         (max-total-ns (or (duration-literal->nanos max-total)
                           (error "invalid benchmark duration literal"
                                  'max_total
                                  max-total))))
    (append
     (benchmark-fixture-projection-fields
      fixture
      +benchmark-receipt-leading-fields+)
     (list (cons 'elapsedMs elapsed-ms)
           (cons 'elapsedMicros elapsed-micros)
           (cons 'elapsedNs elapsed-nanos)
           (cons 'max_total max-total))
     (benchmark-fixture-projection-fields
      fixture
      +benchmark-receipt-budget-fields+)
     (list (cons 'status (if (< elapsed-nanos max-total-ns)
                           'pass
                           'fail))))))

;; benchmark-run
;;   : (-> Alist (-> Value) Alist)
;;   | doc m%
;;       Run a fixture benchmark and return the complete receipt expected by tests.
;;     %
(def (benchmark-run fixture thunk)
  (benchmark-receipt
   fixture
   (benchmark-best-elapsed-micros
    (benchmark-fixture-ref fixture 'iterations)
    thunk)))

;; benchmark-run/result
;;   : (-> Alist (-> Value) (Values Alist Value))
;;   | doc m%
;;       Run a fixture benchmark and preserve the best attempt's result.
;;     %
(def (benchmark-run/result fixture thunk)
  (let-values (((elapsed-micros result)
                (benchmark-best-elapsed-micros/result
                 (benchmark-fixture-ref fixture 'iterations)
                 thunk)))
    (values (benchmark-receipt fixture elapsed-micros)
            result)))

;; benchmark-receipt-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Predicate used by scenario tests to keep benchmark pass/fail checks uniform.
;;     %
(def (benchmark-receipt-pass? receipt)
  (eq? (benchmark-fixture-ref receipt 'status) 'pass))
