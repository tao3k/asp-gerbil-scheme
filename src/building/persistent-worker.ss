;;; -*- Gerbil -*-
;;; Copyright (C) 2026 Tao3k
;;; SPDX-License-Identifier: MIT

(import :gerbil/gambit
        (only-in :clan/poo/object object? object<-alist .ref .has?)
        (only-in :clan/poo/mop .defgeneric)
        (only-in :std/make make)
        :std/text/json
        (only-in :std/srfi/1 iota take)
        ./native-toolchain)

(export persistent-worker-request?
        make-persistent-worker-request
        persistent-worker-request-spec
        persistent-worker-request-srcdir
        persistent-worker-request-options
        persistent-worker-request-toolchain
        persistent-worker-result?
        make-persistent-worker-result
        persistent-worker-result-request
        persistent-worker-result-worker-id
        persistent-worker-result-outcome
        persistent-worker-result-elapsed-ms
        persistent-worker-result-detail
        persistent-worker-pool?
        persistent-worker-pool-worker-count
        persistent-worker-pool-run-window!
        persistent-worker-pool-close!
        make-gxi-persistent-worker-pool
        main)

(def persistent-worker-request-kind
  'gslph.persistent-worker-request.v1)

(def persistent-worker-result-kind
  'gslph.persistent-worker-result.v1)

(def persistent-worker-pool-kind
  'gslph.persistent-worker-pool.v1)

(def persistent-worker-protocol-schema
  "gslph.persistent-worker.protocol.v1")

(def (positive-integer value name)
  (unless (and (integer? value) (> value 0))
    (error "persistent worker requires a positive integer" name value))
  value)

(def (make-persistent-worker-request spec srcdir options toolchain)
  (unless (native-toolchain? toolchain)
    (error "invalid persistent-worker native toolchain" toolchain))
  (object<-alist
   `((kind . ,persistent-worker-request-kind)
     (spec . ,spec)
     (srcdir . ,srcdir)
     (options . ,options)
     (toolchain . ,toolchain))))

(def (persistent-worker-request? request)
  (and (object? request)
       (.has? request kind)
       (eq? (.ref request 'kind) persistent-worker-request-kind)))

(def (persistent-worker-request-slot request slot)
  (unless (persistent-worker-request? request)
    (error "invalid persistent-worker request" request))
  (.ref request slot))

(def (persistent-worker-request-spec request)
  (persistent-worker-request-slot request 'spec))

(def (persistent-worker-request-srcdir request)
  (persistent-worker-request-slot request 'srcdir))

(def (persistent-worker-request-options request)
  (persistent-worker-request-slot request 'options))

(def (persistent-worker-request-toolchain request)
  (persistent-worker-request-slot request 'toolchain))

(def (make-persistent-worker-result request worker-id outcome elapsed-ms detail)
  (object<-alist
   `((kind . ,persistent-worker-result-kind)
     (request . ,request)
     (worker-id . ,worker-id)
     (outcome . ,outcome)
     (elapsed-ms . ,elapsed-ms)
     (detail . ,detail))))

(def (persistent-worker-result? result)
  (and (object? result)
       (.has? result kind)
       (eq? (.ref result 'kind) persistent-worker-result-kind)))

(def (persistent-worker-result-slot result slot)
  (unless (persistent-worker-result? result)
    (error "invalid persistent-worker result" result))
  (.ref result slot))

(def (persistent-worker-result-request result)
  (persistent-worker-result-slot result 'request))

(def (persistent-worker-result-worker-id result)
  (persistent-worker-result-slot result 'worker-id))

(def (persistent-worker-result-outcome result)
  (persistent-worker-result-slot result 'outcome))

(def (persistent-worker-result-elapsed-ms result)
  (persistent-worker-result-slot result 'elapsed-ms))

(def (persistent-worker-result-detail result)
  (persistent-worker-result-slot result 'detail))

(def (persistent-worker-pool? pool)
  (and (object? pool)
       (.has? pool kind)
       (.has? pool worker-count)
       (.has? pool .run-window!)
       (.has? pool .close!)
       (eq? (.ref pool 'kind) persistent-worker-pool-kind)))

(def (persistent-worker-pool-worker-count pool)
  (unless (persistent-worker-pool? pool)
    (error "invalid persistent-worker pool" pool))
  (.ref pool 'worker-count))

(.defgeneric (persistent-worker-pool-run-window! pool requests)
  slot: .run-window!)

(def (persistent-worker-pool-close! pool)
  (unless (persistent-worker-pool? pool)
    (error "invalid persistent-worker pool" pool))
  ((.ref pool '.close!)))

(defstruct persistent-worker-process
  (id port)
  final: #t)

(def (configured-command name)
  (let (value (getenv name #f))
    (and value (> (string-length value) 0) value)))

(def persistent-worker-module
  ":gslph/src/building/persistent-worker")

(def (persistent-worker-process-settings worker-id)
  (let (configured-gxi (configured-command "GERBIL_GXI"))
    (if configured-gxi
      (list path: configured-gxi
            arguments: (list persistent-worker-module worker-id)
            stdin-redirection: #t
            stdout-redirection: #t
            stderr-redirection: #f)
      (list path: (or (configured-command "GERBIL_GXPKG") "gxpkg")
            arguments:
            (list "env" "gxi" persistent-worker-module worker-id)
            stdin-redirection: #t
            stdout-redirection: #t
            stderr-redirection: #f))))

(def (start-persistent-worker worker-id)
  (let (port
        (open-process
         (persistent-worker-process-settings worker-id)))
    (make-persistent-worker-process worker-id port)))

(def (write-json-line! port value)
  (parameterize ((write-json-sort-keys? #t))
    (write-json value port))
  (newline port)
  (force-output port))

(def (read-json-line port)
  (let (line (read-line port))
    (when (eof-object? line)
      (error "persistent worker closed its protocol stream"))
    (unless (and (string? line)
                 (> (string-length line) 0)
                 (char=? (string-ref line 0) #\{))
      (error "persistent worker emitted a non-JSON protocol line" line))
    (string->json-object line)))

(def (persistent-worker-process-request! worker request)
  (let (port (persistent-worker-process-port worker))
    (write-json-line! port request)
    (read-json-line port)))

(def (persistent-worker-request->datum request)
  (let (toolchain (persistent-worker-request-toolchain request))
    `((spec . ,(persistent-worker-request-spec request))
      (srcdir . ,(persistent-worker-request-srcdir request))
      (options . ,(persistent-worker-request-options request))
      (sdkroot . ,(native-toolchain-sdkroot toolchain))
      (developer-dir . ,(native-toolchain-developer-dir toolchain)))))

(def (datum->string datum)
  (call-with-output-string
   (lambda (port)
     (write datum port))))

(def (string->datum string)
  (call-with-input-string string read))

(def (persistent-worker-process-run! worker request request-id)
  (let* ((reply
          (persistent-worker-process-request!
           worker
           (hash ("schema" persistent-worker-protocol-schema)
                 ("operation" "run-spec")
                 ("requestId" request-id)
                 ("payloadSexp"
                  (datum->string
                   (persistent-worker-request->datum request))))))
         (schema (hash-ref reply "schema" #f))
         (outcome (hash-ref reply "outcome" #f))
         (worker-id (hash-ref reply "workerId" #f))
         (elapsed-ms (hash-ref reply "elapsedMs" #f))
         (detail (hash-ref reply "detail" #f)))
    (unless (equal? schema persistent-worker-protocol-schema)
      (error "persistent worker returned an invalid schema" schema))
    (unless (equal? worker-id (persistent-worker-process-id worker))
      (error "persistent worker identity changed" worker-id))
    (unless (equal? outcome "completed")
      (error "persistent worker build failed" worker-id detail))
    (unless (and (integer? elapsed-ms) (>= elapsed-ms 0))
      (error "persistent worker returned invalid elapsed milliseconds"
             elapsed-ms))
    (make-persistent-worker-result
     request worker-id 'completed elapsed-ms detail)))

(def (persistent-worker-process-stop! worker)
  (let* ((reply
          (persistent-worker-process-request!
           worker
           (hash ("schema" persistent-worker-protocol-schema)
                 ("operation" "stop"))))
         (outcome (hash-ref reply "outcome" #f)))
    (unless (equal? outcome "stopped")
      (error "persistent worker refused to stop"
             (persistent-worker-process-id worker)
             outcome))
    (close-port (persistent-worker-process-port worker))))

(def (persistent-worker-process-ready! worker)
  (let* ((reply
          (persistent-worker-process-request!
           worker
           (hash ("schema" persistent-worker-protocol-schema)
                 ("operation" "ping"))))
         (outcome (hash-ref reply "outcome" #f))
         (worker-id (hash-ref reply "workerId" #f)))
    (unless (and (equal? outcome "ready")
                 (equal? worker-id (persistent-worker-process-id worker)))
      (error "persistent worker failed its readiness handshake"
             worker-id
             outcome))
    worker))

(def (persistent-worker-run-window! workers requests first-request-id)
  (when (> (length requests) (length workers))
    (error "persistent-worker window exceeds pool capacity"
           (length requests)
           (length workers)))
  (let* ((assigned-workers (take workers (length requests)))
         (request-ids
          (iota (length requests) first-request-id))
         (threads
          (map
           (lambda (worker request request-id)
             (spawn
              (lambda ()
                (persistent-worker-process-run!
                 worker request request-id))))
           assigned-workers
           requests
           request-ids)))
    (map thread-join! threads)))

(def (make-gxi-persistent-worker-pool worker-count)
  (positive-integer worker-count 'worker-count)
  (let ((workers
         (map
          (lambda (index)
            (persistent-worker-process-ready!
             (start-persistent-worker
              (string-append "gslph-worker-" (number->string index)))))
          (iota worker-count)))
        (next-request-id 0)
        (closed? #f))
    (object<-alist
     `((kind . ,persistent-worker-pool-kind)
       (worker-count . ,worker-count)
       (.run-window! .
        ,(lambda (requests)
           (when closed?
             (error "persistent-worker pool is closed"))
           (unless (andmap persistent-worker-request? requests)
             (error "invalid persistent-worker request window" requests))
           (let (first-request-id next-request-id)
             (set! next-request-id
               (+ next-request-id (length requests)))
             (persistent-worker-run-window!
              workers requests first-request-id))))
       (.close! .
        ,(lambda ()
           (unless closed?
             (set! closed? #t)
             (for-each persistent-worker-process-stop! workers))
           (void)))))))

(def (datum-ref datum key)
  (let (entry (assq key datum))
    (if entry
      (cdr entry)
      (error "persistent-worker payload is missing a field" key))))

(def (elapsed-milliseconds started-at)
  (inexact->exact
   (round
    (* 1000
       (- (time->seconds (current-time))
          (time->seconds started-at))))))

(def (exception->string exception)
  (call-with-output-string
   (lambda (port)
     (display-exception exception port))))

(def (run-persistent-worker-payload! payload-sexp)
  (let* ((payload (string->datum payload-sexp))
         (spec (datum-ref payload 'spec))
         (stage (if (list? spec) spec (list spec)))
         (srcdir (datum-ref payload 'srcdir))
         (options (datum-ref payload 'options))
         (toolchain
          (make-native-toolchain
           (datum-ref payload 'sdkroot)
           (datum-ref payload 'developer-dir))))
    (with-native-toolchain
     toolchain
     (lambda ()
       (parameterize ((current-output-port (current-error-port)))
         (if srcdir
           (apply make stage srcdir: srcdir options)
           (apply make stage options)))))))

(def (worker-response worker-id request)
  (let ((schema (hash-ref request "schema" #f))
        (operation (hash-ref request "operation" #f)))
    (unless (equal? schema persistent-worker-protocol-schema)
      (error "persistent-worker request uses an invalid schema" schema))
    (cond
     ((equal? operation "ping")
      (hash ("schema" persistent-worker-protocol-schema)
            ("outcome" "ready")
            ("workerId" worker-id)))
     ((equal? operation "stop")
      (hash ("schema" persistent-worker-protocol-schema)
            ("outcome" "stopped")
            ("workerId" worker-id)))
     ((equal? operation "run-spec")
      (let (started-at (current-time))
        (with-catch
         (lambda (exception)
           (hash ("schema" persistent-worker-protocol-schema)
                 ("outcome" "error")
                 ("workerId" worker-id)
                 ("requestId" (hash-ref request "requestId" #f))
                 ("elapsedMs" (elapsed-milliseconds started-at))
                 ("detail" (exception->string exception))))
         (lambda ()
           (run-persistent-worker-payload!
            (hash-ref request "payloadSexp"))
           (hash ("schema" persistent-worker-protocol-schema)
                 ("outcome" "completed")
                 ("workerId" worker-id)
                 ("requestId" (hash-ref request "requestId" #f))
                 ("elapsedMs" (elapsed-milliseconds started-at))
                 ("detail" "std/make completed"))))))
     (else
      (hash ("schema" persistent-worker-protocol-schema)
            ("outcome" "rejected")
            ("workerId" worker-id)
            ("detail" "unknown operation"))))))

(def (main worker-id)
  (let (protocol-output (current-output-port))
    (let loop ()
      (let (line (read-line))
        (unless (eof-object? line)
          (let* ((request (string->json-object line))
                 (reply (worker-response worker-id request)))
            (write-json-line! protocol-output reply)
            (unless (equal? (hash-ref request "operation" #f) "stop")
              (loop))))))))
