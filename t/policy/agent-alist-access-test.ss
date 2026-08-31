;;; -*- Gerbil -*-
;;; Gerbil scheme harness repeated alist lookup policy tests.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :policy/fixtures
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade)

(export agent-alist-access-policy-test)

;; PolicyTest
(def agent-alist-access-policy-test
  (test-suite "gerbil scheme harness alist access policy"
    (test-case "agent policy rejects repeated inline assq cdr lookups"
      (let* ((root ".run/policy-alist-inline")
             (source-dir (string-append root "/src/profile")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/profile)\n")
        (write-text
         (string-append source-dir "/bad.ss")
         ";;; -*- Gerbil -*-\n(def (profile-name profile)\n  (cdr (assq 'name profile)))\n(def (profile-owner profile)\n  (cdr (assq 'owner profile)))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-022" findings))
               (finding (car matching))
               (details (type-finding-details finding)))
          (check (length matching) => 1)
          (check (type-finding-path finding) => "src/profile/bad.ss")
          (check (hash-get details 'kind) => "repeated-inline-alist-lookup")
          (check (hash-get details 'lookupCount) => 2)
          (check (if (member "alist:name" (hash-get details 'fieldKeys)) #t #f)
                 => #t)
          (check (if (member "alist:owner" (hash-get details 'fieldKeys)) #t #f)
                 => #t)
          (check (if (member "profile-name" (hash-get details 'callers)) #t #f)
                 => #t)
          (check (if (member "profile-owner" (hash-get details 'callers)) #t #f)
                 => #t))))
    (test-case "agent policy accepts one named alist bridge"
      (let* ((root ".run/policy-alist-helper")
             (source-dir (string-append root "/src/profile")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/profile)\n")
        (write-text
         (string-append source-dir "/good.ss")
         ";;; -*- Gerbil -*-\n(def (profile-ref profile key)\n  (cdr (assq key profile)))\n(def (profile-name profile)\n  (profile-ref profile 'name))\n(def (profile-owner profile)\n  (profile-ref profile 'owner))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-022" findings)))
          (check matching => []))))
    (test-case "agent policy validates alist index scenario under performance gate"
      (let* ((scenario
              (make-policy-scenario
               "alist-index-boundary"
               "t/scenarios/policy/alist-index-boundary"))
             (timing (policy-scenario-run/timed scenario))
             (result (hash-get timing 'result))
             (timings (hash-get timing 'timings))
             (benchmark-contract (hash-get timing 'benchmarkContract))
             (comparison (hash-get timing 'inputExpectedComparison))
             (before-matching
              (policy-scenario-findings
               result
               'before
               "GERBIL-SCHEME-AGENT-POLICY-022"))
             (after-matching
              (policy-scenario-findings
               result
               'after
               "GERBIL-SCHEME-AGENT-POLICY-022"))
             (finding (car before-matching))
             (details (type-finding-details finding)))
        (check (hash-get timing 'schemaId)
               => "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
        (check (hash-get timing 'scenarioId) => "alist-index-boundary")
        (check (length timings) => 4)
        (check (hash-get timing 'performanceStatus) => "pass")
        (check (or (equal? (hash-get timing 'inputExpectedStatus) "pass")
                   (equal? (hash-get timing 'inputExpectedStatus)
                           "pass annotated"))
               => #t)
        (check (hash-get benchmark-contract 'feature) => "alist-index-boundary")
        (check (hash-get benchmark-contract 'rule)
               => "GERBIL-SCHEME-AGENT-POLICY-022")
        (check (string? (hash-get comparison 'annotation)) => #t)
        (check (length before-matching) => 1)
        (check after-matching => [])
        (check (type-finding-path finding) => "src/events/access.ss")
        (check (hash-get details 'kind) => "repeated-inline-alist-lookup")
        (check (hash-get details 'lookupCount) => 4)
        (check (if (member "alist:name" (hash-get details 'fieldKeys)) #t #f)
               => #t)
        (check (if (member "alist:owner" (hash-get details 'fieldKeys)) #t #f)
               => #t)
        (check (if (member "alist:route" (hash-get details 'fieldKeys)) #t #f)
               => #t)
        (check (if (member "alist:priority" (hash-get details 'fieldKeys)) #t #f)
               => #t)))
    (test-case "agent policy validates keyword option scenario under performance gate"
      (let* ((scenario
              (make-policy-scenario
               "keyword-option-boundary"
               "t/scenarios/policy/keyword-option-boundary"))
             (timing (policy-scenario-run/timed scenario))
             (result (hash-get timing 'result))
             (timings (hash-get timing 'timings))
             (benchmark-contract (hash-get timing 'benchmarkContract))
             (comparison (hash-get timing 'inputExpectedComparison))
             (before-matching
              (policy-scenario-findings
               result
               'before
               "GERBIL-SCHEME-AGENT-POLICY-022"))
             (after-matching
              (policy-scenario-findings
               result
               'after
               "GERBIL-SCHEME-AGENT-POLICY-022"))
             (finding (car before-matching))
             (details (type-finding-details finding)))
        (check (hash-get timing 'schemaId)
               => "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
        (check (hash-get timing 'scenarioId) => "keyword-option-boundary")
        (check (length timings) => 4)
        (check (hash-get timing 'performanceStatus) => "pass")
        (check (or (equal? (hash-get timing 'inputExpectedStatus) "pass")
                   (equal? (hash-get timing 'inputExpectedStatus)
                           "pass annotated"))
               => #t)
        (check (hash-get benchmark-contract 'feature) => "keyword-option-boundary")
        (check (hash-get benchmark-contract 'rule)
               => "GERBIL-SCHEME-AGENT-POLICY-022")
        (check (string? (hash-get comparison 'annotation)) => #t)
        (check (length before-matching) => 1)
        (check after-matching => [])
        (check (type-finding-path finding) => "src/reports/options.ss")
        (check (hash-get details 'kind) => "repeated-inline-alist-lookup")
        (check (hash-get details 'lookupCount) => 3)
        (check (if (member "alist:format" (hash-get details 'fieldKeys)) #t #f)
               => #t)
        (check (if (member "alist:limit" (hash-get details 'fieldKeys)) #t #f)
               => #t)
        (check (if (member "alist:metadata" (hash-get details 'fieldKeys)) #t #f)
               => #t)
        (check (if (member "gerbil-keyword-optional-parameters"
                           (hash-get details 'repairStrategies))
                 #t
                 #f)
               => #t)))))
