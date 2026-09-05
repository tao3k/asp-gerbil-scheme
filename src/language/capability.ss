;;; -*- Gerbil -*-
;;; Project-local Gerbil capability posture facts for agent steering.

(import :asp-gerbil-scheme/src/language/evidence
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/catalog
        (only-in :std/srfi/1 append-map take)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar cut filter ormap))

(export capability-posture-facts
        matching-capability-posture-facts)
;; : (-> MaybePackage (List ImportFact) CapabilityStatus )
(def (package-module-posture-status package module-imports)
  (if (or package (pair? module-imports)) "active" "weak"))
;; : (-> MaybePackage MaybeString )
(def (capability-package-name package)
  (and package (project-package-name package)))
;; : (-> MaybePackage MaybePath )
(def (capability-package-path package)
  (and package (project-package-path package)))
;; : (-> (List Fact) CapabilityStatus )
(def (active-or-available facts)
  (if (pair? facts) "active" "available"))
;; : (-> (List PooFact) Boolean CapabilityStatus )
(def (poo-posture-status poo-facts poo-active?)
  (cond
   ((pair? poo-facts) "active")
   (poo-active? "dependency-active")
   (else "inactive")))
;; : (-> (List Selector) (List Selector) )
(def (capability-selector-preview selectors)
  (take selectors (min 8 (length selectors))))
;;; Boundary:
;;; - matching-capability-posture-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List SearchTerm) (List Fact) )
(def (matching-capability-posture-facts index terms)
  (filter (cut capability-posture-matches-terms? <> terms)
          (capability-posture-facts index)))
