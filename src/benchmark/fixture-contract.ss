;;; -*- Gerbil -*-
;;; Benchmark fixture contract owns semantic admission over model fields.
;;; Invariant: contract evaluation performs no timing or receipt emission.

(import :asp-gerbil-scheme/src/benchmark/fixture-model
        :asp-gerbil-scheme/src/support/time
        (only-in :std/sugar andmap ormap foldl))

(export benchmark-fixture-memory-contract-pass?
        benchmark-fixture-observed-timings-contract-pass?
        benchmark-fixture-input-expected-comparison-pass?
        benchmark-fixture-integration-scope?
        benchmark-fixture-timing-class-contract-pass?
        benchmark-fixture-contract-pass?)

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
