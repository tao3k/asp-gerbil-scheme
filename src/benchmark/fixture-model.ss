;;; -*- Gerbil -*-
;;; Benchmark fixture model owns stable defaults and scalar field projections.
;;; Invariant: semantic validation and timing execution remain in sibling owners.

(import :asp-gerbil-scheme/src/support/time
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
        benchmark-hot-target-total
        benchmark-hot-max-total
        benchmark-integration-max-total
        benchmark-default-memory-metric
        benchmark-default-memory-unit
        benchmark-fixture-required-keys
        make-benchmark-fixture
        benchmark-fixture-ref
        benchmark-fixture-missing-keys
        +benchmark-positive-duration-fields+
        +benchmark-non-negative-duration-fields+
        +benchmark-positive-number-fields+
        +benchmark-non-negative-number-fields+
        +benchmark-positive-integer-fields+
        +benchmark-observed-max-field-pairs+
        +benchmark-receipt-leading-fields+
        +benchmark-receipt-budget-fields+
        +benchmark-integration-tags+
        +benchmark-input-timing-names+
        +benchmark-expected-timing-names+
        benchmark-fixture-phase-present?
        benchmark-positive-number?
        benchmark-non-negative-number?
        benchmark-positive-integer?
        benchmark-fixture-duration-field-nanos
        benchmark-fixture-fields-pass?
        benchmark-fixture-duration-field-pass?
        benchmark-fixture-duration-fields-pass?
        benchmark-fixture-non-negative-number-field-pass?
        benchmark-fixture-unit-contract-pass?)

