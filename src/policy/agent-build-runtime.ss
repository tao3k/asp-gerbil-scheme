;;; -*- Gerbil -*-
;;; Agent-facing build/runtime support quality policy.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-package-build-system
        :asp-gerbil-scheme/src/policy/detection
        :asp-gerbil-scheme/src/policy/model
        :asp-gerbil-scheme/src/policy/poo-source
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar cut filter filter-map hash)
        :asp-gerbil-scheme/src/types/findings)

(export build-runtime-quality-findings
        build-runtime-quality-finding)

;; A project lock may protect a short state transition, but it must never own
;; the upstream compiler or scheduler call.  Keeping these vocabularies as
;; data makes the same-caller composite precise without parsing lock syntax.
(def +build-runtime-global-lock-callees+
  '("with-lock" "mutex-lock!" "call-with-mutex"))

(def +build-runtime-compile-callees+
  '("make" "compile-module" "gxc-compile" "gsc-compile"
    "execute-pending-compile-jobs!"))

(def +build-runtime-dependency-wait-callees+
  '("completion-wait!" "barrier-wait!"))

(def +build-runtime-work-channel-callees+
  '("make-channel" "channel-put" "channel-get" "channel-close"))

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
;;; - `map` keeps result order stable across independent package-build
;;;   ownership findings.
;;; Invariant:
;;; - This stays a projection over parser-owned detection results, not a manual
;;;   loop that could merge independent policy evidence.
;; : (-> SourceFile (List TypeFinding) )
(def (build-runtime-quality-findings/file file)
  (append
   (map (cut build-runtime-quality-finding<- file <>)
        (build-runtime-quality-detections file))
   (build-runtime-global-lock-compile-findings file)
   (build-runtime-shadow-scheduler-findings file)
   (runtime-cache-version-findings file)))

;; : (-> SourceFile (List TypeFinding))
(def (build-runtime-global-lock-compile-findings file)
  (if (build-runtime-source-file? file)
    (filter-map
     (lambda (lock-call)
       (let (compile-call
             (build-runtime-compile-call-for-caller
              file (call-fact-caller lock-call)))
         (and compile-call
              (make-type-finding
               (policy-rule-id +agent-build-runtime-quality-rule+)
               (policy-rule-severity +agent-build-runtime-quality-rule+)
               (source-file-path file)
               "build/runtime support holds a global lock in the same owner that invokes the compiler or std/make scheduler; restrict the lock to state mutation and invoke the upstream build executor after releasing it"
               (call-fact-selector lock-call)
               (hash
                (kind "build-runtime-global-lock-compile")
                (caller (call-fact-caller lock-call))
                (lockCallee (call-fact-callee lock-call))
                (compileCallee (call-fact-callee compile-call))
                (compileSelector (call-fact-selector compile-call))
                (requiredEvidence
                 "parser-owned global-lock and compiler/scheduler calls with the same caller")
                (allowedShape
                 "lock only the state-table transition; call std/make or compiler functions after releasing the lock")
                (disallowedShape
                 "with-lock or mutex ownership spanning make, compile-module, gxc-compile, gsc-compile, or pending native compilation")
                (next
                 "split the locked state mutation into a small helper and leave dependency waiting plus compilation under upstream std/make ownership"))))))
     (filter build-runtime-global-lock-call?
             (source-file-calls file)))
    []))

;; : (-> SourceFile MaybeString MaybeCallFact)
(def (build-runtime-compile-call-for-caller file caller)
  (and caller
       (let (calls
             (filter
              (lambda (call)
                (and (equal? (call-fact-caller call) caller)
                     (member (call-fact-callee call)
                             +build-runtime-compile-callees+)))
              (source-file-calls file)))
         (and (pair? calls) (car calls)))))

;; : (-> CallFact Boolean)
(def (build-runtime-global-lock-call? call)
  (member (call-fact-callee call)
          +build-runtime-global-lock-callees+))

;;; Three independent parser-owned call groups identify the harmful topology:
;;; an import/global lock, dependency completion waiting, and a private work
;;; channel.  Any one group alone is ordinary concurrent Scheme code.
;; : (-> SourceFile (List TypeFinding))
(def (build-runtime-shadow-scheduler-findings file)
  (if (build-runtime-source-file? file)
    (let ((locks
           (filter build-runtime-global-lock-call?
                   (source-file-calls file)))
          (waits
           (filter
            (lambda (call)
              (member (call-fact-callee call)
                      +build-runtime-dependency-wait-callees+))
            (source-file-calls file)))
          (channels
           (filter
            (lambda (call)
              (member (call-fact-callee call)
                      +build-runtime-work-channel-callees+))
            (source-file-calls file))))
      (if (and (pair? locks) (pair? waits) (pair? channels))
        [(make-type-finding
          (policy-rule-id +agent-build-runtime-quality-rule+)
          (policy-rule-severity +agent-build-runtime-quality-rule+)
          (source-file-path file)
          "build/runtime support combines a global import lock, dependency-completion waits, and a private work channel; delegate the complete module graph to one upstream std/make session instead of creating a serializing shadow scheduler"
          (call-fact-selector (car locks))
          (hash
           (kind "build-runtime-shadow-scheduler")
           (lockSelector (call-fact-selector (car locks)))
           (dependencyWaitSelector (call-fact-selector (car waits)))
           (workChannelSelector (call-fact-selector (car channels)))
           (requiredEvidence
            "global-lock, dependency-completion-wait, and work-channel calls in one build/runtime owner")
           (allowedShape
            "one declarative module catalog lowered to one upstream std/make invocation")
           (disallowedShape
            "module coordinators serialized by a global import lock before feeding a private worker channel")
           (next
            "remove the private coordinator/worker scheduler and pass the complete build spec plus GERBIL_BUILD_CORES to std/make")))]
        []))
    []))

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
   ((package-build-framework-overreach-result? result)
     "package-level build.ss is adding local phase/cache/stamp/worker ownership on top of Gerbil's build surface; keep std/make or clan/building as the build owner and move cache/receipt policy into reusable harness APIs")
    ((package-build-custom-system-result? result)
     "package-level build.ss is drifting into a hand-written build system; keep build.ss on gxpkg plus clan/building, std/build-script, or std/make build-spec and move command/runtime behavior into package modules")
   (else "build/runtime ownership is outside the admitted package build model")))

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
   ((build-runtime-source-file? file) '())
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
   ((package-build-framework-overreach-result? result)
     "package-build-framework-overreach")
    ((package-build-custom-system-result? result)
     "package-build-custom-system")
   (else "build-runtime-quality")))

