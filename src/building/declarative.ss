;;; Boundary: declarative macros lower caller policy into BuildProfile and BuildRequest values without executing builds.

(import (only-in ./facade
                 make-build-profile
                 std-builder-name
                 std-builder-description
                 make-build-request
                 default-std-builder
                 make-std-builder-profile
                 make-std-builder-request))

(export std-build
        define-build-profile
        define-build-request
        define-std-build)

;;; Macro expansion boundary: declarations lower to ordinary BuildProfile and
;;; BuildRequest values. They do not inspect or mutate the process environment.

;; : (forall (stage hook) (-> StdBuilder (-> stage String) (List hook) BuildProfile))
;; define-build-profile
;;   : (-> Identifier StdBuilder (-> BuildStage String) (List BuildOption) (Maybe BuildStageHook) BuildProfile)
;; | doc m%
;; Declare a reusable profile from caller-owned builder policy.
;; # Examples
;; ```scheme
;; (define-build-profile profile builder: builder label-of: label-of
;;   extra-options: [] after: after)
;; => profile
;; ```
;; Result: the binding names an immutable BuildProfile value.
;;; Boundary: macro expansion constructs a BuildProfile while preserving caller-owned builder policy.
(defrules define-build-profile ()
  ((_ binding
      builder: builder
      label-of: label-of
      extra-options: extra-options
      after: after)
   (def binding
     (make-build-profile
      (std-builder-name builder)
      builder
      label-of
      extra-options
      after
      (std-builder-description builder)))))

;; : (forall (stage context) (-> String BuildProfile (List stage) (-> stage context Boolean) context BuildRequest))
;; define-build-request
;;   : (-> Identifier String BuildProfile (List BuildStage) (-> BuildStage BuildContext Boolean) BuildContext BuildRequest)
;; | doc m%
;; Bind a request with an explicit profile, stage set, freshness predicate, and context.
;; # Examples
;; ```scheme
;; (define-build-request request label: "build" profile: profile
;;   stage-specs: stages current?: current? context: context)
;; => request
;; ```
;; Result: the binding names a BuildRequest with explicit freshness context.
;;; Boundary: freshness and context remain caller-supplied request data until Builder execution.
(defrules define-build-request ()
  ((_ binding
      label: label
      profile: profile
      stage-specs: stage-specs
      current?: current-pred
      context: context)
   (def binding
     (make-build-request
      label
      profile
      stage-specs
      current-pred
      context))))

;; : (forall (source stage context) (-> String source (List BuildOption) (-> stage String) (List stage) (-> stage context Boolean) context BuildRequest))
;; std-build
;;   : (-> String Path (List BuildOption) (-> BuildStage String) (Maybe BuildStageHook) (List BuildStage) (-> BuildStage BuildContext Boolean) BuildContext BuildRequest)
;; | doc m%
;; Construct a standard make request as an expression for functions and local scopes.
;; # Examples
;; ```scheme
;; (std-build label: "build" source: "src" make-options: [] label-of: car
;;   after: after stage-specs: stages current?: current? context: context)
;; => build-request
;; ```
;; Result: an expression-level BuildRequest ready for Builder execution.
;;; Boundary: std-build specializes construction only; execution remains in facade.ss.
(defrules std-build ()
  ((_ label: label
      source: source
      make-options: make-options
      label-of: label-of
      after: after
      stage-specs: stage-specs
      current?: current-pred
      context: context)
   (let* ((builder (default-std-builder source make-options))
          (profile (make-std-builder-profile
                    builder
                    label-of
                    []
                    after)))
     (make-std-builder-request
      label
      profile
      stage-specs
      current-pred
      context))))

;; : (forall (source stage context) (-> Identifier String source (List BuildOption) (List stage) context BuildRequest))
;; define-std-build
;;   : (-> Identifier String Path (List BuildOption) (-> BuildStage String) (Maybe BuildStageHook) (List BuildStage) (-> BuildStage BuildContext Boolean) BuildContext BuildRequest)
;; | doc m%
;; Bind the expression form for downstream build scripts and package modules.
;; # Examples
;; ```scheme
;; (define-std-build request label: "build" source: "src" make-options: []
;;   label-of: car after: after stage-specs: stages current?: current? context: context)
;; => request
;; ```
;; Result: the binding names the same BuildRequest shape as std-build.
;;; Boundary: this declaration expands through std-build so request semantics have one implementation path.
(defrules define-std-build ()
  ((_ binding arguments ...)
   (def binding
     (std-build arguments ...))))
