;;; -*- Gerbil -*-
;;; Shared helpers for stable snapshot projections.

(import :asp-gerbil-scheme/src/parser/facade
        (only-in :std/misc/string string-trim-suffix)
        (only-in :std/srfi/13 string-prefix?))

(export snapshot-project-root)
;; : (-> ProjectIndex Snapshot )
(def (snapshot-project-root index)
  (let* ((project-root (project-index-root index))
         (root (if (> (string-length project-root) 1)
                 (string-trim-suffix "/" project-root)
                 project-root))
         (cwd (current-directory)))
    (if (string-prefix? cwd root)
      (substring root (string-length cwd) (string-length root))
      root)))
