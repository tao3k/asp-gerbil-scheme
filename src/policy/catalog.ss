;;; -*- Gerbil -*-
;;; Central agent-facing policy rule catalog.

(import :asp-gerbil-scheme/src/policy/model
        (only-in :std/srfi/13 string-join string-prefix?))

(export agent-steering-facts
        agent-steering-rule-json
        agent-steering-rule-ids
        agent-steering-rule-id-string
        agent-rule-topic
        agent-rule-guide-topic
        agent-rule-guide-intent
        agent-rule-guide-next-command
        agent-rule-guide-route
        agent-rule-policy-lines)
;; (List Fact)
(def (agent-steering-facts)
  ["macroFacts"
   "definitionFacts"
   "callFacts"
   "bindingFacts"
   "pooFormFacts"
   "higherOrderFacts"
   "controlFlowFacts"
   "predicateFamilyFacts"
   "fieldAccessPatternFacts"
   "booleanConditionFacts"
   "loopDriverFacts"
   "dependencyAdapterQualityFacts"
   "functionQualityProfiles"
   "typedContractFacts"
   "commentQualityFacts"
   "dependencyUsageFacts"])

;;; Boundary:
;;; - agent-steering-rule-json coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;;; : (-> (List Hash))
;; Json
(def (agent-steering-rule-json)
  [(hash (id (policy-rule-id +modularity-source-leaf-rule+))
         (severity (policy-rule-severity +modularity-source-leaf-rule+))
         (topic "source-leaf-modularity")
         (guideTopic "source-leaf-modularity")
         (guideIntent "repair")
         (nextCommand "asp-gerbil-scheme projection --native-index --owner src/policy/modularity.ss --json --workspace .")
         (requires "source owners must stay below the 1000 effective-line hard limit; split oversized leaves into focused owners with facade imports when a public surface is needed"))
   (hash (id (policy-rule-id +modularity-test-leaf-rule+))
         (severity (policy-rule-severity +modularity-test-leaf-rule+))
         (topic "test-leaf-modularity")
         (guideTopic "test-leaf-modularity")
         (guideIntent "repair")
         (nextCommand "asp-gerbil-scheme projection --native-index --owner src/policy/modularity.ss --json --workspace .")
         (requires "test owners must stay below the 1000 effective-line hard limit; split oversized scenario or integration tests into focused test owners instead of hiding complexity in one leaf"))
   (hash (id (policy-rule-id +agent-poo-direct-writeenv-rule+))
         (severity (policy-rule-severity +agent-poo-direct-writeenv-rule+))
         (topic "poo-direct-writeenv")
         (next "facts runtime-source writeenv printer hook"))
   (hash (id (policy-rule-id +agent-poo-io-runtime-witness-rule+))
         (severity (policy-rule-severity +agent-poo-io-runtime-witness-rule+))
         (topic "poo-io-runtime-witness")
         (requires "runtime-source-backed writeenv/printer-hook witness"))
   (hash (id (policy-rule-id +agent-poo-method-shape-rule+))
         (severity (policy-rule-severity +agent-poo-method-shape-rule+))
         (topic "poo-method-shape")
         (guideTopic "poo-policy")
         (guideIntent "repair")
         (nextCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-008 --intent repair")
         (requires "defgeneric plus defclass or defprotocol receiver evidence"))
   (hash (id (policy-rule-id +agent-functional-idiom-advice-rule+))
         (severity (policy-rule-severity +agent-functional-idiom-advice-rule+))
         (topic "functional-data-transform")
         (guideTopic "functional-data-transform")
         (guideIntent "repair")
         (nextCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-009 --intent repair")
         (prefers "map/filter/fold/for/fold/cut for pure transforms")
         (keepsNamedLetWhen "IO/state/generator/continuation driver"))
   (hash (id (policy-rule-id +agent-poo-object-model-rule+))
         (severity (policy-rule-severity +agent-poo-object-model-rule+))
         (topic "manual-object-encoding")
         (requires "POO dependency or parser-owned POO facts should steer constructors toward defclass/defgeneric/defmethod/protocol"))
   (hash (id (policy-rule-id +agent-macro-runtime-source-witness-rule+))
         (severity (policy-rule-severity +agent-macro-runtime-source-witness-rule+))
         (topic "macro-runtime-source-witness")
         (guideTopic "macro-runtime-source")
         (guideIntent "witness")
         (nextCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-011 --intent witness")
         (next "facts runtime-source macro sugar module-sugar"))
   (hash (id (policy-rule-id +agent-protocol-evidence-rule+))
         (severity (policy-rule-severity +agent-protocol-evidence-rule+))
         (topic "protocol-evidence")
         (guideTopic "poo-policy")
         (guideIntent "repair")
         (nextCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-012 --intent repair")
         (next "facts poo protocol"))
   (hash (id (policy-rule-id +agent-typed-combinator-style-rule+))
         (severity (policy-rule-severity +agent-typed-combinator-style-rule+))
         (topic "typed-combinator-style")
         (guideTopic "typed-combinator-style")
         (guideIntent "style")
         (nextCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-013 --intent style")
         (next "guide --code --topic typed-combinator-style --intent style"))
   (hash (id (policy-rule-id +agent-controlled-branch-shape-rule+))
         (severity (policy-rule-severity +agent-controlled-branch-shape-rule+))
         (topic "controlled-branch-shape")
         (guideTopic "controlled-branch-shape")
         (guideIntent "style")
         (nextCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-014 --intent style")
         (requires "repeated match branches should be fixed only after parser-owned policy evidence, using helpers or bounded selector pipelines"))
   (hash (id (policy-rule-id +agent-comment-quality-rule+))
         (severity (policy-rule-severity +agent-comment-quality-rule+))
         (topic "engineering-comment-quality")
         (guideTopic "engineering-comment-quality")
         (guideIntent "style")
         (nextCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-015 --intent style")
         (requires "engineering comments should be driven by parser-owned commentQualityFacts evidence and may span multiple adjacent lines when needed"))
   (hash (id (policy-rule-id +agent-predicate-family-combinator-rule+))
         (severity (policy-rule-severity +agent-predicate-family-combinator-rule+))
         (topic "predicate-family-combinator")
         (guideTopic "predicate-family-combinator")
         (guideIntent "style")
         (nextCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style")
         (requires "parser-owned predicateFamilyFacts or combined high-count plus cross-caller fieldAccessPatternFacts before rewriting repeated field/role predicate helpers or selector access"))
   (hash (id (policy-rule-id +agent-dependency-protocol-adapter-rule+))
         (severity (policy-rule-severity +agent-dependency-protocol-adapter-rule+))
         (topic "dependency-protocol-adapter")
         (guideTopic "dependency-protocol-adapter")
        (guideIntent "repair")
        (nextCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-017 --intent repair")
        (requires "use the provider-owned rationaldict adapter exemplar, parser-owned dependencyAdapterQualityFacts, and a t/ contract witness before treating imported dependency primitives as an engineering boundary"))
   (hash (id (policy-rule-id +agent-explicit-precise-import-rule+))
         (severity (policy-rule-severity +agent-explicit-precise-import-rule+))
         (topic "explicit-precise-import")
         (guideTopic "explicit-precise-import")
         (guideIntent "repair")
         (nextCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-018 --intent repair")
         (requires "parser-owned moduleImportFacts should show only-in imports with explicit symbols for governed runtime library, dependency, and owner-local imports"))
   (hash (id (policy-rule-id +agent-package-build-responsibility-rule+))
         (severity (policy-rule-severity +agent-package-build-responsibility-rule+))
         (topic "package-build-responsibility")
         (guideTopic "package-build-responsibility")
         (guideIntent "repair")
         (nextCommand "asp-gerbil-scheme projection --native-index --owner src/cli.ss --json --workspace .")
         (requires "package-level build.ss next to gerbil.pkg should stay a build spec/orchestration owner; provider command routing and wrapper/script writer definitions belong in src/cli-launcher.ss or src/commands"))
   (hash (id (policy-rule-id +agent-build-runtime-quality-rule+))
         (severity (policy-rule-severity +agent-build-runtime-quality-rule+))
         (topic "build-runtime-quality")
         (guideTopic "build-runtime-quality")
         (guideIntent "repair")
         (nextCommand "asp-gerbil-scheme projection --native-index --owner src/policy/agent-build-runtime.ss --json --workspace .")
         (requires "build/runtime quality warnings require at least two independent parser-owned evidence groups, such as shell helper definitions plus shell control literals or sh -c dispatch plus pipeline literals; keep behavior in Gerbil runtime sources with list command arguments"))
   (hash (id (policy-rule-id +agent-package-build-canonical-shape-rule+))
         (severity (policy-rule-severity +agent-package-build-canonical-shape-rule+))
         (topic "package-build-canonical-shape")
         (guideTopic "package-build-canonical-shape")
         (guideIntent "repair")
         (nextCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-025 --intent repair")
         (requires "package-level build.ss should use a native Gerbil package build surface: :clan/building with all-gerbil-modules for src-root packages, :std/build-script defbuild-script for standard gxpkg packages, or :std/make build-spec for ssi:/gsc:/FFI builds; provider commands should run through the compiled package CLI module, not build.ss stages"))
   (hash (id (policy-rule-id +agent-poo-generated-receipt-boundary-rule+))
         (severity (policy-rule-severity +agent-poo-generated-receipt-boundary-rule+))
         (topic "poo-generated-receipt-boundary")
         (guideTopic "poo-policy")
         (guideIntent "repair")
         (nextCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-043 --intent repair")
         (requires "generated receipt/manifest/snapshot/handoff state should use defstruct internally and one explicit ->alist projection at the ABI boundary; native user POO declarations remain valid"))])
;;; Boundary:
;;; - agent-steering-rule-ids composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String
(def (agent-steering-rule-ids)
  (map (cut hash-get <> 'id) (agent-steering-rule-json)))
;; String
(def +agent-rule-prefix+ "GERBIL-SCHEME-AGENT-")
;;; Boundary:
;;; - agent-steering-rule-id-string composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String
(def (agent-steering-rule-id-string)
  (match (agent-steering-rule-ids)
    ([] "")
    ([first . rest]
     (string-join (cons first (map compact-agent-rule-id rest)) ","))))
;; : (-> RuleId String )
(def (compact-agent-rule-id rule-id)
  (if (string-prefix? +agent-rule-prefix+ rule-id)
    (substring rule-id
               (string-length +agent-rule-prefix+)
               (string-length rule-id))
    rule-id))
;;; Rule lookup: all agent-facing renderers resolve through this list search,
;;; so missing IDs fail as absent catalog data instead of ad hoc fallback text.
;; : (-> RuleId Rule )
(def (agent-rule-by-id rule-id)
  (and rule-id
       (find (lambda (rule)
               (equal? (hash-get rule 'id) rule-id))
             (agent-steering-rule-json))))
;; : (-> RuleId Field String )
(def (agent-rule-field rule-id field)
  (let (rule (agent-rule-by-id rule-id))
    (and rule (hash-key? rule field) (hash-get rule field))))
;; : (-> RuleId String )
(def (agent-rule-topic rule-id)
  (agent-rule-field rule-id 'topic))
;; : (-> RuleId String )
(def (agent-rule-guide-topic rule-id)
  (agent-rule-field rule-id 'guideTopic))
;; : (-> RuleId String )
(def (agent-rule-guide-intent rule-id)
  (agent-rule-field rule-id 'guideIntent))
;; : (-> RuleId String )
(def (agent-rule-guide-next-command rule-id)
  (agent-rule-field rule-id 'nextCommand))
;; : (-> RuleId GuideRoute )
(def (agent-rule-guide-route rule-id)
  (let ((topic (agent-rule-guide-topic rule-id))
        (intent (agent-rule-guide-intent rule-id))
        (next (agent-rule-guide-next-command rule-id)))
    (and topic intent next [topic intent next])))
;;; Boundary:
;;; - agent-rule-policy-lines composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List String)
(def (agent-rule-policy-lines)
  (map agent-rule-policy-line (agent-steering-rule-json)))
;;; Boundary:
;;; - agent-rule-policy-line coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> Rule String )
(def (agent-rule-policy-line rule)
  (let ((id (hash-get rule 'id))
        (topic (hash-get rule 'topic)))
    (cond
     ((equal? topic "poo-direct-writeenv")
      (string-append
       "|policy poo-direct-writeenv=" id
       " blocks raw writeenv calls until runtime-source writeenv/printer hook evidence is cited"))
     ((equal? topic "poo-io-runtime-witness")
      (string-append
       "|policy poo-io-runtime-witness=" id
       " keeps POO IO overrides partial until writeenv/printer-hook runtime witnesses exist"))
     ((equal? topic "poo-method-shape")
      (string-append
       "|policy poo-method-shape=" id
       " requires defmethod edits to have matching defgeneric plus defclass or defprotocol receiver evidence"))
     ((equal? topic "functional-data-transform")
      (string-append
       "|policy functional-data-transform=" id
       " steers pure data transforms toward map/filter/fold/for/fold/cut and keeps named let for IO/state/generator/continuation drivers"))
     ((equal? topic "manual-object-encoding")
      (string-append
       "|policy manual-object-encoding=" id
       " suggests POO/protocol constructors when dependency or parser-owned POO facts are active"))
     ((equal? topic "macro-runtime-source-witness")
      (string-append
       "|policy macro-runtime-source-witness=" id
       " requires macro edits to cite search runtime-source macro sugar module-sugar before changing transformers"))
     ((equal? topic "protocol-evidence")
      (string-append
       "|policy protocol-evidence=" id
       " requires protocol-oriented methods to cite parser-owned defprotocol/defclass evidence"))
     ((equal? topic "typed-combinator-style")
     (string-append
      "|policy typed-combinator-style=" id
       " requires three criteria: adjacent Haskell-like transform signature block, compact expression-level composition, and optimization-boundary comments for specialized branches"))
     ((equal? topic "controlled-branch-shape")
      (string-append
       "|policy controlled-branch-shape=" id
       " turns repeated match branches into a policy-triggered repair: split helpers or use bounded selector pipelines, preserve behavior, and avoid opportunistic style edits"))
     ((equal? topic "engineering-comment-quality")
      (string-append
       "|policy engineering-comment-quality=" id
       " lets parser-owned commentQualityFacts trigger richer multi-line comments and contract rationale before agent repair"))
     ((equal? topic "predicate-family-combinator")
      (string-append
       "|policy predicate-family-combinator=" id
       " turns repeated field/role predicate families into policy-triggered helper or combinator repair using parser-owned predicateFamilyFacts"))
     ((equal? topic "poo-generated-receipt-boundary")
      (string-append
       "|policy poo-generated-receipt-boundary=" id
       " steers generated receipt/manifest/snapshot/handoff state to defstruct plus one explicit ->alist ABI projection"))
    ((equal? topic "dependency-protocol-adapter")
      (string-append
       "|policy dependency-protocol-adapter=" id
       " tells agents that dependency primitives already provide the bottom data structure: run guide --code for the R017 code shape, avoid loose hash/alist objects, build a thin define-type/protocol adapter with precise only-in imports, Key/Value/validate/serialization/equality slots, derived table/set/list/sexp/json/marshal capabilities, and generic t/ contract witnesses"))
     ((equal? topic "build-runtime-quality")
      (string-append
       "|policy build-runtime-quality=" id
       " uses composite parser-owned definition/call evidence to block generated shell templates and sh -c pipelines in build/runtime support code"))
     (else
      (string-append "|policy " topic "=" id)))))
