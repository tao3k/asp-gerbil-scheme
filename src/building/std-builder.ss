;;; The standard Builder adapts declared BuildRequest values to upstream
;;; std/make and returns deterministic stage receipts.  Dependency ordering and
;;; parallel compilation remain upstream responsibilities.
(import (only-in :std/make make make-clean)
        (only-in ./model
                 build-profile-after
                 build-profile-builder
                 build-profile-description
                 build-profile-extra-options
                 build-profile-label-of
                 build-profile-name
                 build-plan-run!
                 build-request-context
                 build-request-current-pred
                 build-request-label
                 build-request-profile
                 build-request-stage-specs
                 build-stage-spec
                 make-build-profile
                 make-build-request
                 make-build-stage)
        (only-in ./native-toolchain
                 native-toolchain-default
                 with-native-toolchain))

;;; Keep the full public surface in one declaration so dependent facades receive
;;; the complete module interface during incremental compilation.
(export std-builder
        std-builder?
        make-std-builder
        std-builder-name
        std-builder-make-proc
        std-builder-stage-kind
        std-builder-description
        std-builder-srcdir
        std-builder-make-options
        std-builder-toolchain
        default-std-builder
        std-builder-effective-options
        std-builder-run-spec!
        std-builder-clean-spec!
        std-builder-stage
        std-builder-stage-plan
        make-std-builder-profile
        make-std-builder-request
        build-request-stage-plan
        build-request-run!
        build-request-clean!
        build-requests-run!
        build-requests-clean!
        package-source-stage
        package-source-stage?
        make-package-source-stage
        package-source-stage-label
        package-source-stage-source
        package-source-stage-prefix
        package-source-stage-specs
        package-source-stage-batched?
        package-source-stage->request
        package-source-stages->requests
        package-source-stages-spec
        package-source-stages-run!
        package-source-stages-clean!
        build-request->alist)

(defstruct std-builder
  (name make-proc stage-kind description srcdir make-options toolchain))

;;; Boundary: projects declare source groups. std/make alone owns dependency
;;; topology, freshness, scheduling, and GERBIL_BUILD_CORES.
(defstruct package-source-stage
  (label source prefix specs batched?))

