;;; -*- Gerbil -*-
;;; Agent-facing package build responsibility policy.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/srfi/13 string-contains string-prefix? string-suffix?)
        (only-in :std/sugar cut filter filter-map find ormap)
        :asp-gerbil-scheme/src/types/findings)

(export package-build-responsibility-findings
        package-build-responsibility-finding
        package-build-canonical-shape-findings
        package-build-canonical-shape-finding)

;;; Marker set names command-routing responsibilities that must not live in
;;; the package-level build owner.
;; (List BuildRoutingMarker)
(def +package-build-runtime-routing-markers+
  '("search pattern"
    "search extension"
    "FAST_PATTERN"
    "FAST_EXTENSION"
    "\"${2:-}\" = pattern"
    "\"${2:-}\" = extension"))

;;; Wrapper/materializer definitions are CLI/provider-wrapper ownership, not
;;; package build ownership.
;; (List String)
(def +package-build-wrapper-definition-prefixes+
  '("write-gsc-wrapper"
    "write-native-"
    "write-provider-cli"
    "write-executable-script"))

;;; Canonical build surface observed in gerbil-poo:
;;; `:clan/building` owns source discovery, load path setup, and the
;;; compile/spec entrypoints.
;; (List ModuleName)
(def +package-build-native-build-modules+
  '(":clan/building" ":std/build-script" ":std/make"))

;;; Legacy module evidence remains available for future migrations, but the
;;; current canonical set accepts clan/building, std/build-script, and std/make.
;; (List ModuleName)
(def +package-build-legacy-build-modules+
  '())

;;; Provider include evidence:
;;; - build.ss may include reusable stage descriptors.
;;; - The include itself is allowed; policy findings target misplaced runtime
;;;   routing or wrapper materialization inside the package build owner.
;; (List IncludePath)
(def +package-build-provider-build-includes+
  '("src/build-api/provider-build.ss"))

;;; Canonical shape witnesses:
;;; - `init-build-environment!` is the public clan/building entrypoint.
;;; - `%set-build-environment!` is the clan/building source-root entrypoint
;;;   used by packages whose Gerbil modules intentionally live under src/.
;;; - Keeping the callees data-driven prevents one-off build.ss exemptions.
;; (List CalleeName)
(def +package-build-spec-callees+
  '("init-build-environment!" "%set-build-environment!" "defbuild-script" "make"))

;; (List CalleeName)
(def +package-build-std-make-callees+
  '("make" "make-clean"))

;; (List CalleeName)
(def +package-build-manual-environment-callees+
  '("add-load-path!" "apply" "setenv"))

;; (List CalleeName)
(def +package-build-manual-dispatch-callees+
  '("invoke" "run-process" "open-process"))

;; (List String)
(def +package-build-compiler-arguments+
  '("gxc" "gsc" "gxi" "cc" "gcc" "clang"))

;;; Boundary:
;;; - Only the package-root build.ss is governed here.
;;; - Wrapper templates and command owners may contain CLI routing elsewhere.
;; : (-> ProjectIndex (List PackageBuildFinding) )
(def (package-build-responsibility-findings index)
  (let (file (package-top-level-build-file index))
    (if file
      (append
       (filter-map (cut package-build-responsibility-finding file <>)
                   (source-file-calls file))
       (filter-map (cut package-build-wrapper-definition-finding file <>)
                   (source-file-definitions file)))
      '())))

;;; Boundary:
;;; - The package-root build.ss should expose the clan/building surface.
;;; - Complex provider builds may keep provider-specific stage descriptors, but
;;;   source discovery and load path setup belong to init-build-environment!.
;; : (-> ProjectIndex (List PackageBuildFinding) )
(def (package-build-canonical-shape-findings index)
  (let (file (package-top-level-build-file index))
    (if file
      (let (finding (package-build-canonical-shape-finding file))
        (if finding [finding] '()))
      '())))

;;; Invariant:
;;; - The rule is intentionally scoped to gerbil.pkg beside build.ss.
;;; - Nested helper owners are outside this policy surface.
;; : (-> ProjectIndex MaybePackageBuildFile )
(def (package-top-level-build-file index)
  (and (project-index-package index)
       (equal? (project-package-path (project-index-package index)) "gerbil.pkg")
       (find (lambda (file)
               (equal? (source-path-class (source-file-path file))
                       "package-build"))
             (project-index-files index))))

;;; Finding contract:
;;; - Canonical witnesses explain repair direction, but they do not trigger R025.
;;; - R025 fires only on forbidden build-control evidence: handwritten load path
;;;   or srcdir control, manual compiler dispatch, or legacy defbuild-script use.
;;; - The rule does not read build.ss text or infer from file names.
;; : (-> PackageBuildFile MaybePackageBuildFinding )
(def (package-build-canonical-shape-finding file)
  (let* ((native-import
          (find package-build-native-build-import?
                (source-file-module-imports file)))
         (legacy-import
          (find package-build-legacy-build-import?
                (source-file-module-imports file)))
         (build-call
          (find package-build-init-environment-call?
                (source-file-calls file)))
         (module-enumerator-call
          (find package-build-module-enumerator-call?
                (source-file-calls file)))
         (manual-environment-call
          (find package-build-manual-environment-call?
                (source-file-calls file)))
         (manual-call
          (find package-build-manual-compiler-dispatch-call?
                (source-file-calls file)))
         (legacy-script-call
          (find package-build-legacy-build-script-call?
                (source-file-calls file)))
         (native-build-definition
          (find package-build-native-build-definition?
                (source-file-definitions file)))
         (provider-build-include
          (find package-build-provider-build-include?
                (source-file-includes file)))
         (main-definition
          (find package-build-main-definition?
                (source-file-definitions file))))
    (and (or manual-environment-call
             manual-call
             legacy-script-call)
         (make-type-finding
          (policy-rule-id +agent-package-build-canonical-shape-rule+)
         (policy-rule-severity +agent-package-build-canonical-shape-rule+)
         (source-file-path file)
          "package-level build.ss contains forbidden build control; use clan/building, std/build-script, or std/make build-spec, and do not hand-write GERBIL_LOADPATH/srcdir setup, manual compiler dispatch, or runtime routing in build.ss"
          (package-build-canonical-shape-selector
           file native-import legacy-import build-call module-enumerator-call manual-environment-call manual-call native-build-definition provider-build-include main-definition)
          (package-build-canonical-shape-details
           native-import legacy-import build-call module-enumerator-call manual-environment-call manual-call native-build-definition provider-build-include main-definition)))))

;; : (-> ModuleImportFact Boolean )
(def (package-build-native-build-import? fact)
  (member (module-import-fact-module fact)
          +package-build-native-build-modules+))

;;; Legacy imports are migration evidence: they explain why R025 fired, but
;;; they never satisfy the canonical clan/building gate.
;; : (-> ModuleImportFact Boolean )
(def (package-build-legacy-build-import? fact)
  (member (module-import-fact-module fact)
          +package-build-legacy-build-modules+))

;;; Boundary:
;;; - Gerbil records macro-like build forms as ordinary call facts.
;;; - clan/building owns both the public init macro and the lower-level
;;;   source-root initializer used by src/ packages.
;;; - `defbuild-script` is the std/build-script package entrypoint used by
;;;   gxpkg templates.
;;; - `make` is canonical when paired with a std/make build-spec, including
;;;   `(ssi:)`/FFI build forms that clan/building does not express.
;; : (-> CallFact Boolean )
(def (package-build-init-environment-call? call)
  (or (member (call-fact-callee call)
              +package-build-spec-callees+)
      (and (equal? (call-fact-callee call) "apply")
           (package-build-call-arguments-contain? call "make"))))

;; : (-> CallFact String Boolean)
(def (package-build-call-arguments-contain? call needle)
  (ormap (lambda (argument)
           (and (string? argument)
                (string-contains argument needle)))
         (call-fact-arguments call)))

;; : (-> CallFact String Boolean)
(def (package-build-call-arguments-member? call needle)
  (ormap (lambda (argument)
           (and (string? argument)
                (equal? argument needle)))
         (call-fact-arguments call)))

;; : (-> CallFact Boolean)
(def (package-build-std-make-call? call)
  (or (member (call-fact-callee call)
              +package-build-std-make-callees+)
      (and (equal? (call-fact-callee call) "apply")
           (ormap (cut package-build-call-arguments-member? call <>)
                  +package-build-std-make-callees+))))

;;; Module enumeration proves the spec delegates source discovery to
;;; clan/building instead of keeping a handwritten file walk.
;; : (-> CallFact Boolean )
(def (package-build-module-enumerator-call? call)
  (equal? (call-fact-callee call) "all-gerbil-modules"))

;;; A std/build-script package form is not a finding by itself. Manual
;;; environment or compiler/process dispatch evidence owns the warning.
;; : (-> CallFact Boolean )
(def (package-build-legacy-build-script-call? call)
  #f)

;;; Definition surface:
;;; - std/make owners may expose `spec` or `build-spec` and pass it to make.
;;; - Parser definition facts still prove the native build-spec boundary exists.
;;; - Keep the accepted names narrow so this does not bless arbitrary build helpers.
;; : (-> DefinitionFact Boolean )
(def (package-build-native-build-definition? definition)
  (package-build-native-build-definition-name? (definition-name definition)))

;; : (-> DefinitionName Boolean)
(def (package-build-native-build-definition-name? name)
  (or (member name '("spec" "build-spec" "buildspec"))
      (string-suffix? "-build-spec" name)))

;; : (-> IncludePath Boolean )
(def (package-build-provider-build-include? include)
  (member include +package-build-provider-build-includes+))

;;; Manual environment setup is the main regression clan/building prevents.
;;; Keep the predicate narrow so normal provider env variables do not trip it.
;; : (-> CallFact Boolean )
(def (package-build-manual-environment-call? call)
  (and (member (call-fact-callee call)
               +package-build-manual-environment-callees+)
       (or (equal? (call-fact-callee call) "add-load-path!")
           (package-build-loadpath-setenv-call? call)
           (and (package-build-srcdir-argument-call? call)
                (not (package-build-std-make-call? call))))
       (not (package-build-test-load-path-call? call))))

;;; Build-local gxtest needs source and test module roots in the running Gerbil
;;; process. This is not a package build environment escape because it does not
;;; set GERBIL_LOADPATH, invoke a compiler, or change source discovery.
;; : (-> CallFact Boolean )
(def (package-build-test-load-path-call? call)
  (and (equal? (call-fact-callee call) "add-load-path!")
       (ormap (lambda (argument)
                (member argument '("source-root" "test-root")))
              (filter string? (call-fact-arguments call)))))

;;; Only GERBIL_LOADPATH setenv calls are blocked; provider builds may still
;;; set other environment variables for wrappers and native toolchains.
;; : (-> CallFact Boolean )
(def (package-build-loadpath-setenv-call? call)
  (and (equal? (call-fact-callee call) "setenv")
       (ormap (cut string-contains <> "GERBIL_LOADPATH")
              (filter string? (call-fact-arguments call)))))

;;; srcdir: is legal as a std/make option. Outside canonical make/make-clean
;;; calls it is handwritten source-root control and belongs in build setup.
;; : (-> CallFact Boolean )
(def (package-build-srcdir-argument-call? call)
  (ormap (cut string-contains <> "srcdir:")
         (filter string? (call-fact-arguments call))))

;;; Risk boundary:
;;; - Compiler executables inside process calls are manual dispatch evidence.
;;; - The canonical-shape rule emits only when no native build-spec call is present.
;;; - Arguments stay parser-owned strings; this predicate does not parse shell text.
;; : (-> CallFact Boolean )
(def (package-build-manual-compiler-dispatch-call? call)
  (and (member (call-fact-callee call)
               +package-build-manual-dispatch-callees+)
       (ormap package-build-compiler-argument?
              (filter string? (call-fact-arguments call)))))

;;; Marker vocabulary:
;;; - These names identify compiler/process boundaries, not arbitrary path text.
;;; - Adding a compiler belongs in the data table above, not in branch logic here.
;; : (-> String Boolean )
(def (package-build-compiler-argument? argument)
  (ormap (cut string-contains argument <>)
         +package-build-compiler-arguments+))

;; : (-> DefinitionFact Boolean )
(def (package-build-main-definition? definition)
  (equal? (definition-name definition) "main"))

;;; Selector priority:
;;; - Manual environment or compiler dispatch is the most actionable location.
;;; - If no violation witness exists, the selector falls back through missing
;;;   canonical witnesses so the diagnostic still points at repairable evidence.
;; : (-> PackageBuildFile MaybeModuleImportFact MaybeModuleImportFact MaybeCallFact MaybeCallFact MaybeCallFact MaybeCallFact MaybeDefinitionFact MaybeIncludePath MaybeDefinitionFact Selector )
(def (package-build-canonical-shape-selector file native-import legacy-import build-call module-enumerator-call manual-environment-call manual-call native-build-definition provider-build-include main-definition)
  (cond
   (manual-environment-call (call-fact-selector manual-environment-call))
   (manual-call (call-fact-selector manual-call))
   (main-definition (definition-selector main-definition))
   (native-build-definition (definition-selector native-build-definition))
   (build-call (call-fact-selector build-call))
   (module-enumerator-call (call-fact-selector module-enumerator-call))
   (native-import (package-build-module-import-selector native-import))
   (legacy-import (package-build-module-import-selector legacy-import))
   (else (string-append (source-file-path file) ":1-1"))))

;;; Details keep source provenance explicit so an agent can repair toward the
;;; gerbil-poo/clan pattern rather than inventing a local mini build system.
;; : (-> MaybeModuleImportFact MaybeModuleImportFact MaybeCallFact MaybeCallFact MaybeCallFact MaybeCallFact MaybeDefinitionFact MaybeIncludePath MaybeDefinitionFact PolicyDetails )
(def (package-build-canonical-shape-details native-import legacy-import build-call module-enumerator-call manual-environment-call manual-call native-build-definition provider-build-include main-definition)
  (hash (kind "package-build-canonical-shape")
        (nativeBuildImport
         (and native-import (module-import-fact-module native-import)))
        (nativeBuildImportModifier
         (and native-import (module-import-fact-modifier native-import)))
        (legacyBuildImport
         (and legacy-import (module-import-fact-module legacy-import)))
        (buildSpecEntrypoint
         (and build-call (call-fact-callee build-call)))
        (moduleEnumerator
         (and module-enumerator-call
              (call-fact-callee module-enumerator-call)))
        (nativeBuildDefinition
         (and native-build-definition
              (definition-name native-build-definition)))
        (providerBuildInclude provider-build-include)
        (manualEnvironmentSetup
         (and manual-environment-call
              (call-fact-callee manual-environment-call)))
        (manualCompilerDispatch
         (and manual-call (call-fact-callee manual-call)))
        (handWrittenMain
         (and main-definition (definition-name main-definition)))
        (allowedShape
         "canonical build.ss: use clan/building for src-root source discovery, std/build-script defbuild-script for the official gxpkg package template, or std/make build-spec when the package needs ssi:/gsc:/FFI build forms")
        (compositionalBuildShape
         "use clan/building for harness source discovery/load path, std/build-script for simple gxpkg packages, or std/make for build-spec features such as ssi:/gsc:; keep package tests on Gerbil's gxtest runner and runtime commands in compiled modules")
        (downstreamRepairPattern
         "keep build.ss as the package build control plane, route package compilation through clan/building, std/build-script, or std/make build-spec, and keep command/runtime behavior in src/cli and src/commands")
        (disallowedShape
         "hand-written srcdir/loadpath setup, manual compiler/process orchestration, shell pipelines, or CLI/runtime routing that replaces Gerbil's package build entrypoints")
        (sourceEvidence
         ["gerbil://tools/gxpkg.ss:1224-1234"
          "gerbil://std/build-script.ss:9-43"
          "gerbil://std/build-spec.ss:150-220"
          "gerbil://std/make.ss:150-190"
          "gerbil://std/make.ss:559-579"
          ".data/gerbil-utils/building.ss:1-120"
          ".data/gerbil-poo/build.ss:1-18"
          "gerbil://doc/reference/std/make.md:32-52"])
        (nativeFactSource
         "parser-owned moduleImportFacts plus include facts, callFacts and definitionFacts")
        (next
         "remove manual compiler/loadpath/srcdir control from build.ss; keep package build initialization on clan/building, std/build-script, or std/make build-spec and route runtime commands through compiled package modules")))

;;; Finding contract:
;;; - Evidence comes from parser-owned call arguments, not raw grep.
;;; - The repair path preserves build orchestration and moves CLI semantics.
;; : (-> PackageBuildFile CallFact MaybePackageBuildFinding )
(def (package-build-responsibility-finding file call)
  (let (evidence (build-routing-call-evidence call))
    (and evidence
         (make-type-finding
          (policy-rule-id +agent-package-build-responsibility-rule+)
          (policy-rule-severity +agent-package-build-responsibility-rule+)
          (source-file-path file)
          "package-level build.ss contains CLI/search routing; keep build.ss as build spec/orchestration and move command semantics into src/cli or src/commands"
          (call-fact-selector call)
          (hash (evidence evidence)
                (kind "package-build-responsibility")
                (allowedBuildRole "build spec, dependency setup, compile orchestration, gxtest execution")
                (disallowedRole "CLI routing policy or generated command semantics")
                (next "move provider routing to src/cli-launcher.ss or a native command owner"))))))

;;; Finding contract:
;;; - Evidence comes from parser-owned definition names.
;;; - Top-level build.ss must not define wrapper/script materializers itself.
;; : (-> PackageBuildFile DefinitionFact MaybePackageBuildFinding )
(def (package-build-wrapper-definition-finding file definition)
  (let (name (definition-name definition))
    (and (package-build-wrapper-definition-name? name)
         (make-type-finding
          (policy-rule-id +agent-package-build-responsibility-rule+)
          (policy-rule-severity +agent-package-build-responsibility-rule+)
          (source-file-path file)
          "package-level build.ss defines provider wrapper/script materializers; keep build.ss as build spec/orchestration and move command behavior into the CLI owner"
          (definition-selector definition)
          (hash (evidence name)
                (kind "package-build-wrapper-definition")
                (allowedBuildRole "build spec, dependency setup, compile orchestration, gxtest execution")
                (disallowedRole "provider wrapper/script generation or CLI executable materialization")
                (next "move command entrypoint behavior to src/cli"))))))

;;; Evidence boundary:
;;; - String arguments are still parser facts.
;;; - The marker list names routing responsibilities that do not belong in build.ss.
;; : (-> CallFact MaybeBuildRoutingEvidence )
(def (build-routing-call-evidence call)
  (find runtime-routing-text?
        (filter string? (call-fact-arguments call))))

;;; Predicate stays intentionally small so future markers extend the data table,
;;; not the control flow.
;; : (-> BuildRoutingEvidence Boolean )
(def (runtime-routing-text? text)
  (ormap (cut string-contains text <>)
         +package-build-runtime-routing-markers+))

;;; Narrow name gate: only wrapper/script materializer families are blocked.
;;; Build helpers may still use ordinary write/compile verbs when they do not
;;; own generated command semantics.
;; : (-> MaybeString Boolean )
(def (package-build-wrapper-definition-name? name)
  (and (string? name)
       (ormap (cut string-prefix? <> name)
              +package-build-wrapper-definition-prefixes+)
       (or (not (string-prefix? "write-native-" name))
           (string-contains name "wrapper"))))

;;; Local selector rendering keeps the finding tied to parser-owned definition
;;; ranges without adding another dependency to the policy surface.
;; : (-> DefinitionFact Selector )
(def (definition-selector definition)
  (string-append (definition-path definition)
                 ":"
                 (number->string (definition-start definition))
                 "-"
                 (number->string (definition-end definition))))

;; : (-> ModuleImportFact Selector )
(def (package-build-module-import-selector fact)
  (string-append (module-import-fact-path fact)
                 ":"
                 (number->string (module-import-fact-start fact))
                 "-"
                 (number->string (module-import-fact-end fact))))
