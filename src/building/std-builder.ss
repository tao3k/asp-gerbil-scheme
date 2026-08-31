(import (only-in :gerbil/gambit
                 ##gc
                 file-exists?
                 file-info
                 file-info-last-modification-time
                 getenv
                 read
                 string-length
                 substring
                 time->seconds)
        (only-in :clan/poo/object object? object<-alist .ref .has?)
        (only-in :clan/poo/mop .defgeneric)
        (only-in :std/make make make-clean)
        :std/misc/path
        (only-in :std/srfi/1 drop filter filter-map take)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        ./model
        ./native-toolchain)

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
        execution-window-controller?
        execution-window-controller-hard-max-rss-bytes
        execution-window-controller-headroom-bytes
        execution-window-controller-window-size
        execution-window-controller-observe-run!
        execution-window-controller-next-state
        make-execution-window-observation
        execution-window-observation?
        execution-window-observation-result
        execution-window-observation-outcome
        execution-window-observation-baseline-rss-bytes
        execution-window-observation-peak-rss-bytes
        execution-window-observation-max-rss-bytes
        execution-window-observation-elapsed-ms
        make-adaptive-execution-window-plan
        adaptive-execution-window-plan?
        adaptive-execution-window-plan-topology-groups
        adaptive-execution-window-plan-controller
        make-adaptive-execution-window-result
        adaptive-execution-window-result?
        adaptive-execution-window-result-topology-groups
        adaptive-execution-window-result-execution-windows
        adaptive-execution-window-result-window-observations
        adaptive-execution-window-result-controller
        std-builder-run-adaptive-plan!
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
        package-source-stage-current?
        source-topology-layers
        source-topology-affected
        package-source-stage-dependencies
        package-source-stage-topology-layers
        package-source-stage->request
        package-source-stages->requests
        package-source-stages-spec
        package-source-stages-run!
        package-source-stages-clean!
        build-request->alist)

(defstruct std-builder
  (name make-proc stage-kind description srcdir make-options toolchain))

;;; Boundary: projects declare source topology and phase ordering.  std/make
;;; owns compiler scheduling and GERBIL_BUILD_CORES; this layer owns only
;;; stage admission, receipts, toolchain scope, and clean delegation.
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

