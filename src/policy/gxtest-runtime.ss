;;; Gxtest policy runtime converts one already-collected ProjectIndex into the
;;; stable report/status API consumed by Build API admission and test tooling.
;;; It must not rediscover sources or rescan owners for individual projections.
(import :gerbil/gambit
        (only-in ../constants +language-id+ +provider-id+)
        (only-in ../parser/model project-index-files)
        (only-in ../parser/selectors project-definitions)
        (only-in ../parser/test-source-scope collect-test-source-scope)
        (only-in ../support/time monotonic-micros duration-micros)
        (only-in ../types/core type-status)
        (only-in ./core run-policy-checks))

(export policy-findings
        policy-status
        policy-report
        gxtest-report-ref
        gxtest-report-status
        gxtest-report-files
        gxtest-report-definitions
        gxtest-report-agent-repair
        gxtest-report-findings
        gxtest-report-finding-count
        gxtest-report-summary
        project-policy-report-json)

;; : (-> Root (List Path) (List TypeFinding))
(def (policy-findings root files)
  (run-policy-checks (collect-test-source-scope root files)))

;; : (-> Root (List Path) Status)
(def (policy-status root files)
  (type-status (policy-findings root files)))

;; : (forall (A) (-> (Maybe (-> String Integer A)) String (-> Any) Any))
;; : (-> (Maybe PolicyPhaseObserver) String (-> Result) Result)
(def (policy-report-phase phase! name thunk)
  (if phase!
    (let (start-micros (monotonic-micros))
      (let (result (thunk))
        (phase! name (duration-micros start-micros (monotonic-micros)))
        result))
    (thunk)))

;; : (-> Root (List Path) (Maybe PolicyPhaseObserver) PolicyReport)
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

;; : (-> ProjectIndex (List TypeFinding) String (Maybe (List Path)) PolicyReport)
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
        (agentRepair (hash (available #f)))
        (findings findings)))

;; : (-> PolicyReport Symbol JsonValue)
(def (gxtest-report-ref report key)
  (hash-get report key))

;; : (-> PolicyReport Status)
(def (gxtest-report-status report)
  (gxtest-report-ref report 'status))

;; : (-> PolicyReport Integer)
(def (gxtest-report-files report)
  (gxtest-report-ref report 'files))

;; : (-> PolicyReport Integer)
(def (gxtest-report-definitions report)
  (gxtest-report-ref report 'definitions))

;; : (-> PolicyReport AgentRepairReceipt)
(def (gxtest-report-agent-repair report)
  (gxtest-report-ref report 'agentRepair))

;; : (-> PolicyReport (List TypeFinding))
(def (gxtest-report-findings report)
  (gxtest-report-ref report 'findings))

;; : (-> PolicyReport Integer)
(def (gxtest-report-finding-count report)
  (length (gxtest-report-findings report)))

;; : (-> PolicyReport PolicySummary)
(def (gxtest-report-summary report)
  (hash (status (gxtest-report-status report))
        (files (gxtest-report-files report))
        (definitions (gxtest-report-definitions report))
        (findingCount (gxtest-report-finding-count report))))
