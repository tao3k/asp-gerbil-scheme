;;; -*- Gerbil -*-
;;; The HTTP server owns transport lifecycle and JSON request/response framing.
;;; Runtime and stream state are validated POO objects; hashes exist only at
;;; the HTTP wire boundary and never become semantic or lifecycle owners.
(import :gerbil/runtime/gambit
        (only-in :asp-gerbil-scheme/src/runtime/provider-operation
                 provider-runtime-contract-receipt
                 provider-runtime-request->response)
        :asp-gerbil-scheme/src/runtime/provider/interface
        (only-in :std/io
                 call-with-output-string
                 read-all-from-reader
                 Socket-address
                 Socket-close
                 tcp-listen)
        (only-in :std/net/address InetAddress InetAddress-port localhost4)
        (only-in :std/log stderr-log-sink)
        (only-in :std/net/http/server
                 Request-body
                 Request-method
                 ResponseHandler-write!
                 Server-start!
                 Server-stop!
                 ServerConfig
                 new-closure-handler
                 new-http-server
                 new-static-mux
                 status-code->status)
        (only-in :std/sync/channel make-channel channel-get channel-put)

        (only-in :std/encoding/json JSONReadOptions read-json write-json))

(export serve-provider-http-json-runtime!
        validate-provider-http-json-environment!)

;; : (List String)
(def +provider-contract-environment+
  '("ASP_PROVIDER_ID"
    "ASP_PROVIDER_LANGUAGE_ID"
    "ASP_PROVIDER_ARTIFACT_DIGEST"
    "ASP_PROVIDER_REGISTRATION_DIGEST"
    "ASP_PROVIDER_RUNTIME_CONTRACT_DIGEST"))
;; : (-> (-> String (Maybe String)) Void)
(def (validate-provider-http-json-environment! lookup)
  (for-each
   (lambda (name)
     (let (value (lookup name))
       (unless (and value (> (string-length value) 0))
         (error "resident Gerbil provider environment is missing" name))))
   +provider-contract-environment+))

