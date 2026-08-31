;;; -*- Gerbil -*-
;;; Policy dispatch for Gerbil project rules.

(import :asp-gerbil-scheme/src/parser/core
        :asp-gerbil-scheme/src/parser/package
        :asp-gerbil-scheme/src/policy/agent
        :asp-gerbil-scheme/src/policy/modularity
        (only-in :std/srfi/13 string-trim)
        :asp-gerbil-scheme/src/types/findings)

(export run-policy-checks)
;; : (-> ProjectIndex (List TypeFinding) )
(def (run-policy-checks index)
  (append
   (package-agent-policy-findings index)
   (filter-enabled-policy-findings
    index
    (append (run-modularity-policy index)
            (run-agent-policy index)))))
;;; Boundary:
;;; - Default policy is all rules enabled.
;;; - Package policy can only disable rules with a concrete explanation.
;; : (-> ProjectIndex (List TypeFinding) Boolean )
(def (filter-enabled-policy-findings index findings)
  (let* ((package (project-index-package index))
         (policy (and package (project-package-agent-policy package))))
    (if (and policy (agent-policy-disable-explanation-valid? policy))
      (filter (cut policy-finding-enabled? policy <>)
              findings)
      findings)))
;; : (-> Policy TypeFinding Boolean )
(def (policy-finding-enabled? policy finding)
  (let ((rule-id (type-finding-rule-id finding))
        (disabled (agent-policy-disabled-rules policy)))
    (not (member rule-id disabled))))

;; : (-> ProjectIndex (List TypeFinding) )
(def (package-agent-policy-findings index)
  (let* ((package (project-index-package index))
         (policy (and package (project-package-agent-policy package))))
    (if (and policy
             (pair? (agent-policy-disabled-rules policy))
             (not (agent-policy-disable-explanation-valid? policy)))
      [(make-type-finding
        "GERBIL-SCHEME-AGENT-POLICY-024"
        "error"
        (or (and package (project-package-path package)) "gerbil.pkg")
        "agent-policy disabled-rules requires a non-empty explanation; rule disables without rationale are ignored so agents cannot escape policy gates"
        (or (and package (project-package-path package)) "gerbil.pkg")
        #f)]
      '())))

;; : (-> AgentPolicy Boolean )
(def (agent-policy-disable-explanation-valid? policy)
  (or (null? (agent-policy-disabled-rules policy))
      (let (explanation (agent-policy-explanation policy))
        (and explanation
             (not (equal? "" (string-trim explanation)))))))
