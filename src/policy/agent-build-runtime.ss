;;; -*- Gerbil -*-
;;; Agent-facing build/runtime support quality policy.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-package-build-system
        :asp-gerbil-scheme/src/policy/detection
        :asp-gerbil-scheme/src/policy/model
        :asp-gerbil-scheme/src/policy/poo-source
        (only-in :std/srfi/1 count)
        (only-in :std/srfi/13 string-contains string-prefix? string-suffix?)
        (only-in :std/sugar cut filter filter-map hash ormap)
        :asp-gerbil-scheme/src/types/findings)

(export build-runtime-quality-findings
        build-runtime-quality-finding)

;; Integer
(def +build-runtime-min-evidence-groups+ 2)
;; Integer
(def +build-runtime-min-shell-helper-definitions+ 2)
;; Integer
(def +build-runtime-min-shell-control-markers+ 2)

;; (List GroupName)
(def +build-runtime-native-compile-required-groups+
  '("native-provider-compile-owner"
    "direct-native-exe-dispatch"
    "missing-native-link-wrapper"))

;; (List String)
(def +shell-helper-definition-markers+
  '("shell-" "-shell-" "sh-"))

;; (List String)
(def +shell-control-literal-markers+
  '("#!/bin/sh"
    "#!/usr/bin/env sh"
    "set -eu"
    "if ["
    "case "
    "esac"
    "fi\n"
    "$@"
    "${"
    "&&"
    "||"
    "trap "
    "exec "
    "|"
    "xargs"))

