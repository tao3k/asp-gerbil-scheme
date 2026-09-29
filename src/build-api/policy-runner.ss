;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Policy evaluates only the source targets selected by PackageSpec's native
;;; BuildSpec. No project discovery or second dependency graph is involved.
(import (only-in :asp-gerbil-scheme/src/parser/model make-project-index)
        (only-in :asp-gerbil-scheme/src/parser/package read-project-package)
        (only-in :asp-gerbil-scheme/src/parser/parse-workers parse-source-files)
        (only-in :asp-gerbil-scheme/src/policy/core run-policy-checks)
        (only-in :asp-gerbil-scheme/src/types/facade
                 type-finding-rule-id type-finding-severity
                 type-finding-path type-finding-message))

(export asp-gerbil-scheme-run-selected-policy)

;; asp-gerbil-scheme-run-selected-policy
;;   : (-> (List Path) Void)
;;   | doc m%
;;       Run the complete ASP policy on the native BuildSpec source selection.
;;       A finding with error severity rejects the build.
;;
;;       # Examples
;;
;;       ```scheme
;;       (asp-gerbil-scheme-run-selected-policy '("src/core.ss"))
;;       ;; => #!void when the selected source has no error findings
;;       ```
;;     %
(def (asp-gerbil-scheme-run-selected-policy paths)
  (let* ((root (current-directory))
         (index (make-project-index
                 root
                 (parse-source-files root paths)
                 (read-project-package root)))
         (findings (run-policy-checks index))
         (errors
          (filter (lambda (finding)
                    (equal? (type-finding-severity finding) "error"))
                  findings)))
    (parameterize ((current-output-port (current-error-port)))
      (for-each
       (lambda (finding)
         (displayln "[asp-gerbil-scheme-policy] "
                    (type-finding-severity finding) " "
                    (type-finding-rule-id finding) " "
                    (type-finding-path finding) ": "
                    (type-finding-message finding)))
       findings)
      (displayln "[asp-gerbil-scheme-policy] COMPLETE findings="
                 (length findings) " errors=" (length errors))
      (force-output))
    (when (pair? errors)
      (error "ASP Gerbil Scheme policy rejected build"
             (length errors)))))
