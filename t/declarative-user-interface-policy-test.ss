;;; -*- Gerbil -*-
;;; R005 regression for declarative user-interface case and profile projections.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        (only-in :asp-gerbil-scheme/src/policy/agent-basic
                 top-level-executable-findings)
        :asp-gerbil-scheme/src/types/facade)

(export declarative-user-interface-policy-test)

;; : (-> Path Void )
(def (ensure-directory path)
  (unless (file-exists? path)
    (create-directory path)))

;; : (-> Path String Void )
(def (write-source path source)
  (call-with-output-file path
    (lambda (port)
      (display source port))))

;; : (-> Root Void )
(def (write-user-interface-project root)
  (let ((src (string-append root "/src"))
        (tests (string-append root "/t"))
        (user-interface (string-append root "/user-interface"))
        (cases (string-append root "/user-interface/custom/domain/cases"))
        (profiles (string-append root "/user-interface/profiles")))
    (ensure-directory ".run")
    (ensure-directory root)
    (ensure-directory src)
    (ensure-directory tests)
    (ensure-directory user-interface)
    (ensure-directory (string-append user-interface "/custom"))
    (ensure-directory (string-append user-interface "/custom/domain"))
    (ensure-directory cases)
    (ensure-directory profiles)
    (write-source (string-append root "/gerbil.pkg")
                  "(package: sample/declarative-ui)\n")
    (write-source
     (string-append cases "/artifact.ss")
     ";;; -*- Gerbil -*-\n(let* ((profile (artifact-profile report))) (list profile))\n")
    (write-source
     (string-append profiles "/report.ss")
     ";;; -*- Gerbil -*-\n(.o (report (.o (kind 'report))))\n")
    (write-source
     (string-append src "/runtime.ss")
     ";;; -*- Gerbil -*-\n(display \"runtime side effect\")\n")
    (write-source
     (string-append root "/domain.ss")
     ";;; -*- Gerbil -*-\n(display \"root runtime side effect\")\n")
    (write-source
     (string-append root "/domain-build.ss")
     ";;; -*- Gerbil -*-\n(display \"build declaration\")\n")
    (write-source
     (string-append tests "/domain-test.ss")
     ";;; -*- Gerbil -*-\n(display \"test harness\")\n")))

;; : (-> (List TypeFinding) Path (List TypeFinding) )
(def (findings-for-path findings path)
  (filter (lambda (finding)
            (equal? (type-finding-path finding) path))
          findings))

;; This is the exact Build API coverage shape that makes a root-level Gerbil
;; project both the source catalog and runtime-root authority.
(def +project-coverage-files+
  '("gerbil.pkg"
    "domain.ss"
    "domain-build.ss"
    "src/runtime.ss"
    "t/domain-test.ss"
    "user-interface/custom/domain/cases/artifact.ss"
    "user-interface/profiles/report.ss"))

(def declarative-user-interface-policy-test
  (test-suite "declarative user interface policy"
    (test-case "case and profile projections are not runtime entrypoints"
      (let* ((root ".run/declarative-user-interface-policy")
             (_ (write-user-interface-project root))
             (index (collect-source-scope/coverage
                     root +project-coverage-files+ ["."] ["."] []))
             (findings (top-level-executable-findings index)))
        (check (source-path-class
                "user-interface/custom/domain/cases/artifact.ss")
               => "declarative-case")
        (check (source-path-class "user-interface/profiles/report.ss")
               => "declarative-profile")
        (check (source-path-class "domain-build.ss") => "package-build")
        (check (source-path-class "t/domain-test.ss") => "test")
        (check (findings-for-path
                findings
                "user-interface/custom/domain/cases/artifact.ss")
               => [])
        (check (findings-for-path findings "user-interface/profiles/report.ss")
               => [])
        (check (findings-for-path findings "domain-build.ss") => [])
        (check (findings-for-path findings "t/domain-test.ss") => [])
        (check (length (findings-for-path findings "src/runtime.ss")) => 1)
        (check (length (findings-for-path findings "domain.ss")) => 1)))))
