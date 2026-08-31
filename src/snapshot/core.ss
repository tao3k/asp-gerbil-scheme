;;; -*- Gerbil -*-
;;; Stable snapshot projections for provider facts and command packets.

(import :asp-gerbil-scheme/src/constants
        :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/snapshot/support
        (only-in :std/srfi/1 list-copy)
        (only-in :std/sugar hash-key?)
        :asp-gerbil-scheme/src/types/facade)

(export snapshot-load
        project-package-snapshot
        extension-fact-snapshot
        extension-search-snapshot
        pattern-evidence-snapshot
        pattern-search-snapshot
        runtime-source-fact-snapshot
        runtime-source-search-snapshot
        language-evidence-fact-snapshot
        language-evidence-search-snapshot
        guide-snapshot
        registry-snapshot
        compare-fact-snapshot
        compare-search-snapshot
        self-apply-findings-snapshot
        finding-snapshot
        check-report-snapshot)

;; : (-> Json String )
(def (snapshot-packet-id packet)
  (hash-get packet 'id))

;;; Invariant:
;;; - snapshot-load owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; : (-> String Snapshot )
(def (snapshot-load path)
  (call-with-input-file path read))
;; : (-> Package Snapshot )
(def (project-package-snapshot package)
  (list 'projectPackage
        (list 'path (project-package-path package))
        (list 'name (project-package-name package))
        (list 'dependencies (list-copy (project-package-dependencies package)))
        (list 'fields
              (list 'packageManager (project-package-manager package))
              (source-scope-policy-snapshot
               (project-package-source-scope-policy package))
              (modularity-policy-snapshot
               (project-package-modularity-policy package))
              (agent-policy-snapshot
               (project-package-agent-policy package)))))
;; : (-> Policy String )
(def (source-scope-policy-snapshot policy)
  (list 'sourceScopePolicy
        (if policy
          (list (list 'roots (list-copy (source-scope-policy-roots policy)))
                (list 'runtimeRoots (list-copy (source-scope-policy-runtime-roots policy)))
                (list 'excludeDirectories (list-copy (source-scope-policy-exclude-directories policy)))
                (list 'explanation (source-scope-policy-explanation policy)))
          '())))
;; : (-> Policy Snapshot )
(def (agent-policy-snapshot policy)
  (list 'agentPolicy
        (if policy
          (list (list 'default "all-rules-enabled")
                (list 'disabledRules (list-copy (agent-policy-disabled-rules policy)))
                (list 'explanation (agent-policy-explanation policy)))
          '())))
;; : (-> Policy Snapshot )
(def (modularity-policy-snapshot policy)
  (list 'modularityPolicy
        (if policy
          (list (list 'disabled (modularity-policy-disabled policy))
                (list 'enabledRules (list-copy (modularity-policy-enabled-rules policy)))
                (list 'disabledRules (list-copy (modularity-policy-disabled-rules policy)))
                (list 'maxSourceLineCount (modularity-policy-max-source-line-count policy))
                (list 'maxTestLineCount (modularity-policy-max-test-line-count policy))
                (list 'minSourceDefinitionCount (modularity-policy-min-source-definition-count policy))
                (list 'minTestDefinitionCount (modularity-policy-min-test-definition-count policy))
                (list 'configPath (modularity-policy-config-path policy))
                (list 'explanation (modularity-policy-explanation policy)))
          '())))
;; : (-> Fact Snapshot )
(def (extension-fact-snapshot fact)
  (list 'providerExtension
        (list 'name (extension-fact-name fact))
        (list 'activation (extension-fact-activation fact))
        (list 'dependencyMode (extension-fact-dependency-mode fact))
        (list 'packageManager (extension-fact-package-manager fact))
        (list 'package (extension-fact-package fact))
        (list 'dependencies (list-copy (extension-fact-dependencies fact)))
        (list 'capabilities (list-copy (extension-fact-capabilities fact)))))
;;; Boundary:
;;; - extension-search-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Query Matches Next Snapshot )
(def (extension-search-snapshot query matches next)
  (list 'extensionSearch
        (list 'namespace "extension")
        (list 'authority "ecosystem-extension")
        (list 'evidenceGrade (if (null? matches) "unknown" "fact"))
        (list 'query query)
        (list 'matches (map extension-fact-snapshot matches))
        (list 'next next)))
;;; Boundary:
;;; - pattern-evidence-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Pattern String )
(def (pattern-evidence-snapshot pattern)
  (list 'pattern
        (list 'id (snapshot-packet-id pattern))
        (list 'extension (hash-get pattern 'extension))
        (list 'focus (hash-get pattern 'focus))
        (source-ref-snapshot (hash-get pattern 'sourceRef))
        (list 'sourceOwners (list-copy (hash-get pattern 'sourceOwners)))
        (list 'agentScenario (hash-get pattern 'agentScenario))
        (list 'intent (hash-get pattern 'intent))
        (list 'selectors
              (map pattern-selector-snapshot
                   (hash-get pattern 'selectors)))
        (list 'minimalForms
              (map pattern-form-snapshot
                   (hash-get pattern 'minimalForms)))
        (list 'failureCases
              (map pattern-failure-case-snapshot
                   (hash-get pattern 'failureCases)))
        (list 'qualitySignals
              (list-copy (hash-get pattern 'qualitySignals)))
        (list 'witness (hash-get pattern 'witness))))
;; : (-> SourceRef Snapshot )
(def (source-ref-snapshot source-ref)
  (append
   (list 'sourceRef
         (list 'kind (hash-get source-ref 'kind))
         (list 'manager (hash-get source-ref 'manager))
         (list 'package (hash-get source-ref 'package))
         (list 'dependency (hash-get source-ref 'dependency))
         (list 'repository (hash-get source-ref 'repository)))
   (if (hash-key? source-ref 'localSource)
     [(local-source-snapshot (hash-get source-ref 'localSource))]
     [])
   (if (hash-key? source-ref 'repositorySource)
     [(repository-source-snapshot (hash-get source-ref 'repositorySource))]
     [])
   (if (hash-key? source-ref 'indexHint)
     [(index-hint-snapshot (hash-get source-ref 'indexHint))]
     [])
   [(list 'pathPolicy (hash-get source-ref 'pathPolicy))
    (list 'selectorScheme (hash-get source-ref 'selectorScheme))]))
;; : (-> LocalSource Snapshot )
(def (local-source-snapshot local-source)
  (list 'localSource
        (list 'kind (hash-get local-source 'kind))
        (list 'manager (hash-get local-source 'manager))
        (list 'rootHint (hash-get local-source 'rootHint))
        (list 'package (hash-get local-source 'package))
        (list 'status (hash-get local-source 'status))
        (list 'owner (hash-get local-source 'owner))))
;; : (-> RepositorySource Snapshot )
(def (repository-source-snapshot repository-source)
  (list 'repositorySource
        (list 'kind (hash-get repository-source 'kind))
        (list 'vcs (hash-get repository-source 'vcs))
        (list 'repository (hash-get repository-source 'repository))
        (list 'url (hash-get repository-source 'url))
        (list 'status (hash-get repository-source 'status))
        (list 'owner (hash-get repository-source 'owner))))
;; : (-> IndexHint Snapshot )
(def (index-hint-snapshot index-hint)
  (list 'indexHint
        (list 'owner (hash-get index-hint 'owner))
        (list 'backend (hash-get index-hint 'backend))
        (list 'mode (hash-get index-hint 'mode))))
;; : (-> String Selector )
(def (pattern-selector-snapshot selector)
  (list 'selector
        (list 'role (hash-get selector 'role))
        (list 'symbol (hash-get selector 'symbol))
        (list 'selector (hash-get selector 'selector))))
;; : (-> Form Snapshot )
(def (pattern-form-snapshot form)
  (list 'form
        (list 'role (hash-get form 'role))
        (list 'symbol (hash-get form 'symbol))
        (pattern-form-template-snapshot (hash-get form 'template))
        (list 'selector (hash-get form 'selector))))
;; : (-> Template Snapshot )
(def (pattern-form-template-snapshot template)
  (list 'template
        (list 'head (hash-get template 'head))
        (list 'operands (list-copy (hash-get template 'operands)))
        (list 'keywords (list-copy (hash-get template 'keywords)))))
;; : (-> Failure SnapshotField )
(def (failure-risk-field-snapshot failure)
  (if (hash-key? failure 'riskKind)
    (list 'riskKind (hash-get failure 'riskKind))
    (list 'risk (hash-get failure 'risk))))
;; : (-> Failure SnapshotField )
(def (failure-correction-field-snapshot failure)
  (if (hash-key? failure 'correctiveAction)
    (list 'correctiveAction (hash-get failure 'correctiveAction))
    (list 'correction (hash-get failure 'correction))))
;; : (-> Failure SnapshotField )
(def (failure-bad-pattern-field-snapshot failure)
  (list 'badPattern
        (if (hash-key? failure 'badPattern)
          (hash-get failure 'badPattern)
          "")))
;; : (-> Failure SnapshotField )
(def (failure-selectors-field-snapshot failure)
  (list 'selectors
        (if (hash-key? failure 'selectors)
          (list-copy (hash-get failure 'selectors))
          '())))
;; : (-> Failure Snapshot )
(def (pattern-failure-case-snapshot failure)
  (list 'failureCase
        (list 'id (snapshot-packet-id failure))
        (failure-risk-field-snapshot failure)
        (failure-correction-field-snapshot failure)
        (failure-bad-pattern-field-snapshot failure)
        (failure-selectors-field-snapshot failure)))
;; : (-> Query Pattern Missing Next Snapshot )
(def (pattern-search-snapshot query pattern missing next)
  (let (missing-items (list-copy missing))
    (list 'patternSearch
          (list 'namespace "pattern")
          (list 'authority "executable-pattern")
          (list 'evidenceGrade (if pattern "fact" "unknown"))
          (list 'quality (cond
                          ((not pattern) "insufficient")
                          ((null? missing) "verified")
                          (else "partial")))
          (list 'query query)
          (list 'pattern (and pattern (pattern-evidence-snapshot pattern)))
          (list 'missing missing-items)
          (list 'witness (if pattern (hash-get pattern 'witness) "pending"))
          (list 'next next))))
;;; Boundary:
;;; - runtime-source-fact-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Fact Snapshot )
(def (runtime-source-fact-snapshot fact)
  (let* ((details (hash-get fact 'details))
         (source-ref (hash-get details 'sourceRef))
         (acquisition (hash-get details 'acquisition)))
    (list 'runtimeSourceFact
          (list 'id (snapshot-packet-id fact))
          (list 'summary (hash-get fact 'summary))
          (list 'evidenceGrade (hash-get fact 'evidenceGrade))
          (list 'witness (hash-get fact 'witness))
          (runtime-source-ref-snapshot source-ref)
          (runtime-source-acquisition-snapshot acquisition)
          (optional-snapshot 'selectorResolver details selector-resolver-snapshot)
          (list 'sourceExamples
                (map source-example-snapshot
                     (snapshot-detail-list-value details 'sourceExamples)))
          (list 'sourceComments
                (map source-comment-snapshot
                     (snapshot-detail-list-value details 'sourceComments)))
          (list 'selectors
                (map evidence-selector-snapshot
                     (hash-get fact 'selectors)))
          (list 'agentScenario (hash-get fact 'agentScenario))
          (list 'intent (hash-get fact 'intent))
          (list 'failureCases
                (map evidence-failure-case-snapshot
                     (hash-get fact 'failureCases)))
          (list 'qualitySignals
                (list-copy (hash-get fact 'qualitySignals))))))
;; : (-> SourceRef Snapshot )
(def (runtime-source-ref-snapshot source-ref)
  (list 'sourceRef
        (list 'kind (hash-get source-ref 'kind))
        (list 'manager (hash-get source-ref 'manager))
        (list 'repository (hash-get source-ref 'repository))
        (list 'checkoutPolicy (hash-get source-ref 'checkoutPolicy))
        (list 'statePathPolicy (hash-get source-ref 'statePathPolicy))
        (list 'selectorScheme (hash-get source-ref 'selectorScheme))))
;; : (-> Acquisition Snapshot )
(def (runtime-source-acquisition-snapshot acquisition)
  (list 'acquisition
        (list 'owner (hash-get acquisition 'owner))
        (list 'operation (hash-get acquisition 'operation))
        (list 'stateNamespace (hash-get acquisition 'stateNamespace))
        (list 'indexOwner (hash-get acquisition 'indexOwner))))
;; : (-> String Selector )
(def (evidence-selector-snapshot selector)
  (list 'selector
        (list 'role (hash-get selector 'role))
        (list 'symbol (hash-get selector 'symbol))
        (list 'selector (hash-get selector 'selector))))
;; : (-> Failure String )
(def (evidence-failure-case-snapshot failure)
  (list 'failureCase
        (list 'id (snapshot-packet-id failure))
        (list 'risk (failure-risk-snapshot failure))
        (list 'correction (failure-correction-snapshot failure))))
;; : (-> Failure String )
(def (failure-risk-snapshot failure)
  (cond
   ((hash-key? failure 'risk) (hash-get failure 'risk))
   ((hash-key? failure 'riskKind) (hash-get failure 'riskKind))
   (else "unknown")))
;; : (-> Failure String )
(def (failure-correction-snapshot failure)
  (cond
   ((hash-key? failure 'correction) (hash-get failure 'correction))
   ((hash-key? failure 'correctiveAction) (hash-get failure 'correctiveAction))
   (else "unknown")))
;;; Boundary:
;;; - runtime-source-search-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Query (List RuntimeSourceFact) Next Snapshot )
(def (runtime-source-search-snapshot query facts next)
  (let-values (((grade quality missing witness)
                (runtime-source-search-summary facts)))
    (list 'runtimeSourceSearch
          (list 'namespace "runtime-source")
          (list 'authority "runtime-version-source")
          (list 'evidenceGrade grade)
          (list 'quality quality)
          (list 'query query)
          (list 'facts (map runtime-source-fact-snapshot facts))
          (list 'missing missing)
          (list 'witness witness)
          (list 'next next))))
;; : (-> (List RuntimeSourceFact) (Values EvidenceGrade Quality Missing Witness) )
(def (runtime-source-search-summary facts)
  (if (null? facts)
    (values "unknown" "insufficient" (list "runtime-source-fact") "pending")
    (values "fact" "version-matched-source-plan" '()
            (hash-get (car facts) 'witness))))
;;; Boundary:
;;; - language-evidence-fact-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> LanguageEvidenceFact Snapshot )
(def (language-evidence-fact-snapshot fact)
  (list 'languageEvidenceFact
        (list 'id (snapshot-packet-id fact))
        (list 'summary (hash-get fact 'summary))
        (list 'evidenceGrade (hash-get fact 'evidenceGrade))
        (list 'witness (hash-get fact 'witness))
        (list 'next (hash-get fact 'next))
        (language-evidence-details-snapshot (hash-get fact 'details))
        (list 'selectors
              (map evidence-selector-snapshot
                   (hash-get fact 'selectors)))
        (list 'agentScenario (hash-get fact 'agentScenario))
        (list 'intent (hash-get fact 'intent))
        (list 'failureCases
              (map evidence-failure-case-snapshot
                   (hash-get fact 'failureCases)))
        (list 'qualitySignals
              (list-copy (hash-get fact 'qualitySignals)))))
;; : (-> Details String )
(def (language-evidence-details-snapshot details)
  (cons 'details
        (append
         (if (hash-key? details 'gerbilHome)
           [(list 'runtimeResolved #t)
            (list 'gxiExists (hash-get details 'gxiExists))
            (list 'gscExists (hash-get details 'gscExists))
            (list 'loadPathKnown (pair? (hash-get details 'loadPath)))]
           '())
         (snapshot-detail-string details 'rule)
         (snapshot-detail-string details 'authority)
         (snapshot-detail-string details 'module)
         (snapshot-detail-list details 'capabilities)
         (snapshot-detail-string details 'minimalImport)
         (snapshot-detail-string details 'runtimeSourceSelector)
         (snapshot-detail-object details 'selectorResolver selector-resolver-snapshot)
         (snapshot-detail-objects details 'sourceExamples source-example-snapshot)
         (snapshot-detail-objects details 'sourceComments source-comment-snapshot)
         (snapshot-detail-string details 'reference)
         (snapshot-detail-string details 'testDirectory)
         (snapshot-detail-list details 'policyRules)
         (snapshot-detail-string details 'styleDoc))))
;; : (-> Details Key String )
(def (snapshot-detail-string details key)
  (if (hash-key? details key)
    [(list key (hash-get details key))]
    '()))
;; : (-> Details Key Snapshot )
(def (snapshot-detail-list details key)
  (if (hash-key? details key)
    [(list key (list-copy (hash-get details key)))]
    '()))
;; : (-> Details Key Snapshot )
(def (snapshot-detail-list-value details key)
  (if (hash-key? details key)
    (hash-get details key)
    []))
;; : (-> Details Key SnapshotProc Snapshot )
(def (snapshot-detail-object details key snapshot-proc)
  (if (hash-key? details key)
    [(snapshot-proc (hash-get details key))]
    '()))
;;; Boundary:
;;; - snapshot-detail-objects composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Details Key SnapshotProc Snapshot )
(def (snapshot-detail-objects details key snapshot-proc)
  (if (hash-key? details key)
    [(list key (map snapshot-proc (hash-get details key)))]
    '()))
;; : (-> Label Details SnapshotProc Snapshot )
(def (optional-snapshot label details snapshot-proc)
  (if (hash-key? details label)
    (snapshot-proc (hash-get details label))
    (list label #f)))
;; : (-> Resolver Selector )
(def (selector-resolver-snapshot resolver)
  (list 'selectorResolver
        (list 'scheme (hash-get resolver 'scheme))
        (list 'owner (hash-get resolver 'owner))
        (list 'stateNamespace (hash-get resolver 'stateNamespace))
        (list 'selectorFormat (hash-get resolver 'selectorFormat))
        (list 'output (hash-get resolver 'output))
        (list 'indexOwner (hash-get resolver 'indexOwner))))
;; : (-> Example Snapshot )
(def (source-example-snapshot example)
  (list 'sourceExample
        (list 'id (snapshot-packet-id example))
        (list 'role (hash-get example 'role))
        (list 'symbol (hash-get example 'symbol))
        (list 'selector (hash-get example 'selector))
        (source-example-form-snapshot (hash-get example 'form))
        (list 'commentMode (hash-get example 'commentMode))))
;; : (-> Form Snapshot )
(def (source-example-form-snapshot form)
  (list 'form
        (list 'head (hash-get form 'head))
        (list 'operands (list-copy (hash-get form 'operands)))
        (list 'keywords (list-copy (hash-get form 'keywords)))))
;; : (-> Comment Snapshot )
(def (source-comment-snapshot comment)
  (list 'sourceComment
        (list 'id (snapshot-packet-id comment))
        (list 'selector (hash-get comment 'selector))
        (list 'extractor (hash-get comment 'extractor))
        (list 'summary (hash-get comment 'summary))
        (list 'fallback (hash-get comment 'fallback))))
;;; Boundary:
;;; - language-evidence-search-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Namespace Authority Query (List String) Next String )
(def (language-evidence-search-snapshot namespace authority query facts next)
  (list 'languageEvidenceSearch
        (list 'namespace namespace)
        (list 'authority authority)
        (list 'evidenceGrade (if (null? facts) "unknown" "fact"))
        (list 'query query)
        (list 'facts (map language-evidence-fact-snapshot facts))
        (list 'next next)))
;; : (-> (List String) String )
(def (guide-snapshot lines)
  (list 'guide
        (list 'lines (list-copy lines))))
;;; Boundary:
;;; - registry-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Registry Snapshot )
(def (registry-snapshot registry)
  (let* ((language (car (hash-get registry 'languages)))
         (schemas (hash-get language 'schemas))
         (descriptors (hash-get language 'methodDescriptors)))
    (list 'registry
          (list 'registryId (hash-get registry 'registryId))
          (list 'registryVersion (hash-get registry 'registryVersion))
          (list 'languageId (hash-get language 'languageId))
          (list 'providerId (hash-get language 'providerId))
          (list 'methods (list-copy (hash-get language 'methods)))
          (list 'schemas (map schema-registry-entry-snapshot schemas))
          (list 'methodDescriptors
                (map method-descriptor-snapshot descriptors)))))
;; : (-> Schema Snapshot )
(def (schema-registry-entry-snapshot schema)
  (list 'schema
        (list 'schemaId (hash-get schema 'schemaId))
        (list 'schemaVersion (hash-get schema 'schemaVersion))
        (list 'path (hash-get schema 'path))))
;; : (-> Descriptor Snapshot )
(def (method-descriptor-snapshot descriptor)
  (list 'methodDescriptor
        (list 'method (hash-get descriptor 'method))
        (list 'command (hash-get descriptor 'command))
        (list 'outputSchemaIds
              (list-copy (hash-get descriptor 'outputSchemaIds)))))
;;; Boundary:
;;; - compare-fact-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Fact Snapshot )
(def (compare-fact-snapshot fact)
  (list 'comparison
        (list 'id (snapshot-packet-id fact))
        (list 'summary (hash-get fact 'summary))
        (list 'evidenceGrade (hash-get fact 'evidenceGrade))
        (list 'witness (hash-get fact 'witness))
        (list 'next (hash-get fact 'next))
        (compare-side-snapshot 'left (hash-get fact 'left))
        (compare-side-snapshot 'right (hash-get fact 'right))
        (list 'result (hash-get fact 'result))
        (list 'agentScenario (hash-get fact 'agentScenario))
        (list 'intent (hash-get fact 'intent))
        (list 'failureCases
              (map evidence-failure-case-snapshot
                   (hash-get fact 'failureCases)))
        (list 'qualitySignals
              (list-copy (hash-get fact 'qualitySignals)))))
;; : (-> Label Side String )
(def (compare-side-snapshot label side)
  (cons label
        (append
         [(list 'kind (hash-get side 'kind))]
         (if (hash-key? side 'gxiResolved)
           [(list 'gxiResolved (hash-get side 'gxiResolved))]
           '())
         (if (hash-key? side 'gscResolved)
           [(list 'gscResolved (hash-get side 'gscResolved))]
           '())
         (snapshot-detail-string side 'source)
         (snapshot-detail-string side 'status)
         (snapshot-detail-list side 'targetVersions)
         (snapshot-detail-string side 'compileMode)
         (snapshot-detail-string side 'stateNamespace))))
;;; Boundary:
;;; - compare-search-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Query (List CompareFact) Next Snapshot )
(def (compare-search-snapshot query facts next)
  (let-values (((grade quality missing witness)
                (compare-search-summary facts)))
    (list 'compareSearch
          (list 'namespace "compare")
          (list 'authority "active-runtime-vs-documented")
          (list 'evidenceGrade grade)
          (list 'quality quality)
          (list 'query query)
          (list 'comparisons (map compare-fact-snapshot facts))
          (list 'missing missing)
          (list 'witness witness)
          (list 'next next))))
;; : (-> (List CompareFact) (Values EvidenceGrade Quality Missing Witness) )
(def (compare-search-summary facts)
  (if (null? facts)
    (values "unknown" "insufficient" (list "compare-fact") "pending")
    (values "fact" "verified" '()
            (hash-get (car facts) 'witness))))
;; : (-> TypeFinding Snapshot )
(def (finding-snapshot finding)
  [(type-finding-rule-id finding)
   (type-finding-path finding)
   (type-finding-selector finding)
   (type-finding-message finding)])
;;; Boundary:
;;; - self-apply-findings-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypeFinding) Snapshot )
(def (self-apply-findings-snapshot findings)
  (list 'selfApplyFindings
        (list 'languageId +language-id+)
        (list 'providerId +provider-id+)
        (list 'status (type-status findings))
        (list 'findingCount (length findings))
        (list 'findings (map finding-snapshot findings))))
;;; Boundary:
;;; - check-report-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) Snapshot )
(def (check-report-snapshot index findings)
  (list 'checkReport
        (list 'languageId +language-id+)
        (list 'providerId +provider-id+)
        (list 'status (type-status findings))
        (list 'findings (map finding-snapshot findings))))