;;; Boundary:
;;; - capability-posture-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List Fact) )
(def (capability-posture-facts index)
  (let* ((files (project-index-files index))
         (package (project-index-package index))
         (dependencies (if package (project-package-dependencies package) '()))
         (macro-facts (append-map source-file-macros files))
         (binding-facts (append-map source-file-bindings files))
         (poo-facts (append-map source-file-poo-forms files))
         (higher-order-facts (append-map source-file-higher-order-forms files))
         (control-flow-facts (append-map source-file-control-flow-forms files))
         (module-imports (append-map source-file-module-imports files))
         (poo-active? (or (pair? poo-facts)
                          (dependency-contains? dependencies "gerbil-poo"))))
    [(capability-posture-fact
     "package-module-posture"
     "package-module"
      (package-module-posture-status package module-imports)
      "Gerbil package/module/namespace/import facts should preserve project module shape instead of flattening into small-Scheme files."
      "parser-owned-package-and-module-facts"
      "search owner <path> --workspace . --view seeds"
      ["capability" "posture" "package" "module" "namespace" "import" "export"]
      (hash (files (length files))
            (package (capability-package-name package))
            (packagePath (capability-package-path package))
            (imports (length module-imports)))
      []
      ["package-module-style"]
      "agent-edits-gerbil-package-module"
      "keep-package-namespace-import-export-style-and-query-owner-before-editing")
     (capability-posture-fact
     "macro-posture"
     "macro"
      (active-or-available macro-facts)
      "Macro edits require parser facts plus runtime-source witness; do not write transformers from dialect memory."
      "parser-owned-macro-facts-and-runtime-source-route"
      "search runtime-source macro sugar"
      ["capability" "posture" "macro" "defsyntax" "defrule" "runtime-source" "hygienic"]
      (hash (macros (length macro-facts))
            (macroSelectors
             (let (selectors (map macro-fact-selector macro-facts))
               (capability-selector-preview selectors))))
      ["GERBIL-SCHEME-AGENT-POLICY-011"]
      ["macro-runtime-source-witness" "parser-owned-macro-heads"]
      "agent-edits-macro-or-syntax-transformer"
      "cite-runtime-source-and-parser-macro-fact-before-changing-transformers")
     (capability-posture-fact
     "poo-posture"
     "poo"
      (poo-posture-status poo-facts poo-active?)
      "POO dependency or parser POO forms should steer object modeling toward defclass/defgeneric/defmethod/protocol evidence."
      "package-dependency-and-parser-owned-poo-facts"
      "search pattern poo class"
      ["capability" "posture" "poo" "object" "defclass" "defgeneric" "defmethod" "protocol" "gerbil-poo"]
      (hash (dependencies dependencies)
            (pooForms (length poo-facts))
            (pooSelectors
             (let (selectors (map poo-form-fact-selector poo-facts))
               (capability-selector-preview selectors))))
      ["GERBIL-SCHEME-AGENT-POLICY-008" "GERBIL-SCHEME-AGENT-POLICY-012"]
      ["poo-method-shape" "protocol-evidence" "manual-object-encoding-opportunity"]
      "agent-models-objects-or-protocols-in-gerbil"
      "prefer-defclass-defgeneric-defmethod-or-protocol-when-poo-capability-is-active")
     (capability-posture-fact
     "higher-order-posture"
     "higher-order"
      (active-or-available higher-order-facts)
      "Pure data transforms should prefer Gerbil higher-order and functional combinators before introducing manual loops."
      "parser-owned-higher-order-facts"
      "projection --native-index --json --workspace ."
      ["capability" "posture" "higher-order" "map" "filter" "fold" "for/fold" "cut" "functional"]
      (hash (higherOrderForms (length higher-order-facts))
            (higherOrderSelectors
             (let (selectors (map higher-order-fact-selector higher-order-facts))
               (capability-selector-preview selectors))))
      ["GERBIL-SCHEME-AGENT-POLICY-009"]
      ["functional-data-transform" "typed-combinator-style"]
      "agent-writes-data-transform-or-loop"
      "use-map-filter-fold-for-fold-cut-for-pure-transforms")
     (capability-posture-fact
     "control-flow-posture"
     "control-flow"
      (active-or-available control-flow-facts)
      "Named control-flow facts identify where loops are IO/state/generator drivers rather than pure data transforms."
      "parser-owned-control-flow-facts"
      "projection --native-index --json --workspace ."
      ["capability" "posture" "control-flow" "named-let" "loop" "generator" "state" "driver"]
      (hash (controlFlowForms (length control-flow-facts))
            (controlFlowSelectors
             (let (selectors (map control-flow-fact-selector control-flow-facts))
               (capability-selector-preview selectors))))
      ["GERBIL-SCHEME-AGENT-POLICY-009"]
      ["manual-loop-functional-advice" "stateful-driver-exception"]
      "agent-edits-loop-or-driver"
      "preserve-named-let-for-io-state-generator-continuation-drivers")
     (capability-posture-fact
      "configurable-interface-posture"
      "configurable-interface"
      (configurable-interface-status package)
      "Downstream projects can override source scope and agent policy through gerbil.pkg policy without redeclaring built-in defaults."
      "parser-owned-gerbil.pkg-and-build.ss-policy"
      "info --json ."
      ["capability" "posture" "configurable" "interface" "source-scope" "agent-policy" "gerbil.pkg" "build.ss"]
      (hash (sourceScope (source-scope-status package))
            (agentPolicy (agent-policy-status package))
            (dependencies dependencies))
      []
      ["downstream-policy-override" "build-ss-runtime-root-fallback"]
      "agent-configures-downstream-project-harness"
      "use-gerbil.pkg-policy-overrides-only-when-project-declares-them")
     (capability-posture-fact
      "quality-closure-posture"
      "quality-closure"
      "declared-closure"
      "Agent-facing Gerbil engineering quality is closed through info, guide, check, self-apply, structural snapshots, and bench receipts."
      "info-owned-closure-commands-plus-parser-owned-policy-facts"
      "info --json ."
      ["capability" "posture" "quality" "closure" "engineering-quality" "agent-steering" "policy" "guide" "check" "self-apply" "bench" "snapshot" "search-projection" "source-class"]
      (hash (files (length files))
            (definitions (length (project-definitions index)))
            (agentRules (agent-steering-rule-ids))
            (facts (agent-steering-facts))
            (closures ["info" "guide" "check" "self-apply" "bench" "structural-snapshot"]))
      (agent-steering-rule-ids)
      ["policy-covered" "guide-covered" "snapshot-covered" "bench-covered" "check-covered" "self-apply-covered" "source-class-covered"]
      "agent-assesses-gerbil-project-quality-before-editing"
      "query-capability-posture-and-run-closure-commands-before-claiming-quality")]))
;; : (-> String Capability Status Summary Witness Next (List SearchTerm) Counts PolicyRules QualitySignals AgentScenario String Fact )
(def (capability-posture-fact id capability status summary witness next terms counts
                              policy-rules quality-signals agent-scenario intent)
  (evidence-fact
   id
   summary
   "fact"
   witness
   next
   terms
   (hash (capability capability)
         (status status)
         (counts counts)
         (policyRules policy-rules))
   []
   agent-scenario
   intent
   quality-signals
   [(hash (id "basic-scheme-fallback")
          (risk "agent-writes-generic-scheme-shape-when-gerbil-project-facts-expose-stronger-engineering-capability")
          (correction "query-capability-posture-and-structural-facts-before-editing"))]))
;;; Boundary:
;;; - capability-posture-matches-terms? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> CapabilityPosture (List SearchTerm) Boolean )
(def (capability-posture-matches-terms? fact terms)
  (or (null? terms)
      (ormap (lambda (term)
               (capability-posture-matches-term? fact term))
             terms)))

;;; One term is matched against a projected value set so capability facts can
;;; add fields without expanding the public search predicate.
;; : (-> CapabilityPosture SearchTerm Boolean )
(def (capability-posture-matches-term? fact term)
  (ormap (cut string-contains <> term)
         (capability-posture-search-values fact)))

;;; Boundary: capability search fields are projected as data before matching so
;;; adding a field does not grow the public predicate.
;; : (-> CapabilityPosture (List String) )
(def (capability-posture-search-values fact)
  (filter string?
          (append [(hash-get fact 'id)
                   (hash-get (hash-get fact 'details) 'capability)]
                  (hash-get fact 'terms))))
;;; Boundary:
;;; - dependency-contains? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List DependencyName) DependencyNeedle Boolean )
(def (dependency-contains? dependencies needle)
  (ormap (cut string-contains <> needle) dependencies))
;; : (-> Package Status )
(def (configurable-interface-status package)
  (cond
   ((not package) "builtin-defaults")
   ((or (project-package-source-scope-policy package)
        (project-package-agent-policy package))
    "project-overridden")
   (else "builtin-defaults")))
;; : (-> Package String )
(def (source-scope-status package)
  (let (policy (and package (project-package-source-scope-policy package)))
    (if policy
      (hash (status "project-overridden")
            (roots (source-scope-policy-roots policy))
            (runtimeRoots (source-scope-policy-runtime-roots policy))
            (excludeDirectories (source-scope-policy-exclude-directories policy))
            (explanation (source-scope-policy-explanation policy)))
      (hash (status "builtin-defaults")
            (roots ["."])
            (runtimeRoots [])
            (excludeDirectories [])
            (explanation "Builtin source-scope defaults apply unless gerbil.pkg policy overrides them.")))))
;; : (-> Package Status )
(def (agent-policy-status package)
  (let (policy (and package (project-package-agent-policy package)))
    (if policy
      (hash (status "project-overridden")
            (default "all-rules-enabled")
            (disabledRules (agent-policy-disabled-rules policy))
            (explanation (agent-policy-explanation policy)))
      (hash (status "builtin-defaults")
            (default "all-rules-enabled")
            (disabledRules [])
            (explanation #f)))))
