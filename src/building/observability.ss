(import :gerbil/gambit
        (only-in :std/text/json
                 json-object->string
                 write-json-sort-keys?)
        ./model
        ./std-builder)

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
(defstruct build-stage-observation
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

;; The guard is checked on both sides of every item.  It therefore blocks at a
;; topology boundary without a polling thread, and can overrun only by the
;; duration of the currently executing item.  Callers own the budget policy;
;; this layer deliberately has no machine-independent time constant.
(def (build-observe-sequence/guard! items observer guard on-observation)
  (let ((start-jiffy (current-jiffy)))
    (let loop ((remaining items) (completed-reverse '()) (completed-count 0))
      (if (null? remaining)
          (reverse completed-reverse)
          (let* ((item (car remaining))
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
              (loop (cdr remaining)
                    (cons observation completed-reverse)
                    next-count)))))))

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

(export build-topology-execution-windows->json-object
        build-topology-execution-windows->json-string
        package-source-stage-topology-execution-windows->json-object
        package-source-stage-topology-execution-windows->json-string
        build-adaptive-execution-windows->json-object
        build-adaptive-execution-windows->json-string)

(def (build-topology-execution-windows-flatten groups)
  (apply append groups))

(def (build-topology-execution-windows->json-object topology-groups execution-windows)
  (let* ((topology-specs
          (build-topology-execution-windows-flatten topology-groups))
         (window-specs
          (build-topology-execution-windows-flatten execution-windows))
         (topology-group-count (length topology-groups))
         (upstream-session-count (length execution-windows)))
    (hash
     ("schema" "asp-gerbil-scheme.build-topology-execution-windows.v1")
     ("version" 1)
     ("metric-scope" "build-topology-execution-windows")
     ("upstream-executor" "std/make")
     ("topology-group-count" topology-group-count)
     ("upstream-session-count" upstream-session-count)
     ("eliminated-barrier-count"
      (max 0 (- topology-group-count upstream-session-count)))
     ("spec-count" (length topology-specs))
     ("dependency-order-preserved" (equal? topology-specs window-specs)))))

(def (build-topology-execution-windows->json-string topology-groups execution-windows)
  (json-object->canonical-string
   (build-topology-execution-windows->json-object
    topology-groups
    execution-windows)))

(def (package-source-stage-topology-execution-windows->json-object stage)
  (build-topology-execution-windows->json-object
   (package-source-stage-topology-request-spec-groups stage)
   (package-source-stage-topology-request-specs stage)))

(def (package-source-stage-topology-execution-windows->json-string stage)
  (json-object->canonical-string
   (package-source-stage-topology-execution-windows->json-object stage)))

(def (build-adaptive-execution-window-spec->json-value spec)
  (cond
   ((symbol? spec) (symbol->string spec))
   ((pair? spec)
    (map build-adaptive-execution-window-spec->json-value spec))
   ((null? spec) [])
   (else spec)))

(def (build-adaptive-execution-window->json-object
      window observation index)
  (hash
   ("index" index)
   ("spec-count" (length window))
   ("specs"
    (map build-adaptive-execution-window-spec->json-value window))
   ("outcome"
    (json-name (execution-window-observation-outcome observation)))
   ("baseline-rss-bytes"
    (execution-window-observation-baseline-rss-bytes observation))
   ("peak-rss-bytes"
    (execution-window-observation-peak-rss-bytes observation))
   ("max-rss-bytes"
    (execution-window-observation-max-rss-bytes observation))
   ("elapsed-ms"
    (execution-window-observation-elapsed-ms observation))))

(def (build-adaptive-execution-window-json-objects
      windows observations (index 0))
  (if (null? windows)
    []
    (cons
     (build-adaptive-execution-window->json-object
      (car windows) (car observations) index)
     (build-adaptive-execution-window-json-objects
      (cdr windows) (cdr observations) (+ index 1)))))

(def (build-adaptive-execution-windows->json-object result)
  (unless (adaptive-execution-window-result? result)
    (error "adaptive execution-window JSON requires an adaptive result" result))
  (let* ((topology-groups
          (adaptive-execution-window-result-topology-groups result))
         (execution-windows
          (adaptive-execution-window-result-execution-windows result))
         (observations
          (adaptive-execution-window-result-window-observations result))
         (controller
          (adaptive-execution-window-result-controller result))
         (topology-specs
          (build-topology-execution-windows-flatten topology-groups))
         (attempted-specs
          (build-topology-execution-windows-flatten execution-windows)))
    (unless (= (length execution-windows) (length observations))
      (error
       "adaptive execution-window result has mismatched observations"
       (length execution-windows)
       (length observations)))
    (hash
     ("schema" "asp-gerbil-scheme.build-adaptive-execution-windows.v1")
     ("version" 1)
     ("metric-scope" "build-adaptive-execution-windows")
     ("upstream-executor" "std/make")
     ("topology-group-count" (length topology-groups))
     ("attempted-window-count" (length execution-windows))
     ("spec-count" (length attempted-specs))
     ("dependency-order-preserved"
      (equal? topology-specs attempted-specs))
     ("hard-max-rss-bytes"
      (execution-window-controller-hard-max-rss-bytes controller))
     ("windows"
      (build-adaptive-execution-window-json-objects
       execution-windows observations)))))

(export build-adaptive-execution-window-diagnostics->json-object
        build-adaptive-execution-window-diagnostics->json-string)

(def (build-adaptive-execution-window-diagnostic-limit window-count)
  (if (<= window-count 0)
    0
    (let loop ((remaining window-count)
               (levels 0))
      (if (<= remaining 1)
        (max 1 levels)
        (loop (quotient (+ remaining 1) 2)
              (+ levels 1))))))

(def (build-adaptive-execution-window-ranked-json-objects
      windows
      observations
      (index 0))
  (if (null? windows)
    '()
    (cons
     (cons
      (execution-window-observation-elapsed-ms (car observations))
      (build-adaptive-execution-window->json-object
       (car windows)
       (car observations)
       index))
     (build-adaptive-execution-window-ranked-json-objects
      (cdr windows)
      (cdr observations)
      (+ index 1)))))

(def (build-adaptive-execution-window-ranked-take ranked limit)
  (if (or (<= limit 0) (null? ranked))
    '()
    (cons (car ranked)
          (build-adaptive-execution-window-ranked-take
           (cdr ranked)
           (- limit 1)))))

(def (build-adaptive-execution-window-ranked-insert candidate selected limit)
  (cond
   ((<= limit 0) '())
   ((null? selected) (list candidate))
   ((> (car candidate) (caar selected))
    (cons candidate
          (build-adaptive-execution-window-ranked-take
           selected
           (- limit 1))))
   (else
    (cons (car selected)
          (build-adaptive-execution-window-ranked-insert
           candidate
           (cdr selected)
           (- limit 1))))))

(def (build-adaptive-execution-window-select-slowest ranked limit)
  (let loop ((remaining ranked)
             (selected '()))
    (if (null? remaining)
      selected
      (loop
       (cdr remaining)
       (build-adaptive-execution-window-ranked-insert
        (car remaining)
        selected
        limit)))))

(def (build-adaptive-execution-window-diagnostics->json-object result)
  (unless (adaptive-execution-window-result? result)
    (error "adaptive execution-window diagnostics require an adaptive result"
           result))
  (let* ((windows
          (adaptive-execution-window-result-execution-windows result))
         (observations
          (adaptive-execution-window-result-window-observations result))
         (window-count (length windows))
         (selection-limit
          (build-adaptive-execution-window-diagnostic-limit window-count)))
    (unless (= window-count (length observations))
      (error "adaptive execution-window diagnostics have mismatched observations"
             window-count
             (length observations)))
    (let* ((ranked
            (build-adaptive-execution-window-ranked-json-objects
             windows
             observations))
           (slowest
            (build-adaptive-execution-window-select-slowest
             ranked
             selection-limit)))
      (hash
       ("schema" "asp-gerbil-scheme.build-adaptive-execution-window-diagnostics.v1")
       ("version" 1)
       ("metric-scope" "build-adaptive-execution-window-diagnostics")
       ("selection-policy" "ceil-log2-window-count")
       ("attempted-window-count" window-count)
       ("selected-window-count" (length slowest))
       ("slowest-windows" (map cdr slowest))))))

(def (build-adaptive-execution-window-diagnostics->json-string result)
  (json-object->canonical-string
   (build-adaptive-execution-window-diagnostics->json-object result)))

(def (build-adaptive-execution-windows->json-string result)
  (json-object->canonical-string
   (build-adaptive-execution-windows->json-object result)))

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
