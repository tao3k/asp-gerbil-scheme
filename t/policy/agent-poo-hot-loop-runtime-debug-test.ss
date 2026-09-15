;;; -*- Gerbil -*-
;;; gerbil scheme harness agent POO hot loop runtime debug policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        (only-in :std/text/json read-json)
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(import :policy/agent-poo-support)
(export agent-poo-hot-loop-runtime-debug-policy-test)

;; PolicyTest
(def agent-poo-hot-loop-runtime-debug-policy-test
  (test-suite "gerbil scheme harness agent POO hot loop runtime debug policy"
    (test-case "agent policy redirects loop-local POO debug instrumentation to one setup boundary"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-debug-instrumentation-loop-performance"
                   "t/scenarios/policy/poo-debug-instrumentation-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-POLICY-035"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-POLICY-035"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/debug.ss")
              (check (hash-get details 'kind)
                     => "poo-debug-instrumentation-loop-performance")
              (check (hash-get details 'callee) => "trace-poo")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "hoist trace-poo outside the loop and reuse the traced object")))
    (test-case "agent policy redirects loop-local POO slot-spec mutation to value updates"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-slot-spec-mutation-loop-performance"
                   "t/scenarios/policy/poo-slot-spec-mutation-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-POLICY-036"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-POLICY-036"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/shape.ss")
              (check (hash-get details 'kind)
                     => "poo-slot-spec-mutation-loop-performance")
              (check (hash-get details 'callee) => ".def!")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "define slots once at setup; use .put! for intentional value mutation or scalar loop state plus one final object update")))
    (test-case "agent policy redirects loop-local POO slot predicates to a boundary check"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-slot-predicate-loop-performance"
                   "t/scenarios/policy/poo-slot-predicate-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-POLICY-037"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-POLICY-037"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/predicate.ss")
              (check (hash-get details 'kind)
                     => "poo-slot-predicate-loop-performance")
              (check (hash-get details 'callee) => "o?/slots")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "hoist stable o?/slots predicate results outside the loop; hoist the predicate closure when only the slot list is stable")))
  ))
