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
        (user-interface (string-append root "/user-interface"))
        (cases (string-append root "/user-interface/custom/domain/cases"))
        (profiles (string-append root "/user-interface/profiles")))
    (ensure-directory ".run")
    (ensure-directory root)
    (ensure-directory src)
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
     ";;; -*- Gerbil -*-\n(display \"runtime side effect\")\n")))

;; : (-> (List TypeFinding) Path (List TypeFinding) )
(def (findings-for-path findings path)
  (filter (lambda (finding)
            (equal? (type-finding-path finding) path))
          findings))

(def declarative-user-interface-policy-test
  (test-suite "declarative user interface policy"
    (test-case "case and profile projections are not runtime entrypoints"
      (let* ((root ".run/declarative-user-interface-policy")
             (_ (write-user-interface-project root))
             (index (collect-project root))
             (findings (top-level-executable-findings index)))
        (check (source-path-class
                "user-interface/custom/domain/cases/artifact.ss")
               => "declarative-case")
        (check (source-path-class "user-interface/profiles/report.ss")
               => "declarative-profile")
        (check (findings-for-path
                findings
                "user-interface/custom/domain/cases/artifact.ss")
               => [])
        (check (findings-for-path findings "user-interface/profiles/report.ss")
               => [])
        (check (length (findings-for-path findings "src/runtime.ss")) => 1)))))
