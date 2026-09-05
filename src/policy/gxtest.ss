;;; -*- Gerbil -*-
;;; Tiny gxtest adapter for downstream packages that depend on this harness.

(import :gerbil/gambit
        (for-syntax :gerbil/gambit
                    :gerbil/expander
                    :std/stxutil)
        (only-in :std/test check test-case test-suite)
        (only-in "./gxtest-report"
                 display-project-policy-report
                 gxtest-report-agent-repair
                 gxtest-report-definitions
                 gxtest-report-files
                 gxtest-report-finding-count
                 gxtest-report-findings
                 gxtest-report-ref
                 gxtest-report-status
                 gxtest-report-summary
                 policy-findings
                 policy-status
                 project-policy-findings
                 project-policy-report
                 project-policy-status)
        (rename-in "./gxtest-report"
                   (policy-report gxtest-report-policy-report)
                   (policy-source-report gxtest-report-policy-source-report)))

(export make-policy-test
        make-file-policy-test
        make-gxtest-policy-test
        policy-findings
        policy-status
        policy-report
        policy-source-report
        make-project-policy-test
        gxtest-report-ref
        gxtest-report-status
        gxtest-report-files
        gxtest-report-definitions
        gxtest-report-agent-repair
        gxtest-report-findings
        gxtest-report-finding-count
        gxtest-report-summary
        project-policy-findings
        project-policy-status
        project-policy-report
        display-project-policy-report)

;; : (-> Root (List Path) Json )
(def (policy-report root files (phase! #f))
  (gxtest-report-policy-report root files phase!))

;; : (-> Root (List Path) Json )
(def (policy-source-report root files (phase! #f))
  (gxtest-report-policy-source-report root files phase!))

(begin-syntax
  (def (gxtest-policy-trim-trailing-slash path)
    (let trim ((end (string-length path)))
      (if (and (> end 1)
               (char=? (string-ref path (- end 1)) #\/))
        (trim (- end 1))
        (substring path 0 end))))

  (def (gxtest-policy-package-root-path root)
    (let* ((expanded-root
            (path-normalize (path-expand root (current-directory))))
           (normalized-root
            (gxtest-policy-trim-trailing-slash expanded-root)))
      (let loop ((candidate normalized-root))
        (let (parent (path-directory candidate))
          (cond
           ((file-exists? (path-expand "gerbil.pkg" candidate))
            candidate)
           ((or (not parent) (string=? parent candidate))
            normalized-root)
           (else (loop parent)))))))

  (def (gxtest-policy-resolve-root root-stx)
    (let (root (syntax->datum root-stx))
      (if (string? root)
        (gxtest-policy-package-root-path root)
        root)))

  (def (gxtest-policy-resolve-files files-stx)
    (let (files (syntax->datum files-stx))
      (cond
       ((string? files) [files])
       ((list? files) files)
       (else #f)))))

;;; Macro boundary:
;;; - Downstream gxtest aggregators call this inside their normal test suite.
;;; - The caller passes the same entry files used by the upstream gxtest runner.
;;; - The expansion produces one ordinary files-scoped gxtest suite; dependency
;;;   and full-project policy remain explicit project gates.
;; make-gxtest-policy-test
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       Expand into a gxtest policy test rooted at the supplied project root
;;       and scoped to the supplied runner entry files.
;;
;;       # Examples
;;
;;       ```scheme
;;       (test-suite "project tests"
;;         (make-gxtest-policy-test "." ["t/unit-tests.ss"])
;;         project-unit-tests)
;;       ;; => TestSuite
;;       ```
;;     %
(defsyntax (make-gxtest-policy-test stx)
  (syntax-case stx ()
    ((_ root files)
     (let (resolved-files (gxtest-policy-resolve-files #'files))
       (unless resolved-files
         (raise-syntax-error
          'make-gxtest-policy-test
          "expected literal file path or literal list of file paths"
          stx
          #'files))
       (with-syntax ((resolved-root
                      (datum->syntax (stx-car stx)
                                     (gxtest-policy-resolve-root #'root)))
                     (resolved-files
                      (datum->syntax (stx-car stx) resolved-files)))
         #'(asp-gerbil-scheme/src/policy/gxtest#make-policy-test
            resolved-root
            resolved-files))))
    (_
     (raise-syntax-error
      'make-gxtest-policy-test
      "expected (make-gxtest-policy-test root files)"
      stx))))

;;; Boundary:
;;; - make-policy-test is the default gxtest bridge for downstream packages.
;;; - The caller supplies target files explicitly; build/test owners should pass
;;;   their internal test scope here instead of relying on process argv.
;; : (-> Root (List Path) TestSuite )
(def (make-policy-test root files)
  (test-suite "gerbil scheme scoped policy"
    (test-case "package policy passes for test scope"
      (let (report (policy-report root files))
        (when (not (equal? (hash-get report 'status) "pass"))
          (display-project-policy-report report))
        (check (hash-get report 'status) => "pass")))))

;; : (-> Root Path TestSuite )
(def (make-file-policy-test root file)
  (make-policy-test root [file]))

;;; Boundary:
;;; - make-project-policy-test is the explicit full-project policy gate.
;;; - Project-level warning backlog fails through the same status contract as
;;;   check/report, so downstream packages do not need wrapper tests.
;;; - Regular gxtest targets should use make-policy-test with their file scope.
;; : (-> Root TestSuite )
(def (make-project-policy-test root)
  (test-suite "gerbil scheme project policy"
    (test-case "package policy has no findings"
      (let (report (project-policy-report root))
        (when (not (equal? (hash-get report 'status) "pass"))
          (display-project-policy-report report))
        (check (hash-get report 'status) => "pass")))))
