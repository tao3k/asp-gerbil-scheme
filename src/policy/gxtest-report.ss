;;; -*- Gerbil -*-
;;; Runtime gxtest policy report API.

(import :gerbil/gambit
        (only-in "../build-api/source-coverage"
                 asp-gerbil-scheme-source-coverage-exclude-directories
                 asp-gerbil-scheme-source-coverage-files
                 asp-gerbil-scheme-source-coverage-roots)
        (only-in "../constants" +language-id+ +provider-id+)
        (only-in "../parser/facade"
                 collect-source-scope/coverage
                 collect-selected-source-scope
                 collect-test-source-scope
                 project-definitions
                 project-index-files)
        (only-in "../support/time"
                 duration-micros
                 monotonic-micros)
        (only-in "./facade"
                 agent-repair-report-json
                 policy-finding-json
                 run-policy-checks)
        (only-in "../protocol/json-output" write-json-line)
        (only-in "../types/facade"
                 type-finding-details
                 type-finding-message
                 type-finding-path
                 type-finding-rule-id
                 type-finding-selector
                 type-finding-severity
                 type-status))

(export policy-findings
        policy-status
        policy-report
        policy-source-report
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
        project-policy-report-packet
        write-project-policy-report-packet)

;; : (-> Root (List Path) (List TypeFinding) )
(def (policy-findings root files)
  (run-policy-checks (collect-test-source-scope root files)))

;; : (-> Root (List Path) String )
(def (policy-status root files)
  (type-status (policy-findings root files)))

;;; Boundary:
;;; - policy-report is the stable files-scoped downstream gxtest data surface.
;;; - Package metadata is read for policy configuration, but execution parses
;;;   only files supplied by the test runner and package-local imports those
;;;   files actually reach. Full-project coverage stays an explicit project gate.
;; : (forall (a) (-> (Maybe (-> String Integer Void)) String (-> a) a))
(def (policy-report-phase phase! name thunk)
  (if phase!
    (let (start-micros (monotonic-micros))
      (let (result (thunk))
        (phase! name (duration-micros start-micros (monotonic-micros)))
        result))
    (thunk)))

