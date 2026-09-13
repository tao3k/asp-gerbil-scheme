;;; -*- Gerbil -*-
;;; Benchmark fixture contract owns semantic admission over model fields.
;;; Invariant: contract evaluation performs no timing or receipt emission.

(import :asp-gerbil-scheme/src/benchmark/fixture-model
        :asp-gerbil-scheme/src/support/time)

(export benchmark-fixture-regression-budget-contract-pass?
        benchmark-fixture-kind-contract-pass?
        benchmark-fixture-scenario-duration-contract-pass?
        benchmark-fixture-contract-pass?)

;; : (-> Alist Boolean)
(def (benchmark-fixture-regression-budget-contract-pass? fixture)
  (let ((max-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'max_total))
        (target-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'target_total))
        (regression-budget-ns
         (benchmark-fixture-duration-field-nanos fixture 'regression_budget)))
    (and max-total-ns
         target-total-ns
         regression-budget-ns
         (= max-total-ns (+ target-total-ns regression-budget-ns)))))

;; : (-> Alist Boolean)
(def (benchmark-fixture-kind-contract-pass? fixture)
  (eq? (benchmark-fixture-ref fixture 'benchmarkKind) 'scenario-e2e))

;; benchmark-fixture-scenario-duration-contract-pass?
;;   : (-> Alist Boolean)
;;   | doc m%
;;       Keep every scenario-e2e fixture below the shared one-second ceiling.
;;       Scenario tags describe behavior; they do not select a timing class.
;;       Micro-kernels have a separate ns/op contract.
;;     %
(def (benchmark-fixture-scenario-duration-contract-pass? fixture)
  (let ((max-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'max_total))
        (target-total-ns
         (benchmark-fixture-duration-field-nanos fixture 'target_total))
        (scenario-max-total-ns
         (duration-literal->nanos benchmark-scenario-max-total)))
    (and max-total-ns
         target-total-ns
         (< max-total-ns scenario-max-total-ns)
         (< target-total-ns scenario-max-total-ns))))

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
       (benchmark-fixture-kind-contract-pass? fixture)
       (benchmark-fixture-duration-fields-pass?
        benchmark-positive-number?
        fixture
        +benchmark-positive-duration-fields+)
       (benchmark-fixture-duration-fields-pass?
        benchmark-non-negative-number?
        fixture
        +benchmark-non-negative-duration-fields+)
       (benchmark-fixture-fields-pass?
        benchmark-positive-integer?
        fixture
        +benchmark-positive-integer-fields+)
       (>= (benchmark-fixture-ref fixture 'sampleCount)
           benchmark-minimum-sample-count)
       (benchmark-fixture-regression-budget-contract-pass? fixture)
       (benchmark-fixture-scenario-duration-contract-pass? fixture)))
