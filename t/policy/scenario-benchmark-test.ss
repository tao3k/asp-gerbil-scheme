;;; -*- Gerbil -*-
;;; All policy scenario benchmarks must expose measured target budgets.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/scenario/benchmark-contract
        (only-in :std/sort sort)
        (only-in :std/sugar filter-map)
        (only-in :asp-gerbil-scheme/src/support/time duration-literal->nanos))
(export scenario-benchmark-policy-test)

(def +scenario-benchmark-include-dirs+
  '("t/scenarios/policy"))
(def +scenario-benchmark-file+ "benchmark.ss")

;; : (-> String String )
(def (scenario-benchmark-child root name)
  (if (equal? root ".")
    name
    (string-append root "/" name)))

;; : (-> String String (Maybe String))
(def (scenario-benchmark-path root entry)
  (let* ((scenario-root (scenario-benchmark-child root entry))
         (benchmark-path
          (scenario-benchmark-child scenario-root +scenario-benchmark-file+)))
    (and (eq? (file-type scenario-root) 'directory)
         (file-exists? benchmark-path)
         benchmark-path)))

;; : (-> (List String) )
(def (scenario-benchmark-paths root)
  (filter-map (lambda (entry)
                (scenario-benchmark-path root entry))
              (sort (directory-files root) string<?)))

;; : (-> (List String) (List String) )
(def (scenario-benchmark-paths/include-dirs roots)
  (if (null? roots)
    []
    (append (scenario-benchmark-paths (car roots))
            (scenario-benchmark-paths/include-dirs (cdr roots)))))

;; : (-> String BenchmarkContract )
(def (scenario-benchmark-contract path)
  (scenario-benchmark-contract/path path path))

;; : (-> BenchmarkContract Boolean )
(def (scenario-benchmark-targeted? contract)
  (let* ((target-ns
          (duration-literal->nanos (hash-get contract 'target_total)))
         (max-ns
          (duration-literal->nanos (hash-get contract 'max_total)))
         (regression-budget-ns
          (duration-literal->nanos (hash-get contract 'regression_budget)))
         (expected-over-input-budget-ns
          (duration-literal->nanos
           (hash-get contract 'expected_over_input_budget)))
         (target-rationale (hash-get contract 'targetRationale)))
    (and (eq? (hash-get contract 'benchmarkKind) 'scenario-e2e)
         (>= (hash-get contract 'sampleCount) 20)
         target-ns
         max-ns
         regression-budget-ns
         expected-over-input-budget-ns
         (> target-ns 0)
         (< target-ns max-ns)
         (> regression-budget-ns 0)
         (>= expected-over-input-budget-ns 0)
         (string? target-rationale)
         (> (string-length target-rationale) 0)
         (= max-ns (+ target-ns regression-budget-ns)))))

;; : (-> String (Maybe String))
(def (scenario-benchmark-path-without-target path)
  (and (not (scenario-benchmark-targeted?
             (scenario-benchmark-contract path)))
       path))

;; : (-> (List String) (List String) )
(def (scenario-benchmark-paths-without-targets paths)
  (filter-map scenario-benchmark-path-without-target paths))

(def scenario-benchmark-policy-test
  (test-suite "gerbil scheme harness policy scenario benchmark contracts"
    (test-case "all policy scenario benchmarks carry explicit target headroom"
      (let (paths (scenario-benchmark-paths/include-dirs
                   +scenario-benchmark-include-dirs+))
        (check (pair? paths) => #t)
        (check (scenario-benchmark-paths-without-targets paths)
               => [])))

    (test-case "scenario normalization rejects a one-second ceiling"
      (check-exception
       (scenario-benchmark-datum->contract
        '((benchmarkKind . scenario-e2e)
          (max_total . 1s)
          (target_total . 500ms)
          (regression_budget . 500ms)
          (expected_over_input_budget . 0ns)
          (targetRationale . "invalid boundary witness")
          (sampleCount . 20)))
       true))))
