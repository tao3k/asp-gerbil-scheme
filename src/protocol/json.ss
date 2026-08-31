;;; -*- Gerbil -*-
;;; JSON projections for Gerbil parser-owned facts.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/constants
        :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/parser/query
        :asp-gerbil-scheme/src/policy/repair
        (only-in :asp-gerbil-scheme/src/protocol/json-output write-json-line)
        :asp-gerbil-scheme/src/protocol/structural-index
        :asp-gerbil-scheme/src/protocol/structural-facts
        (only-in :std/sort sort)
        (only-in :std/srfi/1 iota take)
        (only-in :std/sugar hash hash-key? hash-put!)
        :asp-gerbil-scheme/src/types/facade)

(export source-file-json
        project-package-json
        search-prime-packet-json
        structural-index-packet-json
        structural-index-artifact-packet-json
        native-syntax-owner-facts-packet-json
        pattern-mapping-json
        definition-json
        call-json
        module-import-json
        module-export-json
        macro-json
        binding-json
        poo-form-json
        higher-order-json
        dependency-adapter-quality-json
        top-form-json
        finding-json
        parse-error-json
        write-json-line)
;; String
(def +semantic-search-schema-id+
  "agent.semantic-protocols.semantic-search-packet")
;; String
(def +semantic-language-protocol-id+
  "agent.semantic-protocols.semantic-language")
;; ConfigConstant
(def +semantic-namespace+
  "agent.semantic-protocols.gerbil-scheme")
;;; Boundary:
;;; - source-file-json composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile Json )
(def (source-file-json file)
  (hash (path (source-file-path file))
        (package (source-file-package file))
        (prelude (source-file-prelude file))
        (namespace (source-file-namespace file))
        (imports (source-file-imports file))
        (exports (source-file-exports file))
        (includes (source-file-includes file))
        (definitions (map definition-json (source-file-definitions file)))
        (calls (map call-json (source-file-calls file)))
        (moduleImports (map module-import-json (source-file-module-imports file)))
        (moduleExports (map module-export-json (source-file-module-exports file)))
        (macros (map macro-json (source-file-macros file)))
        (bindings (map binding-json (source-file-bindings file)))
        (pooForms (map poo-form-json (source-file-poo-forms file)))
        (higherOrderForms
         (map higher-order-json (source-file-higher-order-forms file)))
        (controlFlowForms
         (map control-flow-json (source-file-control-flow-forms file)))
        (dependencyAdapterQualityFacts
         (map dependency-adapter-quality-json
              (source-file-dependency-adapter-quality-facts file)))
        (forms (map top-form-json (source-file-forms file)))
        (parseError (source-file-parse-error file))))
;; : (-> Package Json )
(def (project-package-json package)
  (and package
       (hash (path (project-package-path package))
             (name (project-package-name package))
             (dependencies (project-package-dependencies package))
             (fields (hash (packageManager (project-package-manager package))
                           (testDirectoryPolicy
                            (test-directory-policy-json
                             (project-package-test-directory-policy package)))
                           (macroGovernancePolicy
                            (macro-governance-policy-json
                             (project-package-macro-governance-policy package)))
                           (sourceScopePolicy
                            (source-scope-policy-json
                             (project-package-source-scope-policy package)))
                           (agentPolicy
                            (agent-policy-json
                             (project-package-agent-policy package))))))))
;; : (-> Policy Json )
(def (test-directory-policy-json policy)
  (and policy
       (hash (allowedDirectories
              (test-directory-policy-allowed-directories policy))
             (explanation
              (test-directory-policy-explanation policy)))))
;; : (-> Policy Json )
(def (macro-governance-policy-json policy)
  (and policy
       (hash (allowGenerated
              (macro-governance-policy-allow-generated policy))
             (explanation
              (macro-governance-policy-explanation policy))
             (witness
              (macro-governance-policy-witness policy)))))
;; : (-> Policy String )
(def (source-scope-policy-json policy)
  (and policy
       (hash (roots
              (source-scope-policy-roots policy))
             (runtimeRoots
              (source-scope-policy-runtime-roots policy))
             (excludeDirectories
              (source-scope-policy-exclude-directories policy))
             (explanation
              (source-scope-policy-explanation policy)))))
;; : (-> Policy Json )
(def (agent-policy-json policy)
  (and policy
       (hash (default "all-rules-enabled")
             (disabledRules
              (agent-policy-disabled-rules policy))
             (explanation
              (agent-policy-explanation policy)))))
