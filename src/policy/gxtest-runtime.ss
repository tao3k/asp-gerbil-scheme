(import :gerbil/gambit
        ../constants
        ../parser/model
        ../parser/selectors
        ../parser/test-source-scope
        ../support/time
        ../types/core
        ./core)

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

;; : (-> Path (List Path) (List Any))
(def (policy-findings root files)
  (run-policy-checks (collect-test-source-scope root files)))

;; : (-> Path (List Path) String)
(def (policy-status root files)
  (type-status (policy-findings root files)))

;; : (forall (A) (-> (Maybe (-> String Integer A)) String (-> Any) Any))
(def (policy-report-phase phase! name thunk)
  (if phase!
    (let (start-micros (monotonic-micros))
      (let (result (thunk))
        (phase! name (duration-micros start-micros (monotonic-micros)))
        result))
    (thunk)))

;; : (-> Path (List Path) (Maybe (-> String Integer Any)) HashTable)
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

;; : (-> ProjectIndex (List Any) String (Maybe (List Path)) HashTable)
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

;; : (-> HashTable Symbol Any)
(def (gxtest-report-ref report key)
  (hash-get report key))

;; : (-> HashTable String)
(def (gxtest-report-status report)
  (gxtest-report-ref report 'status))

;; : (-> HashTable Integer)
(def (gxtest-report-files report)
  (gxtest-report-ref report 'files))

;; : (-> HashTable Integer)
(def (gxtest-report-definitions report)
  (gxtest-report-ref report 'definitions))

;; : (-> HashTable Any)
(def (gxtest-report-agent-repair report)
  (gxtest-report-ref report 'agentRepair))

;; : (-> HashTable (List Any))
(def (gxtest-report-findings report)
  (gxtest-report-ref report 'findings))

;; : (-> HashTable Integer)
(def (gxtest-report-finding-count report)
  (length (gxtest-report-findings report)))

;; : (-> HashTable HashTable)
(def (gxtest-report-summary report)
  (hash (status (gxtest-report-status report))
        (files (gxtest-report-files report))
        (definitions (gxtest-report-definitions report))
        (findingCount (gxtest-report-finding-count report))))
