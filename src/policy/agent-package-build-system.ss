;;; -*- Gerbil -*-
;;; Package-level build.ss custom build-system detection.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/detection
        :asp-gerbil-scheme/src/policy/poo-source
        (only-in :std/srfi/13 string-contains string-suffix?)
        (only-in :std/sugar cut filter hash ormap))

(export package-build-file?
        package-build-quality-detection-prototypes
        package-build-custom-system-result?
        package-build-framework-overreach-result?)

;; (List GroupName)
(def +package-build-custom-system-required-groups+
  '("package-build-file"
    "missing-native-build-surface"
    "manual-build-orchestration"))

;; (List GroupName)
(def +package-build-framework-overreach-required-groups+
  '("package-build-file"
    "native-build-surface"
    "local-build-state-owner"))

;; (List ModuleName)
(def +package-build-canonical-modules+
  '(":clan/building"))

;; (List ModuleName)
(def +package-build-std-build-script-modules+
  '(":std/build-script"))

;; (List ModuleName)
(def +package-build-std-make-modules+
  '(":std/make"))

;; (List CalleeName)
(def +package-build-canonical-environment-callees+
  '("init-build-environment!" "%set-build-environment!"))

;; (List CalleeName)
(def +package-build-std-build-script-callees+
  '("defbuild-script"))

;; (List CalleeName)
(def +package-build-std-make-callees+
  '("make"))

;; (List DefinitionName)
(def +package-build-std-make-spec-definitions+
  '("spec" "build-spec" "buildspec"))

;; (List IncludePath)
(def +package-build-std-make-spec-includes+
  '("build-spec.ss"))

;; (List CalleeName)
(def +package-build-canonical-enumerator-callees+
  '("all-gerbil-modules"))

;; (List CalleeName)
(def +package-build-manual-orchestration-callees+
  '("add-load-path!"
    "invoke"
    "open-process"
    "run-process"
    "setenv"
    "shell-command"
    "system"))

;; (List String)
(def +package-build-manual-orchestration-markers+
  '("GERBIL_LOADPATH"
    "gxc"
    "gsc"
    "gxi"
    "srcdir:"
    "-exe"
    "-static"
    "find src"))

;; (List String)
(def +package-build-shell-pipeline-literal-markers+
  '("|" "xargs" "find src" "sort |" " -P "))

;; (List CalleeName)
(def +package-build-shell-dispatch-callees+
  '("invoke" "run-process" "open-process"))

;;; Local state evidence includes cache, stamp, receipt, and worker ownership.
;;; It only becomes a finding when combined with package build scope and a
;;; native build surface, so ordinary package helper identifiers are not enough.
;; (List String)
(def +package-build-local-state-definition-markers+
  '("build-cache"
    "build-job"
    "build-queue"
    "build-runner"
    "build-worker"
    "build-stamp"
    "cache-fresh"
    "delete-build-stamp"
    "emit-phase-receipt"
    "phase-receipt"
    "write-build-stamp"
    "worker-count"))

;; (List String)
(def +package-build-local-state-binding-markers+
  '("build-cache"
    "build-job"
    "build-jobs"
    "build-queue"
    "build-runner"
    "build-worker"
    "build-stamp"
    "cache-stamp"
    "phase-receipt-schema"
    "worker-count"))

;;; Public detector surface:
;;; - Keep package build-system policy in one owner.
;;; - The caller decides when a SourceFile is in package-build scope.
;; : (-> (List DetectionPrototype))
(def (package-build-quality-detection-prototypes)
  [(package-build-custom-system-detection-prototype)
   (package-build-framework-overreach-detection-prototype)
   (package-build-shell-pipeline-detection-prototype)])

;; : (-> DetectionResult Boolean)
(def (package-build-custom-system-result? result)
  (equal? (detection-result-prototype result)
          "package-build-custom-system-all-of"))

;; : (-> DetectionResult Boolean)
(def (package-build-framework-overreach-result? result)
  (equal? (detection-result-prototype result)
          "package-build-framework-overreach-all-of"))

;;; Package build custom-system detection is deliberately all-of:
;;; missing canonical shape alone is R025, and manual orchestration alone can be
;;; a fixture.  Together they identify a downstream agent replacing gxpkg and
;;; canonical Gerbil build entrypoints with a local build control plane.
;; : (-> DetectionPrototype)
(def (package-build-custom-system-detection-prototype)
  (detection-prototype-extend
   +all-of-detection-prototype+
   (poo-source-pattern-detection-overlay 'prototype-composition)
   (detection-prototype
    "package-build-custom-system-all-of"
    'all-of
    [package-build-source-evidence
     package-build-missing-native-surface-evidence
     package-build-manual-orchestration-evidence]
    0
    +package-build-custom-system-required-groups+
    "package build custom-system drift requires scope, missing native build surface, and manual orchestration evidence")))

;;; Framework-overreach detection catches the opposite failure mode from the
;;; custom-system detector: build.ss imports std/make or clan/building, but then
;;; recreates build-phase/cache ownership locally.  The repair is not to replace
;;; Gerbil's build system; it is to keep cache/receipt policy in harness APIs
;;; that wrap the normal build entrypoint.
;; : (-> DetectionPrototype)
(def (package-build-framework-overreach-detection-prototype)
  (detection-prototype-extend
   +all-of-detection-prototype+
   (poo-source-pattern-detection-overlay 'prototype-composition)
   (detection-prototype
    "package-build-framework-overreach-all-of"
    'all-of
    [package-build-source-evidence
     package-build-native-surface-evidence
     package-build-local-state-owner-evidence]
    0
    +package-build-framework-overreach-required-groups+
    "package build API overreach requires package scope, native build surface evidence, and local phase/cache/stamp ownership")))

;;; Shell pipeline detection stays separate from the broader custom-system
;;; detector so sh -c pipeline repair remains precise.
;; : (-> DetectionPrototype)
(def (package-build-shell-pipeline-detection-prototype)
  (detection-prototype-extend
   +all-of-detection-prototype+
   (poo-source-pattern-detection-overlay 'prototype-composition)
   (detection-prototype
    "package-build-shell-pipeline-all-of"
    'all-of
    [package-build-shell-dispatch-call-evidence
     package-build-shell-pipeline-literal-evidence]
    0
    ["shell-dispatch-call" "shell-pipeline-literal"]
    "package build shell-pipeline drift requires dispatch and payload evidence")))

;;; Scope guard: only package-root build.ss is checked for custom build-system
;;; drift.  build/runtime owners use a separate detector profile.
;; : (-> SourceFile Boolean)
(def (package-build-file? file)
  (equal? (source-path-class (source-file-path file))
          "package-build"))

;; : (-> SourceFile MaybeEvidenceGroup)
(def (package-build-source-evidence file)
  (and (package-build-file? file)
       (evidence-group
        "package-build-file"
        1
        (source-file-root-selector file))))

;;; Negative evidence is explainable only because the all-of detector pairs it
;;; with positive manual orchestration evidence.
;; : (-> SourceFile MaybeEvidenceGroup)
(def (package-build-missing-native-surface-evidence file)
  (and (package-build-file? file)
       (not (package-build-canonical-build-shape? file))
       (evidence-group
        "missing-native-build-surface"
        1
        (source-file-root-selector file))))

;;; Positive native-surface evidence keeps framework-overreach separate from
;;; custom build systems: this warning only fires when build.ss already uses the
;;; upstream Gerbil build surface but adds a second local build-control layer.
;; : (-> SourceFile MaybeEvidenceGroup)
(def (package-build-native-surface-evidence file)
  (and (package-build-file? file)
       (package-build-canonical-build-shape? file)
       (evidence-group
        "native-build-surface"
        1
        (source-file-root-selector file))))

;;; Local phase/cache/stamp ownership belongs in reusable harness APIs or
;;; upstream std/make integration, not in every downstream package build.ss.
;; : (-> SourceFile MaybeEvidenceGroup)
(def (package-build-local-state-owner-evidence file)
  (let* ((definitions (filter package-build-local-state-definition?
                              (source-file-definitions file)))
         (bindings (filter package-build-local-state-binding?
                           (source-file-bindings file))))
    (cond
     ((pair? definitions)
      (evidence-group
       "local-build-state-owner"
       (+ (length definitions) (length bindings))
       (definition-selector (car definitions))))
     ((pair? bindings)
      (evidence-group
       "local-build-state-owner"
       (length bindings)
       (binding-fact-selector (car bindings))))
     (else #f))))

;;; Evidence boundary: keep only parser-owned calls that prove build.ss is
;;; coordinating compiler/process work instead of delegating to clan/building.
;; : (-> SourceFile MaybeEvidenceGroup)
(def (package-build-manual-orchestration-evidence file)
  (let (calls (filter package-build-manual-orchestration-call?
                      (source-file-calls file)))
    (and (pair? calls)
         (evidence-group
          "manual-build-orchestration"
          (length calls)
          (call-fact-selector (car calls))))))

;;; Shell dispatch evidence stays separate from literal pipeline strings so
;;; command invocation and argument content can compose as independent signals.
;; : (-> SourceFile MaybeEvidenceGroup)
(def (package-build-shell-dispatch-call-evidence file)
  (let (calls (filter package-build-shell-dispatch-call?
                      (source-file-calls file)))
    (and (pair? calls)
         (evidence-group
          "shell-dispatch-call"
          (length calls)
          (call-fact-selector (car calls))))))

;;; Pipeline literals refine sh -c evidence so build.ss warnings focus on
;;; pipeline orchestration instead of every shell invocation.
;; : (-> SourceFile MaybeEvidenceGroup)
(def (package-build-shell-pipeline-literal-evidence file)
  (let (calls (filter package-build-shell-pipeline-literal-call?
                      (source-file-calls file)))
    (and (pair? calls)
         (evidence-group
          "shell-pipeline-literal"
          (length calls)
          (call-fact-selector (car calls))))))

;;; Canonical package build evidence stays structural: module imports prove
;;; clan/building is present, calls prove environment initialization, and either
;;; calls or definitions prove delegated source discovery.
;; : (-> SourceFile Boolean)
(def (package-build-canonical-build-shape? file)
  (or (package-build-canonical-clan-shape? file)
      (package-build-std-build-script-shape? file)
      (package-build-std-make-buildspec-shape? file)))

;;; Clan/building shape is the preferred package boundary: the import provides
;;; build semantics, init call owns environment setup, and enumerator/spec
;;; evidence proves source discovery is delegated instead of handwritten.
;; : (-> SourceFile Boolean)
(def (package-build-canonical-clan-shape? file)
  (and (ormap package-build-canonical-module-import?
              (source-file-module-imports file))
       (ormap package-build-canonical-environment-call?
              (source-file-calls file))
       (or (ormap package-build-canonical-enumerator-call?
                  (source-file-calls file))
           (ormap package-build-spec-definition?
                  (source-file-definitions file)))))

;;; std/build-script is accepted as a legacy structural witness only when the
;;; import and defbuild-script call appear together, keeping migration evidence
;;; distinct from arbitrary package-level compiler orchestration.
;; : (-> SourceFile Boolean)
(def (package-build-std-build-script-shape? file)
  (and (ormap package-build-std-build-script-module-import?
              (source-file-module-imports file))
       (ormap package-build-std-build-script-call?
              (source-file-calls file))))

;;; std/make compatibility requires both the make import and make call plus a
;;; parser-visible spec definition/include, so a loose make invocation does not
;;; become an accepted custom build system.
;; : (-> SourceFile Boolean)
(def (package-build-std-make-buildspec-shape? file)
  (and (ormap package-build-std-make-module-import?
              (source-file-module-imports file))
       (ormap package-build-std-make-call?
              (source-file-calls file))
       (or (ormap package-build-std-make-spec-definition?
                  (source-file-definitions file))
           (ormap package-build-std-make-spec-include?
                  (source-file-includes file)))))

;; : (-> ModuleImportFact Boolean)
(def (package-build-canonical-module-import? fact)
  (member (module-import-fact-module fact)
          +package-build-canonical-modules+))

;; : (-> ModuleImportFact Boolean)
(def (package-build-std-build-script-module-import? fact)
  (member (module-import-fact-module fact)
          +package-build-std-build-script-modules+))

;; : (-> ModuleImportFact Boolean)
(def (package-build-std-make-module-import? fact)
  (member (module-import-fact-module fact)
          +package-build-std-make-modules+))

;; : (-> CallFact Boolean)
(def (package-build-canonical-environment-call? call)
  (member (call-fact-callee call)
          +package-build-canonical-environment-callees+))

;; : (-> CallFact Boolean)
(def (package-build-std-build-script-call? call)
  (member (call-fact-callee call)
          +package-build-std-build-script-callees+))

;; : (-> CallFact Boolean)
(def (package-build-std-make-call? call)
  (or (member (call-fact-callee call)
              +package-build-std-make-callees+)
      (and (equal? (call-fact-callee call) "apply")
           (call-arguments-contain? call "make"))))

;; : (-> CallFact Boolean)
(def (package-build-canonical-enumerator-call? call)
  (member (call-fact-callee call)
          +package-build-canonical-enumerator-callees+))

;; : (-> DefinitionFact Boolean)
(def (package-build-spec-definition? definition)
  (equal? (definition-name definition) "spec"))

;; : (-> DefinitionFact Boolean)
(def (package-build-std-make-spec-definition? definition)
  (package-build-spec-definition-name? (definition-name definition)))

;; : (-> DefinitionName Boolean)
(def (package-build-spec-definition-name? name)
  (or (member name +package-build-std-make-spec-definitions+)
      (string-suffix? "-build-spec" name)))

;; : (-> IncludePath Boolean)
(def (package-build-std-make-spec-include? include)
  (member include +package-build-std-make-spec-includes+))

;;; Manual orchestration needs a build-owned callee or compiler/env marker.
;;; The marker table is policy data, so extending it does not add branch logic.
;; : (-> CallFact Boolean)
(def (package-build-manual-orchestration-call? call)
  (or (member (call-fact-callee call)
              +package-build-manual-orchestration-callees+)
      (ormap package-build-manual-orchestration-argument?
             (filter string? (call-fact-arguments call)))))

;;; Marker matching is a predicate family: cut/ormap express any orchestration
;;; marker hit without turning the package-build rule into an open-coded branch.
;; : (-> String Boolean)
(def (package-build-manual-orchestration-argument? argument)
  (ormap (cut string-contains argument <>)
         +package-build-manual-orchestration-markers+))

;;; sh -c is the risk boundary because it collapses typed argv into shell text.
;; : (-> CallFact Boolean)
(def (package-build-shell-dispatch-call? call)
  (and (member (call-fact-callee call)
               +package-build-shell-dispatch-callees+)
       (call-arguments-contain? call "sh")
       (call-arguments-contain? call "-c")))

;;; Nested argument scanning requires the shell dispatcher and pipeline literal
;;; to be on the same parsed call, which is stricter than source text matching.
;; : (-> CallFact Boolean)
(def (package-build-shell-pipeline-literal-call? call)
  (and (package-build-shell-dispatch-call? call)
       (ormap (lambda (argument)
                (and (string? argument)
                     (ormap (cut string-contains argument <>)
                            +package-build-shell-pipeline-literal-markers+)))
              (call-fact-arguments call))))

;;; Shared argument containment keeps signal logic data-driven: callers provide
;;; the marker, while parser-owned argument values remain the evidence boundary.
;; : (-> CallFact String Boolean)
(def (call-arguments-contain? call needle)
  (ormap (lambda (argument)
           (and (string? argument)
                (string-contains argument needle)))
         (call-fact-arguments call)))

;; : (-> DefinitionFact Boolean)
(def (package-build-local-state-definition? definition)
  (let (name (definition-name definition))
    (and (string? name)
         (ormap (cut string-contains name <>)
                +package-build-local-state-definition-markers+))))

;; : (-> BindingFact Boolean)
(def (package-build-local-state-binding? binding)
  (let (name (binding-fact-name binding))
    (and (string? name)
         (ormap (cut string-contains name <>)
                +package-build-local-state-binding-markers+))))

;; : (-> DefinitionFact Selector)
(def (definition-selector definition)
  (string-append (definition-path definition)
                 ":"
                 (number->string (definition-start definition))
                 "-"
                 (number->string (definition-end definition))))

;; : (-> SourceFile Selector)
(def (source-file-root-selector file)
  (string-append (source-file-path file) ":1-1"))
