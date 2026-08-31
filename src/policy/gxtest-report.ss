;;; -*- Gerbil -*-
;;; Runtime gxtest policy report API.

(import :gerbil/gambit
        (only-in "../build-api/source-coverage"
                 asp-gerbil-scheme-load-source-coverage
                 asp-gerbil-scheme-source-coverage-files)
        (only-in "../constants" +language-id+ +provider-id+)
        (only-in "../parser/facade"
                 collect-source-scope
                 collect-selected-source-scope
                 collect-test-source-scope
                 project-definitions
                 project-index-files)
        (only-in "../support/time"
                 duration-micros
                 monotonic-micros)
        (only-in "./facade"
                 agent-repair-summary-parts
                 agent-repair-report-json
                 finding-agent-repair-parts
                 finding-guide-detail-parts
                 run-policy-checks)
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
        display-project-policy-report)

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
  (let (policy-root (project-policy-root root))
    (asp-gerbil-scheme-load-source-coverage policy-root)
    (collect-source-scope policy-root (asp-gerbil-scheme-source-coverage-files policy-root))))

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

;;; Boundary:
;;; - display-project-policy-report mirrors check output for failing gxtest runs.
;;; - Keep the line protocol compact so downstream CI logs stay readable.
;; : (-> PolicyReport Unit )
(def (display-project-policy-report report)
  (let (findings (gxtest-report-findings report))
    (displayln "[gerbil-gxtest] status=" (gxtest-report-status report)
               " files=" (gxtest-report-files report)
               " definitions=" (gxtest-report-definitions report)
               " findings=" (gxtest-report-finding-count report))
    (display-project-policy-agent-repair-summary findings)
    (display-project-policy-agent-repair-rules findings)
    (for-each display-project-policy-finding findings)))

;; : (-> (List TypeFinding) Unit )
(def (display-project-policy-agent-repair-summary findings)
  (display-project-policy-line "|agent-repair-info"
                               (agent-repair-summary-parts findings)))

;; : (-> (List TypeFinding) Unit )
(def (display-project-policy-agent-repair-rules findings)
  (let (seen [])
    (for-each
     (lambda (finding)
       (let* ((rule-id (type-finding-rule-id finding))
              (already-seen? (member rule-id seen)))
         (unless already-seen?
           (display-project-policy-line "|agent-repair-rule"
                                        (finding-agent-repair-parts finding))
           (set! seen (cons rule-id seen)))))
     findings)))

;;; Boundary:
;;; - Finding lines expose the same selector/message/detail fields as check.
;;; - Per-rule repair hints stay compact by default; full detail is opt-in.
;; : (-> TypeFinding Unit )
(def (display-project-policy-finding finding)
  (displayln "|finding rule=" (type-finding-rule-id finding)
             " severity=" (type-finding-severity finding)
             " path=" (type-finding-path finding)
             " selector=" (or (type-finding-selector finding) "")
             " message=" (type-finding-message finding))
  (when (project-policy-detail-output?)
    (display-project-policy-line "|agent-repair"
                                 (finding-agent-repair-parts finding))
    (display-project-policy-line
     "|finding-detail"
     (append (project-policy-finding-detail-parts finding)
             (finding-guide-detail-parts finding)))))

;; : (-> Boolean)
(def (project-policy-detail-output?)
  (let (value (with-catch (lambda (_) #f)
               (lambda () (getenv "ASP_GERBIL_SCHEME_POLICY_DETAIL"))))
    (or (equal? value "1")
        (equal? value "true")
        (equal? value "full"))))

;;; Render each part with a shared prefix so gxtest failure logs stay line-oriented.
;;; The one-argument lambda is safe because repair/detail parts are already display-ready strings.
;; : (-> Prefix (List String) Unit )
(def (display-project-policy-line prefix parts)
  (when (and parts (pair? parts))
    (display prefix)
    (for-each (lambda (part)
                (display " ")
                (display part))
              parts)
    (newline)))

;; : (List Key)
(def +project-policy-finding-detail-keys+
  '(advice next keepNamedLetWhen styleGuide styleCommand
    expectedCommentShape signatureShape
    expectedDocShape typedDocRequiredWhen typedDocMissing
    typedDocMissingCount typedDocMissingTargets
    invalidTypedContractCount invalidTypedContractReasons
    invalidTypedContractExamples
    repairAction guideCodeFlag searchExampleCommand repairCodeCommand
    codeShapeExemplar adapterRepairShape agentRepairStandard
    qualityFacets qualityFacetSteering requiredWitness rewriteScope
    evidence kind name selector))

;;; Preserve detail key order with map, then filter absent policy-specific fields.
;;; This keeps compact output stable without forcing every finding to carry every detail slot.
;; : (-> TypeFinding (List String) )
(def (project-policy-finding-detail-parts finding)
  (let (details (type-finding-details finding))
    (if details
      (filter (lambda (part) part)
              (map (lambda (key)
                     (project-policy-finding-detail-part details key))
                   +project-policy-finding-detail-keys+))
      [])))

;; : (-> Details Key MaybeString )
(def (project-policy-finding-detail-part details key)
  (let (value (project-policy-finding-detail-value details key))
    (and value
         (string-append (symbol->string key)
                        "="
                        (project-policy-datum->display-string value)))))

;;; Finding details are optional and policy-specific, so missing keys should not hide the original failure.
;;; The protected lookup keeps custom downstream reports usable across mixed harness versions.
;; : (-> Details Key MaybeDatum )
(def (project-policy-finding-detail-value details key)
  (with-catch
   (lambda (_) #f)
   (lambda () (hash-get details key))))

;;; Use a display port conversion so symbols, lists, and strings keep their Scheme-readable shape.
;;; A one-argument port lambda keeps the resource scope local to the conversion.
;; : (-> Datum String )
(def (project-policy-datum->display-string value)
  (call-with-output-string "" (lambda (port) (display value port))))
