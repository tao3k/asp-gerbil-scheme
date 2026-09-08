;;; -*- Gerbil -*-
;;; Stable public surface for macro governance v1.

(import :asp-gerbil-scheme/src/macro-governance/admission
        :asp-gerbil-scheme/src/macro-governance/model)

(export macro-governance-rule-prototype
        macro-governance-hygiene-rule
        macro-governance-phase-rule
        macro-governance-pattern-budget-rule
        macro-governance-runtime-witness-rule
        macro-governance-expansion-io-rule
        macro-governance-rule-id
        macro-governance-rule-reason-kind
        macro-governance-rule-severity
        macro-governance-profile-prototype
        asp-strict-macro-governance-profile
        macro-governance-profile-name
        macro-governance-profile-rules
        macro-governance-profile-allowed-phases
        macro-governance-profile-require-hygiene?
        macro-governance-profile-max-pattern-count
        macro-governance-profile-rule-enabled?
        make-macro-governance-contract
        macro-governance-contract-macro
        macro-governance-contract-purpose
        macro-governance-contract-capabilities
        macro-governance-contract-witness-owners
        macro-governance-decision?
        macro-governance-decision-macro
        macro-governance-decision-selector
        macro-governance-decision-purpose
        macro-governance-decision-capabilities
        macro-governance-decision-status
        macro-governance-decision-reason-kinds
        macro-governance-decision-json
        macro-governance-receipt?
        macro-governance-receipt-schema-id
        macro-governance-receipt-schema-version
        macro-governance-receipt-profile
        macro-governance-receipt-status
        macro-governance-receipt-macro-count
        macro-governance-receipt-admitted-count
        macro-governance-receipt-rejected-count
        macro-governance-receipt-decisions
        macro-governance-receipt-json
        macro-governance-admit
        macro-governance-findings
        macro-governance-profile-findings
        macro-governance-contracts
        macro-governance-compile-rule-plan)
