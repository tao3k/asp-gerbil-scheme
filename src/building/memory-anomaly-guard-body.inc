;;; Boundary:
;;; - std/make owns normal compiler scheduling and always receives the selected
;;;   host/configured core count.
;;; - This module observes the complete build process tree and terminates only
;;;   an abnormal RSS trajectory or a hard-limit breach. It never estimates a
;;;   per-worker reservation and never lowers GERBIL_BUILD_CORES.

(def +framework-memory-anomaly-guard-schema+
  'asp-gerbil-scheme.memory-anomaly-guard.v1)

(def +framework-memory-anomaly-hard-limit-bytes+ (* 5 1024 1024 1024))
(def +framework-memory-anomaly-window-seconds+ 10)
(def +framework-memory-anomaly-growth-ratio-numerator+ 1)
(def +framework-memory-anomaly-growth-ratio-denominator+ 5)
(def +framework-memory-anomaly-confirmations+ 2)
(def +framework-memory-anomaly-sample-seconds+ 1)
(def +framework-build-trace-interval-seconds+ 10)

(def (framework-build-trace-receipt label phase elapsed-seconds rss-bytes
                                    cpu-percent active-compiler-jobs)
  (hash ("schema" "asp-gerbil-scheme.build-trace.v1")
        ("version" 1)
        ("label" label)
        ("phase" (symbol->string phase))
        ("activityKind"
         (cond
          ((eq? phase 'lease-wait) "build-lease")
          ((eq? phase 'started) "std-make-admission")
          ((positive? active-compiler-jobs) "native-compiler")
          (else "scheme-expansion-or-dependency-analysis")))
        ("elapsedMs" (inexact->exact (round (* elapsed-seconds 1000))))
        ("rssBytes" rss-bytes)
        ("cpuPercent" cpu-percent)
        ("activeCompilerJobs" active-compiler-jobs)))

(def (framework-build-trace-emit! receipt)
  ;; Verbose output is a human-facing compiler progress stream.  Keep the
  ;; structured receipt in memory for contracts/tests, but do not interleave
  ;; JSON telemetry with std/make and gxc diagnostics.
  (let (port (current-error-port))
    (display "[asp-gerbil-scheme-build] phase=" port)
    (display (hash-get receipt "activityKind") port)
    (display " elapsed-ms=" port)
    (display (hash-get receipt "elapsedMs") port)
    (newline port)
    (force-output port)))

;; framework-memory-anomaly-policy
;; : (-> MemoryAnomalyPolicy)
;; | type MemoryAnomalyPolicy = POOObject
(def (framework-memory-anomaly-policy)
  (.o (kind +framework-memory-anomaly-guard-schema+)
      (hard-limit-bytes +framework-memory-anomaly-hard-limit-bytes+)
      (window-seconds +framework-memory-anomaly-window-seconds+)
      (growth-ratio-numerator
       +framework-memory-anomaly-growth-ratio-numerator+)
      (growth-ratio-denominator
       +framework-memory-anomaly-growth-ratio-denominator+)
      (confirmations +framework-memory-anomaly-confirmations+)
      (sample-seconds +framework-memory-anomaly-sample-seconds+)))

;; framework-memory-anomaly-policy?
;; : (-> Any Boolean)
(def (framework-memory-anomaly-policy? value)
  (and (object? value)
       (.has? value kind)
       (eq? (.ref value 'kind) +framework-memory-anomaly-guard-schema+)))

;; framework-memory-anomaly-sample
;; : (-> Real Integer MemoryAnomalySample)
;; | type MemoryAnomalySample = (Pair Real Integer)
(def (framework-memory-anomaly-sample elapsed-seconds rss-bytes)
  (unless (and (real? elapsed-seconds)
               (>= elapsed-seconds 0)
               (integer? rss-bytes)
               (>= rss-bytes 0))
    (error "invalid build memory sample" elapsed-seconds rss-bytes))
  (cons elapsed-seconds rss-bytes))

;; framework-memory-anomaly-sample?
;; : (-> Any Boolean)
(def (framework-memory-anomaly-sample? value)
  (and (pair? value)
       (real? (car value))
       (integer? (cdr value))))

;; framework-memory-anomaly-window
;; : (-> (List MemoryAnomalySample) Real Real (List MemoryAnomalySample))
(def (framework-memory-anomaly-window samples now-seconds window-seconds)
  (filter (lambda (sample)
            (<= (- now-seconds (car sample)) window-seconds))
          samples))

;; framework-memory-anomaly-growth-bytes
;; : (-> (List MemoryAnomalySample) Integer Integer)
(def (framework-memory-anomaly-growth-bytes samples current-rss-bytes)
  (if (null? samples)
    0
    (max 0 (- current-rss-bytes (cdr (car samples))))))

;; framework-memory-anomaly-growth-rate-bytes-per-second
;; : (-> (List MemoryAnomalySample) Real Integer Real)
(def (framework-memory-anomaly-growth-rate-bytes-per-second
      samples now-seconds current-rss-bytes)
  (if (null? samples)
    0
    (let (elapsed (- now-seconds (car (car samples))))
      (if (positive? elapsed)
        (/ (framework-memory-anomaly-growth-bytes samples current-rss-bytes)
           elapsed)
        0))))

;; framework-memory-anomaly-transition
;; : (-> MemoryAnomalyPolicy Symbol Integer (List MemoryAnomalySample)
;;        Real Integer (Values Symbol Integer Symbol))
;;; A stable high-water mark below the hard line is normal. Only an immediate
;;; hard breach or repeated rapid growth across the rolling window trips the
;;; guard; one rapid sample first enters the suspect state.
(def (framework-memory-anomaly-transition
      policy state rapid-confirmations samples now-seconds current-rss-bytes)
  (unless (framework-memory-anomaly-policy? policy)
    (error "invalid build memory anomaly policy" policy))
  (let* ((hard-limit (.ref policy 'hard-limit-bytes))
         (window
          (framework-memory-anomaly-window
           samples now-seconds (.ref policy 'window-seconds)))
         (growth (framework-memory-anomaly-growth-bytes
                  window current-rss-bytes))
         (rapid-threshold
          (quotient (* hard-limit (.ref policy 'growth-ratio-numerator))
                    (.ref policy 'growth-ratio-denominator)))
         ;; Confirmation requires another threshold quantum of growth inside
         ;; the same window. Re-sampling one ordinary startup jump must not
         ;; turn the same evidence into two independent anomaly votes.
         (rapid? (>= growth
                     (* rapid-threshold (+ rapid-confirmations 1))))
         (next-confirmations (if rapid? (+ rapid-confirmations 1) 0)))
    (cond
     ((>= current-rss-bytes hard-limit)
      (values 'tripped next-confirmations 'hard-limit-exceeded))
     ((>= next-confirmations (.ref policy 'confirmations))
      (values 'tripped next-confirmations 'rapid-rss-growth))
     (rapid?
      (values 'suspect next-confirmations 'rapid-rss-growth-suspected))
     (else
      (values 'normal 0 (if (eq? state 'suspect)
                          'rss-growth-recovered
                          'within-envelope))))))

(def (framework-memory-guard-exit-code status)
  (cond ((< status 0) 1)
        ((> status 255) (quotient status 256))
        (else status)))

(def (framework-memory-guard-process-table-observation)
  (try
   (let* ((status 0)
          (output
           (run-process
            ["ps" "-axo" "pid=,ppid=,rss=,%cpu=,comm="]
            stderr-redirection: #t
            check-status: (lambda (value _settings) (set! status value)))))
     (if (= (framework-memory-guard-exit-code status) 0)
       (cons
        #t
        (filter-map
         (lambda (line)
           (let (tokens (string-tokenize line))
             (and (= (length tokens) 5)
                  (let ((pid (string->number (car tokens)))
                        (ppid (string->number (cadr tokens)))
                        (rss-kib (string->number (caddr tokens)))
                        (cpu-percent (string->number (cadddr tokens)))
                        (command (list-ref tokens 4)))
                    (and pid ppid rss-kib cpu-percent
                         (list pid ppid (* rss-kib 1024)
                               cpu-percent command))))))
         (string-split output #\newline)))
       (cons #f [])))
   ;; Process-table access can be denied in a sandbox even though the build is
   ;; valid. Preserve the guard and report degraded observability; an observer
   ;; transport failure is not evidence of an RSS anomaly.
   (catch _ (cons #f []))))

(def (framework-memory-guard-process-table)
  (cdr (framework-memory-guard-process-table-observation)))

(def (framework-memory-guard-load-average)
  (let (text
        (try
         (cond-expand
          (darwin
           (run-process ["sysctl" "-n" "vm.loadavg"]
                        stderr-redirection: #t))
          (linux
           (call-with-input-file "/proc/loadavg" read-line))
          (else ""))
         (catch _ "")))
    (let loop ((tokens (string-tokenize text)) (values []))
      (cond
       ((or (null? tokens) (= (length values) 3)) (reverse values))
       ((string->number (car tokens))
        => (lambda (value) (loop (cdr tokens) (cons value values))))
       (else (loop (cdr tokens) values))))))

(def (framework-memory-guard-process-tree-pids root-pid rows)
  (let expand ((known [root-pid]))
    (let loop ((remaining rows) (next known) (changed? #f))
      (if (null? remaining)
        (if changed? (expand next) next)
        (let* ((row (car remaining))
               (pid (car row))
               (ppid (cadr row)))
          (if (and (member ppid next) (not (member pid next)))
            (loop (cdr remaining) (cons pid next) #t)
            (loop (cdr remaining) next changed?)))))))

(def (framework-memory-guard-process-tree-rss-bytes root-pid)
  (let* ((rows (framework-memory-guard-process-table))
         (pids (framework-memory-guard-process-tree-pids root-pid rows)))
    (foldl (lambda (row total)
             (if (member (car row) pids) (+ total (caddr row)) total))
           0
           rows)))

(def (framework-memory-guard-process-tree-cpu-percent root-pid rows)
  (let (pids (framework-memory-guard-process-tree-pids root-pid rows))
    (foldl (lambda (row total)
             (if (member (car row) pids) (+ total (cadddr row)) total))
           0
           rows)))

(def (framework-memory-guard-compiler-front-end? command)
  (or (string=? command "gsc")
      (string=? command "gxi")
      (string-suffix? "/gsc" command)
      (string-suffix? "/gxi" command)))

;; Count scheduler jobs, not every native child in a compiler pipeline.  Gerbil
;; starts one gsc/gxi front end as a direct child of the guarded build process;
;; gcc and cc1 descendants belong to that same job and must not be double-counted.
(def (framework-memory-guard-active-compiler-jobs root-pid rows)
  (foldl (lambda (row count)
           (if (and (= (cadr row) root-pid)
                    (framework-memory-guard-compiler-front-end?
                     (list-ref row 4)))
             (+ count 1)
             count))
         0
         rows))

(def (framework-memory-anomaly-receipt policy label outcome reason worker-count
                                       peak-rss growth-bytes growth-rate
                                       elapsed-seconds maximum-active-jobs
                                       active-job-sum compiler-samples
                                       saturated-samples maximum-cpu-percent
                                       cpu-percent-sum first-active-seconds
                                       last-active-seconds load-average-start
                                       load-average-end observer-failure-count
                                       last-observer-seconds
                                       maximum-observer-interval-seconds)
  (let* ((average-active-jobs
         (if (zero? compiler-samples)
           0
           (/ (exact->inexact active-job-sum) compiler-samples)))
        (saturation-ratio
         (if (zero? compiler-samples)
           0
           (/ (exact->inexact saturated-samples) compiler-samples)))
        (average-cpu-percent
         (if (zero? compiler-samples)
           0
           (/ cpu-percent-sum compiler-samples)))
        (configured-cpu-capacity-percent (* worker-count 100))
        (logical-cpu-count (max 1 (##cpu-count)))
        (maximum-allowed-observer-interval-seconds
         (* 2 (.ref policy 'sample-seconds)))
        (terminal-observer-gap-seconds
         (max 0 (- elapsed-seconds last-observer-seconds)))
        (observed-maximum-interval-seconds
         (max maximum-observer-interval-seconds
              terminal-observer-gap-seconds))
        (expected-samples
         (max 1
              (inexact->exact
               (ceiling (/ elapsed-seconds
                           maximum-allowed-observer-interval-seconds)))))
        (observer-sample-sequence-complete?
         (and (zero? observer-failure-count)
              (positive? compiler-samples)
              (<= observed-maximum-interval-seconds
                  maximum-allowed-observer-interval-seconds)))
        (host-contention?
         (and (pair? load-average-start)
              (> (car load-average-start) logical-cpu-count))))
  (hash ("schema" "asp-gerbil-scheme.memory-anomaly-guard.v1")
        ("version" 1)
        ("label" label)
        ("outcome" (symbol->string outcome))
        ("reason" (symbol->string reason))
        ("configured-worker-count" worker-count)
        ("worker-count" worker-count)
        ("worker-count-limited-by-memory" #f)
        ("host-logical-cpu-count" logical-cpu-count)
        ("host-load-average-start" load-average-start)
        ("host-load-average-end" load-average-end)
        ("host-runnable-pressure-ratio"
         (and (pair? load-average-start)
              (/ (exact->inexact (car load-average-start))
                 logical-cpu-count)))
        ("host-contention-observed" host-contention?)
        ("window-seconds" (.ref policy 'window-seconds))
        ("peak-rss-bytes" peak-rss)
        ("hard-limit-bytes" (.ref policy 'hard-limit-bytes))
        ("maximum-window-growth-bytes" growth-bytes)
        ("maximum-growth-rate-bytes-per-second" growth-rate)
        ("maximum-active-compiler-jobs" maximum-active-jobs)
        ("average-active-compiler-jobs" average-active-jobs)
        ("compiler-active-samples" compiler-samples)
        ("compiler-saturated-samples" saturated-samples)
        ("compiler-saturation-ratio" saturation-ratio)
        ("observer-expected-samples" expected-samples)
        ("process-table-observer-status"
         (if (zero? observer-failure-count) "available" "degraded"))
        ("process-table-observer-failure-count" observer-failure-count)
        ("observer-sample-coverage-ratio"
         (/ (exact->inexact compiler-samples) expected-samples))
        ("observer-sample-sequence-complete"
         observer-sample-sequence-complete?)
        ("observer-maximum-interval-ms"
         (inexact->exact
          (round (* observed-maximum-interval-seconds 1000))))
        ("observer-maximum-allowed-interval-ms"
         (inexact->exact
          (round (* maximum-allowed-observer-interval-seconds 1000))))
        ;; std/make 0.18.2 keeps workch/completions/import-mx lexical inside
        ;; make-build. Process inspection can observe compiler children but
        ;; cannot prove the scheduler's instantaneous ready frontier.
        ("ready-queue-observed" #f)
        ("scheduler-starvation-verdict"
         "not-provable-with-current-std-make-public-api")
        ("performance-baseline-valid"
         (and (not host-contention?)
              observer-sample-sequence-complete?))
        ("observer-average-interval-ms"
         (if (zero? compiler-samples)
           0
           (/ (* elapsed-seconds 1000) compiler-samples)))
        ("scheme-to-native-first-job-ms"
         (and first-active-seconds
              (inexact->exact (round (* first-active-seconds 1000)))))
        ("native-compiler-observed-window-ms"
         (and first-active-seconds last-active-seconds
              (inexact->exact
               (round (* (- last-active-seconds first-active-seconds)
                         1000)))))
        ("post-native-observed-ms"
         (and last-active-seconds
              (inexact->exact
               (round (* (- elapsed-seconds last-active-seconds) 1000)))))
        ("configured-cpu-capacity-percent" configured-cpu-capacity-percent)
        ("maximum-process-tree-cpu-percent" maximum-cpu-percent)
        ("average-process-tree-cpu-percent" average-cpu-percent)
        ("average-configured-cpu-utilization-ratio"
         (if (zero? configured-cpu-capacity-percent)
           0
           (/ average-cpu-percent configured-cpu-capacity-percent)))
        ("elapsed-ms" (inexact->exact (round (* elapsed-seconds 1000)))))))

(def (framework-memory-anomaly-emit! receipt)
  (parameterize ((write-json-sort-keys? #t))
    (display "ASP_GERBIL_SCHEME_MEMORY_GUARD " (current-error-port))
    (display (json-object->string receipt) (current-error-port))
    (newline (current-error-port))
    (force-output (current-error-port))))

;; call-with-framework-memory-anomaly-guard
;; : (-> String Integer (-> Any) Any)
;;; The std/make scheduler has no supported mid-flight worker-resize hook.
;;; Therefore a confirmed anomaly fails closed with a receipt; the Framework
;;; never pretends it can pause or shrink already admitted native compiler jobs.
(def (call-with-framework-memory-anomaly-guard label worker-count thunk
                                               (trace? #f))
  (let* ((policy (framework-memory-anomaly-policy))
         (started (time->seconds (current-time)))
         (load-average-start (framework-memory-guard-load-average))
         ;; stop?, anomaly-state, confirmations, memory samples, peak, growth,
         ;; rate, completion, max active jobs, active-job sum, compiler sample
         ;; count, saturated sample count, process-tree CPU trajectory, and
         ;; first/last observed compiler activity and process-table observer
         ;; failures and real observation cadence are watcher-owned state.
         ;; The last two flags make verbose phase observations exactly once:
         ;; one silent Scheme-expansion signal and one native-compiler signal.
         (state (vector #f 'normal 0 [] 0 0 0 #f 0 0 0 0 0 0 #f #f 0 0 0
                        #f #f))
         (watcher
          (spawn
           (lambda ()
             (let loop ()
               (unless (vector-ref state 0)
                 (let* ((now (- (time->seconds (current-time)) started))
                        (observation
                         (framework-memory-guard-process-table-observation))
                        (observer-available? (car observation))
                        (rows (cdr observation))
                        (root-pid (##os-getpid))
                        (pids (framework-memory-guard-process-tree-pids
                               root-pid rows))
                        (rss
                         (foldl (lambda (row total)
                                  (if (member (car row) pids)
                                    (+ total (caddr row))
                                    total))
                                0
                                rows))
                        (cpu-percent
                         (framework-memory-guard-process-tree-cpu-percent
                          root-pid rows))
                        (active-jobs
                         (framework-memory-guard-active-compiler-jobs
                          root-pid rows))
                        (samples
                         (framework-memory-anomaly-window
                          (append (vector-ref state 3)
                                  [(framework-memory-anomaly-sample now rss)])
                          now
                          (.ref policy 'window-seconds)))
                        (growth
                         (framework-memory-anomaly-growth-bytes samples rss))
                        (rate
                         (framework-memory-anomaly-growth-rate-bytes-per-second
                          samples now rss)))
                   (when (and trace? (positive? active-jobs)
                              (not (vector-ref state 20)))
                     (vector-set! state 20 #t)
                     (framework-build-trace-emit!
                     (framework-build-trace-receipt
                       label 'active now rss cpu-percent active-jobs)))
                   (when (and trace? (zero? active-jobs)
                              (>= now +framework-build-trace-interval-seconds+)
                              (not (vector-ref state 19)))
                     (vector-set! state 19 #t)
                     (framework-build-trace-emit!
                     (framework-build-trace-receipt
                       label 'active now rss cpu-percent active-jobs)))
                   (unless observer-available?
                     (vector-set! state 16 (+ 1 (vector-ref state 16))))
                   (call-with-values
                    (lambda ()
                      (framework-memory-anomaly-transition
                       policy
                       (vector-ref state 1)
                       (vector-ref state 2)
                       samples now rss))
                    (lambda (next-state confirmations reason)
                      (vector-set! state 1 next-state)
                      (vector-set! state 2 confirmations)
                      (vector-set! state 3 samples)
                      (vector-set! state 4 (max rss (vector-ref state 4)))
                      ;; Preserve recovered spikes in the terminal receipt;
                      ;; the last stable window must not erase earlier evidence.
                      (vector-set! state 5 (max growth (vector-ref state 5)))
                      (vector-set! state 6 (max rate (vector-ref state 6)))
                      (vector-set! state 8
                                   (max active-jobs (vector-ref state 8)))
                      (vector-set! state 9
                                   (+ active-jobs (vector-ref state 9)))
                      (vector-set! state 10 (+ 1 (vector-ref state 10)))
                      (when (>= active-jobs worker-count)
                        (vector-set! state 11 (+ 1 (vector-ref state 11))))
                      (vector-set! state 12
                                   (max cpu-percent (vector-ref state 12)))
                      (vector-set! state 13
                                   (+ cpu-percent (vector-ref state 13)))
                      (vector-set! state 18
                                   (max (vector-ref state 18)
                                        (- now (vector-ref state 17))))
                      (vector-set! state 17 now)
                      (when (> active-jobs 0)
                        (unless (vector-ref state 14)
                          (vector-set! state 14 now))
                        (vector-set! state 15 now))
                      (if (eq? next-state 'tripped)
                        (begin
                          (framework-memory-anomaly-emit!
                           (framework-memory-anomaly-receipt
                            policy label 'aborted reason worker-count
                            (vector-ref state 4) growth rate now
                            (vector-ref state 8)
                            (vector-ref state 9)
                            (vector-ref state 10)
                            (vector-ref state 11)
                            (vector-ref state 12)
                            (vector-ref state 13)
                            (vector-ref state 14)
                            (vector-ref state 15)
                            load-average-start
                            (framework-memory-guard-load-average)
                            (vector-ref state 16)
                            (vector-ref state 17)
                            (vector-ref state 18)))
                          (exit 70))
                        (begin
                          (thread-sleep! (.ref policy 'sample-seconds))
                          (loop))))))))))))
    (when trace?
      (framework-build-trace-emit!
       (framework-build-trace-receipt label 'started 0 0 0 0)))
    (dynamic-wind
      (lambda () #!void)
      (lambda ()
        (let (result (thunk))
          (vector-set! state 7 #t)
          result))
      (lambda ()
        (vector-set! state 0 #t)
        (thread-join! watcher)
        ;; A tripped watcher emitted the authoritative abort receipt before
        ;; exit. Do not overwrite it with a generic unwind receipt.
        (unless (eq? (vector-ref state 1) 'tripped)
          (let* ((elapsed (- (time->seconds (current-time)) started))
                 (completed? (vector-ref state 7))
                 (reason
                  (cond
                   ((not completed?) 'build-failed)
                   ((eq? (vector-ref state 1) 'suspect)
                    'completed-after-unconfirmed-growth)
                   ((positive? (vector-ref state 16))
                    'completed-with-degraded-observability)
                   (else 'within-envelope))))
            (framework-memory-anomaly-emit!
             (framework-memory-anomaly-receipt
              policy label (if completed? 'completed 'failed) reason
              worker-count
              (vector-ref state 4)
              (vector-ref state 5)
              (vector-ref state 6)
              elapsed
              (vector-ref state 8)
              (vector-ref state 9)
              (vector-ref state 10)
              (vector-ref state 11)
              (vector-ref state 12)
              (vector-ref state 13)
              (vector-ref state 14)
              (vector-ref state 15)
              load-average-start
              (framework-memory-guard-load-average)
              (vector-ref state 16)
              (vector-ref state 17)
              (vector-ref state 18)))))))))