;; : (-> String String)
(def (required-environment name)
  (match (getenv name #f)
    (#f (error "resident Gerbil provider environment is missing" name))
    (value
     (if (> (string-length value) 0)
       value
       (error "resident Gerbil provider environment is missing" name)))))

;; : (-> Json U8Vector)
(def (json->u8vector value)
  (string->utf8
   (call-with-output-string ""
     (lambda (output) (write-json output value)))))

;; : (-> U8Vector Json)
(def (u8vector->json bytes)
  ;; HTTP owns UTF-8 bytes while `read-json` owns characters.  Passing a raw
  ;; u8vector port through here makes each non-ASCII byte a separate character
  ;; and changes parser byte offsets after a JSON round trip.
  (read-json (open-input-string (utf8->string bytes))
             (JSONReadOptions object-as-hash: #t)))

;; : (-> HttpResponse Integer Json Void)
(def (write-json-response response status value)
  (let (body (json->u8vector value))
    (ResponseHandler-write!
     response
     (status-code->status status)
     (list (cons "Content-Type" "application/json")
           (cons "Connection" "keep-alive"))
     body)))

;; : (-> RuntimeError String)
(def (runtime-error->string error)
  ;; This is a v1 wire boundary. Runtime-owned cold admission can surface a
  ;; non-Exception failure value, but the frame's `error` field is always a
  ;; JSON string and must never inherit that value's JSON representation.
  (cond
   ((string? error) error)
   ((symbol? error) (symbol->string error))
   (else
    (with-catch
     (lambda (_) "provider runtime operation failed")
     (lambda ()
       (let (message
             (with-catch (lambda (_) #f)
               (lambda () (error-message error))))
         (cond
          ((and (string? message) (> (string-length message) 0)) message)
          (else
           (let (rendered
                 (with-catch
                  (lambda (_)
                    (call-with-output-string
                     (lambda (port) (display error port))))
                  (lambda ()
                    (call-with-output-string ""
                      (lambda (port) (display-exception error port))))))
             (if (> (string-length rendered) 0)
                 rendered
                 "provider runtime operation failed"))))))))))

;; : (-> String RuntimeError JsonObject)
(def (runtime-error-response request-id error)
  (provider-runtime-response->json
   (provider-runtime-error-response
    request-id
    (runtime-error->string error))))

;; : (-> JsonObject JsonObject)
(def (provider-runtime-request-value->response request-value)
  (let (request-id (hash-ref request-value "requestId" "invalid-request"))
    (with-catch
     (lambda (error) (runtime-error-response request-id error))
     (lambda () (provider-runtime-request->response request-value)))))

;; : (-> String [ProviderRequestStreamState] [ProviderRequestStreamState])
(def (remove-request-stream stream-id streams)
  (filter (lambda (state)
            (not (string=? stream-id (provider-request-stream-id state))))
          streams))

;; : (-> String [ProviderRequestStreamState]
;;        (Maybe ProviderRequestStreamState))
(def (find-request-stream stream-id streams)
  (find (lambda (state)
          (string=? stream-id (provider-request-stream-id state)))
        streams))

;; : (-> ProviderHttpRuntimeState String Integer Integer String
;;        (Values Symbol Object))
(def (accept-request-stream-frame! runtime stream-id frame-index frame-count
                                   request-chunk)
  (let ((lock (provider-http-runtime-stream-lock runtime))
        (streams-cell (provider-http-runtime-streams-cell runtime)))
   (dynamic-wind
    (lambda () (mutex-lock! lock))
    (lambda ()
      (unless (and (string? stream-id) (> (string-length stream-id) 0)
                   (fixnum? frame-index) (>= frame-index 0)
                   (fixnum? frame-count) (> frame-count 1)
                   (<= frame-count (provider-http-runtime-frame-limit runtime))
                   (string? request-chunk))
        (error "provider runtime request stream frame identity is invalid"))
      (let* ((streams (vector-ref streams-cell 0))
             (state
              (cond
               ((find-request-stream stream-id streams) => values)
               ((zero? frame-index)
                (provider-request-stream-state stream-id frame-count 0 '()))
               (else (error "provider runtime request stream is absent")))))
        (unless (and (= (provider-request-stream-frame-count state) frame-count)
                     (= (provider-request-stream-next-index state) frame-index))
          (vector-set! streams-cell 0
                       (remove-request-stream stream-id streams))
          (error "provider runtime request stream order drift"))
        (let (advanced (provider-request-stream-advance state request-chunk))
        (if (= (+ frame-index 1) frame-count)
            (begin
              (vector-set! streams-cell 0
                           (remove-request-stream stream-id streams))
              (values 'complete
                      (apply string-append
                             (reverse
                              (provider-request-stream-chunks advanced)))))
            (begin
              (vector-set! streams-cell 0
                           (cons advanced
                                 (remove-request-stream stream-id streams)))
              (values 'accepted frame-index))))))
    (lambda () (mutex-unlock! lock)))))

;; : (-> HttpRequest HttpResponse Void)
(def (health-handler request response)
  (cond
    ((string=? (Request-method request) "GET")
     (write-json-response response 200 (provider-runtime-contract-receipt)))
    (else
     (write-json-response response 405
                          (hash ("state" "failed")
                                ("failure" "health endpoint requires GET"))))))

;; : (-> HttpRequest HttpResponse Void)
(def (provider-runtime-handler request response)
  (if (string=? (Request-method request) "POST")
      (with-catch
       (lambda (error)
         (write-json-response
          response 400
          (hash ("schemaId" "agent.semantic-protocols.provider-runtime-http-failure")
                ("schemaVersion" "1")
                ("reasonKind" "provider-runtime-request-decode-failed")
                ("error" (runtime-error->string error)))))
       (lambda ()
         (let* ((body (read-all-from-reader (Request-body request)))
                (request-value (u8vector->json body))
                (response-value
                 (provider-runtime-request-value->response request-value)))
           (write-json-response response 200 response-value))))
      (write-json-response response 405
                           (hash ("state" "failed")
                                 ("failure" "provider runtime endpoint requires POST")))))

;; : (-> ProviderHttpRuntimeState HttpRequest HttpResponse Void)
(def (provider-runtime-stream-handler runtime request response)
  (if (string=? (Request-method request) "POST")
      (with-catch
       (lambda (error)
         (write-json-response
          response 400
          (hash ("schemaId" "agent.semantic-protocols.provider-runtime-http-failure")
                ("schemaVersion" "1")
                ("reasonKind" "provider-runtime-request-stream-frame-invalid")
                ("error" (runtime-error->string error)))))
       (lambda ()
         (let* ((body (read-all-from-reader (Request-body request)))
                (frame (u8vector->json body))
                (_ (unless
                    (and (string=?
                          (hash-ref frame "schemaId" "")
                          "agent.semantic-protocols.provider-runtime-request-stream-frame")
                         (string=? (hash-ref frame "schemaVersion" "") "1"))
                     (error "provider runtime request stream schema identity drift")))
                (stream-id (hash-ref frame "streamId" #f))
                (frame-index (hash-ref frame "frameIndex" #f))
                (frame-count (hash-ref frame "frameCount" #f))
                (request-chunk (hash-ref frame "requestChunk" #f)))
           (call-with-values
            (lambda ()
              (accept-request-stream-frame!
               runtime stream-id frame-index frame-count request-chunk))
            (lambda (outcome value)
              (if (eq? outcome 'complete)
                  (write-json-response
                   response 200
                   (provider-runtime-request-value->response
                    (u8vector->json (string->utf8 value))))
                  (write-json-response
                   response 200
                   (hash ("schemaId"
                          "agent.semantic-protocols.provider-runtime-request-stream-ack")
                         ("schemaVersion" "1")
                         ("streamId" stream-id)
                         ("frameIndex" value)
                         ("state" "accepted")))))))))
      (write-json-response
       response 405
       (hash ("state" "failed")
             ("failure" "provider runtime stream endpoint requires POST")))))

;; : (-> ProviderHttpRuntimeState HttpRequest HttpResponse Void)
(def (shutdown-handler runtime stopped request response)
  (if (string=? (Request-method request) "POST")
      (begin
        (write-json-response response 200 (hash ("state" "draining")))
        (spawn (lambda ()
                 (thread-sleep! 0.001)
                 (Server-stop! (provider-http-runtime-server runtime))
                 (channel-put stopped #t))))
      (write-json-response response 405
                           (hash ("state" "failed")
                                 ("failure" "shutdown endpoint requires POST")))))

;; : (-> String JsonObject)
(def (runtime-bootstrap endpoint)
  (hash ("schemaId" "agent.semantic-protocols.asp-client-server-bootstrap")
        ("schemaVersion" "1")
        ("providerId" (required-environment "ASP_PROVIDER_ID"))
        ("languageId" (required-environment "ASP_PROVIDER_LANGUAGE_ID"))
        ("transport" "http-json")
        ("state" "ready")
        ("endpoint" endpoint)
        ("concurrency"
         (hash
          ("model" "green-thread-per-connection")
          ("requestScheduling" "serial-within-connection")
          ("hostProcessors" (max 1 (##cpu-count)))
          ("vmProcessors" (max 1 (##current-vm-processor-count)))
          ("smpRuntime"
           (cond-expand
             (gerbil-smp #t)
             (else #f)))))))

;; : (-> String String)
(def (concrete-http-address requested-address)
  (match requested-address
    ("127.0.0.1:0"
     (let* ((reservation (tcp-listen (InetAddress localhost4 0)))
            (bound-address (Socket-address reservation))
            (address (string-append "127.0.0.1:"
                                    (number->string
                                     (InetAddress-port bound-address)))))
       (Socket-close reservation)
       address))
    (address address)))

;; : (-> Void)
(def (serve-provider-http-json-runtime!)
  (validate-provider-http-json-environment!
   (lambda (name) (getenv name #f)))
  (let* ((address (concrete-http-address
                   (required-environment "ASP_CLIENT_SERVER_HOST")))
         (endpoint (string-append "http://" address "/"))
         (stopped (make-channel 1))
         (runtime-cell (vector #f))
         (server
          (new-http-server
           (ServerConfig
            mux: (new-static-mux
                  path: "/health" (new-closure-handler health-handler)
                  path: "/v1/provider-runtime"
                  (new-closure-handler provider-runtime-handler)
                  path: "/v1/provider-runtime-stream"
                  (new-closure-handler
                   (lambda (request response)
                     (provider-runtime-stream-handler
                      (vector-ref runtime-cell 0) request response)))
                  path: "/shutdown"
                  (new-closure-handler
                   (lambda (request response)
                     (shutdown-handler
                      (vector-ref runtime-cell 0) stopped request response))))
            log: (stderr-log-sink)
            listen: (list (string-append "inet4:" address))
            backlog: 64)))
         (runtime (provider-http-runtime-state
                   server
                   (make-mutex 'provider-request-stream)
                   (vector '())
                   1024))
         (output (current-output-port)))
    (vector-set! runtime-cell 0 runtime)
    (Server-start! server)
    (write-json output (runtime-bootstrap endpoint))
    (newline)
    (force-output output)
    (channel-get stopped)))
