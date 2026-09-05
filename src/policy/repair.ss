;;; -*- Gerbil -*-
;;; Agent repair metadata derived from policy findings.

(import :asp-gerbil-scheme/src/policy/repair-diagnostic
        :asp-gerbil-scheme/src/policy/repair-report)

(export repairable-finding?
        repairable-findings
        agent-repair-report-json
        agent-repair-summary-parts
        finding-agent-repair-json
        finding-agent-repair-parts
        finding-guide-detail-parts)