;; benchmark-default-max-total
;;   : DurationLiteral
;;   | doc m%
;;       Default wall-clock budget for policy scenario benchmark receipts.
;;     %
(def benchmark-default-max-total '100ms)
;; : Integer
(def benchmark-default-max-collect-ms 25)
;; : Integer
(def benchmark-default-max-parse-ms 15)
;; : Integer
(def benchmark-default-max-file-ms 5)
;; : Integer
(def benchmark-default-max-phase-ms 6)
;; : Number
(def benchmark-default-observed-collect-ms 10)
;; : Number
(def benchmark-default-observed-parse-ms 0)
;; : Number
(def benchmark-default-observed-file-ms 0)
;; : Number
(def benchmark-default-observed-phase-ms 6)
;; : DurationLiteral
(def benchmark-default-observed-total '10ms)
;; : DurationLiteral
(def benchmark-default-target-total '25ms)
;; : DurationLiteral
(def benchmark-default-regression-budget '15ms)
;; : DurationLiteral
(def benchmark-default-expected-over-input-budget '15ms)
;; : Integer
(def benchmark-default-max-rss-mb 512)
;; : DurationLiteral
(def benchmark-hot-target-total '25ms)
;; : DurationLiteral
(def benchmark-hot-max-total '100ms)
;; : DurationLiteral
(def benchmark-integration-max-total '1s)
;; : Symbol
(def benchmark-default-memory-metric 'resident-set-size)
;; : String
(def benchmark-default-memory-unit "MB")

;; benchmark-fixture-required-keys
;;   : (List Symbol)
;;   | doc m%
;;       Minimum fixture contract shared by scenario files and runtime gates.
;;     %
(def benchmark-fixture-required-keys
  '(max_total
    maxCollectMs
    maxParseMs
    maxFileMs
    maxPhaseMs
    observedCollectMs
    observedParseMs
    observedFileMs
    observedPhaseMs
    observed_total
    target_total
    regression_budget
    observedTimings
    targetRationale
    maxRssMb
    memoryMetric
    memoryUnit
    iterations
    unit
    rule
    feature
    optimizationFocus
    inputShape
    expectedOutcome
    measurementPhases
    tags))

;; : (List Symbol)
(def +benchmark-positive-duration-fields+
  '(max_total target_total))

;; : (List Symbol)
(def +benchmark-non-negative-duration-fields+
  '(observed_total regression_budget))

;; : (List Symbol)
(def +benchmark-positive-number-fields+
  '(maxCollectMs maxParseMs maxFileMs maxPhaseMs))

;; : (List Symbol)
(def +benchmark-non-negative-number-fields+
  '(observedCollectMs observedParseMs observedFileMs observedPhaseMs))

;; : (List Symbol)
(def +benchmark-positive-integer-fields+
  '(iterations))

;; : (List Pair)
(def +benchmark-observed-max-field-pairs+
  '((observedCollectMs . maxCollectMs)
    (observedParseMs . maxParseMs)
    (observedFileMs . maxFileMs)
    (observedPhaseMs . maxPhaseMs)))

;; : (List Symbol)
(def +benchmark-receipt-leading-fields+
  '(rule feature optimizationFocus inputShape expectedOutcome))

;; : (List Symbol)
(def +benchmark-receipt-budget-fields+
  '(observed_total
    target_total
    regression_budget
    observedTimings
    targetRationale
    maxCollectMs
    maxParseMs
    maxFileMs
    maxPhaseMs
    maxRssMb
    memoryMetric
    memoryUnit))

;; +benchmark-integration-tags+
;;   : (List String)
;;   | doc m%
;;       Tags for benchmarks that intentionally include source collection,
;;       gxtest import closure, subprocess, cache, or launcher boundaries.
;;     %
(def +benchmark-integration-tags+
  '("integration" "import-closure" "gxtest" "downstream"
    "cold-path" "cache" "launcher" "subprocess"))

;; : (List String)
(def +benchmark-input-timing-names+
  '("collect-before" "policy-before"))

;; : (List String)
(def +benchmark-expected-timing-names+
  '("collect-after" "policy-after"))

;; make-benchmark-fixture
;;   : (-> Symbol Symbol String String String (List Symbol) Alist)
;;   | doc m%
;;       Build the benchmark fixture alist consumed by scenario gates.
;;     %
(def (make-benchmark-fixture rule feature optimization-focus
                             input-shape expected-repair tags)
  (list (cons 'max_total benchmark-default-max-total)
        (cons 'maxCollectMs benchmark-default-max-collect-ms)
        (cons 'maxParseMs benchmark-default-max-parse-ms)
        (cons 'maxFileMs benchmark-default-max-file-ms)
        (cons 'maxPhaseMs benchmark-default-max-phase-ms)
        (cons 'observedCollectMs benchmark-default-observed-collect-ms)
        (cons 'observedParseMs benchmark-default-observed-parse-ms)
        (cons 'observedFileMs benchmark-default-observed-file-ms)
        (cons 'observedPhaseMs benchmark-default-observed-phase-ms)
        (cons 'observed_total benchmark-default-observed-total)
        (cons 'target_total benchmark-default-target-total)
        (cons 'regression_budget benchmark-default-regression-budget)
        (cons 'expected_over_input_budget
              benchmark-default-expected-over-input-budget)
        (cons 'observedTimings
              `(((name . collect-before)
                 (durationMs . 6))
                ((name . collect-after)
                 (durationMs . 4))
                ((name . policy-before)
                 (durationMs . 0))
                ((name . policy-after)
                 (durationMs . 0))))
        (cons 'targetRationale
              "default generated benchmark fixture target")
        (cons 'maxRssMb benchmark-default-max-rss-mb)
        (cons 'memoryMetric benchmark-default-memory-metric)
        (cons 'memoryUnit benchmark-default-memory-unit)
        (cons 'iterations 3)
        (cons 'unit "ms")
        (cons 'rule rule)
        (cons 'feature feature)
        (cons 'optimizationFocus optimization-focus)
        (cons 'inputShape input-shape)
        (cons 'expectedOutcome expected-repair)
        (cons 'measurementPhases
              '(collect-before collect-after policy-before policy-after
                assert-time-gate assert-memory-gate))
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

;; benchmark-fixture-phase-present?
;;   : (-> (List Value) Symbol Boolean)
;;   | doc m%
;;       Return `#t` when a phase appears either as its symbol or string form.
;;
;;       Scenario fixtures sometimes cross JSON boundaries, so this predicate
;;       accepts both representations without branching at each call site.
;;
;;       # Examples
;;
;;       ```scheme
;;       (benchmark-fixture-phase-present? '(prepare-fixture) 'prepare-fixture)
;;       ;; => #t
;;       ```
;;     %
;; : (forall (a) (-> [a] a Boolean))
;; : (-> (List Value) Symbol Boolean)
(def (benchmark-fixture-phase-present? phases phase)
  (ormap (lambda (candidate) (member candidate phases))
         [phase (symbol->string phase)]))

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

;; : (-> Alist Symbol Boolean)
(def (benchmark-fixture-non-negative-number-field-pass? fixture key)
  (benchmark-non-negative-number? (benchmark-fixture-ref fixture key)))

;; : (-> Alist Boolean)
(def (benchmark-fixture-unit-contract-pass? fixture)
  (equal? (benchmark-fixture-ref fixture 'unit) "ms"))
