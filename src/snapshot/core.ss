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
        guide-snapshot
        registry-snapshot
        self-apply-findings-snapshot
        finding-snapshot
        check-report-snapshot)

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
