;;; Build observability projects already-executed stage receipts and guard
;;; samples into evidence.  It may detect rapid memory anomalies, but it must
;;; not reduce configured concurrency or become a second scheduler.
(import :gerbil/gambit
        (only-in :clan/poo/object defclass object)
        (only-in :std/text/json
                 json-object->string
                 write-json-sort-keys?)
        (only-in :std/srfi/1 fold)
        (only-in ./model
                 build-stage-receipt-description
                 build-stage-receipt-elapsed-jiffies
                 build-stage-receipt-kind
                 build-stage-receipt-label
                 build-stage-receipt-status
                 build-stage-run!
                 build-stage-spec)
        (only-in ./std-builder build-request-stage-plan))

(export build-stage-observation?
        make-build-stage-observation
        build-stage-observation-receipt
        build-stage-observation-work-item-count
        build-stage-observation-wall-seconds
        build-stage-observation-control-plane-user-seconds
        build-stage-observation-control-plane-system-seconds
        build-stage-observation-control-plane-cpu-seconds
        build-stage-observation-control-plane-cpu-utilization
        build-stage-observation-control-plane-gc-user-seconds
        build-stage-observation-control-plane-gc-system-seconds
        build-stage-observation-control-plane-gc-wall-seconds
        build-stage-observation-control-plane-gc-count
        build-stage-observation-control-plane-allocated-bytes
        build-stage-observation->json-object
        build-plan-observations->json-object
        build-plan-observations-summary->json-object
        build-stage-observation->json-string
        build-plan-observations->json-string
        build-plan-observations-summary->json-string
        write-build-stage-observation-json
        write-build-plan-observations-json
        write-build-plan-observations-summary-json
        make-build-elapsed-budget-guard
        build-observe-sequence/guard!
        build-action-observe!
        build-stage-observe!
        build-plan-observe!
        build-plan-observe/guard!
        build-request-observe!
        build-requests-observe!
        package-source-stages-observe!
        package-source-stages-observe/guard!)

