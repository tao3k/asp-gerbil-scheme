(import :gerbil/gambit
        (only-in :gslph/src/runtime/provider-operation
                 provider-runtime-contract-receipt
                 provider-runtime-request->response)
        :std/format
        :std/io
        :std/net/httpd
        (only-in :std/sugar hash)
        (only-in :std/text/json read-json write-json))

(export serve-provider-http-json-runtime!
        validate-provider-http-json-environment!)

(def +provider-contract-environment+
  '("ASP_PROVIDER_ID"
    "ASP_PROVIDER_LANGUAGE_ID"
    "ASP_PROVIDER_ARTIFACT_DIGEST"
    "ASP_PROVIDER_REGISTRATION_DIGEST"
    "ASP_PROVIDER_RUNTIME_CONTRACT_DIGEST"))
(def *provider-http-server* #f)
(def *provider-request-stream-lock* (make-mutex 'provider-request-stream))
(def *provider-request-streams* '())
(def +provider-request-stream-frame-limit+ 1024)

(def (validate-provider-http-json-environment! lookup)
  (for-each
   (lambda (name)
     (let (value (lookup name))
       (unless (and value (> (string-length value) 0))
         (error "resident Gerbil provider environment is missing" name))))
   +provider-contract-environment+))

(def (required-environment name)
  (let (value (getenv name #f))
    (unless (and value (> (string-length value) 0))
      (error "resident Gerbil provider environment is missing" name))
    value))

(def (json->u8vector value)
  (string->utf8
   (call-with-output-string ""
     (lambda (output) (write-json value output)))))

(def (u8vector->json bytes)
  ;; HTTP owns UTF-8 bytes while `read-json` owns characters.  Passing a raw
  ;; u8vector port through here makes each non-ASCII byte a separate character
  ;; and changes parser byte offsets after a JSON round trip.
  (read-json (open-input-string (utf8->string bytes))))

(def (write-json-response response status value)
  (let (body (json->u8vector value))
    (http-response-write
     response
     status
     (list (cons "Content-Type" "application/json")
           (cons "Content-Length" (number->string (u8vector-length body)))
           (cons "Connection" "keep-alive"))
     body)))

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

(def (runtime-error-response request-id error)
  (hash ("schemaId" "agent.semantic-protocols.provider-runtime-response-frame")
        ("schemaVersion" "1")
        ("requestId" request-id)
        ("outcome" "error")
        ("error" (runtime-error->string error))))

(def (provider-runtime-request-value->response request-value)
  (let (request-id (hash-ref request-value "requestId" "invalid-request"))
    (with-catch
     (lambda (error) (runtime-error-response request-id error))
     (lambda () (provider-runtime-request->response request-value)))))

(def (remove-request-stream stream-id streams)
  (cond
   ((null? streams) '())
   ((string=? stream-id (caar streams)) (cdr streams))
   (else (cons (car streams)
               (remove-request-stream stream-id (cdr streams))))))

(def (accept-request-stream-frame! stream-id frame-index frame-count request-chunk)
  (dynamic-wind
    (lambda () (mutex-lock! *provider-request-stream-lock*))
    (lambda ()
      (unless (and (string? stream-id) (> (string-length stream-id) 0)
                   (fixnum? frame-index) (>= frame-index 0)
                   (fixnum? frame-count) (> frame-count 1)
                   (<= frame-count +provider-request-stream-frame-limit+)
                   (string? request-chunk))
        (error "provider runtime request stream frame identity is invalid"))
      (let* ((pair (assoc stream-id *provider-request-streams*))
             (state
              (cond
               (pair (cdr pair))
               ((zero? frame-index)
                (let (fresh (vector frame-count 0 '()))
                  (set! *provider-request-streams*
                        (cons (cons stream-id fresh) *provider-request-streams*))
                  fresh))
               (else (error "provider runtime request stream is absent")))))
        (unless (and (= (vector-ref state 0) frame-count)
                     (= (vector-ref state 1) frame-index))
          (set! *provider-request-streams*
                (remove-request-stream stream-id *provider-request-streams*))
          (error "provider runtime request stream order drift"))
        (vector-set! state 1 (+ frame-index 1))
        (vector-set! state 2 (cons request-chunk (vector-ref state 2)))
        (if (= (+ frame-index 1) frame-count)
            (let (request-text (apply string-append (reverse (vector-ref state 2))))
              (set! *provider-request-streams*
                    (remove-request-stream stream-id *provider-request-streams*))
              (cons 'complete request-text))
            (cons 'accepted frame-index))))
    (lambda () (mutex-unlock! *provider-request-stream-lock*))))

(def (health-handler request response)
  (if (eq? (http-request-method request) 'GET)
      (write-json-response response 200 (provider-runtime-contract-receipt))
      (write-json-response response 405
                           (hash ("state" "failed")
                                 ("failure" "health endpoint requires GET")))))

(def (provider-runtime-handler request response)
  (if (eq? (http-request-method request) 'POST)
      (with-catch
       (lambda (error)
         (write-json-response
          response 400
          (hash ("schemaId" "agent.semantic-protocols.provider-runtime-http-failure")
                ("schemaVersion" "1")
                ("reasonKind" "provider-runtime-request-decode-failed")
                ("error" (runtime-error->string error)))))
       (lambda ()
         (let* ((body (http-request-body request))
                (_ (unless body
                     (error "provider runtime request body is required")))
                (request-value (u8vector->json body))
                (response-value
                 (provider-runtime-request-value->response request-value)))
           (write-json-response response 200 response-value))))
      (write-json-response response 405
                           (hash ("state" "failed")
                                 ("failure" "provider runtime endpoint requires POST")))))

(def (provider-runtime-stream-handler request response)
  (if (eq? (http-request-method request) 'POST)
      (with-catch
       (lambda (error)
         (write-json-response
          response 400
          (hash ("schemaId" "agent.semantic-protocols.provider-runtime-http-failure")
                ("schemaVersion" "1")
                ("reasonKind" "provider-runtime-request-stream-frame-invalid")
                ("error" (runtime-error->string error)))))
       (lambda ()
         (let* ((body (http-request-body request))
                (_ (unless body
                     (error "provider runtime request stream body is required")))
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
                (request-chunk (hash-ref frame "requestChunk" #f))
                (outcome (accept-request-stream-frame!
                          stream-id frame-index frame-count request-chunk)))
           (if (eq? (car outcome) 'complete)
               (write-json-response
                response 200
                (provider-runtime-request-value->response
                 (u8vector->json (string->utf8 (cdr outcome)))))
               (write-json-response
                response 200
                (hash ("schemaId"
                       "agent.semantic-protocols.provider-runtime-request-stream-ack")
                      ("schemaVersion" "1")
                      ("streamId" stream-id)
                      ("frameIndex" frame-index)
                      ("state" "accepted")))))))
      (write-json-response
       response 405
       (hash ("state" "failed")
             ("failure" "provider runtime stream endpoint requires POST")))))

(def (shutdown-handler request response)
  (if (eq? (http-request-method request) 'POST)
      (begin
        (write-json-response response 200 (hash ("state" "draining")))
        (spawn (lambda ()
                 (thread-sleep! 0.001)
                 (when *provider-http-server*
                   (stop-http-server! *provider-http-server*)))))
      (write-json-response response 405
                           (hash ("state" "failed")
                                 ("failure" "shutdown endpoint requires POST")))))

(def (runtime-bootstrap endpoint)
  (hash ("schemaId" "agent.semantic-protocols.asp-client-server-bootstrap")
        ("schemaVersion" "1")
        ("providerId" (required-environment "ASP_PROVIDER_ID"))
        ("languageId" (required-environment "ASP_PROVIDER_LANGUAGE_ID"))
        ("transport" "http-json")
        ("state" "ready")
        ("endpoint" endpoint)))

(def (concrete-http-address requested-address)
  (if (string=? requested-address "127.0.0.1:0")
      (let* ((reservation (tcp-listen (cons localhost4 0)))
             (bound-address (Socket-address reservation))
             (address (format "127.0.0.1:~a" (cdr bound-address))))
        (ServerSocket-close reservation)
        address)
      requested-address))

(def (serve-provider-http-json-runtime!)
  (validate-provider-http-json-environment!
   (lambda (name) (getenv name #f)))
  (let* ((address (concrete-http-address
                   (required-environment "ASP_CLIENT_SERVER_HOST")))
         (endpoint (format "http://~a/" address))
         (server (start-http-server! backlog: 64 address)))
    (set! *provider-http-server* server)
    (http-register-handler server "/health" health-handler)
    (http-register-handler server "/v1/provider-runtime" provider-runtime-handler)
    (http-register-handler server "/v1/provider-runtime-stream"
                           provider-runtime-stream-handler)
    (http-register-handler server "/shutdown" shutdown-handler)
    (write-json (runtime-bootstrap endpoint) (current-output-port))
    (newline)
    (force-output (current-output-port))
    (thread-join! server)))
