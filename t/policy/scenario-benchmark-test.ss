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
(def +scenario-benchmark-input-timing-names+
  '("collect-before" "policy-before"))
(def +scenario-benchmark-expected-timing-names+
  '("collect-after" "policy-after"))

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

;; : (-> BenchmarkTimingName String Boolean)
(def (scenario-benchmark-timing-name-equal? candidate name)
  (cond
   ((symbol? candidate) (equal? (symbol->string candidate) name))
   ((string? candidate) (equal? candidate name))
   (else #f)))

;; : (-> Alist String Boolean)
(def (scenario-benchmark-observed-timing-name? timing name)
  (let (entry (and (list? timing) (assoc 'name timing)))
    (and entry
         (scenario-benchmark-timing-name-equal? (cdr entry) name))))

;; : (-> (List Alist) String Boolean)
(def (scenario-benchmark-observed-timing-present? timings name)
  (cond
   ((null? timings) #f)
   ((scenario-benchmark-observed-timing-name? (car timings) name) #t)
   (else
    (scenario-benchmark-observed-timing-present? (cdr timings) name))))

;; : (-> (List Alist) (List String) Boolean)
(def (scenario-benchmark-observed-timings-present? timings names)
  (cond
   ((null? names) #t)
   ((scenario-benchmark-observed-timing-present? timings (car names))
    (scenario-benchmark-observed-timings-present? timings (cdr names)))
   (else #f)))

;; : (-> Alist (List String) Boolean)
(def (scenario-benchmark-observed-timing-selected? timing names)
  (cond
   ((null? names) #f)
   ((scenario-benchmark-observed-timing-name? timing (car names)) #t)
   (else
    (scenario-benchmark-observed-timing-selected? timing (cdr names)))))

;; : (-> Alist Number)
(def (scenario-benchmark-observed-timing-duration-ms timing)
  (let (entry (assoc 'durationMs timing))
    (if entry (cdr entry) 0)))

;; : (-> Alist Number)
(def (scenario-benchmark-observed-timing-duration-nanos timing)
  (let ((duration-ns-entry (assoc 'durationNs timing))
        (duration-ms-entry (assoc 'durationMs timing)))
    (cond
     (duration-ns-entry (cdr duration-ns-entry))
     (duration-ms-entry (* (cdr duration-ms-entry) 1000000))
     (else 0))))

;; : (-> (List Alist) (List String) Number)
(def (scenario-benchmark-observed-timings-total-ms timings names)
  (cond
   ((null? timings) 0)
   ((scenario-benchmark-observed-timing-selected? (car timings) names)
    (+ (scenario-benchmark-observed-timing-duration-ms (car timings))
       (scenario-benchmark-observed-timings-total-ms (cdr timings) names)))
  (else
    (scenario-benchmark-observed-timings-total-ms (cdr timings) names))))

;; : (-> (List Alist) (List String) Number)
(def (scenario-benchmark-observed-timings-total-nanos timings names)
  (cond
   ((null? timings) 0)
   ((scenario-benchmark-observed-timing-selected? (car timings) names)
    (+ (scenario-benchmark-observed-timing-duration-nanos (car timings))
       (scenario-benchmark-observed-timings-total-nanos
        (cdr timings)
        names)))
   (else
    (scenario-benchmark-observed-timings-total-nanos (cdr timings) names))))

;; : (-> BenchmarkContract Boolean)
(def (scenario-benchmark-input-expected-annotation? contract)
  (let ((note (hash-get contract 'expected_over_input_note))
        (rationale (hash-get contract 'targetRationale)))
    (or (and (string? note) (> (string-length note) 0))
        (and (string? rationale) (> (string-length rationale) 0)))))

;; : (-> Any Boolean)
(def (scenario-benchmark-non-negative-number? value)
  (and (number? value) (>= value 0)))

;; : (-> BenchmarkContract Symbol Symbol Boolean)
(def (scenario-benchmark-observed-under-max? contract observed-key max-key)
  (let ((observed (hash-get contract observed-key))
        (max-value (hash-get contract max-key)))
    (and (scenario-benchmark-non-negative-number? observed)
         (number? max-value)
         (<= observed max-value))))

;; : (-> BenchmarkContract Boolean )
(def (scenario-benchmark-targeted? contract)
  (let* ((observed-ns
          (duration-literal->nanos (hash-get contract 'observed_total)))
         (target-ns
          (duration-literal->nanos (hash-get contract 'target_total)))
         (max-ns
          (duration-literal->nanos (hash-get contract 'max_total)))
         (regression-budget-ns
          (duration-literal->nanos (hash-get contract 'regression_budget)))
         (expected-over-input-budget-ns
          (duration-literal->nanos
           (hash-get contract 'expected_over_input_budget)))
         (observed-timings (hash-get contract 'observedTimings))
         (target-rationale (hash-get contract 'targetRationale))
         (input-total-ns
          (scenario-benchmark-observed-timings-total-nanos
           observed-timings
           +scenario-benchmark-input-timing-names+))
         (expected-total-ns
          (scenario-benchmark-observed-timings-total-nanos
           observed-timings
           +scenario-benchmark-expected-timing-names+)))
    (and observed-ns
         target-ns
         max-ns
         regression-budget-ns
         expected-over-input-budget-ns
         (pair? observed-timings)
         (string? target-rationale)
         (scenario-benchmark-observed-timings-present?
          observed-timings
          +scenario-benchmark-input-timing-names+)
         (scenario-benchmark-observed-timings-present?
          observed-timings
          +scenario-benchmark-expected-timing-names+)
         (<= observed-ns target-ns)
         (< target-ns max-ns)
         (<= expected-total-ns
             (+ input-total-ns expected-over-input-budget-ns))
         (or (< expected-total-ns input-total-ns)
             (scenario-benchmark-input-expected-annotation? contract))
         (scenario-benchmark-observed-under-max?
          contract
          'observedCollectMs
          'maxCollectMs)
         (scenario-benchmark-observed-under-max?
          contract
          'observedParseMs
          'maxParseMs)
         (scenario-benchmark-observed-under-max?
          contract
          'observedFileMs
          'maxFileMs)
         (scenario-benchmark-observed-under-max?
          contract
          'observedPhaseMs
          'maxPhaseMs)
         (= max-ns (+ observed-ns regression-budget-ns)))))

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
    (test-case "all policy scenario benchmarks carry measured target budgets"
      (let (paths (scenario-benchmark-paths/include-dirs
                   +scenario-benchmark-include-dirs+))
        (check (pair? paths) => #t)
        (check (scenario-benchmark-paths-without-targets paths)
               => [])))))
