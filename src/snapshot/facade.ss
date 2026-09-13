;;; -*- Gerbil -*-
;;; Stable facade for provider snapshot projections.

(import :asp-gerbil-scheme/src/snapshot/core
        (only-in :asp-gerbil-scheme/src/snapshot/bench bench-report-snapshot)
        (only-in :asp-gerbil-scheme/src/snapshot/parser parser-source-file-snapshot)
        (only-in :asp-gerbil-scheme/src/snapshot/graph extension-packet-snapshot))

(export snapshot-load
        project-package-snapshot
        extension-fact-snapshot
        guide-snapshot
        registry-snapshot
        parser-source-file-snapshot
        extension-packet-snapshot
        self-apply-findings-snapshot
        finding-snapshot
        bench-report-snapshot
        check-report-snapshot)
