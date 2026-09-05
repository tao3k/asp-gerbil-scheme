;;; -*- Gerbil -*-
;;; Optional native query command entrypoint for the Gerbil Scheme harness.

(import (only-in :asp-gerbil-scheme/src/cli-launcher command-line-args provider-command-line-args)
        (only-in :asp-gerbil-scheme/src/commands/query query-main))
(export main
        command-line-args
        provider-command-line-args)

;;; Optional fast-path boundary:
;;; - This module is the source entrypoint for an explicit `asp-gerbil-scheme-query`
;;;   sibling binary when a build chooses to pay the heavier query link cost.
;;; - The default package build keeps only `.bin/asp-gerbil-scheme`; tests therefore require
;;;   an executable sibling before measuring native query latency.
;;; - Arguments are already the query tail here. The public launcher strips the
;;;   `query` command token before delegating to any installed sibling.
;; main
;;   : (-> (List String) Integer)
;;   | doc m%
;;       `main args` runs the query command graph for an optional native
;;       fast-path executable.
;;
;;       # Examples
;;
;;       ```scheme
;;       (main "--selector" "src/support/io.ss:1-3" "--content")
;;       ;; => 0
;;       ```
;;     %
(def (main . args)
  (query-main args))