;; : (-> Root (List Path) Json )
(def (policy-report root files (phase! #f))
  (let* ((index
          (policy-report-phase
           phase!
           "policy-collect"
           (lambda ()
             (collect-test-source-scope root files))))
         (findings
          (policy-report-phase
           phase!
           "policy-checks"
           (lambda ()
             (run-policy-checks index)))))
    (policy-report-phase
     phase!
     "policy-json"
     (lambda ()
       (project-policy-report-json index findings "files" files)))))

;;; Boundary:
;;; - gxtest runner passes an already expanded source scope, so this entry
;;;   parses exactly that scope and does not chase imports a second time.
;;; - policy-report keeps the downstream test-file API that expands imports.
;; : (-> Root (List Path) Json )
(def (policy-source-report root files (phase! #f))
  (let* ((index
          (policy-report-phase
           phase!
           "policy-collect"
           (lambda ()
             (collect-selected-source-scope root files))))
         (findings
          (policy-report-phase
           phase!
           "policy-checks"
           (lambda ()
             (run-policy-checks index)))))
    (policy-report-phase
     phase!
     "policy-json"
     (lambda ()
       (project-policy-report-json index findings "source-files" files)))))

;; : (-> Path Path)
(def (project-policy-trim-trailing-slash path)
  (let trim ((end (string-length path)))
    (if (and (> end 1)
             (char=? (string-ref path (- end 1)) #\/))
      (trim (- end 1))
      (substring path 0 end))))

;; : (-> Root Root)
(def (project-policy-root root)
  (let* ((expanded-root
          (path-normalize (path-expand root (current-directory))))
         (normalized-root
          (project-policy-trim-trailing-slash expanded-root)))
    (let loop ((candidate normalized-root))
      (let (parent (path-directory candidate))
        (cond
         ((file-exists? (path-expand "gerbil.pkg" candidate))
          candidate)
         ((or (not parent) (string=? parent candidate))
          normalized-root)
         (else (loop parent)))))))

;; : (-> Root (List TypeFinding) )
(def (project-policy-findings root)
  (run-policy-checks (project-policy-index root)))

;; : (-> Root String )
(def (project-policy-status root)
  (type-status (project-policy-findings root)))

;;; Boundary:
;;; - project-policy-report is the stable downstream gxtest data surface.
;;; - Coverage follows the build.ss source coverage declaration instead of a
;;;   separate whole-repository scan.
;; : (-> Root Json )
(def (project-policy-report root)
  (let* ((index (project-policy-index root))
         (findings (run-policy-checks index)))
    (project-policy-report-json index findings "project" #f)))

;; : (-> Root ProjectIndex)
(def (project-policy-index root)
  (let* ((policy-root (project-policy-root root))
         ;; source-coverage-files owns the only conditional build.ss load and
         ;; returns the macro-declared owner catalog without directory discovery.
         (files (asp-gerbil-scheme-source-coverage-files policy-root)))
    (collect-source-scope/coverage
     policy-root
     files
     (asp-gerbil-scheme-source-coverage-roots)
     (asp-gerbil-scheme-source-coverage-roots)
     (asp-gerbil-scheme-source-coverage-exclude-directories))))

;; : (-> ProjectIndex (List TypeFinding) String MaybePaths Json )
(def (project-policy-report-json index findings scope requested-files)
  (hash (schemaId "agent.semantic-protocols.asp-gerbil-scheme-gxtest-report")
        (schemaVersion "1")
        (languageId +language-id+)
        (providerId +provider-id+)
        (scope scope)
        (requestedFiles (or requested-files []))
        (status (type-status findings))
        (files (length (project-index-files index)))
        (definitions (length (project-definitions index)))
        (agentRepair (agent-repair-report-json findings))
        (findings findings)))

;;; Boundary:
;;; - Downstream agents should use these accessors instead of guessing the
;;;   report container shape.
;;; - Reports are Gerbil hash tables; the accessor names are the stable public
;;;   contract for compact custom checks.
;; : (-> PolicyReport Symbol (U #f Json))
(def (gxtest-report-ref report key)
  (hash-get report key))

;; : (-> PolicyReport String)
(def (gxtest-report-status report)
  (gxtest-report-ref report 'status))

;; : (-> PolicyReport Fixnum)
(def (gxtest-report-files report)
  (gxtest-report-ref report 'files))

;; : (-> PolicyReport Fixnum)
(def (gxtest-report-definitions report)
  (gxtest-report-ref report 'definitions))

;; : (-> PolicyReport Json)
(def (gxtest-report-agent-repair report)
  (gxtest-report-ref report 'agentRepair))

;; : (-> PolicyReport (List TypeFinding))
(def (gxtest-report-findings report)
  (gxtest-report-ref report 'findings))

;; : (-> PolicyReport Fixnum)
(def (gxtest-report-finding-count report)
  (length (gxtest-report-findings report)))

;; : (-> PolicyReport Json)
(def (gxtest-report-summary report)
  (hash (status (gxtest-report-status report))
        (files (gxtest-report-files report))
        (definitions (gxtest-report-definitions report))
        (findingCount (gxtest-report-finding-count report))))

;;; Provider wire boundary.  This is the only public output projection for a
;;; policy report.  Unified ASP validates this shared packet and owns every
;;; human-readable presentation.
;; : (-> PolicyReport Json )
(def (project-policy-report-packet report)
  (hash (schemaId "agent.semantic-protocols.semantic-language-policy-report")
        (schemaVersion "1")
        (languageId (hash-get report 'languageId))
        (providerId (hash-get report 'providerId))
        (status (hash-get report 'status))
        (scope (hash-get report 'scope))
        (requestedFiles (or (hash-get report 'requestedFiles) []))
        (files (hash-get report 'files))
        (definitions (hash-get report 'definitions))
        (agentRepair (hash-get report 'agentRepair))
        (findings (map policy-finding-json
                       (gxtest-report-findings report)))))

;; : (-> PolicyReport Unit )
(def (write-project-policy-report-packet report)
  (write-json-line (project-policy-report-packet report)))
