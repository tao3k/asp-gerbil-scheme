;;; -*- Gerbil -*-
;;; Boundary: reusable benchmark fixtures and performance gate receipts.

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

;; benchmark-fixture-memory-contract-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Validate the reusable RSS budget fields required by benchmark fixtures.
;;     %
(def (benchmark-fixture-memory-contract-pass? fixture)
  (let ((max-rss-entry (assoc 'maxRssMb fixture))
        (memory-metric-entry (assoc 'memoryMetric fixture))
        (memory-unit-entry (assoc 'memoryUnit fixture))
        (measurement-phases-entry (assoc 'measurementPhases fixture)))
    (and max-rss-entry
         memory-metric-entry
         memory-unit-entry
         measurement-phases-entry
         (let ((max-rss-mb (cdr max-rss-entry))
               (memory-metric (cdr memory-metric-entry))
               (memory-unit (cdr memory-unit-entry))
               (measurement-phases (cdr measurement-phases-entry)))
           (and (benchmark-positive-integer? max-rss-mb)
                (eq? memory-metric benchmark-default-memory-metric)
                (equal? memory-unit benchmark-default-memory-unit)
                (not (not (benchmark-fixture-phase-present?
                           measurement-phases
                           'assert-memory-gate))))))))

;; benchmark-fixture-observed-timings-contract-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Validate observed timing baseline fields carried by benchmark fixtures.
;;     %
;; : (forall (v) (-> [(Pair Symbol v)] Boolean))
;; benchmark-fixture-observed-timings-contract-pass?
;; : (-> Alist Boolean)
(def (benchmark-fixture-observed-timings-contract-pass? fixture)
  (let ((observed-total-entry (assoc 'observed_total fixture))
        (target-total-entry (assoc 'target_total fixture))
        (regression-budget-entry (assoc 'regression_budget fixture))
        (observed-timings-entry (assoc 'observedTimings fixture))
        (target-rationale-entry (assoc 'targetRationale fixture)))
    (and observed-total-entry
         target-total-entry
         regression-budget-entry
         observed-timings-entry
         target-rationale-entry
         (let ((observed-total-ns
                (duration-literal->nanos (cdr observed-total-entry)))
               (target-total-ns
                (duration-literal->nanos (cdr target-total-entry)))
               (regression-budget-ns
                (duration-literal->nanos (cdr regression-budget-entry)))
               (observed-timings (cdr observed-timings-entry))
               (target-rationale (cdr target-rationale-entry)))
           (and observed-total-ns
                target-total-ns
                regression-budget-ns
                (>= observed-total-ns 0)
                (> target-total-ns 0)
                (>= regression-budget-ns 0)
                (string? target-rationale)
                (list? observed-timings)
                (not (null? observed-timings))
                (andmap benchmark-observed-timing-contract-pass?
                        observed-timings))))))

;; : (-> Alist Boolean)
(def (benchmark-observed-timing-contract-pass? timing)
  (and (list? timing)
       (let ((name-entry (assoc 'name timing))
             (duration-ms-entry (assoc 'durationMs timing))
             (duration-ns-entry (assoc 'durationNs timing)))
         (and name-entry
              (or duration-ms-entry duration-ns-entry)
              (let ((name (cdr name-entry))
                    (duration-ms (and duration-ms-entry
                                      (cdr duration-ms-entry)))
                    (duration-ns (and duration-ns-entry
                                      (cdr duration-ns-entry))))
                (and (or (symbol? name) (string? name))
                     (or (benchmark-non-negative-number? duration-ns)
                         (benchmark-non-negative-number? duration-ms))))))))

;; : (-> Alist String Boolean)
(def (benchmark-observed-timing-name-match? timing name)
  (let (name-entry (and (list? timing) (assoc 'name timing)))
    (and name-entry
         (benchmark-tag-equal? (cdr name-entry) name))))

;; : (-> (List Alist) String Boolean)
(def (benchmark-observed-timings-name-present? timings name)
  (ormap (lambda (timing)
           (benchmark-observed-timing-name-match? timing name))
         timings))

;; : (-> (List Alist) (List String) Boolean)
(def (benchmark-observed-timings-names-present? timings names)
  (andmap (lambda (name)
            (benchmark-observed-timings-name-present? timings name))
          names))

;; : (-> Alist Number)
(def (benchmark-observed-timing-duration-nanos timing)
  (let ((duration-ns-entry (assoc 'durationNs timing))
        (duration-ms-entry (assoc 'durationMs timing)))
    (cond
     (duration-ns-entry (cdr duration-ns-entry))
     (duration-ms-entry (* (cdr duration-ms-entry) 1000000))
     (else 0))))

;; : (-> Alist (List String) Number)
(def (benchmark-observed-timing-selected-nanos timing names)
  (if (ormap (lambda (name)
               (benchmark-observed-timing-name-match? timing name))
             names)
    (benchmark-observed-timing-duration-nanos timing)
    0))

;; : (-> Procedure (List Alist) (List String) Number)
(def (benchmark-observed-timings-selected-total selector timings names)
  (foldl (lambda (timing total)
           (+ total (selector timing names)))
         0
         timings))

;; : (-> (List Alist) (List String) Number)
(def (benchmark-observed-timings-selected-total-nanos timings names)
  (benchmark-observed-timings-selected-total
   benchmark-observed-timing-selected-nanos
   timings
   names))

;; : (-> Alist Symbol (U String False))
(def (benchmark-fixture-non-empty-string-field fixture key)
  (let (entry (assoc key fixture))
    (and entry
         (string? (cdr entry))
         (> (string-length (cdr entry)) 0)
         (cdr entry))))

;; : (-> Alist (U String False))
(def (benchmark-fixture-input-expected-annotation fixture)
  (or (benchmark-fixture-non-empty-string-field
       fixture
       'expected_over_input_note)
      (benchmark-fixture-non-empty-string-field
       fixture
       'targetRationale)))

;; : (-> Alist (U Integer False))
(def (benchmark-fixture-expected-over-input-budget-nanos fixture)
  (let (entry (or (assoc 'expected_over_input_budget fixture)
                  (assoc 'regression_budget fixture)))
    (and entry
         (duration-literal->nanos (cdr entry)))))

;; benchmark-fixture-input-expected-comparison-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Compare the original input-side policy timing with the expected
;;       repaired-side timing. The expected side may be slower only within the
;;       scenario-owned `expected_over_input_budget`.
;;     %
(def (benchmark-fixture-input-expected-comparison-pass? fixture)
  (let ((observed-timings-entry (assoc 'observedTimings fixture))
        (expected-budget-ns
         (benchmark-fixture-expected-over-input-budget-nanos fixture)))
    (and observed-timings-entry
         expected-budget-ns
         (let ((observed-timings (cdr observed-timings-entry)))
           (and (benchmark-fixture-observed-timings-contract-pass? fixture)
                (benchmark-observed-timings-names-present?
                 observed-timings
                 +benchmark-input-timing-names+)
                (benchmark-observed-timings-names-present?
                 observed-timings
                 +benchmark-expected-timing-names+)
                (let* ((input-ns
                        (benchmark-observed-timings-selected-total-nanos
                         observed-timings
                         +benchmark-input-timing-names+))
                       (expected-ns
                        (benchmark-observed-timings-selected-total-nanos
                         observed-timings
                         +benchmark-expected-timing-names+)))
                  (and (<= expected-ns (+ input-ns expected-budget-ns))
                       (or (< expected-ns input-ns)
                           (not
                            (not
                             (benchmark-fixture-input-expected-annotation
                              fixture)))))))))))

;; benchmark-tag-equal?
;;   : (-> BenchmarkTagCandidate String Boolean)
;;   | type BenchmarkTagCandidate = (U Symbol String)
;;   | doc m%
;;       Compare a fixture tag carried as a Scheme symbol or JSON string with
;;       the normalized integration tag name.
;;     %
(def (benchmark-tag-equal? candidate tag)
  (cond
   ((symbol? candidate) (equal? (symbol->string candidate) tag))
   ((string? candidate) (equal? candidate tag))
   (else #f)))

;; : (-> Alist String Boolean)
(def (benchmark-fixture-tag? fixture tag)
  (ormap (lambda (candidate)
           (benchmark-tag-equal? candidate tag))
         (benchmark-fixture-ref fixture 'tags)))

;; : (-> Alist Boolean)
;; : (forall (v) (-> [(Pair Symbol v)] Boolean))
;; benchmark-fixture-integration-scope?
;; : (-> Alist Boolean)
(def (benchmark-fixture-integration-scope? fixture)
  (ormap (lambda (tag)
           (benchmark-fixture-tag? fixture tag))
         +benchmark-integration-tags+))

;; : (-> Alist Boolean)
(def (benchmark-fixture-hot-timing-pass? fixture)
  (let ((max-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'max_total))
        (target-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'target_total))
        (observed-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'observed_total))
        (hot-max-total-ns (duration-literal->nanos benchmark-hot-max-total))
        (hot-target-total-ns
         (duration-literal->nanos benchmark-hot-target-total)))
    (and max-total-ns
         target-total-ns
         observed-total-ns
         (<= max-total-ns hot-max-total-ns)
         (<= target-total-ns hot-target-total-ns)
         (<= observed-total-ns target-total-ns))))

;; : (-> Alist Boolean)
(def (benchmark-fixture-integration-timing-pass? fixture)
  (let ((max-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'max_total))
        (target-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'target_total))
        (observed-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'observed_total))
        (integration-max-total-ns
         (duration-literal->nanos benchmark-integration-max-total)))
    (and max-total-ns
         target-total-ns
         observed-total-ns
         (< max-total-ns integration-max-total-ns)
         (< target-total-ns integration-max-total-ns)
         (< observed-total-ns integration-max-total-ns)
         (<= observed-total-ns target-total-ns))))

;;; Timing class contract:
;;; - Hot policy scenarios are the default and must keep a tight millisecond
;;;   budget; this is where Gerbil/Gambit language idioms should pay off.
;;; - Integration scenarios may include gxtest import closure, launcher, cache,
;;;   or subprocess overhead, but must say so through tags and stay subsecond.
;; : (-> Alist Boolean)
(def (benchmark-fixture-timing-class-contract-pass? fixture)
  (if (benchmark-fixture-integration-scope? fixture)
    (benchmark-fixture-integration-timing-pass? fixture)
    (benchmark-fixture-hot-timing-pass? fixture)))

;; benchmark-fixture-contract-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Validate the shared fixture contract without running the benchmark.
;;     %
;; : (forall (v) (-> [(Pair Symbol v)] Boolean))
;; benchmark-fixture-contract-pass?
;; : (-> Alist Boolean)
(def (benchmark-fixture-contract-pass? fixture)
  (and (null? (benchmark-fixture-missing-keys fixture))
       (benchmark-fixture-duration-fields-pass?
        benchmark-positive-number?
        fixture
        +benchmark-positive-duration-fields+)
       (benchmark-fixture-duration-fields-pass?
        benchmark-non-negative-number?
        fixture
        +benchmark-non-negative-duration-fields+)
       (benchmark-fixture-fields-pass?
        benchmark-positive-number?
        fixture
        +benchmark-positive-number-fields+)
       (benchmark-fixture-fields-pass?
        benchmark-non-negative-number?
        fixture
        +benchmark-non-negative-number-fields+)
       (andmap
        (lambda (pair)
          (let ((observed (benchmark-fixture-ref fixture (car pair)))
                (max-value (benchmark-fixture-ref fixture (cdr pair))))
            (and (number? observed)
                 (number? max-value)
                 (<= observed max-value))))
        +benchmark-observed-max-field-pairs+)
       (benchmark-fixture-fields-pass?
        benchmark-positive-integer?
        fixture
        +benchmark-positive-integer-fields+)
       (benchmark-fixture-unit-contract-pass? fixture)
       (benchmark-fixture-observed-timings-contract-pass? fixture)
       (benchmark-fixture-input-expected-comparison-pass? fixture)
       (benchmark-fixture-memory-contract-pass? fixture)
       (benchmark-fixture-timing-class-contract-pass? fixture)))

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
