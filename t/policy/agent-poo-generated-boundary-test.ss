;;; -*- Gerbil -*-
;;; Gerbil scheme harness generated POO boundary policy.

(import :gerbil/gambit
        :std/test
        :policy/agent-poo-support
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade)

(export agent-poo-generated-boundary-policy-test)

;; PolicyTest
(def agent-poo-generated-boundary-policy-test
  (test-suite "gerbil scheme harness generated POO boundary policy"
    (test-case "P043 does not infer representation defects from receipt names"
      (let* ((scenario
              (make-policy-scenario
               "poo-generated-receipt-boundary-performance"
               "t/scenarios/policy/poo-generated-receipt-boundary-performance"))
             (timing (policy-scenario-run/timed scenario))
             (result (hash-get timing 'result))
             (timings (hash-get timing 'timings))
             (before-matching
              (policy-scenario-findings
               result
               'before
               "GERBIL-SCHEME-AGENT-POLICY-043"))
             (after-matching
              (policy-scenario-findings
               result
               'after
               "GERBIL-SCHEME-AGENT-POLICY-043"))
             )
        (check (length timings) => 4)
        (check (policy-scenario-timing-steps-measured? timings) => #t)
        (check (policy-scenario-benchmark-constrained? timing) => #t)
        (check before-matching => [])
        (check after-matching => [])
        ))))
