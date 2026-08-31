;;; -*- Gerbil -*-
;;; Stable facade for provider snapshot projections.

(import :asp-gerbil-scheme/src/snapshot/core
        (only-in :asp-gerbil-scheme/src/snapshot/bench bench-report-snapshot)
        (only-in :asp-gerbil-scheme/src/snapshot/parser parser-source-file-snapshot)
        (only-in :asp-gerbil-scheme/src/snapshot/graph extension-packet-snapshot
                                 search-prime-snapshot))

(export snapshot-load
        project-package-snapshot
        extension-fact-snapshot
        extension-search-snapshot
        pattern-evidence-snapshot
        pattern-search-snapshot
        runtime-source-fact-snapshot
        runtime-source-search-snapshot
        language-evidence-fact-snapshot
        language-evidence-search-snapshot
        guide-snapshot
        registry-snapshot
        compare-fact-snapshot
        compare-search-snapshot
        parser-source-file-snapshot
        extension-packet-snapshot
        search-prime-snapshot
        self-apply-findings-snapshot
        finding-snapshot
        bench-report-snapshot
        check-report-snapshot)
