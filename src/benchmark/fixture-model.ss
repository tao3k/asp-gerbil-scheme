;;; -*- Gerbil -*-
;;; Benchmark fixture model owns stable defaults and scalar field projections.
;;; Invariant: semantic validation and timing execution remain in sibling owners.

(import :asp-gerbil-scheme/src/support/time
        (only-in :std/sugar andmap ormap foldl))

(export benchmark-default-max-total
        benchmark-default-kind
        benchmark-default-target-total
        benchmark-default-regression-budget
        benchmark-default-expected-over-input-budget
        benchmark-scenario-max-total
        benchmark-minimum-sample-count
        benchmark-fixture-required-keys
        make-benchmark-fixture
        benchmark-fixture-ref
        benchmark-fixture-missing-keys
        +benchmark-positive-duration-fields+
        +benchmark-non-negative-duration-fields+
        +benchmark-positive-integer-fields+
        +benchmark-receipt-leading-fields+
        +benchmark-receipt-budget-fields+
        benchmark-positive-number?
        benchmark-non-negative-number?
        benchmark-positive-integer?
        benchmark-fixture-duration-field-nanos
        benchmark-fixture-fields-pass?
        benchmark-fixture-duration-field-pass?
        benchmark-fixture-duration-fields-pass?)

;; benchmark-default-max-total
;;   : DurationLiteral
;;   | doc m%
;;       Default wall-clock budget for policy scenario benchmark receipts.
;;     %
(def benchmark-default-max-total '100ms)
;; : Symbol
(def benchmark-default-kind 'scenario-e2e)
;; : DurationLiteral
(def benchmark-default-target-total '25ms)
;; : DurationLiteral
(def benchmark-default-regression-budget '75ms)
;; : DurationLiteral
(def benchmark-default-expected-over-input-budget '15ms)
;; : DurationLiteral
(def benchmark-scenario-max-total '1s)
;; Twenty samples make nearest-rank p95 distinct from the maximum sample while
;; retaining enough independent observations for end-to-end admission.
(def benchmark-minimum-sample-count 20)

;; benchmark-fixture-required-keys
;;   : (List Symbol)
;;   | doc m%
;;       Minimum fixture contract shared by scenario files and runtime gates.
;;     %
(def benchmark-fixture-required-keys
  '(benchmarkKind
    max_total
    target_total
    regression_budget
    expected_over_input_budget
    targetRationale
    sampleCount
    rule
    feature
    optimizationFocus
    inputShape
    expectedOutcome
    measurementPhases
    tags))

;; : (List Symbol)
(def +benchmark-positive-duration-fields+
  '(max_total target_total regression_budget))

;; : (List Symbol)
(def +benchmark-non-negative-duration-fields+
  '(expected_over_input_budget))

;; : (List Symbol)
(def +benchmark-positive-integer-fields+
  '(sampleCount))

;; : (List Symbol)
(def +benchmark-receipt-leading-fields+
  '(benchmarkKind rule feature optimizationFocus inputShape expectedOutcome))

;; : (List Symbol)
(def +benchmark-receipt-budget-fields+
  '(target_total
    regression_budget
    expected_over_input_budget
    targetRationale
    measurementPhases))

;; make-benchmark-fixture
;;   : (-> Symbol Symbol String String String (List Symbol) Alist)
;;   | doc m%
;;       Build the benchmark fixture alist consumed by scenario gates.
;;     %
(def (make-benchmark-fixture rule feature optimization-focus
                             input-shape expected-repair tags)
  (list (cons 'benchmarkKind benchmark-default-kind)
        (cons 'max_total benchmark-default-max-total)
        (cons 'target_total benchmark-default-target-total)
        (cons 'regression_budget benchmark-default-regression-budget)
        (cons 'expected_over_input_budget
              benchmark-default-expected-over-input-budget)
        (cons 'targetRationale
              "default generated benchmark fixture target")
        (cons 'sampleCount benchmark-minimum-sample-count)
        (cons 'rule rule)
        (cons 'feature feature)
        (cons 'optimizationFocus optimization-focus)
        (cons 'inputShape input-shape)
        (cons 'expectedOutcome expected-repair)
        (cons 'measurementPhases
              '(collect-before collect-after policy-before policy-after
                assert-time-gate observe-runtime-memory))
        (cons 'tags tags)))

;; benchmark-fixture-ref
;;   : (-> Alist Symbol Value)
;;   | doc m%
;;       Read required fixture metadata and fail loudly when a field is missing.
;;     %
(def (benchmark-fixture-ref fixture key)
  (let (entry (assoc key fixture))
    (if entry
      (cdr entry)
      (error "missing benchmark fixture key" key))))

;; benchmark-fixture-missing-keys
;;   : (-> Alist (List Symbol))
;;   | doc m%
;;       Return required benchmark fixture keys that are absent from an alist.
;;     %
;; : (forall (k v) (-> [(Pair k v)] [k]))
;; : (-> Alist (List Symbol))
(def (benchmark-fixture-missing-keys fixture)
  (filter (lambda (key) (not (assoc key fixture)))
          benchmark-fixture-required-keys))

;; : (-> Number Boolean)
(def (benchmark-positive-number? value)
  (and (number? value) (> value 0)))

;; : (-> Number Boolean)
(def (benchmark-non-negative-number? value)
  (and (number? value) (>= value 0)))

;; : (-> Integer Boolean)
(def (benchmark-positive-integer? value)
  (and (integer? value) (> value 0)))

;; : (-> Alist Symbol (U Integer False))
(def (benchmark-fixture-duration-field-nanos fixture key)
  (duration-literal->nanos (benchmark-fixture-ref fixture key)))

;; : (forall (v) (-> (-> v Boolean) Alist [Symbol] Boolean))
;; : (-> Procedure Alist (List Symbol) Boolean)
(def (benchmark-fixture-fields-pass? predicate fixture keys)
  (andmap (lambda (key)
            (predicate (benchmark-fixture-ref fixture key)))
          keys))

;; : (forall (n) (-> (-> n Boolean) Alist Symbol Boolean))
;; : (-> Procedure Alist Symbol Boolean)
(def (benchmark-fixture-duration-field-pass? nanos-pass? fixture key)
  (let (nanos (benchmark-fixture-duration-field-nanos fixture key))
    (and nanos (nanos-pass? nanos))))

;; : (forall (n) (-> (-> n Boolean) Alist [Symbol] Boolean))
;; : (-> Procedure Alist (List Symbol) Boolean)
(def (benchmark-fixture-duration-fields-pass? nanos-pass? fixture keys)
  (andmap (lambda (key)
            (benchmark-fixture-duration-field-pass?
             nanos-pass?
             fixture
             key))
          keys))