;; (List String)
(def +shell-dispatch-callees+
  '("invoke" "run-process" "open-process"))

;; (List String)
(def +native-provider-compile-owner-prefixes+
  '("compile-native-" "compile-full-native-" "run-native-"))

;; String
(def +native-wrapper-runtime-source+ "src/build-api/native-wrapper-runtime.ss")

;; String
(def +native-wrapper-binary-prefix+ "gerbil-native-")

;; (List ModuleNamePrefix)
(def +native-fast-disallowed-import-prefixes+
  '(":commands/"))

;;; Boundary:
;;; - Quality findings are composite gates over parser-owned definitions and
;;;   call arguments.
;;; - A single string marker is advisory evidence only.
;; : (-> ProjectIndex (List TypeFinding) )
(def (build-runtime-quality-findings index)
  (let (batches (map build-runtime-quality-findings/file
                     (project-index-files index)))
    (if (pair? batches)
      (apply append batches)
      '())))

;;; Data flow:
;;; - Each detection result is mapped to one finding with the same file owner.
;;; - `map` keeps result order stable so shell-template and native-safety
;;;   warnings stay deterministic when both detectors fire.
;;; Invariant:
;;; - This stays a projection over parser-owned detection results, not a manual
;;;   loop that could merge independent policy evidence.
;; : (-> SourceFile (List TypeFinding) )
(def (build-runtime-quality-findings/file file)
  (append
   (map (cut build-runtime-quality-finding<- file <>)
        (build-runtime-quality-detections file))
   (runtime-cache-version-findings file)))

;;; Finding contract:
;;; - The detection combinator owns the multi-evidence decision.
;;; - This rule owns the agent-facing repair message and build/runtime scope.
;; : (-> SourceFile MaybeTypeFinding )
(def (build-runtime-quality-finding file)
  (let (results (build-runtime-quality-detections file))
    (and (pair? results)
         (build-runtime-quality-finding<- file (car results)))))

;; : (-> SourceFile DetectionResult TypeFinding )
(def (build-runtime-quality-finding<- file result)
  (make-type-finding
   (policy-rule-id +agent-build-runtime-quality-rule+)
   (policy-rule-severity +agent-build-runtime-quality-rule+)
   (source-file-path file)
   (runtime-quality-message result)
   (detection-result-selector result (source-file-path file))
   (runtime-quality-details result)))

;; : (-> DetectionResult String )
(def (runtime-quality-message result)
  (cond
   ((runtime-native-compile-safety-result? result)
    "build/runtime support compiles provider native executables through a direct gxc -exe path; route provider executables through the timeout-safe native wrapper so existing binaries survive compiler hangs")
    ((runtime-native-fast-command-adapter-result? result)
     "native fast source imports a full command adapter; keep native-fast entrypoints dependency-light or route the command through the provider dispatcher runtime path")
    ((package-build-framework-overreach-result? result)
     "package-level build.ss is adding local phase/cache/stamp/worker ownership on top of Gerbil's build surface; keep std/make or clan/building as the build owner and move cache/receipt policy into reusable harness APIs")
    ((package-build-custom-system-result? result)
     "package-level build.ss is drifting into a hand-written build system; keep build.ss on gxpkg plus clan/building, std/build-script, or std/make build-spec and move command/runtime behavior into package modules")
   (else
    "build/runtime support code is drifting back to shell-template or sh -c pipeline orchestration; use Gerbil runtime sources, std/misc/process, list command arguments, and small launcher/config writers")))

;;; Compatibility helper for callers that expect one finding per source file.
;; : (-> SourceFile MaybeDetectionResult )
(def (build-runtime-quality-detection file)
  (let (results (build-runtime-quality-detections file))
    (and (pair? results) (car results))))

;;; Release/cache invariant:
;;; - Cache schema format versions may stay literal because they describe data
;;;   shape.
;;; - Runtime cache version identities must derive from +release-version+ so
;;;   launcher and command cache producers cannot drift after release bumps.
;; : (-> SourceFile (List TypeFinding) )
(def (runtime-cache-version-findings file)
  (map (cut runtime-cache-version-finding file <>)
       (filter cache-version-literal-binding?
               (source-file-bindings file))))

;;; Intentional raw data record:
;;; - TypeFinding details cross the provider JSON boundary as diagnostic
;;;   evidence.
;;; - This is not runtime object construction or a dependency protocol adapter.
;; : (-> SourceFile BindingFact TypeFinding )
(def (runtime-cache-version-finding file binding)
  (make-type-finding
   (policy-rule-id +agent-build-runtime-quality-rule+)
   (policy-rule-severity +agent-build-runtime-quality-rule+)
   (source-file-path file)
   "build/runtime cache version identity is hardcoded as a string; derive runtime cache version from +release-version+ and keep only the cache format version as a schema literal"
   (binding-fact-selector binding)
   (hash (kind "build-runtime-cache-version-release-drift")
         (bindingName (binding-fact-name binding))
         (bindingKind (binding-fact-kind binding))
         (bindingScope (binding-fact-scope binding))
         (valueType (binding-fact-value-type binding))
         (requiredEvidence "parser-owned top-level cache-version binding with string value type")
         (allowedShape "runtime cache version constants derive from +release-version+; cache format/schema constants may remain literal")
         (disallowedShape "top-level cache-version constants whose value type is a string literal")
         (next "import +release-version+ from :asp-gerbil-scheme/src/constants and define the runtime cache version from it; keep formatVersion as the separate cache schema literal"))))

;; : (-> BindingFact Boolean )
(def (cache-version-literal-binding? binding)
  (and (cache-version-binding-name? (binding-fact-name binding))
       (equal? (binding-fact-scope binding) "top-level")
       (equal? (binding-fact-value-type binding) "string")))

;; : (-> MaybeString Boolean )
(def (cache-version-binding-name? name)
  (and (string? name)
       (string-contains name "cache")
       (string-contains name "version")
       (not (string-contains name "format-version"))))

;;; Dispatch boundary:
;;; - A build/runtime owner may trip several independent runtime-quality
;;;   detectors.
;;; - Each detector stays prototype/combinator backed, not branch-hardcoded.
;; : (-> SourceFile (List DetectionResult) )
(def (build-runtime-quality-detections file)
  (filter-map
   (cut run-detection-prototype file <>)
   (build-runtime-quality-detection-prototypes file)))

;; : (-> SourceFile (List DetectionPrototype) )
(def (build-runtime-quality-detection-prototypes file)
  (cond
   ((build-runtime-source-file? file)
    [(build-runtime-shell-template-detection-prototype)
     (build-runtime-native-compile-safety-detection-prototype)])
   ((native-fast-runtime-source-file? file)
    [(native-fast-command-adapter-detection-prototype)])
   ((package-build-file? file)
    (package-build-quality-detection-prototypes))
   (else '())))

;;; Intentional raw data record:
;;; - Details stay JSON-shaped for command output because TypeFinding receipts
;;;   cross the provider JSON boundary as key/value diagnostic evidence.
;;; - This is not runtime object construction or a dependency protocol adapter.
;; : (-> DetectionResult PolicyDetails )
(def (runtime-quality-details result)
  (let (details (detection-result-details result))
    (hash (kind (runtime-quality-kind result))
        (detectionCombiner (hash-get details 'detectionCombiner))
        (detectionPrototype (hash-get details 'detectionPrototype))
        (detectionCombinerKind (hash-get details 'detectionCombinerKind))
        (detectionThreshold (hash-get details 'detectionThreshold))
        (requiredGroups (hash-get details 'requiredGroups))
        (missingGroups (hash-get details 'missingGroups))
        (detectionDescription (hash-get details 'detectionDescription))
        (detectionSourcePattern (hash-get details 'detectionSourcePattern))
        (detectionSourceOwners (hash-get details 'detectionSourceOwners))
        (detectionQualitySignals (hash-get details 'detectionQualitySignals))
        (detectionWitness (hash-get details 'detectionWitness))
        (evidenceGroups (hash-get details 'evidenceGroups))
        (evidenceCounts (hash-get details 'evidenceCounts))
        (evidenceSelectors (hash-get details 'evidenceSelectors))
        (requiredEvidence (runtime-quality-required-evidence result))
        (allowedShape (runtime-quality-allowed-shape result))
        (disallowedShape (runtime-quality-disallowed-shape result))
        (next (runtime-quality-next-action result)))))

;; : (-> DetectionResult String )
(def (runtime-quality-kind result)
  (cond
   ((runtime-native-compile-safety-result? result)
    "build-runtime-native-compile-safety")
    ((runtime-native-fast-command-adapter-result? result)
     "build-runtime-native-fast-command-adapter")
    ((package-build-framework-overreach-result? result)
     "package-build-framework-overreach")
    ((package-build-custom-system-result? result)
     "package-build-custom-system")
   (else "build-runtime-quality")))

;; : (-> DetectionResult String )
(def (runtime-quality-required-evidence result)
  (cond
   ((runtime-native-compile-safety-result? result)
    "native provider compile owner, direct gxc -exe dispatch, and missing native-wrapper delegation")
    ((runtime-native-fast-command-adapter-result? result)
     "native-fast source class plus parser-owned module import of a full command adapter")
    ((package-build-framework-overreach-result? result)
     "package build file, native Gerbil build surface, and local phase/cache/stamp ownership")
    ((package-build-custom-system-result? result)
     "package build file, missing native Gerbil build surface, and manual build orchestration")
   (else "at least two independent parser-owned groups")))

;; : (-> DetectionResult String )
(def (runtime-quality-allowed-shape result)
  (cond
   ((runtime-native-compile-safety-result? result)
    "provider native binaries are compiled through a build/runtime native-wrapper source via gerbil-native-link or gerbil-native-diagnose")
    ((runtime-native-fast-command-adapter-result? result)
     "native-fast sources import only dependency-light modules; full commands run through harness_runtime in the native dispatcher")
    ((package-build-framework-overreach-result? result)
     "build.ss delegates source discovery and compilation to clan/building, std/build-script, or std/make; optional acceleration is exposed as a thin harness API around the existing build entrypoint")
    ((package-build-custom-system-result? result)
     "package build delegates to a native Gerbil surface: gxpkg plus :clan/building for src-root discovery, :std/build-script for simple package templates, or :std/make build-spec for ssi:/gsc:/FFI/native build forms")
   (else "Gerbil runtime wrapper source plus list command arguments")))

;; : (-> DetectionResult String )
(def (runtime-quality-disallowed-shape result)
  (cond
   ((runtime-native-compile-safety-result? result)
    "direct gxc -exe invocation inside provider native compile owners without native wrapper timeout and atomic replacement")
    ((runtime-native-fast-command-adapter-result? result)
     "src/*-fast entrypoints importing :commands/* adapters and forcing full command graphs through native link")
    ((package-build-framework-overreach-result? result)
     "downstream build.ss defining its own phase receipt, stamp cache, cache freshness, or phase-skip control plane on top of std/make or clan/building")
    ((package-build-custom-system-result? result)
     "hand-written compiler dispatch, GERBIL_LOADPATH/source-root management, or local mini build orchestration inside build.ss")
   (else "generated shell templates or sh -c pipelines")))

;; : (-> DetectionResult String )
(def (runtime-quality-next-action result)
  (cond
   ((runtime-native-compile-safety-result? result)
    "replace direct gxc -exe provider builds with compile-build-runtime-executable! for gerbil-native-link/gerbil-native-diagnose and pass tmp/final/source as argv")
    ((runtime-native-fast-command-adapter-result? result)
     "delete the native-fast wrapper or split a real dependency-light fast implementation; route full command behavior through the dispatcher harness_runtime path")
    ((package-build-framework-overreach-result? result)
     "delete local phase/cache/stamp ownership from downstream build.ss; keep std/make or clan/building calls in place and move reusable acceleration/receipt behavior into a harness API that wraps the normal build entrypoint")
    ((package-build-custom-system-result? result)
     "replace the local build system with :clan/building plus all-gerbil-modules for src-root packages, :std/build-script defbuild-script for simple gxpkg packages, or :std/make build-spec for ssi:/gsc:/FFI builds; keep CLI commands in src/cli or src/commands")
   (else
    "move behavior into build/runtime source modules or normal Gerbil helpers; keep launchers as data/config writers")))

;; : (-> DetectionResult Boolean )
(def (runtime-native-compile-safety-result? result)
  (equal? (detection-result-prototype result)
          "build-runtime-native-compile-safety-all-of"))

;; : (-> DetectionResult Boolean )
(def (runtime-native-fast-command-adapter-result? result)
  (equal? (detection-result-prototype result)
          "native-fast-command-adapter-all-of"))

;;; Launcher quality is declared as a prototype: the threshold base owns the
;;; combiner shape, while this overlay owns build/runtime evidence slots.
;; : (-> DetectionPrototype )
(def (build-runtime-shell-template-detection-prototype)
  (detection-prototype-extend
   +threshold-detection-prototype+
   (poo-source-pattern-detection-overlay 'prototype-composition)
   (detection-prototype
    "build-runtime-shell-template-composite"
    'threshold
    [shell-helper-definition-evidence
     shell-control-literal-evidence
     shell-writer-call-evidence]
    +build-runtime-min-evidence-groups+
    '()
    "build/runtime shell-template drift requires multiple parser-owned evidence groups")))

;;; Native compile safety is stricter than shell-template drift:
;;; all three signals must align before warning, which keeps the bootstrap
;;; compile of gerbil-native-link itself outside the provider executable rule.
;; : (-> DetectionPrototype )
(def (build-runtime-native-compile-safety-detection-prototype)
  (detection-prototype-extend
   +all-of-detection-prototype+
   (poo-source-pattern-detection-overlay 'prototype-composition)
   (detection-prototype
    "build-runtime-native-compile-safety-all-of"
    'all-of
    [native-provider-compile-owner-evidence
     direct-native-exe-dispatch-evidence
     missing-native-link-wrapper-evidence]
    0
    +build-runtime-native-compile-required-groups+
    "native provider executable compilation requires timeout-safe wrapper delegation")))

;;; Native-fast sources should be small compiled entrypoints.  Importing a full
;;; command adapter is a graph-shape violation because it pushes parser, policy,
;;; repair, and protocol modules through native link.
;; : (-> DetectionPrototype )
(def (native-fast-command-adapter-detection-prototype)
  (detection-prototype-extend
   +all-of-detection-prototype+
   (poo-source-pattern-detection-overlay 'prototype-composition)
   (detection-prototype
    "native-fast-command-adapter-all-of"
    'all-of
    [native-fast-runtime-source-evidence
     native-fast-command-adapter-import-evidence]
    0
    ["native-fast-source" "full-command-adapter-import"]
    "native-fast entrypoints must not import full command adapters")))

;;; Data flow:
;;; The source file provides parser-owned DefinitionFact values.
;;; filter applies shell-helper-definition? to each DefinitionFact.
;;; The filtered list keeps parser order for selector choice.
;;; Arity evidence:
;;; shell-helper-definition? accepts one DefinitionFact.
;;; filter keeps the list shape and does not synthesize selectors.
;;; Invariant:
;;; Helper names are soft evidence only.
;;; The composite gate owns the decision to emit a finding.
;;; Hidden invariant:
;;; A manual loop could select a later helper.
;;; That would make finding selectors unstable across parser order changes.
;; : (-> SourceFile MaybeEvidenceGroup )
(def (shell-helper-definition-evidence file)
  (let (definitions (filter shell-helper-definition?
                            (source-file-definitions file)))
    (and (>= (length definitions) +build-runtime-min-shell-helper-definitions+)
         (evidence-group
          "shell-helper-definitions"
          (length definitions)
          (definition-selector (car definitions))))))

;;; Boundary:
;;; - One launcher heredoc can contain several shell-only controls.
;;; - The marker total measures payload density across parser literals.
;;; - The group still needs a second independent signal before warning.
;;; Data flow:
;;; - filter keeps only call facts whose string arguments satisfy the marker
;;;   predicate, then a separate total scores marker density.
;;; Arity evidence:
;;; - call-has-shell-control-literal? consumes one CallFact.
;;; - shell-control-marker-total consumes the filtered CallFact list.
;;; Invariant:
;;; - Selector choice follows the first parser call fact.
;;; - Count only affects
;;;   evidence strength.
;;; Hidden invariant:
;;; - The evidence selector remains independent from the scoring pass.
;; : (-> SourceFile MaybeEvidenceGroup )
(def (shell-control-literal-evidence file)
  (let* ((calls (filter call-has-shell-control-literal?
                        (source-file-calls file)))
         (count (shell-control-marker-total calls)))
    (and (>= count +build-runtime-min-shell-control-markers+)
         (evidence-group
          "shell-control-literals"
          count
          (call-fact-selector (car calls))))))

;;; Boundary:
;;; - build/runtime sources may write launcher/config files.
;;; - Writer calls become evidence only when their payload is shell control.
;;; - Plain display or write-string calls remain below the warning gate.
;;; Data flow:
;;; - filter applies one pure CallFact classifier before count and selector are
;;;   packaged into an EvidenceGroup.
;;; Arity evidence:
;;; - shell-writer-call? consumes one CallFact and returns a boolean.
;;; - The filtered list can be counted without reclassifying calls.
;;; Invariant:
;;; - Writer identity and shell-control payload must be true together.
;;; - Neither
;;;   condition alone is actionable.
;;; Hidden invariant:
;;; - Keeping the classifier separate prevents writer calls from bypassing the
;;;   shell-control payload check.
;; : (-> SourceFile MaybeEvidenceGroup )
(def (shell-writer-call-evidence file)
  (let (calls (filter shell-writer-call? (source-file-calls file)))
    (and (pair? calls)
         (evidence-group
          "shell-writer-calls"
          (length calls)
          (call-fact-selector (car calls))))))

;;; Provider native compile owners are data-shaped by parser definition names.
;;; This signal is harmless alone; the all-of detector needs unsafe dispatch and
;;; missing wrapper delegation before emitting a warning.
;; : (-> SourceFile MaybeEvidenceGroup )
(def (native-provider-compile-owner-evidence file)
  (let (definitions (filter native-provider-compile-definition?
                            (source-file-definitions file)))
    (and (pair? definitions)
         (evidence-group
          "native-provider-compile-owner"
          (length definitions)
          (definition-selector (car definitions))))))

;;; Direct gxc -exe dispatch is only actionable inside provider native compile
;;; owners. Bootstrap compilation of the wrapper runtime itself remains outside
;;; this group.
;; : (-> SourceFile MaybeEvidenceGroup )
(def (direct-native-exe-dispatch-evidence file)
  (let (calls (filter direct-native-exe-dispatch-call?
                      (source-file-calls file)))
    (and (pair? calls)
         (evidence-group
          "direct-native-exe-dispatch"
          (length calls)
          (call-fact-selector (car calls))))))

;;; Absence is made explainable by anchoring the selector on the unsafe direct
;;; compile call whose caller lacks a native-wrapper delegation call.
;; : (-> SourceFile MaybeEvidenceGroup )
(def (missing-native-link-wrapper-evidence file)
  (let (calls (filter (lambda (call)
                        (and (direct-native-exe-dispatch-call? call)
                             (not (native-wrapper-delegation-for-caller?
                                   file
                                   (call-fact-caller call)))))
                      (source-file-calls file)))
    (and (pair? calls)
         (evidence-group
          "missing-native-link-wrapper"
          (length calls)
          (call-fact-selector (car calls))))))

;;; Parser-owned source class is the scope signal.  Policy does not repeat the
;;; path classifier; it only consumes the language vocabulary.
;; : (-> SourceFile MaybeEvidenceGroup )
(def (native-fast-runtime-source-evidence file)
  (and (native-fast-runtime-source-file? file)
       (evidence-group
        "native-fast-source"
        1
        (string-append (source-file-path file) ":1-1"))))

;;; Module imports carry the real dependency boundary.  A full command adapter
;;; inside a native-fast source means native link will traverse the command graph.
;; : (-> SourceFile MaybeEvidenceGroup )
(def (native-fast-command-adapter-import-evidence file)
  (let (imports (filter native-fast-command-adapter-import?
                        (source-file-module-imports file)))
    (and (pair? imports)
         (evidence-group
          "full-command-adapter-import"
          (length imports)
          (module-import-selector (car imports))))))

;;; Scope guard: build/runtime files intentionally emit launcher/runtime
;;; wrappers, so they need a dedicated evidence profile.
;; : (-> SourceFile Boolean )
(def (build-runtime-source-file? file)
  (equal? (source-path-class (source-file-path file))
          "build-runtime"))

;; : (-> SourceFile Boolean )
(def (native-fast-runtime-source-file? file)
  (equal? (source-path-class (source-file-path file))
          "native-fast-runtime"))

;;; Naming markers catch helper families before they become an unbounded shell
;;; wrapper subsystem.
;; : (-> DefinitionFact Boolean )
(def (shell-helper-definition? definition)
  (let (name (definition-name definition))
    (and (string? name)
         (ormap (lambda (marker)
                  (if (string-suffix? "-" marker)
                    (string-prefix? marker name)
                    (string-contains name marker)))
                +shell-helper-definition-markers+))))

;;; Boundary:
;;; - Parser-owned call arguments are the evidence boundary.
;;; - ormap keeps marker detection declarative across literal arguments.
;;; - The policy does not become a shell parser.
;;; Data flow:
;;; - filter removes non-string arguments, then ormap asks whether any remaining
;;;   literal carries a shell-control marker.
;;; Invariant:
;;; - Non-string parser arguments are ignored rather than coerced into shell
;;;   text.
;; : (-> CallFact Boolean )
(def (call-has-shell-control-literal? call)
  (ormap string-has-shell-control-marker?
         (filter string? (call-fact-arguments call))))

;;; Writer calls become evidence only when their argument payload contains
;;; shell-control markers.
;; : (-> CallFact Boolean )
(def (shell-writer-call? call)
  (and (member (call-fact-callee call) '("display" "write-string"))
       (call-has-shell-control-literal? call)))

;; : (-> DefinitionFact Boolean )
(def (native-provider-compile-definition? definition)
  (native-provider-compile-owner-name? (definition-name definition)))

;; : (-> CallFact Boolean )
(def (direct-native-exe-dispatch-call? call)
  (and (native-provider-compile-owner-name? (call-fact-caller call))
       (member (call-fact-callee call) +shell-dispatch-callees+)
       (call-arguments-contain? call "gxc")
       (call-arguments-contain? call "-exe")))

;;; Data flow:
;;; - Caller equality scopes wrapper proof to the same native compile owner as
;;;   the unsafe dispatch candidate.
;;; - `ormap` is intentional existential evidence: one matching wrapper call is
;;;   enough to prove timeout/atomic replacement delegation.
;;; Hidden invariant:
;;; - A file-wide wrapper hit must not bless a different direct compiler caller.
;; : (-> SourceFile MaybeCaller Boolean )
(def (native-wrapper-delegation-for-caller? file caller)
  (and (string? caller)
       (ormap (lambda (call)
                (and (equal? (call-fact-caller call) caller)
                     (native-wrapper-delegation-call? call)))
              (source-file-calls file))))

;; : (-> CallFact Boolean )
(def (native-wrapper-delegation-call? call)
  (and (equal? (call-fact-callee call) "compile-build-runtime-executable!")
       (call-arguments-contain? call +native-wrapper-binary-prefix+)
       (call-arguments-contain? call +native-wrapper-runtime-source+)))

;;; Data flow:
;;; - Module import facts provide the adapter name; the prefix table owns the
;;;   disallowed command-adapter vocabulary.
;;; - `ormap` keeps this an open policy surface: new full-command prefixes add
;;;   data, not branches through individual fast source files.
;; : (-> ModuleImportFact Boolean )
(def (native-fast-command-adapter-import? fact)
  (ormap (cut string-prefix? <> (module-import-fact-module fact))
         +native-fast-disallowed-import-prefixes+))

;; : (-> ModuleImportFact Selector )
(def (module-import-selector fact)
  (string-append (module-import-fact-path fact)
                 ":"
                 (number->string (module-import-fact-start fact))
                 "-"
                 (number->string (module-import-fact-end fact))))

;;; Data flow:
;;; - Owner prefixes are data, and `cut` specializes the prefix predicate over
;;;   the candidate parser-owned definition/caller name.
;;; Invariant:
;;; - Adding another native compile owner extends the prefix table instead of
;;;   branching through source paths or concrete function bodies.
;; : (-> MaybeString Boolean )
(def (native-provider-compile-owner-name? name)
  (and (string? name)
       (ormap (cut string-prefix? <> name)
              +native-provider-compile-owner-prefixes+)))

;;; Argument containment stays string-only so parser facts, not shell parsing,
;;; own the evidence boundary.
;; : (-> CallFact String Boolean )
(def (call-arguments-contain? call needle)
  (ormap (lambda (argument)
           (and (string? argument)
                (string-contains argument needle)))
         (call-fact-arguments call)))

;;; Boundary:
;;; - Marker matching is intentionally lexical and conservative.
;;; - ormap keeps the vocabulary data-owned instead of branch-owned.
;;; - Composite evidence decides whether lexical hits are actionable.
;;; Data flow:
;;; - ormap short-circuits over the configured marker vocabulary and returns a
;;;   boolean predicate for one string literal.
;;; Arity evidence:
;;; - cut specializes string-contains with the fixed text argument.
;;; - Each marker remains the second argument to string-contains.
;;; Invariant:
;;; - The marker list remains data.
;;; - Changing markers does not add branch logic.
;;; Hidden invariant:
;;; - Marker ordering affects only short-circuit cost, not evidence semantics.
;; : (-> String Boolean )
(def (string-has-shell-control-marker? text)
  (ormap (cut string-contains text <>)
         +shell-control-literal-markers+))

;;; The total marker count measures payload density across calls, not just the
;;; number of calls.
;; : (-> (List CallFact) Integer )
(def (shell-control-marker-total calls)
  (apply +
         (map call-shell-control-marker-count calls)))

;;; Per-call counts preserve density evidence when one generated launcher
;;; contains several shell-control markers.
;; : (-> CallFact Integer )
(def (call-shell-control-marker-count call)
  (apply +
         (map string-shell-control-marker-count
              (filter string? (call-fact-arguments call)))))

;;; Boundary:
;;; - Literal marker count is a small evidence score.
;;; - filter keeps the marker vocabulary data-owned.
;;; - Counting remains advisory until another evidence group agrees.
;;; Data flow:
;;; - filter materializes the matched marker subset so length can score how
;;;   dense one generated literal is.
;;; Arity evidence:
;;; - cut again fixes the text argument and maps each marker through the same
;;;   string-contains predicate.
;;; Invariant:
;;; - The score is marker density only.
;;; - It never interprets shell grammar.
;;; Hidden invariant:
;;; - Counting the matched subset keeps scoring independent from marker order.
;; : (-> String Integer )
(def (string-shell-control-marker-count text)
  (count (cut string-contains text <>)
         +shell-control-literal-markers+))
