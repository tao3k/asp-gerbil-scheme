;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent POO policy support.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/scenario/policy
        (only-in :asp-gerbil-scheme/src/support/time duration-literal->nanos)
        :asp-gerbil-scheme/src/types/facade)
(export #t)


;; : (-> TimedPolicyScenarioResult Boolean )
(def (policy-scenario-benchmark-constrained? timing)
  (and (duration-literal->nanos (hash-get timing 'max_total))
       (equal? (hash-get timing 'performanceStatus) "pass")))

;; : (-> TimedPolicyScenarioResult Boolean )
(def (policy-scenario-benchmark-targeted? timing)
  (let* ((observed-ns
          (duration-literal->nanos (hash-get timing 'observed_total)))
         (target-ns
          (duration-literal->nanos (hash-get timing 'target_total)))
         (max-ns
          (duration-literal->nanos (hash-get timing 'max_total)))
         (regression-budget-ns
          (duration-literal->nanos (hash-get timing 'regression_budget))))
    (and observed-ns
         target-ns
         max-ns
         regression-budget-ns
         (<= observed-ns target-ns)
         (< target-ns max-ns)
         (= max-ns (+ observed-ns regression-budget-ns)))))

;; : (-> MaybeNumber String )
(def (poo-policy-performance-timing-status total-ms)
  (if (and (number? total-ms) (>= total-ms 0))
    "pass"
    "fail"))

;; : (-> (List Timing) Boolean )
(def (policy-scenario-timing-steps-measured? timings)
  (cond
   ((null? timings) #t)
   ((and (number? (hash-get (car timings) 'durationMs))
         (>= (hash-get (car timings) 'durationMs) 0))
    (policy-scenario-timing-steps-measured? (cdr timings)))
   (else #f)))

(def +poo-performance-scenario-ids+
  '("poo-clone-override-loop-performance"
    "poo-composition-loop-performance"
    "poo-construction-performance"
    "poo-debug-instrumentation-loop-performance"
    "poo-fq-type-construction-loop-performance"
    "poo-function-type-construction-loop-performance"
    "poo-integer-range-type-construction-loop-performance"
    "poo-lens-loop-performance"
    "poo-marlin-config-interface-large-object-performance"
    "poo-materialization-loop-performance"
    "poo-object-construction-loop-performance"
    "poo-object-iteration-loop-performance"
    "poo-real-dashboard-workflow-performance"
    "poo-slot-predicate-loop-performance"
    "poo-slot-projection-loop-performance"
    "poo-slot-spec-mutation-loop-performance"
    "poo-type-construction-loop-performance"
    "poo-validation-loop-performance"
    "poo-z-type-construction-loop-performance"))

(def +poo-real-dashboard-workflow-rule-ids+
  '("GERBIL-SCHEME-AGENT-POLICY-028"
    "GERBIL-SCHEME-AGENT-POLICY-029"
    "GERBIL-SCHEME-AGENT-POLICY-030"
    "GERBIL-SCHEME-AGENT-POLICY-031"
    "GERBIL-SCHEME-AGENT-POLICY-033"
    "GERBIL-SCHEME-AGENT-POLICY-035"
    "GERBIL-SCHEME-AGENT-POLICY-037"))

(def +poo-native-primary-scenario-ids+
  '("poo-clone-override-loop-performance"
    "poo-composition-loop-performance"
    "poo-construction-performance"
    "poo-debug-instrumentation-loop-performance"
    "poo-lens-loop-performance"
    "poo-marlin-config-interface-large-object-performance"
    "poo-materialization-loop-performance"
    "poo-object-construction-loop-performance"
    "poo-object-iteration-loop-performance"
    "poo-real-dashboard-workflow-performance"
    "poo-slot-predicate-loop-performance"
    "poo-slot-projection-loop-performance"
    "poo-slot-spec-mutation-loop-performance"
    "poo-validation-loop-performance"))

(def +poo-native-source-markers+
  '("(.o" "(.cc" "(.get" "(.ref" "(.mix" "(defpoo" "(defclass" "(defgeneric"))

(def +poo-adapter-construction-markers+
  '("(object<-alist (list"
    "(object<-alist\n   (list"
    "(object<-hash (list"
    "(object<-hash\n   (list"
    "(object<-fun (lambda"
    "(object<-fun\n   (lambda"))

;; : (-> String (List String) Boolean )
(def (string-list-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else (string-list-member? value (cdr values)))))

;; : (-> String String Boolean )
(def (string-contains-fragment? text fragment)
  (let ((text-length (string-length text))
        (fragment-length (string-length fragment)))
    (cond
     ((zero? fragment-length) #t)
     ((< text-length fragment-length) #f)
     (else
      (let loop ((offset 0))
        (cond
         ((> (+ offset fragment-length) text-length) #f)
         ((string=? (substring text offset (+ offset fragment-length))
                    fragment)
          #t)
         (else (loop (+ offset 1)))))))))

;; : (-> String (List String) Boolean )
(def (string-contains-any-fragment? text fragments)
  (cond
   ((null? fragments) #f)
   ((string-contains-fragment? text (car fragments)) #t)
   (else (string-contains-any-fragment? text (cdr fragments)))))

;; : (-> Path Boolean )
(def (policy-source-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

;; : (-> String Boolean )
(def (policy-source-directory-entry? entry)
  (not (or (equal? entry ".")
           (equal? entry ".."))))

;; : (-> String String Boolean )
(def (string-suffix-fragment? text suffix)
  (let ((text-length (string-length text))
        (suffix-length (string-length suffix)))
    (and (>= text-length suffix-length)
         (string=? (substring text
                              (- text-length suffix-length)
                              text-length)
                   suffix))))

;; : (-> Path (List Path) )
(def (policy-source-files root)
  (let (paths [])
    (def (walk dir)
      (for-each
       (lambda (entry)
         (let (path (path-expand entry dir))
           (cond
            ((not (policy-source-directory-entry? entry))
             #!void)
            ((policy-source-directory? path)
             (walk path))
            ((string-suffix-fragment? entry ".ss")
             (set! paths (cons path paths)))
            (else #!void))))
       (directory-files dir)))
    (walk root)
    (reverse paths)))

;; : (-> Path String )
(def (read-policy-source-file path)
  (call-with-input-file path
    (lambda (port)
      (call-with-output-string
       []
       (lambda (out)
         (let loop ()
           (let (line (read-line port))
             (unless (eof-object? line)
               (display line out)
               (newline out)
               (loop)))))))))

;; : (-> Path String )
(def (policy-source-tree-text root)
  (apply string-append
         (map read-policy-source-file
              (policy-source-files root))))

;; : (-> PolicyScenarioResult Symbol (List String) (List TypeFinding) )
(def (policy-scenario-findings/rules result phase rule-ids)
  (apply append
         (map (lambda (rule-id)
                (policy-scenario-findings result phase rule-id))
              rule-ids)))

;; : (-> String (List TypeFinding) Boolean )
(def (policy-rule-present? rule-id findings)
  (if (member rule-id (map type-finding-rule-id findings)) #t #f))

;; : (-> String String )
(def (poo-performance-scenario-benchmark-path scenario-id)
  (string-append "t/scenarios/policy/" scenario-id "/benchmark.ss"))

;; : (-> (List String) (List String) )
(def (missing-poo-performance-scenario-benchmarks scenario-ids)
  (cond
   ((null? scenario-ids) [])
   ((file-exists? (poo-performance-scenario-benchmark-path (car scenario-ids)))
    (missing-poo-performance-scenario-benchmarks (cdr scenario-ids)))
   (else
    (cons (poo-performance-scenario-benchmark-path (car scenario-ids))
          (missing-poo-performance-scenario-benchmarks (cdr scenario-ids))))))

;; : (-> String BenchmarkContract )
(def (poo-performance-scenario-benchmark-contract scenario-id)
  (policy-scenario-benchmark-contract
   (make-policy-scenario
    scenario-id
    (string-append "t/scenarios/policy/" scenario-id))))

;; : (-> BenchmarkContract Boolean )
(def (poo-performance-scenario-hot-path-exemption-complete? contract)
  (and (hash-get contract 'hotPathExemption)
       (pair? (hash-get contract 'hotPathEvidence))
       (hash-get contract 'styleRewriteBoundary)))

;; : (-> (List String) (List String) )
(def (poo-performance-scenarios-missing-hot-path-exemptions scenario-ids)
  (cond
   ((null? scenario-ids) [])
   ((poo-performance-scenario-hot-path-exemption-complete?
     (poo-performance-scenario-benchmark-contract (car scenario-ids)))
    (poo-performance-scenarios-missing-hot-path-exemptions
     (cdr scenario-ids)))
   (else
    (cons (car scenario-ids)
          (poo-performance-scenarios-missing-hot-path-exemptions
           (cdr scenario-ids))))))

;; : (-> BenchmarkContract Boolean )
(def (poo-performance-scenario-native-poo-primary? contract)
  (and (hash-get contract 'nativePooPrimary)
       (string-list-member?
        "native-poo-primary"
        (hash-get contract 'hotPathEvidence))))

;; : (-> (List String) (List String) )
(def (poo-performance-scenarios-missing-native-poo-primary scenario-ids)
  (cond
   ((null? scenario-ids) [])
   ((poo-performance-scenario-native-poo-primary?
     (poo-performance-scenario-benchmark-contract (car scenario-ids)))
    (poo-performance-scenarios-missing-native-poo-primary
     (cdr scenario-ids)))
   (else
    (cons (car scenario-ids)
          (poo-performance-scenarios-missing-native-poo-primary
           (cdr scenario-ids))))))

;; : (-> String Boolean )
(def (poo-performance-scenario-native-source-complete? scenario-id)
  (let* ((scenario
          (make-policy-scenario
           scenario-id
           (string-append "t/scenarios/policy/" scenario-id)))
         (contract (poo-performance-scenario-benchmark-contract scenario-id))
         (source-text
          (policy-source-tree-text
           (policy-scenario-expected-root scenario))))
    (and (string-contains-any-fragment?
          source-text
          +poo-native-source-markers+)
         (or (hash-get contract 'adapterBoundary)
             (not (string-contains-any-fragment?
                   source-text
                   +poo-adapter-construction-markers+))))))

;; : (-> (List String) (List String) )
(def (poo-performance-scenarios-missing-native-source scenario-ids)
  (cond
   ((null? scenario-ids) [])
   ((poo-performance-scenario-native-source-complete? (car scenario-ids))
    (poo-performance-scenarios-missing-native-source (cdr scenario-ids)))
   (else
    (cons (car scenario-ids)
          (poo-performance-scenarios-missing-native-source
           (cdr scenario-ids))))))

;; PolicyTest
