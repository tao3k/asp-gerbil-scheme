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
    (test-case "agent policy moves generated receipt adapters to defstruct boundary projection"
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
             (finding (car before-matching))
             (details (type-finding-details finding)))
        (check (length timings) => 4)
        (check (policy-scenario-timing-steps-measured? timings) => #t)
        (check (policy-scenario-benchmark-constrained? timing) => #t)
        (check (length before-matching) => 1)
        (check after-matching => [])
        (check (type-finding-path finding) => "src/runtime/receipt.ss")
        (check (hash-get details 'kind) => "poo-generated-receipt-boundary")
        (check (hash-get details 'callee) => "object<-alist")
        (check (hash-get details 'preferredConstruction)
               => "defstruct for generated receipt state plus explicit receipt->alist projection at presentation/runtime ABI boundary")))))
