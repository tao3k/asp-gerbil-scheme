;;; -*- Gerbil -*-
;;; Policy dispatch for Gerbil project rules.

(import :asp-gerbil-scheme/src/policy/agent
        :asp-gerbil-scheme/src/policy/modularity)

(export run-policy-checks)
;; : (-> ProjectIndex (List TypeFinding) )
(def (run-policy-checks index)
  ;; Rule execution is provider-owned. Package metadata cannot suppress findings.
  (append (run-modularity-policy index)
          (run-agent-policy index)))
