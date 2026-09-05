;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent style policy support.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        :std/sort
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-style
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(export #t)


;; Relpath
(def +agent-style-policy-scenario-fixtures-root+ "t/scenarios/policy")
(def +agent-style-policy-r013-rule-id+ "GERBIL-SCHEME-AGENT-POLICY-013")
(def +agent-style-policy-scenario-timing-schema-id+
  "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
(def +agent-style-policy-self-apply-r013-clean-owners+
  ["src/benchmark/gate.ss"])

;; : (-> Path Boolean )
(def (agent-style-policy-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

;; : (-> String Boolean )
(def (agent-style-policy-scenario-entry? entry)
  (not (member entry '("." ".."))))

;; : (-> String Path )
(def (agent-style-policy-scenario-root entry)
  (path-expand entry +agent-style-policy-scenario-fixtures-root+))

;; : (-> Path Boolean )
(def (agent-style-policy-scenario-fixture-root? root)
  (and (agent-style-policy-directory? root)
       (agent-style-policy-directory? (path-expand "input" root))
       (agent-style-policy-directory? (path-expand "expected" root))))

;; : (-> (List Path) )
(def (agent-style-policy-scenario-roots)
  (filter agent-style-policy-scenario-fixture-root?
          (map agent-style-policy-scenario-root
               (filter agent-style-policy-scenario-entry?
                       (sort
                        (directory-files
                         +agent-style-policy-scenario-fixtures-root+)
                        string<?)))))

;; : (-> Path Path )
(def (agent-style-policy-scenario-benchmark-path root)
  (path-expand "benchmark.ss" root))

;; : (-> (List Path) )
(def (agent-style-policy-scenario-missing-benchmarks)
  (filter (lambda (path) (not (file-exists? path)))
          (map agent-style-policy-scenario-benchmark-path
               (agent-style-policy-scenario-roots))))

;; : (-> (List Timing) Boolean )
(def (agent-style-policy-scenario-timing-steps-measured? timings)
  (cond
   ((null? timings) #t)
   ((and (number? (hash-get (car timings) 'durationMs))
         (>= (hash-get (car timings) 'durationMs) 0))
    (agent-style-policy-scenario-timing-steps-measured? (cdr timings)))
   (else #f)))

;; project-index-source-file-by-path
;;   : (-> ProjectIndex Relpath (U SourceFile False) )
;;   | doc m%
;;       `project-index-source-file-by-path index path` returns the source
;;       file in `index` whose relative path matches `path`, or `#f` when the
;;       fixture does not contain that source.
;;
;;       # Examples
;;       ```scheme
;;       (project-index-source-file-by-path index "src/orders/core.ss")
;;       ;; => <source-file>
;;       ```
;;     %
(def (project-index-source-file-by-path index path)
  (let loop ((files (project-index-files index)))
    (cond
     ((null? files) #f)
     ((equal? (source-file-path (car files)) path) (car files))
     (else (loop (cdr files))))))

;; : (-> SourceFile (List Role) )
(def (source-file-higher-order-roles file)
  (map higher-order-fact-role
       (source-file-higher-order-forms file)))

;; : (-> String Path )
(def (agent-style-policy-scenario-path scenario-id)
  (path-expand scenario-id +agent-style-policy-scenario-fixtures-root+))

;; : (-> String HashTable )
(def (agent-style-policy-r013-scenario-context scenario-id)
  (let* ((scenario
          (make-policy-scenario
           scenario-id
           (agent-style-policy-scenario-path scenario-id)))
         (timing (policy-scenario-run/timed scenario))
         (result (hash-get timing 'result))
         (benchmark-contract (hash-get timing 'benchmarkContract))
         (before-matching
          (policy-scenario-findings
           result
           'before
           +agent-style-policy-r013-rule-id+))
         (after-matching
          (policy-scenario-findings
           result
           'after
           +agent-style-policy-r013-rule-id+))
         (finding (car before-matching))
         (details (type-finding-details finding)))
    (hash (timing timing)
          (result result)
          (timings (hash-get timing 'timings))
          (benchmarkContract benchmark-contract)
          (beforeMatching before-matching)
          (afterMatching after-matching)
          (finding finding)
          (details details)
          (qualityReference (hash-get details 'qualityReference))
          (expectedReferenceExamples
           (hash-get benchmark-contract 'expectedReferenceExamples))
          (expectedQualitySignals
           (hash-get benchmark-contract 'expectedQualitySignals)))))

;; : (-> ProjectIndex Relpath (List TypeFinding) )
(def (agent-style-policy-r013-findings-for-owner index path)
  (filter (lambda (finding)
            (equal? (type-finding-path finding) path))
          (typed-combinator-style-findings index)))

;; : (forall (a) (-> a (List a) Boolean ))
(def (agent-style-member? item items)
  (if (member item items) #t #f))

;; : (forall (a) (-> (List a) (List a) Boolean ))
(def (agent-style-all-members? items candidates)
  (cond
   ((null? items) #t)
   ((agent-style-member? (car items) candidates)
    (agent-style-all-members? (cdr items) candidates))
   (else #f)))

;; : (forall (a) (-> (List a) (List Integer) (List a) ))
(def (agent-style-select-indexes items indexes)
  (map (lambda (index) (list-ref items index)) indexes))

;; : (-> HashTable String String Void )
(def (agent-style-check-r013-scenario! context scenario-id feature)
  (let ((timing (hash-get context 'timing))
        (timings (hash-get context 'timings))
        (benchmark-contract (hash-get context 'benchmarkContract))
        (input-expected-comparison
         (hash-get (hash-get context 'timing) 'inputExpectedComparison))
        (before-matching (hash-get context 'beforeMatching))
        (after-matching (hash-get context 'afterMatching)))
    (check (hash-get timing 'schemaId)
           => +agent-style-policy-scenario-timing-schema-id+)
    (check (hash-get timing 'scenarioId) => scenario-id)
    (check (length timings) => 4)
    (check (agent-style-policy-scenario-timing-steps-measured? timings)
           => #t)
    (check (hash-get benchmark-contract 'feature) => feature)
    (check (hash-get benchmark-contract 'rule)
           => +agent-style-policy-r013-rule-id+)
    (check (hash-get timing 'performanceStatus) => "pass")
    (check (or (equal? (hash-get timing 'inputExpectedStatus) "pass")
               (equal? (hash-get timing 'inputExpectedStatus)
                       "pass annotated"))
           => #t)
    (check (or (equal? (hash-get (hash-get timing 'inputExpectedComparison)
                                 'status)
                       "pass")
               (equal? (hash-get (hash-get timing 'inputExpectedComparison)
                                 'status)
                       "pass annotated"))
           => #t)
    (check (or (equal? (hash-get input-expected-comparison 'relation)
                       "expected-faster")
               (equal? (hash-get input-expected-comparison 'relation)
                       "expected-not-faster"))
           => #t)
    (check (or (equal? (hash-get input-expected-comparison 'relation)
                       "expected-faster")
               (string? (hash-get input-expected-comparison 'annotation)))
           => #t)
    (check (length before-matching) => 1)
    (check after-matching => [])))

;; : (-> HashTable (List Integer) (List Integer) Void )
(def (agent-style-check-r013-quality-reference! context example-indexes signal-indexes)
  (let* ((benchmark-contract (hash-get context 'benchmarkContract))
         (quality-reference (hash-get context 'qualityReference))
         (expected-reference-examples
          (hash-get context 'expectedReferenceExamples))
         (expected-quality-signals
          (hash-get context 'expectedQualitySignals)))
    (check (hash-get quality-reference 'referencePattern)
           => (hash-get benchmark-contract 'expectedReferencePattern))
    (check (agent-style-all-members?
            (agent-style-select-indexes expected-reference-examples example-indexes)
            (hash-get quality-reference 'referenceExamples))
           => #t)
    (check (agent-style-all-members?
            (agent-style-select-indexes expected-quality-signals signal-indexes)
            (hash-get quality-reference 'qualitySignals))
           => #t)))

;; : (-> HashTable (List String) (List String) Void )
(def (agent-style-check-r013-scenario-learning! context sources axes)
  (let (benchmark-contract (hash-get context 'benchmarkContract))
    (check (agent-style-all-members?
            sources
            (hash-get benchmark-contract 'learnedStyleSources))
           => #t)
    (check (string? (hash-get benchmark-contract 'antiAiScaffoldIntent))
           => #t)
    (check (agent-style-all-members?
            axes
            (hash-get benchmark-contract 'scenarioQualityAxes))
           => #t)))

;; PolicyTest