(def (default-std-builder (srcdir #f)
                          (make-options [])
                          (toolchain (native-toolchain-default)))
  (make-std-builder
   "std/make"
   make
   'std/make
   "Gerbil std/make stage runner"
   srcdir
   make-options
   toolchain))

(def (std-builder-effective-options builder extra-options)
  (append (std-builder-make-options builder) extra-options))

(def (std-builder-spec-list spec)
  (if (list? spec) spec [spec]))

(def (std-builder-run-spec! builder spec (extra-options []))
  (std-builder-run-spec/raw! builder spec extra-options))

(def (std-builder-run-spec/raw! builder spec (extra-options []))
  (let ((stage (std-builder-spec-list spec))
        (options (std-builder-effective-options builder extra-options)))
    (let (result
          (with-native-toolchain
           (std-builder-toolchain builder)
           (lambda ()
             (if (std-builder-srcdir builder)
               (apply (std-builder-make-proc builder)
                      stage
                      srcdir: (std-builder-srcdir builder)
                      options)
               (apply (std-builder-make-proc builder)
                      stage
                      options)))))
      result)))

;; : (-> StdBuilder List [BuildOption] Any)
(def (std-builder-clean-spec! builder spec (extra-options []))
  (let ((stage (std-builder-spec-list spec))
        (options (std-builder-effective-options builder extra-options)))
    (with-native-toolchain
     (std-builder-toolchain builder)
     (lambda ()
       (if (std-builder-srcdir builder)
         (apply make-clean stage srcdir: (std-builder-srcdir builder) options)
         (apply make-clean stage options))))))

(def (std-builder-stage builder
                        label
                        spec
                        current-pred
                        (extra-options [])
                        (after (lambda (stage context result) #!void)))
  (make-build-stage
   label
   (std-builder-stage-kind builder)
   spec
   current-pred
   (lambda (stage context)
     (std-builder-run-spec! builder (build-stage-spec stage) extra-options))
   after
   (std-builder-description builder)))

;; : (forall (s) (-> s String))
;; default-std-builder-stage-label
;; : (-> Any String)
(def (default-std-builder-stage-label spec)
  (if (and (pair? spec) (string? (car spec)))
    (car spec)
    "std/make"))

;; : (forall (s c) (-> StdBuilder [s] (-> s c Boolean) [BuildStage]))
;; std-builder-stage-plan
;; : (-> StdBuilder List Procedure List)
(def (std-builder-stage-plan builder
                              stage-specs
                              current-pred
                              (label-of default-std-builder-stage-label)
                              (extra-options [])
                              (after (lambda (stage context result) #!void)))
  (map
   (lambda (spec)
     (std-builder-stage
      builder
      (label-of spec)
      spec
      (lambda (stage context)
        (current-pred (build-stage-spec stage) context))
      extra-options
      after))
   stage-specs))

;; : (forall (s) (-> StdBuilder (-> s String) [Any] Procedure BuildProfile))
;; make-std-builder-profile
;; : (-> StdBuilder Procedure List Procedure BuildProfile)
(def (make-std-builder-profile builder
                                (label-of default-std-builder-stage-label)
                                (extra-options [])
                                (after (lambda (stage context result) #!void)))
  (make-build-profile
   (std-builder-name builder)
   builder
   label-of
   extra-options
   after
   (std-builder-description builder)))

;; : (forall (s c) (-> String BuildProfile [s] (-> s c Boolean) c BuildRequest))
;; make-std-builder-request
;; : (-> String BuildProfile List Procedure Any BuildRequest)
(def (make-std-builder-request label profile stage-specs current-pred context)
  (make-build-request label profile stage-specs current-pred context))

;; : (-> BuildRequest [BuildStage])
;; build-request-stage-plan
;; : (-> BuildRequest List)
(def (build-request-stage-plan request)
  (let (profile (build-request-profile request))
    (std-builder-stage-plan
     (build-profile-builder profile)
     (build-request-stage-specs request)
     (build-request-current-pred request)
     (build-profile-label-of profile)
     (build-profile-extra-options profile)
     (build-profile-after profile))))

;; : (-> BuildRequest [BuildStageReceipt])
;; build-request-run!
;; : (-> BuildRequest List)
(def (build-request-run! request)
  (build-plan-run!
   (build-request-stage-plan request)
   (build-request-context request)))

;; : (-> BuildRequest Any)
(def (build-request-clean! request)
  (let (profile (build-request-profile request))
    (map (lambda (spec)
           (std-builder-clean-spec!
            (build-profile-builder profile)
            spec
            (build-profile-extra-options profile)))
         (build-request-stage-specs request))))

;; : (-> [BuildRequest] [BuildStageReceipt])
(def (build-requests-run! requests)
  (apply append (map build-request-run! requests)))

;; : (-> [BuildRequest] [Any])
(def (build-requests-clean! requests)
  (map build-request-clean! requests))

;; : (-> PackageSourceStage [[BuildSpec]])
(def (package-source-stage-request-specs stage)
  (let (specs (package-source-stage-specs stage))
    (if (package-source-stage-batched? stage)
      (list specs)
      (map list specs))))

;; : (-> PackageSourceStage [BuildOption] BuildRequest)
(def (package-source-stage->request stage options)
  (let* ((label (package-source-stage-label stage))
         (builder
          (default-std-builder
           (package-source-stage-source stage)
           (append
            options
            [prefix: (package-source-stage-prefix stage)])))
         (profile
          (make-std-builder-profile
           builder
           (lambda (spec)
             (string-append
              label
              " modules="
              (number->string (length spec)))))))
    (make-std-builder-request
     label
     profile
     (package-source-stage-request-specs stage)
     ;; The framework does not predict Gerbil currentness. Each declared group
     ;; reaches std/make, which performs the authoritative incremental check.
     (lambda (_specs _context) #f)
     stage)))

;; : (-> [PackageSourceStage] [BuildOption] [BuildRequest])
(def (package-source-stages->requests stages options)
  (map (lambda (stage)
         (package-source-stage->request stage options))
       stages))

;; : (-> [PackageSourceStage] [[BuildSpec]])
(def (package-source-stages-spec stages)
  (map (lambda (stage)
         (let (specs (package-source-stage-specs stage))
           (if (package-source-stage-batched? stage)
             (list specs)
             (map list specs))))
       stages))

;; : (-> [PackageSourceStage] [BuildOption] [BuildStageReceipt])
(def (package-source-stages-run! stages options)
  (build-requests-run!
   (package-source-stages->requests stages options)))

;; : (-> [PackageSourceStage] [Any])
(def (package-source-stages-clean! stages)
  (build-requests-clean!
   (package-source-stages->requests stages [])))

;; : (-> BuildRequest Alist)
;; build-request->alist
;; : (-> BuildRequest Alist)
(def (build-request->alist request)
  (let (profile (build-request-profile request))
    `((label . ,(build-request-label request))
      (profile . ,(build-profile-name profile))
      (description . ,(build-profile-description profile))
      (stage-count . ,(length (build-request-stage-specs request))))))