;; : (-> DetectionResult String )
(def (runtime-quality-required-evidence result)
  (cond
   ((package-build-framework-overreach-result? result)
     "package build file, native Gerbil build surface, and local phase/cache/stamp ownership")
    ((package-build-custom-system-result? result)
     "package build file, missing native Gerbil build surface, and manual build orchestration")
   (else "at least two independent parser-owned groups")))

;; : (-> DetectionResult String )
(def (runtime-quality-allowed-shape result)
  (cond
   ((package-build-framework-overreach-result? result)
     "build.ss delegates source discovery and compilation to clan/building, std/build-script, or std/make; optional acceleration is exposed as a thin harness API around the existing build entrypoint")
    ((package-build-custom-system-result? result)
     "package build delegates to a native Gerbil surface: gxpkg plus :clan/building for src-root discovery, :std/build-script for simple package templates, or :std/make build-spec for ssi:/gsc:/FFI/native build forms")
   (else "Gerbil runtime wrapper source plus list command arguments")))

;; : (-> DetectionResult String )
(def (runtime-quality-disallowed-shape result)
  (cond
   ((package-build-framework-overreach-result? result)
     "downstream build.ss defining its own phase receipt, stamp cache, cache freshness, or phase-skip control plane on top of std/make or clan/building")
    ((package-build-custom-system-result? result)
     "hand-written compiler dispatch, GERBIL_LOADPATH/source-root management, or local mini build orchestration inside build.ss")
   (else "local build orchestration outside the admitted package owner")))

;; : (-> DetectionResult String )
(def (runtime-quality-next-action result)
  (cond
   ((package-build-framework-overreach-result? result)
     "delete local phase/cache/stamp ownership from downstream build.ss; keep std/make or clan/building calls in place and move reusable acceleration/receipt behavior into a harness API that wraps the normal build entrypoint")
    ((package-build-custom-system-result? result)
     "replace the local build system with :clan/building plus all-gerbil-modules for src-root packages, :std/build-script defbuild-script for simple gxpkg packages, or :std/make build-spec for ssi:/gsc:/FFI builds; keep provider behavior in a thin entry module over POO-native runtime owners")
   (else "delegate package compilation to the native upstream build owner")))

;;; Scope guard: build/runtime files intentionally emit launcher/runtime
;;; wrappers, so they need a dedicated evidence profile.
;; : (-> SourceFile Boolean )
(def (build-runtime-source-file? file)
  (equal? (source-path-class (source-file-path file))
          "build-runtime"))
