;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent POO policy smoke.
;;;
;;; Heavy POO scenario suites live in sibling t/policy/agent-poo-*.ss files.
;;; The gxtest full target discovers those files directly so the runner can
;;; batch them instead of serializing every scenario through this aggregator.

(import :std/test
        :asp-gerbil-scheme/src/policy/catalog
        :asp-gerbil-scheme/src/policy/model)

(export agent-poo-policy-test)

;; PolicyTest
(def agent-poo-policy-test
  (test-suite "gerbil scheme harness agent POO policy smoke"
    (test-case "POO policy catalog exposes generated receipt boundary guidance"
      (check (policy-rule-id +agent-poo-generated-receipt-boundary-rule+)
             => "GERBIL-SCHEME-AGENT-POLICY-043")
      (check (agent-rule-topic
              (policy-rule-id +agent-poo-generated-receipt-boundary-rule+))
             => "poo-generated-receipt-boundary")
      (check (agent-rule-guide-next-command
              (policy-rule-id +agent-poo-generated-receipt-boundary-rule+))
             => "asp gerbil-scheme search pattern defstruct receipt ->alist boundary --workspace . --view seeds"))
    (test-case "POO policy catalog keeps loop object construction rule available"
      (check (policy-rule-id +agent-poo-object-construction-loop-performance-rule+)
             => "GERBIL-SCHEME-AGENT-POLICY-033"))))
