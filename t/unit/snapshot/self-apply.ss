;;; -*- Gerbil -*-
(import :asp-gerbil-scheme/src/snapshot/facade
        :std/test)
(export check-empty-self-apply-findings-snapshot)
;; Snapshot
(def (check-empty-self-apply-findings-snapshot)
  (check (self-apply-findings-snapshot '())
         => '(selfApplyFindings
              (languageId "gerbil-scheme")
              (providerId "asp-gerbil-scheme")
              (status "pass")
              (findingCount 0)
              (findings ()))))
