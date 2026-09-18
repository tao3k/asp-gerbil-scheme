;;; -*- Gerbil -*-
;;; gerbil scheme harness agent POO hot loop core policy.

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
(export agent-poo-hot-loop-core-policy-test)

;; PolicyTest
(def agent-poo-hot-loop-core-policy-test
  (test-suite "gerbil scheme harness agent POO hot loop core policy"
(test-case "agent policy redirects loop-local POO clone overrides out of hot loops"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-clone-override-loop-performance"
                   "t/scenarios/policy/poo-clone-override-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-POLICY-028"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-POLICY-028"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/score.ss")
              (check (hash-get details 'kind)
                     => "poo-clone-override-loop-performance")
              (check (hash-get details 'callee) => ".cc")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "accumulate loop state and apply one final .cc; use .put! only for intentional mutable objects")))
(test-case "agent policy redirects loop-local POO materialization to a single boundary snapshot"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-materialization-loop-performance"
                   "t/scenarios/policy/poo-materialization-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-POLICY-029"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-POLICY-029"))
                 (finding (car before-matching))
                 (details (type-finding-details finding))
                 (callees
                  (map (lambda (finding)
                         (hash-get (type-finding-details finding) 'callee))
                       before-matching)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 5)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/export.ss")
              (check (hash-get details 'kind)
                     => "poo-materialization-loop-performance")
              (check (not (not (member ".alist/sort" callees))) => #t)
              (check (not (not (member ".all-slots" callees))) => #t)
              (check (not (not (member ".all-slots/sort" callees))) => #t)
              (check (not (not (member "hash<-object" callees))) => #t)
              (check (not (not (member "force-object" callees))) => #t)
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "materialize, iterate, or project once outside the loop, or use direct .ref access for specific slots")))
(test-case "agent policy redirects loop-local POO slot projection to a boundary snapshot"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-slot-projection-loop-performance"
                   "t/scenarios/policy/poo-slot-projection-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-POLICY-029"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-POLICY-029"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/project.ss")
              (check (hash-get details 'kind)
                     => "poo-materialization-loop-performance")
              (check (hash-get details 'callee) => ".refs/slots")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "materialize, iterate, or project once outside the loop, or use direct .ref access for specific slots")))
(test-case "agent policy redirects loop-local POO object iteration to a boundary snapshot"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-object-iteration-loop-performance"
                   "t/scenarios/policy/poo-object-iteration-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-POLICY-029"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-POLICY-029"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/iteration.ss")
              (check (hash-get details 'kind)
                     => "poo-materialization-loop-performance")
              (check (hash-get details 'callee) => ".for-each!")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "materialize, iterate, or project once outside the loop, or use direct .ref access for specific slots")))
(test-case "agent policy redirects loop-local POO composition to one boundary object"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-composition-loop-performance"
                   "t/scenarios/policy/poo-composition-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-POLICY-030"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-POLICY-030"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/compose.ss")
              (check (hash-get details 'kind)
                     => "poo-composition-loop-performance")
              (check (hash-get details 'callee) => ".mix")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "accumulate scalar loop state and apply one final POO composition outside the loop")))
(test-case "agent policy redirects loop-local POO validation to a boundary check"
          (let* ((scenario
                  (make-policy-scenario
                   "poo-validation-loop-performance"
                   "t/scenarios/policy/poo-validation-loop-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-POLICY-031"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-POLICY-031"))
                 (finding (car before-matching))
                   (details (type-finding-details finding)))
              (check (length timings) => 4)
              (check (policy-scenario-timing-steps-measured? timings)
                     => #t)
              (check (policy-scenario-benchmark-constrained? timing)
                     => #t)
              (check (length before-matching) => 1)
              (check after-matching => [])
              (check (type-finding-path finding) => "src/reports/validate.ss")
              (check (hash-get details 'kind)
                     => "poo-validation-loop-performance")
              (check (hash-get details 'callee) => "validate")
              (check (hash-get details 'loopRole) => "manual-loop")
              (check (hash-get details 'preferredConstruction)
                     => "validate once outside the loop, then operate on the validated object or scalar fields")))
  ))