;;; Boundary:
;;; - pattern-mapping-json composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Pattern Json )
(def (pattern-mapping-json pattern)
  (and pattern
       (let* ((source-ref (hash-get pattern 'sourceRef))
              (packet
               (hash (id (hash-get pattern 'id))
                     (extension (hash-get pattern 'extension))
                     (focus (hash-get pattern 'focus))
                     (origin (hash-get pattern 'origin))
                     (sourceRef source-ref)
                     (sourceOwners (hash-get pattern 'sourceOwners))
                     (agentScenario (hash-get pattern 'agentScenario))
                     (intent (hash-get pattern 'intent))
                     (selectors (map pattern-selector-json
                                     (hash-get pattern 'selectors)))
                     (minimalForms (map pattern-form-json
                                        (hash-get pattern 'minimalForms)))
                     (failureCases (map pattern-failure-case-json
                                         (hash-get pattern 'failureCases)))
                     (qualitySignals (hash-get pattern 'qualitySignals))
                     (witness (hash-get pattern 'witness)))))
         (pattern-attach-agent-guidance! packet pattern source-ref)
         (when (hash-key? pattern 'via)
           (hash-put! packet 'via (hash-get pattern 'via)))
         (when (hash-key? pattern 'importWitness)
           (hash-put! packet 'importWitness (hash-get pattern 'importWitness)))
         packet)))
;;; Boundary:
;;; - Pattern guidance mirrors compact search lines in the machine packet.
;;; - Logical package selectors must not be mistaken for workspace selectors.
;; : (-> Packet Pattern SourceRef Unit )
(def (pattern-attach-agent-guidance! packet pattern source-ref)
  (when (equal? (hash-get pattern 'extension) "poo")
    (when (hash-key? source-ref 'selectorScheme)
      (hash-put! packet 'selectorResolver
                 (pattern-selector-resolver-json source-ref)))
    (when (and (hash-key? source-ref 'localSource)
               (hash-key? source-ref 'repositorySource)
               (hash-key? source-ref 'indexHint))
      (hash-put! packet 'sourceLookup
                 (pattern-source-lookup-json source-ref)))
    (hash-put! packet 'agentReadOrder (pattern-agent-read-order-json))
    (hash-put! packet 'agentAction
               (pattern-agent-action-json
                (pattern-mapping-quality pattern)))))
;; : (-> SourceRef Json )
(def (pattern-selector-resolver-json source-ref)
  (hash (scheme (hash-get source-ref 'selectorScheme))
        (status "logical-selector")
        (querySelector "not-direct")
        (sourceRef (pattern-source-ref-summary source-ref))))
;; : (-> SourceRef Json )
(def (pattern-source-lookup-json source-ref)
  (let (index-hint (hash-get source-ref 'indexHint))
    (hash (order "local-source-before-git")
          (missingLocalAction (hash-get index-hint 'missingLocalAction))
          (fallbackPolicy (hash-get index-hint 'fallbackPolicy))
          (localSource (hash-get source-ref 'localSource))
          (repositorySource (hash-get source-ref 'repositorySource))
          (indexHint index-hint))))
;; Json
(def (pattern-agent-read-order-json)
  (hash (first "agentScenario")
        (second "agentSteering")
        (third "selectorResolver")
        (fourth "minimalForms")
        (fifth "failureCases")
        (sixth "quality")))
;; : (-> Quality Json )
(def (pattern-agent-action-json quality)
  (hash (action "use-minimalForms-before-editing")
        (selectorUse "source-anchor")
        (missingLocalAction "install-package-before-repository-fallback")
        (fallback "repository-source-after-install-check")
        (quality quality)
        (avoid "generic-scheme-or-racket-class-guess")))
;; : (-> Pattern Quality )
(def (pattern-mapping-quality pattern)
  (let (missing (if (hash-key? pattern 'missing)
                  (hash-get pattern 'missing)
                  []))
    (if (null? missing) "verified" "partial")))
;; : (-> SourceRef String )
(def (pattern-source-ref-summary source-ref)
  (string-append
   (hash-get source-ref 'kind)
   ":"
   (hash-get source-ref 'manager)
   ":"
   (hash-get source-ref 'dependency)
   ":"
   (hash-get source-ref 'pathPolicy)))
;; : (-> String Selector )
(def (pattern-selector-json selector)
  (hash (role (hash-get selector 'role))
        (symbol (hash-get selector 'symbol))
        (selector (hash-get selector 'selector))))
;; : (-> Form Json )
(def (pattern-form-json form)
  (hash (role (hash-get form 'role))
        (symbol (hash-get form 'symbol))
        (selector (hash-get form 'selector))
        (template (pattern-form-template-json
                   (hash-get form 'template)))))
;; : (-> Template Json )
(def (pattern-form-template-json template)
  (hash (head (hash-get template 'head))
        (operands (hash-get template 'operands))
        (keywords (hash-get template 'keywords))))
;; : (-> Failure Json )
(def (pattern-failure-case-json failure)
  (let (packet (hash (id (hash-get failure 'id))))
    (if (hash-key? failure 'riskKind)
      (begin
        (hash-put! packet 'riskKind (hash-get failure 'riskKind))
        (hash-put! packet 'correctiveAction (hash-get failure 'correctiveAction)))
      (begin
        (hash-put! packet 'risk (hash-get failure 'risk))
        (hash-put! packet 'correction (hash-get failure 'correction))))
    (when (hash-key? failure 'badPattern)
      (hash-put! packet 'badPattern (hash-get failure 'badPattern)))
    (hash-put! packet 'selectors
               (if (hash-key? failure 'selectors)
                 (hash-get failure 'selectors)
                 []))
    packet))
;;; Boundary:
;;; - search-prime-packet-json composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex Json )
(def (search-prime-packet-json index)
  (let* ((ranked-owners (ranked-files index))
         (owners (take ranked-owners (min 100 (length ranked-owners))))
         (owner-ranks (iota (length owners) 1))
         (package (project-index-package index))
         (extensions (project-extension-facts index))
         (packet
          (hash
           (schemaId +semantic-search-schema-id+)
           (schemaVersion "1")
           (protocolId +semantic-language-protocol-id+)
           (protocolVersion "1")
           (languageId +language-id+)
           (providerId +provider-id+)
           (binary +provider-id+)
           (namespace +semantic-namespace+)
           (method "search/prime")
           (projectRoot (project-index-root index))
           (view "prime")
           (renderMode "facts")
           (header (search-header-json index))
           (nodes (search-prime-nodes package extensions owners))
           (edges (search-prime-edges package extensions owners))
           (owners (map owner-json owners))
           (hits (map owner-hit-json owners owner-ranks))
           (findings '())
           (nextActions (list (hash (kind "search")
                                    (target "lexical")
                                    (scope (project-index-root index))
                                    (fields (hash (command
                                                   "asp-gerbil-scheme search lexical '<term>' owner tests --workspace . --view seeds"))))))
           (notes (list (hash (kind "parser")
                              (message "core-read-module native Scheme reader facts")))))))
    (when package
      (hash-put! packet 'packageName (project-package-name package))
      (hash-put! packet 'projectPackage (project-package-json package)))
    (hash-put! packet 'extensions (map extension-fact-json extensions))
    packet))
;; : (-> ProjectIndex Json )
(def (search-header-json index)
  (hash (kind "search-prime")
        (fields (hash (parser "core-read-module")
                      (files (length (project-index-files index)))
                      (definitions (length (project-definitions index)))))))
;;; Boundary:
;;; - search-prime-nodes composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Package Extensions (List Owner) (List Json) )
(def (search-prime-nodes package extensions owners)
  (append (if package (list (package-node-json package)) '())
          (map extension-node-json extensions)
          (map owner-node-json owners (iota (length owners) 1))))
;;; Boundary:
;;; - search-prime-edges composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Package Extensions (List Owner) (List Json) )
(def (search-prime-edges package extensions owners)
  (if package
    (append (map (lambda (extension)
                   (hash (from (package-node-id package))
                         (kind "activates")
                         (to (extension-node-id extension))))
                 extensions)
            (map (lambda (owner)
                   (hash (from (package-node-id package))
                         (kind "owns")
                         (to (owner-node-id owner))))
                 owners))
    '()))
;; : (-> Package String )
(def (package-node-id package)
  (string-append "package:" (project-package-name package)))
;; : (-> Extension String )
(def (extension-node-id extension)
  (string-append "extension:" (extension-fact-name extension)))
;; : (-> SourceFile String )
(def (owner-node-id file)
  (string-append "owner:" (source-file-path file)))
;; : (-> Package Json )
(def (package-node-json package)
  (hash (id (package-node-id package))
        (kind "package")
        (path (project-package-path package))
        (fields (hash (name (project-package-name package))
                      (packageManager (project-package-manager package))
                      (dependencies (project-package-dependencies package))))))
;; : (-> Extension Json )
(def (extension-node-json extension)
  (hash (id (extension-node-id extension))
        (kind "extension")
        (fields (hash (name (extension-fact-name extension))
                      (activation (extension-fact-activation extension))
                      (dependencyMode (extension-fact-dependency-mode extension))
                      (packageManager (extension-fact-package-manager extension))
                      (package (extension-fact-package extension))
                      (dependencies (extension-fact-dependencies extension))
                      (capabilities (extension-fact-capabilities extension))))))
;; : (-> SourceFile Integer Json )
(def (owner-node-json file rank)
  (hash (id (owner-node-id file))
        (kind "owner")
        (path (source-file-path file))
        (rank rank)
        (fields (owner-fields-json file))))
;; : (-> SourceFile Json )
(def (owner-json file)
  (hash (path (source-file-path file))
        (role "source")
        (public #t)
        (exports (source-file-exports file))
        (fields (owner-fields-json file))))
;; : (-> SourceFile Json )
(def (owner-fields-json file)
  (hash (package (or (source-file-package file) ""))
        (definitions (length (source-file-definitions file)))
        (imports (length (source-file-imports file)))
        (includes (length (source-file-includes file)))))
;; : (-> SourceFile Integer Json )
(def (owner-hit-json file rank)
  (hash (kind "owner")
        (ownerPath (source-file-path file))
        (location (owner-location-json file))
        (score rank)
        (reason "ranked-owner")
        (fields (owner-fields-json file))))
;; : (-> SourceFile Json )
(def (owner-location-json file)
  (hash (path (source-file-path file))
        (lineRange (owner-line-range file))))
;; : (-> SourceFile OwnerLineRange )
(def (owner-line-range file)
  (let (definitions (source-file-definitions file))
    (if (null? definitions)
      "1:1"
      (let (first (car definitions))
        (string-append (number->string (definition-start first))
                       ":"
                       (number->string (definition-end first)))))))
;; : (-> Definition Json )
(def (definition-json defn)
  (hash (name (definition-name defn))
        (kind (definition-kind defn))
        (path (definition-path defn))
        (start (definition-start defn))
        (end (definition-end defn))
        (formals (definition-formals defn))
        (arity (definition-arity defn))
        (selector (definition-selector defn))))
;;; Boundary:
;;; - call-json composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> CallFact Json )
(def (call-json call)
  (hash (callee (call-fact-callee call))
        (arity (call-fact-arity call))
        (path (call-fact-path call))
        (start (call-fact-start call))
        (end (call-fact-end call))
        (arguments (call-fact-arguments call))
        (argumentTypes (map (lambda (type) (or type "unknown"))
                            (call-fact-argument-types call)))
        (caller (or (call-fact-caller call) ""))
        (selector (call-fact-selector call))))
;; : (-> Fact Json )
(def (module-import-json fact)
  (hash (module (module-import-fact-module fact))
        (phase (module-import-fact-phase fact))
        (modifier (module-import-fact-modifier fact))
        (alias (or (module-import-fact-alias fact) ""))
        (symbols (module-import-fact-symbols fact))
        (path (module-import-fact-path fact))
        (start (module-import-fact-start fact))
        (end (module-import-fact-end fact))
        (selector (module-import-fact-selector fact))))
;; : (-> Fact Json )
(def (module-export-json fact)
  (hash (name (module-export-fact-name fact))
        (modifier (module-export-fact-modifier fact))
        (alias (or (module-export-fact-alias fact) ""))
        (module (or (module-export-fact-module fact) ""))
        (symbols (module-export-fact-symbols fact))
        (path (module-export-fact-path fact))
        (start (module-export-fact-start fact))
        (end (module-export-fact-end fact))
        (selector (module-export-fact-selector fact))))
;; : (-> Fact Json )
(def (macro-json fact)
  (hash (name (macro-fact-name fact))
        (kind (macro-fact-kind fact))
        (path (macro-fact-path fact))
        (start (macro-fact-start fact))
        (end (macro-fact-end fact))
        (transformer (macro-fact-transformer fact))
        (phase (macro-fact-phase fact))
        (patternCount (macro-fact-pattern-count fact))
        (hygienicSyntax (macro-fact-hygienic fact))
        (qualityFacets (macro-fact-quality-facets fact))
        (selector (macro-fact-selector fact))))
;; : (-> Fact Json )
(def (binding-json fact)
  (hash (name (binding-fact-name fact))
        (kind (binding-fact-kind fact))
        (path (binding-fact-path fact))
        (start (binding-fact-start fact))
        (end (binding-fact-end fact))
        (scope (binding-fact-scope fact))
        (valueType (or (binding-fact-value-type fact) "unknown"))
        (selector (binding-fact-selector fact))))
;; : (-> Fact Json )
(def (poo-form-json fact)
  (hash (name (poo-form-fact-name fact))
        (kind (poo-form-fact-kind fact))
        (path (poo-form-fact-path fact))
        (start (poo-form-fact-start fact))
        (end (poo-form-fact-end fact))
        (role (poo-form-fact-role fact))
        (generic (or (poo-form-fact-generic fact) ""))
        (receiver (or (poo-form-fact-receiver fact) ""))
        (receiverType (or (poo-form-fact-receiver-type fact) ""))
        (supers (poo-form-fact-supers fact))
        (slots (poo-form-fact-slots fact))
        (options (poo-form-fact-options fact))
        (specializers (poo-form-fact-specializers fact))
        (specializerTypes (poo-form-fact-specializer-types fact))
        (selector (poo-form-fact-selector fact))))
;; : (-> Fact Json )
(def (higher-order-json fact)
  (hash (name (higher-order-fact-name fact))
        (kind (higher-order-fact-kind fact))
        (path (higher-order-fact-path fact))
        (start (higher-order-fact-start fact))
        (end (higher-order-fact-end fact))
        (role (higher-order-fact-role fact))
        (operandCount (higher-order-fact-operand-count fact))
        (arities (higher-order-fact-arities fact))
        (formals (higher-order-fact-formals fact))
        (caller (or (higher-order-fact-caller fact) ""))
        (qualityFacets (higher-order-quality-facets fact))
        (selector (higher-order-fact-selector fact))))
;; : (-> ControlFlowFact Json )
(def (control-flow-json fact)
  (hash (name (control-flow-fact-name fact))
        (kind (control-flow-fact-kind fact))
        (path (control-flow-fact-path fact))
        (start (control-flow-fact-start fact))
        (end (control-flow-fact-end fact))
        (role (control-flow-fact-role fact))
        (caller (or (control-flow-fact-caller fact) ""))
        (bindingCount (control-flow-fact-binding-count fact))
        (bodyFormCount (control-flow-fact-body-form-count fact))
        (qualityFacets (control-flow-quality-facets fact))
        (selector (control-flow-fact-selector fact))))

;;; Boundary:
;;; - JSON projection is the stable API surface for R017 evidence.
;;; - Policy, guide, and structural owner facts consume these fields.
;;; - Field names must stay aligned with schema snapshots.
;;; - Parser internals may evolve without changing downstream packet keys.
;; : (-> DependencyAdapterQualityFact Json )
(def (dependency-adapter-quality-json fact)
  (hash (name (dependency-adapter-quality-fact-name fact))
        (kind (dependency-adapter-quality-fact-kind fact))
        (path (dependency-adapter-quality-fact-path fact))
        (start (dependency-adapter-quality-fact-start fact))
        (end (dependency-adapter-quality-fact-end fact))
        (role (dependency-adapter-quality-fact-role fact))
        (dependency (dependency-adapter-quality-fact-dependency fact))
        (imports (dependency-adapter-quality-fact-imports fact))
        (importedSymbols
         (dependency-adapter-quality-fact-imported-symbols fact))
        (usedSymbols (dependency-adapter-quality-fact-used-symbols fact))
        (protocolRefs
         (dependency-adapter-quality-fact-protocol-refs fact))
        (slots (dependency-adapter-quality-fact-slots fact))
        (derivedCapabilities
         (dependency-adapter-quality-fact-derived-capabilities fact))
        (manualObjectEncodingRisk
         (dependency-adapter-quality-fact-manual-object-encoding-risk fact))
        (genericContractWitnessKind
         (dependency-adapter-quality-fact-generic-contract-witness-kind fact))
        (quality (dependency-adapter-quality-fact-quality fact))
        (qualityFacets
         (dependency-adapter-quality-fact-quality-facets fact))
        (missingEvidence
         (dependency-adapter-quality-fact-missing-evidence fact))
        (advice (dependency-adapter-quality-fact-advice fact))
        (selector (dependency-adapter-quality-fact-selector fact))))

;; : (-> Form Json )
(def (top-form-json form)
  (hash (kind (top-form-kind form))
        (head (top-form-head form))
        (path (top-form-path form))
        (start (top-form-start form))
        (end (top-form-end form))
        (selector (top-form-selector form))))
;; : (-> TypeFinding Json )
(def (finding-json finding)
  (let ((packet (hash (ruleId (type-finding-rule-id finding))
                      (severity (type-finding-severity finding))
                      (path (type-finding-path finding))
                      (message (type-finding-message finding))
                      (selector (type-finding-selector finding))
                      (details (type-finding-details finding))))
        (repair (finding-agent-repair-json finding)))
    (when repair
      (hash-put! packet 'agentRepair repair))
    packet))
;; : (-> SourceFile Json )
(def (parse-error-json file)
  (hash (path (source-file-path file))
        (ruleId "GERBIL-SCHEME-READ-R001")
        (message (source-file-parse-error file))))
