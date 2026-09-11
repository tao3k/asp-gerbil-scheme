;;; -*- Gerbil -*-
;;; Lightweight benchmark contract normalization for policy scenarios.

(import :gerbil/gambit
        (only-in :std/sugar hash hash-put!)
        (only-in :asp-gerbil-scheme/src/benchmark/fixture-model
                 benchmark-scenario-max-total)
        :asp-gerbil-scheme/src/support/time)

(export scenario-benchmark-contract/path
        scenario-benchmark-datum->contract
        scenario-benchmark-max-total)

;; : (List BenchmarkContractKey)
(def +scenario-benchmark-required-duration-fields+
  '(max_total
    target_total
    regression_budget
    expected_over_input_budget))

;; : (List BenchmarkContractKey)
(def +scenario-benchmark-required-value-fields+
  '(benchmarkKind targetRationale))

;; : (List (Cons BenchmarkContractKey BenchmarkContractValue))
(def +scenario-benchmark-default-fields+
  '((expected_over_input_note . #f)
    (sampleCount . 20)
    (purpose . "scenario timing")
    (feature . "policy-scenario")
    (rule . #f)
    (optimizationFocus . #f)
    (inputShape . #f)
    (expectedOutcome . #f)
    (misuseGuard . #f)
    (nativePooPrimary . #f)
    (adapterBoundary . #f)
    (expectedReferencePattern . #f)
    (expectedReferenceExamples . ())
    (expectedQualitySignals . ())
    (learnedStyleSources . ())
    (antiAiScaffoldIntent . #f)
    (scenarioQualityAxes . ())
    (hotPathExemption . #f)
    (hotPathEvidence . ())
    (styleRewriteBoundary . #f)
    (measurementPhases . ("collect-before"
                          "collect-after"
                          "policy-before"
                          "policy-after"))
    (tags . ())))

;;; Fixture benchmark contract:
;;; - A scenario must carry benchmark.ss beside input/ and expected/.
;;; - The file is data, not code: an alist such as ((max_total . 1s)).
;;; - This module avoids loading parser and policy facades for metadata sweeps.
;; scenario-benchmark-contract/path
;;   : (-> Id Path BenchmarkContract)
;;   | doc m%
;;       Reads the scenario-owned benchmark datum and normalizes it before a
;;       policy runner can use the timing contract.
;; # Examples
;; ```scheme
;; (scenario-benchmark-contract/path 'scenario "benchmark.ss")
;; => normalized benchmark contract or a missing-fixture error
;; ```
;;     %
(def (scenario-benchmark-contract/path scenario-id path)
  (if (file-exists? path)
    (scenario-benchmark-datum->contract
     (call-with-input-file path read))
    (error "policy scenario requires benchmark.ss" scenario-id path)))

;;; Contract normalization boundary:
;;; - Keep fixture syntax small and stable.
;;; - Timed runners receive hash data so tests and future JSON packets do not
;;;   depend on alist shape.
;;; - Target and regression budget are required so performance guidance exposes
;;;   optimization headroom instead of embedding stale observations in fixtures.
;; scenario-benchmark-datum->contract
;;   : (-> BenchmarkContractDatum BenchmarkContract)
;;   | doc m%
;;       Converts fixture alist data into a schema-versioned hash with required
;;       gates validated and optional fields defaulted.
;; # Examples
;; ```scheme
;; (scenario-benchmark-datum->contract '((max_total . 25ms) ...))
;; => schema-versioned benchmark contract hash
;; ```
;;     %
(def (scenario-benchmark-datum->contract datum)
  (let (contract
        (hash (schemaId "agent.semantic-protocols.gerbil-scheme-policy-scenario-benchmark")
              (schemaVersion "4")))
    (scenario-benchmark-put-fields!
     contract
     datum
     +scenario-benchmark-required-duration-fields+
     scenario-benchmark-required-duration)
    (scenario-benchmark-put-fields!
     contract
     datum
     +scenario-benchmark-required-value-fields+
     scenario-benchmark-required-value)
    (unless (eq? (hash-get contract 'benchmarkKind) 'scenario-e2e)
      (error "policy scenario benchmark requires scenario-e2e kind"
             (hash-get contract 'benchmarkKind)))
    (scenario-benchmark-put-defaults!
     contract
     datum
     +scenario-benchmark-default-fields+)
    (let ((maximum
           (duration-literal->nanos (hash-get contract 'max_total)))
          (target
           (duration-literal->nanos (hash-get contract 'target_total)))
          (regression
           (duration-literal->nanos
            (hash-get contract 'regression_budget)))
          (expected-over-input
           (duration-literal->nanos
            (hash-get contract 'expected_over_input_budget)))
          (scenario-maximum
           (duration-literal->nanos benchmark-scenario-max-total))
          (sample-count (hash-get contract 'sampleCount)))
      (unless (and (> maximum 0)
                   (> target 0)
                   (> regression 0)
                   (>= expected-over-input 0)
                   (= maximum (+ target regression))
                   (< maximum scenario-maximum)
                   (< target scenario-maximum))
        (error "policy scenario benchmark has inconsistent duration budgets"
               target regression maximum expected-over-input))
      (unless (and (integer? sample-count) (>= sample-count 20))
        (error "policy scenario benchmark requires at least twenty samples for p95 admission"
               sample-count)))
    contract))

;; scenario-benchmark-put-fields!
;;   : (-> BenchmarkContract BenchmarkContractDatum (List BenchmarkContractKey)
;;          Procedure
;;          BenchmarkContract)
;;   | doc m%
;;       Projects required fixture keys into the runtime contract through the
;;       supplied validator, so malformed timing fields fail at normalization.
;; # Examples
;; ```scheme
;; (scenario-benchmark-put-fields! contract datum '(max_total) value-ref)
;; => contract includes a validated max_total field
;; ```
;;     %
(def (scenario-benchmark-put-fields! contract datum keys value-ref)
  (for-each (lambda (key)
              (hash-put! contract key (value-ref datum key)))
            keys)
  contract)

;; scenario-benchmark-put-defaults!
;;   : (-> BenchmarkContract BenchmarkContractDatum
;;          Alist
;;          BenchmarkContract)
;;   | doc m%
;;       Adds optional fixture fields before the version-four timing and sample
;;       admission checks run.
;; # Examples
;; ```scheme
;; (scenario-benchmark-put-defaults! contract datum defaults)
;; => contract receives each absent optional default
;; ```
;;     %
(def (scenario-benchmark-put-defaults! contract datum defaults)
  (for-each (lambda (entry)
              (let (key (car entry))
                (hash-put!
                 contract
                 key
                 (scenario-benchmark-value datum key (cdr entry)))))
            defaults)
  contract)

;;; Required benchmark field lookup:
;;; - Missing target/headroom fields are contract errors, not optional legacy
;;;   defaults; otherwise new scenarios silently fall back to unhelpful gates.
;; : (-> BenchmarkContractDatum BenchmarkContractKey BenchmarkContractValue )
(def (scenario-benchmark-required-value datum key)
  (let (entry (and (list? datum) (assoc key datum)))
    (if entry
      (cdr entry)
      (error "policy scenario benchmark missing required field" key))))

;; : (-> BenchmarkContractDatum BenchmarkContractKey DurationLiteral )
(def (scenario-benchmark-required-duration datum key)
  (let (value (scenario-benchmark-required-value datum key))
    (if (duration-literal? value)
      value
      (error "policy scenario benchmark invalid duration literal" key value))))

;;; Datum lookup boundary:
;;; - Optional benchmark metadata falls back to explicit contract defaults.
;; : (-> BenchmarkContractDatum BenchmarkContractKey BenchmarkContractValue BenchmarkContractValue )
(def (scenario-benchmark-value datum key default)
  (let (entry (and (list? datum) (assoc key datum)))
    (if entry (cdr entry) default)))

;;; Performance gate boundary:
;;; - #f means the scenario records timing without enforcing a ceiling.
;;; - benchmark.ss remains the owner for configured time budgets.
;; scenario-benchmark-max-total
;;   : (-> BenchmarkContract (U Integer False))
;;   | doc m%
;;       Returns the normalized wall-clock ceiling selected by the scenario
;;       receipt without re-reading benchmark fixture data.
;; # Examples
;; ```scheme
;; (scenario-benchmark-max-total contract)
;; => contract max_total duration literal
;; ```
;;     %
(def (scenario-benchmark-max-total contract)
  (hash-get contract 'max_total))
