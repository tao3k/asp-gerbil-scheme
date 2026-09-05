;;; -*- Gerbil -*-
;;; Gerbil scheme harness macro expansion IO policy tests.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :policy/fixtures
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade)

(export agent-macro-io-policy-test)

;; PolicyTest
(def agent-macro-io-policy-test
  (test-suite "gerbil scheme harness macro expansion IO policy"
    (test-case "agent policy rejects file IO inside a macro owner"
      (let* ((root ".run/policy-macro-expansion-io")
             (source-dir (string-append root "/src/macros")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/macros)\n")
        (write-text
         (string-append source-dir "/load.ss")
         ";;; -*- Gerbil -*-\n(package: sample/macros)\n(export load-fragment)\n(defsyntax (load-fragment stx)\n  (syntax-case stx ()\n    ((_ path)\n     (let* ((path-value (syntax->datum (syntax path)))\n            (forms (call-with-input-file path-value\n                     (lambda (port)\n                       (let loop ((out '()))\n                         (let (form (read port))\n                           (if (eof-object? form)\n                             (reverse out)\n                             (loop (cons form out)))))))))\n       (datum->syntax (syntax stx) (cons 'begin forms))))))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-040" findings))
               (finding (car matching))
               (details (type-finding-details finding)))
          (check (length matching) => 1)
          (check (type-finding-path finding) => "src/macros/load.ss")
          (check (hash-get details 'kind) => "macro-expansion-io-boundary")
          (check (hash-get details 'callee) => "call-with-input-file")
          (check (if (member "syntax-payload-instead-of-file-read"
                             (hash-get details 'repairStrategies))
                   #t
                   #f)
                 => #t))))
    (test-case "agent policy accepts thin syntax payload macro"
      (let* ((root ".run/policy-macro-expansion-io-thin")
             (source-dir (string-append root "/src/macros")))
        (reset-fixture-root root)
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir (string-append root "/src"))
        (ensure-dir source-dir)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/macros)\n")
        (write-text
         (string-append source-dir "/load.ss")
         ";;; -*- Gerbil -*-\n(package: sample/macros)\n(export define-fragment)\n(defsyntax (define-fragment stx)\n  (syntax-case stx ()\n    ((_ binding form ...)\n     (syntax (def binding (begin form ...))))))\n")
        (let* ((index (collect-project root))
               (findings (run-agent-policy index))
               (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-040" findings)))
          (check matching => []))))
    (test-case "agent policy validates macro expansion IO scenario under performance gate"
      (let* ((scenario
              (make-policy-scenario
               "macro-expansion-io-boundary"
               "t/scenarios/policy/macro-expansion-io-boundary"))
             (timing (policy-scenario-run/timed scenario))
             (result (hash-get timing 'result))
             (benchmark-contract (hash-get timing 'benchmarkContract))
             (before-matching
              (policy-scenario-findings
               result
               'before
               "GERBIL-SCHEME-AGENT-POLICY-040"))
             (after-matching
              (policy-scenario-findings
               result
               'after
               "GERBIL-SCHEME-AGENT-POLICY-040"))
             (finding (car before-matching))
             (details (type-finding-details finding)))
        (check (hash-get timing 'schemaId)
               => "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
        (check (hash-get timing 'scenarioId) => "macro-expansion-io-boundary")
        (check (hash-get timing 'performanceStatus) => "pass")
        (check (or (equal? (hash-get timing 'inputExpectedStatus) "pass")
                   (equal? (hash-get timing 'inputExpectedStatus)
                           "pass annotated"))
               => #t)
        (check (hash-get benchmark-contract 'feature)
               => "macro-expansion-io-boundary")
        (check (hash-get benchmark-contract 'rule)
               => "GERBIL-SCHEME-AGENT-POLICY-040")
        (check (length before-matching) => 1)
        (check after-matching => [])
        (check (type-finding-path finding) => "src/macros/load.ss")
        (check (hash-get details 'kind) => "macro-expansion-io-boundary")
        (check (hash-get details 'callee) => "call-with-input-file")))))