(def (execution-window-controller? controller)
  (and (object? controller)
       (.has? controller kind)
       (.has? controller hard-max-rss-bytes)
       (.has? controller headroom-bytes)
       (.has? controller window-size)
       (.has? controller .observe-run!)
       (.has? controller .next-state)
       (eq? (.ref controller 'kind)
            'asp-gerbil-scheme.execution-window-controller.v1)))

(def (execution-window-controller-slot controller slot)
  (unless (execution-window-controller? controller)
    (error "invalid execution-window controller" controller))
  (.ref controller slot))

(def (execution-window-controller-hard-max-rss-bytes controller)
  (execution-window-controller-slot controller 'hard-max-rss-bytes))

(def (execution-window-controller-headroom-bytes controller)
  (execution-window-controller-slot controller 'headroom-bytes))

(def (execution-window-controller-window-size controller)
  (execution-window-controller-slot controller 'window-size))

(.defgeneric
 (execution-window-controller-observe-run! controller label thunk)
 slot: .observe-run!)

(.defgeneric
 (execution-window-controller-next-state
  controller
  observation
  spec-count)
 slot: .next-state)

(def (make-execution-window-observation
      result
      outcome
      baseline-rss-bytes
      peak-rss-bytes
      max-rss-bytes
      elapsed-ms)
  (object<-alist
   `((kind . asp-gerbil-scheme.execution-window-observation.v1)
     (result . ,result)
     (outcome . ,outcome)
     (baseline-rss-bytes . ,baseline-rss-bytes)
     (peak-rss-bytes . ,peak-rss-bytes)
     (max-rss-bytes . ,max-rss-bytes)
     (elapsed-ms . ,elapsed-ms))))

(def (execution-window-observation? observation)
  (and (object? observation)
       (.has? observation kind)
       (.has? observation result)
       (.has? observation outcome)
       (.has? observation baseline-rss-bytes)
       (.has? observation peak-rss-bytes)
       (.has? observation max-rss-bytes)
       (.has? observation elapsed-ms)
       (eq? (.ref observation 'kind)
            'asp-gerbil-scheme.execution-window-observation.v1)))

(def (execution-window-observation-slot observation slot)
  (unless (execution-window-observation? observation)
    (error "invalid execution-window observation" observation))
  (.ref observation slot))

(def (execution-window-observation-result observation)
  (execution-window-observation-slot observation 'result))

(def (execution-window-observation-outcome observation)
  (execution-window-observation-slot observation 'outcome))

(def (execution-window-observation-baseline-rss-bytes observation)
  (execution-window-observation-slot observation 'baseline-rss-bytes))

(def (execution-window-observation-peak-rss-bytes observation)
  (execution-window-observation-slot observation 'peak-rss-bytes))

(def (execution-window-observation-max-rss-bytes observation)
  (execution-window-observation-slot observation 'max-rss-bytes))

(def (execution-window-observation-elapsed-ms observation)
  (execution-window-observation-slot observation 'elapsed-ms))

(def (make-adaptive-execution-window-plan topology-groups controller)
  (unless (execution-window-controller? controller)
    (error "invalid adaptive execution-window controller" controller))
  (object<-alist
   `((kind . asp-gerbil-scheme.adaptive-execution-window-plan.v1)
     (topology-groups . ,topology-groups)
     (controller . ,controller))))

(def (adaptive-execution-window-plan? plan)
  (and (object? plan)
       (.has? plan kind)
       (eq? (.ref plan 'kind)
            'asp-gerbil-scheme.adaptive-execution-window-plan.v1)))

(def (adaptive-execution-window-plan-topology-groups plan)
  (.ref plan 'topology-groups))

(def (adaptive-execution-window-plan-controller plan)
  (.ref plan 'controller))

(def (std-builder-request-spec-count spec)
  (if (adaptive-execution-window-plan? spec)
    (length
     (apply append
            (adaptive-execution-window-plan-topology-groups spec)))
    (length spec)))

(def (make-adaptive-execution-window-result
      topology-groups
      execution-windows
      window-observations
      controller)
  (object<-alist
   `((kind . asp-gerbil-scheme.adaptive-execution-window-result.v1)
     (topology-groups . ,topology-groups)
     (execution-windows . ,execution-windows)
     (window-observations . ,window-observations)
     (controller . ,controller))))

(def (adaptive-execution-window-result? result)
  (and (object? result)
       (.has? result kind)
       (eq? (.ref result 'kind)
            'asp-gerbil-scheme.adaptive-execution-window-result.v1)))

(def (adaptive-execution-window-result-topology-groups result)
  (.ref result 'topology-groups))

(def (adaptive-execution-window-result-execution-windows result)
  (.ref result 'execution-windows))

(def (adaptive-execution-window-result-window-observations result)
  (.ref result 'window-observations))

(def (adaptive-execution-window-result-controller result)
  (.ref result 'controller))

(def (execution-window-positive-integer value label)
  (unless (and (integer? value) (> value 0))
    (error "invalid adaptive execution-window value" label value))
  value)

(def (std-builder-run-adaptive-plan/sequential! builder plan (extra-options []))
  (let* ((topology-groups
          (adaptive-execution-window-plan-topology-groups plan))
         (specs (apply append topology-groups))
         (initial-controller
          (adaptive-execution-window-plan-controller plan)))
    (let loop ((remaining specs)
               (controller initial-controller)
               (execution-windows [])
               (window-observations []))
      (if (null? remaining)
        (make-adaptive-execution-window-result
         topology-groups
         (reverse execution-windows)
         (reverse window-observations)
         controller)
        (let* ((requested-window-size
                (execution-window-positive-integer
                 (execution-window-controller-window-size controller)
                 'window-size))
               (window-size (min requested-window-size (length remaining)))
               (window (take remaining window-size)))
          (let (observation
                (execution-window-controller-observe-run!
                 controller
                 "std/make adaptive execution window"
                 (lambda ()
                   (std-builder-run-spec/raw!
                    builder
                    window
                    extra-options))))
            (unless (execution-window-observation? observation)
              (error
               "adaptive controller returned an invalid observation"
               observation))
            (let* ((outcome
                    (execution-window-observation-outcome observation))
                   (observed-rss-bytes
                    (execution-window-observation-peak-rss-bytes observation))
                   (observation-max-rss-bytes
                    (execution-window-observation-max-rss-bytes observation))
                   (elapsed-ms
                    (execution-window-observation-elapsed-ms observation))
                   (hard-max-rss-bytes
                  (execution-window-positive-integer
                   (execution-window-controller-hard-max-rss-bytes controller)
                   'hard-max-rss-bytes)))
              (unless (memq outcome '(completed ok))
                (error
                 "adaptive execution-window observation failed closed"
                 outcome
                 observed-rss-bytes
                 hard-max-rss-bytes))
              (unless (and (integer? observed-rss-bytes)
                           (>= observed-rss-bytes 0))
                (error
                 "invalid adaptive execution-window RSS observation"
                 observed-rss-bytes))
              (unless (and (integer? observation-max-rss-bytes)
                           (> observation-max-rss-bytes 0)
                           (= observation-max-rss-bytes
                              hard-max-rss-bytes))
                (error
                 "adaptive observation RSS limit does not match controller"
                 observation-max-rss-bytes
                 hard-max-rss-bytes))
              (unless (and (integer? elapsed-ms) (>= elapsed-ms 0))
                (error
                 "invalid adaptive execution-window elapsed observation"
                 elapsed-ms))
              (when (> observed-rss-bytes hard-max-rss-bytes)
                (error
                 (if (= window-size 1)
                   "one build spec cannot fit the adaptive RSS budget"
                   "adaptive execution window exceeded the RSS budget")
                 observed-rss-bytes
                 hard-max-rss-bytes))
              (let (next-controller
                    (execution-window-controller-next-state
                     controller
                     observation
                     window-size))
                (unless (execution-window-controller? next-controller)
                  (error
                   "adaptive controller returned an invalid next state"
                   next-controller))
                (loop
                 (drop remaining window-size)
                 next-controller
                 (cons window execution-windows)
                 (cons observation window-observations))))))))))

(def (adaptive-execution-window-next-controller
      controller observation window-size)
  (unless (execution-window-observation? observation)
    (error "adaptive controller returned an invalid observation" observation))
  (let* ((outcome (execution-window-observation-outcome observation))
         (observed-rss-bytes
          (execution-window-observation-peak-rss-bytes observation))
         (observation-max-rss-bytes
          (execution-window-observation-max-rss-bytes observation))
         (elapsed-ms (execution-window-observation-elapsed-ms observation))
         (hard-max-rss-bytes
          (execution-window-positive-integer
           (execution-window-controller-hard-max-rss-bytes controller)
           'hard-max-rss-bytes)))
    (unless (memq outcome '(completed ok))
      (error "adaptive execution-window observation failed closed"
             outcome observed-rss-bytes hard-max-rss-bytes))
    (unless (and (integer? observed-rss-bytes)
                 (>= observed-rss-bytes 0))
      (error "invalid adaptive execution-window RSS observation"
             observed-rss-bytes))
    (unless (and (integer? observation-max-rss-bytes)
                 (> observation-max-rss-bytes 0)
                 (= observation-max-rss-bytes hard-max-rss-bytes))
      (error "adaptive observation RSS limit does not match controller"
             observation-max-rss-bytes hard-max-rss-bytes))
    (unless (and (integer? elapsed-ms) (>= elapsed-ms 0))
      (error "invalid adaptive execution-window elapsed observation"
             elapsed-ms))
    (when (> observed-rss-bytes hard-max-rss-bytes)
      (error
       (if (= window-size 1)
         "one build spec cannot fit the adaptive RSS budget"
         "adaptive execution window exceeded the RSS budget")
       observed-rss-bytes hard-max-rss-bytes))
    (let (next-controller
          (execution-window-controller-next-state
           controller observation window-size))
      (unless (execution-window-controller? next-controller)
        (error "adaptive controller returned an invalid next state"
               next-controller))
      next-controller)))

(def (std-builder-run-adaptive-plan! builder plan (extra-options []))
  (std-builder-run-adaptive-plan/sequential! builder plan extra-options))

(def (std-builder-run-spec! builder spec (extra-options []))
  (if (adaptive-execution-window-plan? spec)
    (std-builder-run-adaptive-plan! builder spec extra-options)
    (std-builder-run-spec/raw! builder spec extra-options)))

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
  (let (batching (package-source-stage-batched? stage))
    (if (execution-window-controller? batching)
      (let (topology-groups
            (package-source-stage-topology-request-spec-groups stage))
        (if (and (pair? topology-groups)
                 (null? (cdr topology-groups)))
          (list
           (make-adaptive-execution-window-plan
            topology-groups
            batching))
          (topology-groups->upstream-execution-windows topology-groups)))
      (package-source-stage-request-specs/default stage))))

;; : (-> PackageSourceStage [[BuildSpec]])
(def (package-source-stage-request-specs/default stage)
  (let (specs (package-source-stage-specs stage))
    (cond
      ((eq? (package-source-stage-batched? stage) 'topology)
       (package-source-stage-topology-request-specs stage))
     ((package-source-stage-batched? stage)
      (list specs))
     (else
      (map list specs)))))

;; : (-> BuildSpec ModulePath)
(def (package-source-spec-module spec)
  (cond
   ((string? spec) spec)
   ((and (pair? spec)
         (pair? (cdr spec))
         (string? (cadr spec)))
    (cadr spec))
   (else
    (error "package source stage requires a module source spec" spec))))

(def (package-source-spec-ssi? spec)
  (and (pair? spec)
       (eq? (car spec) 'ssi:)))

;; : (-> ModulePath ModulePath)
(def (package-source-module-stem module)
  (let (length (string-length module))
    (if (and (>= length 3)
             (equal? (substring module (- length 3) length) ".ss"))
      (substring module 0 (- length 3))
      module)))

;; : (-> PackageSourceStage BuildSpec Path)
(def (package-source-stage-source-path stage spec)
  (path-expand
   (package-source-spec-module spec)
   (package-source-stage-source stage)))

;; : (-> PackageSourceStage BuildSpec Path)
(def (package-source-stage-output-path stage spec)
  (path-expand
   (string-append
    (package-source-stage-prefix stage)
    "/"
    (package-source-module-stem (package-source-spec-module spec))
    ".ssi")
   (path-expand "lib" (or (getenv "GERBIL_PATH") ".gerbil"))))

;; : (-> Path Integer)
(def (package-source-file-seconds path)
  (time->seconds (file-info-last-modification-time (file-info path))))

;; : (-> PackageSourceStage BuildSpec [ModulePath] Boolean)
(def (package-source-spec-artifact-current? stage spec dependencies)
  (let ((source (package-source-stage-source-path stage spec))
        (output (package-source-stage-output-path stage spec)))
    (and (file-exists? source)
         (file-exists? output)
         (<= (package-source-file-seconds source)
             (package-source-file-seconds output))
         (or (package-source-spec-ssi? spec)
             (andmap
              (lambda (dependency)
                (let (dependency-output
                      (package-source-stage-output-path stage dependency))
                  (and (file-exists? dependency-output)
                       (<= (package-source-file-seconds dependency-output)
                           (package-source-file-seconds output)))))
              dependencies)))))

;; : (-> PackageSourceStage BuildSpec Boolean)
(def (package-source-spec-current? stage spec)
  (package-source-spec-artifact-current?
   stage
   spec
   (if (eq? (package-source-stage-batched? stage) 'topology)
     (package-source-stage-dependencies
      stage (package-source-spec-module spec))
     [])))

;; : (-> PackageSourceStage [BuildSpec] Boolean)
(def (package-source-stage-current? stage specs)
  (if (adaptive-execution-window-plan? specs)
    (null?
     (apply append
            (adaptive-execution-window-plan-topology-groups specs)))
    (and (pair? specs)
         (andmap (lambda (spec)
                   (package-source-spec-current? stage spec))
                 specs))))

;; : (forall (n) (-> n [n] (-> n [n]) Boolean))
(def (source-topology-ready? node remaining dependencies-of)
  (not (ormap (lambda (dependency)
                (member dependency remaining))
              (dependencies-of node))))

;; : (forall (n) (-> [n] [n] [n]))
(def (source-topology-without nodes removed)
  (filter (lambda (node)
            (not (member node removed)))
          nodes))

;; : (forall (n) (-> [n] (-> n [n]) [[n]]))
(def (source-topology-layers nodes dependencies-of)
  (let loop ((remaining nodes) (layers []))
    (if (null? remaining)
      (reverse layers)
      (let (ready
            (filter (lambda (node)
                      (source-topology-ready?
                       node remaining dependencies-of))
                    remaining))
        (if (null? ready)
          (error "source topology contains a dependency cycle" remaining)
          (loop (source-topology-without remaining ready)
                (cons ready layers)))))))

;; : (forall (n) (-> [n] [n] (-> n [n]) [n]))
(def (source-topology-affected nodes stale dependencies-of)
  (let loop ((affected stale))
    (let (dependents
          (filter
           (lambda (node)
             (and (not (member node affected))
                  (ormap (lambda (dependency)
                           (member dependency affected))
                         (dependencies-of node))))
           nodes))
      (if (null? dependents)
        (filter (lambda (node) (member node affected)) nodes)
        (loop (append affected dependents))))))

;; : (-> String String)
(def (package-source-module-path module)
  (if (string-suffix? ".ss" module)
    module
    (string-append module ".ss")))

;; : (-> PackageSourceStage ModulePath Datum (Maybe ModulePath))
(def (package-source-import-reference stage owner reference)
  (cond
   ((symbol? reference)
    (let* ((name (symbol->string reference))
           (prefix (string-append ":" (package-source-stage-prefix stage) "/")))
      (and (string-prefix? prefix name)
           (package-source-module-path
            (substring name (string-length prefix) (string-length name))))))
   ((and (string? reference) (string-prefix? "." reference))
    (let* ((root (path-normalize (package-source-stage-source stage)))
           (directory (path-expand (path-directory owner) root))
             (absolute (path-normalize
                         (path-expand (package-source-module-path reference)
                                      directory))))
      (package-source-module-path
       (substring absolute
                  (+ (string-length root)
                     (if (string-suffix? "/" root) 0 1))
                  (string-length absolute)))))
   (else #f)))

;; : (-> PackageSourceStage ModulePath Datum [ModulePath])
(def (package-source-import-references stage owner datum)
  (cond
   ((pair? datum)
    (apply append
           (map (lambda (item)
                  (package-source-import-references stage owner item))
                datum)))
   (else
    (let (module (package-source-import-reference stage owner datum))
      (if module [module] [])))))

;; : (-> Datum Boolean)
(def (package-source-module-header-form? form)
  (and (pair? form)
       (memq (car form)
             '(import export package: namespace declare prelude:))))

;; : (-> Path [Datum])
(def (package-source-read-import-forms path)
  (call-with-input-file path
    (lambda (port)
      (let loop ((forms []))
        (let (form (read port))
          (cond
           ((eof-object? form) (reverse forms))
           ((and (pair? form) (memq (car form) '(import export)))
            (loop (cons form forms)))
           ((package-source-module-header-form? form)
            (loop forms))
           (else (reverse forms))))))))

;; : (-> PackageSourceStage ModulePath [ModulePath])
(def (package-source-stage-dependencies stage module)
  (let* ((modules (map package-source-spec-module
                       (package-source-stage-specs stage)))
         (forms
          (package-source-read-import-forms
           (package-source-stage-source-path stage module))))
    (filter
     (lambda (dependency) (member dependency modules))
     (apply append
            (filter-map
             (lambda (form)
               (and (pair? form)
                    (memq (car form) '(import export))
                    (package-source-import-references stage module (cdr form))))
             forms)))))

;; : (-> PackageSourceStage [[ModulePath]])
(def (package-source-stage-topology-layers stage)
  (let (modules (map package-source-spec-module
                      (package-source-stage-specs stage)))
    (source-topology-layers
     modules
     (lambda (module)
       (package-source-stage-dependencies stage module)))))

(export topology-groups->upstream-execution-windows
        package-source-stage-topology-request-spec-groups
        package-source-stage-topology-request-specs)

;; : (-> [[ModulePath]] [[ModulePath]])
(def (topology-groups->upstream-execution-windows groups)
  (let (specs (apply append groups))
    (if (null? specs)
        []
        (list specs))))

;; : (-> PackageSourceStage [[ModulePath]])
(def (package-source-stage-topology-request-specs stage)
  (topology-groups->upstream-execution-windows
   (package-source-stage-topology-request-spec-groups stage)))

;; : (-> PackageSourceStage [[ModulePath]])
(def (package-source-stage-topology-request-spec-groups stage)
  (let* ((specs (package-source-stage-specs stage))
         (modules (map package-source-spec-module specs))
         (specs-by-module
          (map (lambda (spec)
                 (cons (package-source-spec-module spec) spec))
               specs))
         (dependencies
          (map (lambda (module)
                 (cons module
                       (package-source-stage-dependencies stage module)))
               modules))
         (dependencies-of
          (lambda (module) (cdr (assoc module dependencies))))
         (layers (source-topology-layers modules dependencies-of))
         (stale
         (filter
           (lambda (module)
             (not (package-source-spec-artifact-current?
                   stage
                   (cdr (assoc module specs-by-module))
                   (dependencies-of module))))
           modules))
         (affected
          (source-topology-affected modules stale dependencies-of)))
    (filter-map
     (lambda (layer)
       (let (selected
             (filter (lambda (module) (member module affected)) layer))
         (and (pair? selected)
              (map (lambda (module)
                     (cdr (assoc module specs-by-module)))
                   selected))))
     layers)))

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
              (number->string (std-builder-request-spec-count spec)))))))
    (make-std-builder-request
     label
     profile
     (package-source-stage-request-specs stage)
     (lambda (specs context)
       (package-source-stage-current? context specs))
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