;; These counters intentionally describe only the long-lived Gerbil control
;; process.  Native compiler children are outside ##process-statistics and must
;; never be presented as control-plane CPU time.
(defclass (build-stage-observation object)
  (receipt
   work-item-count
   wall-seconds
   control-plane-user-seconds
   control-plane-system-seconds
   control-plane-cpu-seconds
   control-plane-cpu-utilization
   control-plane-gc-user-seconds
   control-plane-gc-system-seconds
   control-plane-gc-wall-seconds
   control-plane-gc-count
   control-plane-allocated-bytes)
  transparent: #t)

(def (statistics-ref statistics index)
  (if (< index (f64vector-length statistics))
      (f64vector-ref statistics index)
      0.0))

(def (statistics-delta start end index)
  (max 0.0
       (- (statistics-ref end index)
          (statistics-ref start index))))

(def (elapsed-seconds start-jiffy end-jiffy)
  (exact->inexact
   (/ (- end-jiffy start-jiffy)
      (jiffies-per-second))))

(def (stage-work-item-count stage)
  (let ((spec (build-stage-spec stage)))
    (if (list? spec) (length spec) 1)))

(def (safe-utilization cpu-seconds wall-seconds)
  (if (positive? wall-seconds)
      (/ cpu-seconds wall-seconds)
      0.0))

(def (make-build-elapsed-budget-guard limit-seconds)
  (unless (and (real? limit-seconds) (positive? limit-seconds))
    (error "build elapsed budget must be positive" limit-seconds))
  (lambda (_phase elapsed-seconds _completed-count _subject)
    (<= elapsed-seconds limit-seconds)))

(def (allow-build-observation? _phase _elapsed-seconds _completed-count _subject)
  #t)

(def (ignore-build-observation! _observation _completed-count _elapsed-seconds)
  #!void)

;; The guard is checked on both sides of every item.  It therefore blocks at an
;; observation boundary without a polling thread, and can overrun only by the
;; duration of the currently executing item.  Callers own the budget policy;
;; this layer deliberately has no machine-independent time constant.
(def (build-observe-sequence/guard! items observer guard on-observation)
  (let* ((start-jiffy (current-jiffy))
         (progress
          (fold
           (lambda (item progress)
             (let* ((completed-reverse (vector-ref progress 0))
                    (completed-count (vector-ref progress 1))
                    (before-seconds
                     (elapsed-seconds start-jiffy (current-jiffy))))
               (unless (guard 'before-item
                              before-seconds
                              completed-count
                              item)
                 (error "build observation guard blocked before item"
                        `((elapsed-seconds . ,before-seconds)
                          (completed-count . ,completed-count))))
               (let* ((observation (observer item))
                      (next-count (+ completed-count 1))
                      (after-seconds
                       (elapsed-seconds start-jiffy (current-jiffy))))
                 (on-observation observation next-count after-seconds)
                 (unless (guard 'after-item
                                after-seconds
                                next-count
                                observation)
                   (error "build observation guard blocked after item"
                          `((elapsed-seconds . ,after-seconds)
                            (completed-count . ,next-count))))
                 (vector (cons observation completed-reverse)
                         next-count))))
           (vector '() 0)
           items)))
    (reverse (vector-ref progress 0))))

(def (sum-observation-field accessor observations)
  (apply + (map accessor observations)))

(def (json-name value)
  (if (symbol? value) (symbol->string value) value))

;; Formal receipt metadata excludes the runner's arbitrary Scheme result.  A
;; status and metrics projection is portable JSON; the raw result remains on
;; the in-process receipt for Scheme callers only.
(def (build-stage-observation->json-object observation)
  (let ((receipt (build-stage-observation-receipt observation)))
    (hash ("schema" "asp-gerbil-scheme.build-stage-observation.v1")
          ("version" 1)
          ("label" (build-stage-receipt-label receipt))
          ("kind" (json-name (build-stage-receipt-kind receipt)))
          ("status" (json-name (build-stage-receipt-status receipt)))
          ("description" (build-stage-receipt-description receipt))
          ("elapsed-jiffies" (build-stage-receipt-elapsed-jiffies receipt))
          ("work-item-count"
           (build-stage-observation-work-item-count observation))
          ("wall-seconds"
           (build-stage-observation-wall-seconds observation))
          ("control-plane-user-seconds"
           (build-stage-observation-control-plane-user-seconds observation))
          ("control-plane-system-seconds"
           (build-stage-observation-control-plane-system-seconds observation))
          ("control-plane-cpu-seconds"
           (build-stage-observation-control-plane-cpu-seconds observation))
          ("control-plane-cpu-utilization"
           (build-stage-observation-control-plane-cpu-utilization observation))
          ("control-plane-gc-user-seconds"
           (build-stage-observation-control-plane-gc-user-seconds observation))
          ("control-plane-gc-system-seconds"
           (build-stage-observation-control-plane-gc-system-seconds observation))
          ("control-plane-gc-wall-seconds"
           (build-stage-observation-control-plane-gc-wall-seconds observation))
          ("control-plane-gc-count"
           (build-stage-observation-control-plane-gc-count observation))
          ("control-plane-allocated-bytes"
           (build-stage-observation-control-plane-allocated-bytes observation)))))

(def (build-plan-observations->json-object observations)
  (hash ("schema" "asp-gerbil-scheme.build-observations.v1")
        ("version" 1)
        ("metric-scope" "gerbil-control-plane")
        ("native-child-cpu-included" #f)
        ("stages" (map build-stage-observation->json-object observations))))


(def (build-plan-observations-summary->json-object observations)
  (let* ((wall-seconds
          (sum-observation-field build-stage-observation-wall-seconds
                                 observations))
         (cpu-seconds
          (sum-observation-field build-stage-observation-control-plane-cpu-seconds
                                 observations)))
    (hash ("schema" "asp-gerbil-scheme.build-observations-summary.v1")
          ("version" 1)
          ("metric-scope" "gerbil-control-plane")
          ("native-child-cpu-included" #f)
          ("stage-count" (length observations))
          ("work-item-count"
           (sum-observation-field build-stage-observation-work-item-count
                                  observations))
          ("wall-seconds" wall-seconds)
          ("control-plane-cpu-seconds" cpu-seconds)
          ("control-plane-cpu-utilization"
           (safe-utilization cpu-seconds wall-seconds))
          ("control-plane-gc-user-seconds"
           (sum-observation-field
            build-stage-observation-control-plane-gc-user-seconds
            observations))
          ("control-plane-gc-system-seconds"
           (sum-observation-field
            build-stage-observation-control-plane-gc-system-seconds
            observations))
          ("control-plane-gc-wall-seconds"
           (sum-observation-field
            build-stage-observation-control-plane-gc-wall-seconds
            observations))
          ("control-plane-gc-count"
           (sum-observation-field
            build-stage-observation-control-plane-gc-count
            observations))
          ("control-plane-allocated-bytes"
           (sum-observation-field
            build-stage-observation-control-plane-allocated-bytes
            observations)))))

(def (json-object->canonical-string object)
  (parameterize ((write-json-sort-keys? #t))
    (json-object->string object)))

(def (build-stage-observation->json-string observation)
  (json-object->canonical-string
   (build-stage-observation->json-object observation)))

(def (build-plan-observations->json-string observations)
  (json-object->canonical-string
   (build-plan-observations->json-object observations)))

(def (build-plan-observations-summary->json-string observations)
  (json-object->canonical-string
   (build-plan-observations-summary->json-object observations)))

(def (write-json-line string port)
  (display string port)
  (newline port))

(def (write-build-stage-observation-json
      observation (port (current-output-port)))
  (write-json-line (build-stage-observation->json-string observation) port))

(def (write-build-plan-observations-json
      observations (port (current-output-port)))
  (write-json-line (build-plan-observations->json-string observations) port))

(def (write-build-plan-observations-summary-json
      observations (port (current-output-port)))
  (write-json-line
   (build-plan-observations-summary->json-string observations)
   port))

(def (build-action-observe! work-item-count thunk)
  (let* ((start-jiffy (current-jiffy))
         (start-statistics (##process-statistics))
         (receipt (thunk))
         (end-statistics (##process-statistics))
         (end-jiffy (current-jiffy))
         (wall-seconds (elapsed-seconds start-jiffy end-jiffy))
         (user-seconds (statistics-delta start-statistics end-statistics 0))
         (system-seconds (statistics-delta start-statistics end-statistics 1))
         (cpu-seconds (+ user-seconds system-seconds)))
    (make-build-stage-observation
     receipt
     work-item-count
     wall-seconds
     user-seconds
     system-seconds
     cpu-seconds
     (safe-utilization cpu-seconds wall-seconds)
     (statistics-delta start-statistics end-statistics 3)
     (statistics-delta start-statistics end-statistics 4)
     (statistics-delta start-statistics end-statistics 5)
     (statistics-delta start-statistics end-statistics 6)
     (statistics-delta start-statistics end-statistics 7))))

(def (build-stage-observe! stage context)
  (build-action-observe!
   (stage-work-item-count stage)
   (lambda () (build-stage-run! stage context))))

(def (build-plan-observe! stages context)
  (build-plan-observe/guard!
   stages
   context
   allow-build-observation?
   ignore-build-observation!))

(def (build-plan-observe/guard! stages context guard on-observation)
  (build-observe-sequence/guard!
   stages
   (lambda (stage) (build-stage-observe! stage context))
   guard
   on-observation))

(def (build-request-observe! request context)
  (build-plan-observe! (build-request-stage-plan request) context))

(def (build-requests-observe! requests context)
  (apply append
         (map (lambda (request)
                (build-request-observe! request context))
              requests)))

(def (package-source-stages-observe! source-stages requests)
  (package-source-stages-observe/guard!
   source-stages
   requests
   allow-build-observation?
   ignore-build-observation!))

(defstruct observed-build-stage (stage context) transparent: #t)

(def (package-source-stage-observation-items source-stages requests)
  (apply append
         (map (lambda (source-stage request)
                (map (lambda (stage)
                       (make-observed-build-stage stage source-stage))
                     (build-request-stage-plan request)))
              source-stages
              requests)))

(def (package-source-stages-observe/guard!
      source-stages requests guard on-observation)
  (build-observe-sequence/guard!
   (package-source-stage-observation-items source-stages requests)
   (lambda (item)
     (build-stage-observe!
      (observed-build-stage-stage item)
      (observed-build-stage-context item)))
   guard
   on-observation))
