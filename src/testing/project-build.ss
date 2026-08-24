;;; Boundary: this module is a thin library facade over the upstream-shaped
;;; gxtest runner; it owns no command parsing, process wrapper, or test policy.

(export configure-project-testing-root!
        project-test-target
        project-test-file-target
        project-test-full-target)

(import :gslph/src/testing/gxtest-runner
        (only-in :std/sugar cut))

;; configure-project-testing-root!
;;   : (-> Path Void)
;;   | doc m%
;;       Configures the package-local testing context before a downstream
;;       project invokes the shared gxtest library API.
;; # Examples
;; ```scheme
;; (configure-project-testing-root! ".")
;; => package-local test roots and artifacts are selected
;; ```
;;     %
(def configure-project-testing-root!
  (cut configure-build-root! <>))

;; project-test-target
;;   : (-> TestReceipt)
;;   | doc m%
;;       Runs the selected default gxtest target through the shared test
;;       runner, without adding a project-specific command wrapper.
;; # Examples
;; ```scheme
;; (project-test-target)
;; => receipt for the default selected gxtest files
;; ```
;;     %
(def project-test-target test-target)

;; project-test-file-target
;;   : (-> (List Path) TestReceipt)
;;   | doc m%
;;       Runs an explicit list of gxtest files through the same scoped policy
;;       and artifact path as the default target.
;; # Examples
;; ```scheme
;; (project-test-file-target '("t/parser-test.ss"))
;; => receipt for the selected parser test file
;; ```
;;     %
(def (project-test-file-target files)
  (test-file-target files))

;; project-test-full-target
;;   : (-> TestReceipt)
;;   | doc m%
;;       Runs every selected top-level and policy gxtest file while excluding
;;       scenario input and expected fixture directories.
;; # Examples
;; ```scheme
;; (project-test-full-target)
;; => receipt for the complete selected project test set
;; ```
;;     %
(def project-test-full-target test-full-target)
