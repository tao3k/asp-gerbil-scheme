;;; -*- Gerbil -*-
(import :asp-gerbil-scheme/src/snapshot/facade
        :std/test)
(export check-empty-check-report-snapshot)
;; Snapshot
(def (check-empty-check-report-snapshot)
  (check (check-report-snapshot #f '())
         => '(checkReport
              (languageId "gerbil-scheme")
              (providerId "asp-gerbil-scheme")
              (status "pass")
              (findings ()))))
