;;; -*- Gerbil -*-
;;; Parallel source-file parse scheduling.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/profile
        :asp-gerbil-scheme/src/parser/source-file
        :asp-gerbil-scheme/src/support/time
        (only-in :std/srfi/1 iota)
        (only-in :std/sugar cut while))

(export parse-source-files/concurrent
        parse-source-files
        parse-source-files/profile)

;; : (-> String String Unit)
(def (parse-worker-trace event path)
  (when (getenv "ASP_GERBIL_SCHEME_PARSE_TRACE" #f)
    (display (string-append "[asp-gerbil-scheme-parse-worker] event=" event
                            " path=" path "\n"))
    (force-output)))

;;; Profile row boundary:
;;; - Worker details become one JSON-ready row before crossing back into the
;;;   foreground scheduler.
;;; - Full-project profile rows are scalar-only; stage timing is an explicit
;;;   per-owner operation and never retains extra source trees here.
;; parse-profile-row
;;   : (-> String Integer SourceFile HashTable)
;;   | doc m%
;;       `parse-profile-row path elapsed-ms source-file` records the per-file
;;       parser cost and scalar source facts.
;;     %
(def (parse-profile-row path elapsed-ms source-file)
  (hash (path path)
        (durationMs elapsed-ms)
        (lineCount (source-file-line-count source-file))
        (definitions (length (source-file-definitions source-file)))
        (calls (length (source-file-calls source-file)))))

;;; Worker body boundary:
;;; - Worker threads own exactly one parse operation and one mailbox send.
;;; - Error payloads stay data-shaped so the foreground thread remains the only
;;;   place that raises into the scheduler.
;; parse-source-worker!
;;   : (-> Thread String String Integer Boolean)
;;   | doc m%
;;       `parse-source-worker! foreground-thread root path index`
;;       parses one file and sends either an `ok` or `error` vector.
;;     %
(def (parse-source-worker! foreground-thread root path index)
  (with-catch
   (lambda (exn)
     (thread-send foreground-thread
                  (vector 'error (current-thread) index exn))
     #f)
   (lambda ()
     (let* ((file-start (monotonic-ms))
            (source-file (parse-source-file root path))
            (continue? #f))
       (parse-worker-trace "complete" path)
       (thread-send foreground-thread
                    (vector 'ok
                            (current-thread)
                            index
                            source-file
                            (duration-ms file-start (monotonic-ms))
                            #f))
       (set! continue? (eq? (thread-receive) 'continue))
       (set! source-file #f)
       continue?))))

;;; Worker reuse boundary:
;;; - A collection creates one thread per worker, never one thread per source
;;;   file, so repeated project collection cannot retain a thread history that
;;;   grows with corpus size.
;; parse-source-worker-batch!
;;   : (-> Thread String Vector Integer Integer Unit)
;;   | doc m%
;;       `parse-source-worker-batch!` parses a stride-partitioned group of
;;       source indexes and stops after its first reported error.
;;     %
(def (parse-source-worker-batch! foreground-thread root file-vector
                                 start-index stride)
  (let* ((remaining (- (vector-length file-vector) start-index))
         (count (quotient (+ remaining (fx1- stride)) stride)))
    (andmap
     (lambda (index)
       (let (path (vector-ref file-vector index))
         (parse-worker-trace "start" path)
         (parse-source-worker! foreground-thread root path index)))
     (iota count start-index stride))))

;;; Spawn boundary:
;;; - The foreground scheduler chooses indexes; this helper only maps an index
;;;   to its path and starts a named worker.
;; spawn-parse-worker!
;;   : (-> Thread String Vector Integer Integer Thread)
;;   | doc m%
;;       `spawn-parse-worker! foreground-thread root file-vector index profile?`
;;       starts one bounded worker for the indexed source file.
;;     %
(def (spawn-parse-worker! foreground-thread root file-vector
                          start-index stride)
  (spawn/name
   [worker: start-index]
   (lambda ()
     (parse-source-worker-batch! foreground-thread root file-vector
                                 start-index stride))))

;;; Receive boundary:
;;; - The mailbox protocol is vector-shaped and foreground-owned.
;;; - Successful results update output vectors in input order; errors re-raise
;;;   after the worker joins.
;; receive-parse-worker!
;;   : (-> Vector Vector Boolean (Values Integer (Maybe HashTable)))
;;   | doc m%
;;       `receive-parse-worker! file-vector source-vector row-vector profile?`
;;       receives one worker message, records it, and returns completed count.
;;     %
(def (receive-parse-worker! file-vector source-vector timing?)
  (let* ((message (thread-receive))
         (fields (and (vector? message) (vector->list message))))
    (match fields
      ([error _worker _index exception]
       (raise exception))
      ([status _worker _index _payload _elapsed _reserved]
      (case status
        ((ok)
         (let (profile-row
               (record-parse-worker-success! file-vector
                                             source-vector
                                             timing?
                                             message))
           ;; Acknowledge only after the foreground has projected or retained
           ;; the SourceFile. This bounds queued AST payloads by worker count.
           (thread-send (vector-ref message 1) 'continue)
           (cons 1 profile-row)))
        (else
         (error "unexpected parse worker status" status))))
      (else (error "unexpected parse worker message" message)))))

;; record-parse-worker-success!
;;   : (-> Vector Vector Boolean Vector (Maybe HashTable))
;;   | doc m%
;;       `record-parse-worker-success!` writes one successful worker result into
;;       the foreground-owned result vectors.
;;     %
(def (record-parse-worker-success! file-vector source-vector timing? message)
  (let ((index (vector-ref message 2))
        (source-file (vector-ref message 3))
        (elapsed-ms (vector-ref message 4)))
    (when source-vector
      (vector-set! source-vector index source-file))
    (if timing?
      (parse-profile-row (vector-ref file-vector index)
                         elapsed-ms
                         source-file)
      #f)))

;;; Aggregate phase boundary:
;;; - Keep scheduler metadata in one packet so profile receipts can explain
;;;   concurrency behavior without re-reading source.
;; parse-worker-phase-row
;;   : (-> Integer Integer HashTable)
;;   | doc m%
;;       `parse-worker-phase-row start worker-count` records aggregate parse
;;       duration and scheduler metadata.
;;     %
(def (parse-worker-phase-row start worker-count)
  (let (row (profile-row "parse-source-files"
                         (duration-ms start (monotonic-ms))))
    (hash-put! row 'workerCount worker-count)
    (hash-put! row 'parallel (> worker-count 1))
    (hash-put! row 'scheduler "green-thread-mailbox")
    (hash-put! row 'sharedState "foreground-owned")
    (hash-put! row 'backpressure "bounded-active-workers")
    row))

;; : (-> Thread Unit)
(def (stop-parse-worker! worker)
  (with-catch
   (lambda (_error) #!void)
   (lambda () (thread-send worker 'stop))))

;; : (-> Thread Unit)
(def (join-parse-worker! worker)
  (with-catch
   (lambda (_error) #!void)
   (lambda () (thread-join! worker))))

;;; Request-owner boundary:
;;; - This function always runs in a dedicated coordinator thread. Worker
;;;   replies therefore cannot consume or contaminate the caller mailbox.
;;; - On failure, every worker receives a stop acknowledgement and is joined
;;;   before the typed error crosses back through `thread-join!`.
;; parse-source-files/concurrent
;;   : (-> String (List String) Boolean (Or (Values (List SourceFile) HashTable (List HashTable)) (List SourceFile)))
;;   | doc m%
;;       `parse-source-files/concurrent root files profile?` parses files
;;       through bounded green-thread workers and optionally returns profile
;;       rows.
;;
;;       # Examples
;;
;;       ```scheme
;;       (parse-source-files/concurrent "." ["build.ss"] #f)
;;       ;; => source files in input order
;;       ```
;;     %
;; : (-> String (List String) Boolean Boolean
;;       (Or (List SourceFile)
;;           (Values (Maybe (List SourceFile)) HashTable (List HashTable) Integer)))
(def (parse-source-files/concurrent-owned* root files timing? retain-source?)
  (let* ((file-count (length files))
         (worker-count (collect-project-worker-count file-count))
         (file-vector (list->vector files))
         (source-vector (and retain-source? (make-vector file-count #f)))
         (profile-frontier '())
         (definition-count 0)
         (foreground-thread (current-thread))
         (workers
          (map (lambda (start-index)
                 (spawn-parse-worker! foreground-thread
                                      root
                                      file-vector
                                      start-index
                                      worker-count))
               (iota worker-count)))
         (start (monotonic-ms)))
    (with-catch
     (lambda (error)
       (for-each stop-parse-worker! workers)
       (for-each join-parse-worker! workers)
       (raise error))
     (lambda ()
       (let receive-loop ((completed 0))
         (if (= completed file-count)
           #!void
           (let* ((result (receive-parse-worker! file-vector
                                                 source-vector
                                                 timing?))
                  (count (car result))
                  (profile-row (cdr result)))
             (when profile-row
               (set! definition-count
                 (+ definition-count
                    (or (hash-get profile-row 'definitions) 0)))
               (set! profile-frontier
                 (slowest-profile-rows
                  (cons profile-row profile-frontier)
                  10)))
             (set! result #f)
             (set! profile-row #f)
             (receive-loop (+ completed count)))))))
    (for-each thread-join! workers)
    (let* ((source-files (and retain-source? (vector->list source-vector)))
           (parse-phase (parse-worker-phase-row start worker-count)))
      (if timing?
        (values source-files
                parse-phase
                profile-frontier
                definition-count)
        source-files))))

;;; Parallel parse boundary:
;;; - Each request owns one private coordinator mailbox and bounded worker set.
;;; - A caller cancellation can abandon its join without redirecting worker
;;;   replies into another request; the coordinator still drains its workers.
;; : (-> String (List String) Boolean Boolean
;;       (Or (List SourceFile)
;;           (Values (Maybe (List SourceFile)) HashTable (List HashTable) Integer)))
(def (parse-source-files/concurrent* root files timing? retain-source?)
  (thread-join!
   (spawn/name
    'parse-request-owner
    (lambda ()
      (parse-source-files/concurrent-owned*
       root files timing? retain-source?)))))

;; `profile?` preserves the public parser contract.  The implementation keeps
;; all-file parsing on the ordinary concurrent path and profiles only its
;; bounded timing frontier.
;; : (-> String (List String) Boolean (List SourceFile))
(def (parse-source-files/concurrent root files profile?)
  (if profile?
    (parse-source-files/profile root files)
    (match files
      ([] [])
      ([path] [(parse-source-file root path)])
      (else (parse-source-files/concurrent* root files #f #t)))))

;; parse-source-files
;;   : (-> String (List String) (List SourceFile))
;;   | doc m%
;;       `parse-source-files root files` parses files concurrently without
;;       profile telemetry.
;;     %
(def (parse-source-files root files)
  ((cut parse-source-files/concurrent <> <> #f) root files))

;; parse-source-files/profile
;;   : (-> String (List String) HashTable)
;;   | doc m%
;;       `parse-source-files/profile root files` materializes the project once
;;       and returns a packet with its parse phase and bounded timing frontier.
;;     %
;; parse-source-files/profile
;; : (-> String [String] Hash)
;; | doc m%
;;   Build one parser profile for a source-file set rooted at `root`.
;;   The result records phase timing, slow files, and definition coverage for
;;   callers that need a compact performance receipt.
;;   # Examples
;;   ```scheme
;;   (parse-source-files/profile "." ["src/example.ss"])
;;   ;; => #hash((parsePhase . ...) (slowestFiles . ...) (definitionCount . ...))
;;   ```
(def (parse-source-files/profile root files)
  ;; Diagnostic profiling must not create a second green-thread pool whose
  ;; completed stacks outlive the sampled project. Normal index collection
  ;; remains concurrent; this path projects and releases one SourceFile at a
  ;; time so repeated profiles have a bounded heap.
  (let ((start (monotonic-ms)))
    (let profile-loop ((remaining files)
                       (profile-frontier '())
                       (definition-count 0))
      (if (null? remaining)
        (hash (parsePhase (parse-worker-phase-row start 1))
              (slowestFiles profile-frontier)
              (definitionCount definition-count))
        (let* ((path (car remaining))
               (file-start (monotonic-ms)))
          (parse-worker-trace "profile-start" path)
          (let* ((source-file (parse-source-file root path))
               (profile-row
                (parse-profile-row path
                                   (duration-ms file-start (monotonic-ms))
                                   source-file))
               (next-definition-count
                (+ definition-count
                   (or (hash-get profile-row 'definitions) 0)))
               (next-profile-frontier
                (slowest-profile-rows
                 (cons profile-row profile-frontier)
                 10)))
          (parse-worker-trace "profile-complete" path)
          (set! source-file #f)
          (set! profile-row #f)
          (##gc)
          (profile-loop (cdr remaining)
                        next-profile-frontier
                        next-definition-count)))))))
