;;; -*- Gerbil -*-
;;; HTTP client boundary for the resident provider runtime.

(import :gerbil/gambit
        :std/test
        (only-in :std/sugar hash)
        "../src/runtime/provider-http-json-client")

(export provider-http-json-client-test)

(def (runtime-request request-id)
  (hash ("schemaId" "agent.semantic-protocols.provider-runtime-request-frame")
        ("schemaVersion" "1")
        ("requestId" request-id)
        ("operation" "query")
        ("payload" (hash ("selector" "gerbil-scheme://src/main.ss#item/def/main")))))

(def (runtime-ready-response request-id)
  (hash ("schemaId" "agent.semantic-protocols.provider-runtime-response-frame")
        ("schemaVersion" "1")
        ("requestId" request-id)
        ("outcome" "ready")
        ("payload" (hash ("state" "ready")))))

(def (call-rejected? thunk)
  (with-catch
   (lambda (_) #t)
   (lambda ()
     (thunk)
     #f)))

(def provider-http-json-client-test
  (test-suite "resident provider HTTP JSON client"
    (test-case "endpoint is mandatory and never defaults to localhost"
      (check (call-rejected?
              (lambda ()
                (provider-http-json-request/transport!
                 #f
                 (runtime-request "missing-endpoint")
                 (lambda (_url _request)
                   (values 200 (runtime-ready-response "missing-endpoint"))))))
             => #t)
      (check (call-rejected?
              (lambda ()
                (provider-http-json-request/transport!
                 ""
                 (runtime-request "empty-endpoint")
                 (lambda (_url _request)
                   (values 200 (runtime-ready-response "empty-endpoint"))))))
             => #t))
    (test-case "client posts one typed request to the injected runtime endpoint"
      (let* ((request (runtime-request "request-1"))
             (calls '())
             (response
              (provider-http-json-request/transport!
               "http://provider.example/runtime/"
               request
               (lambda (url actual-request)
                 (set! calls (cons (cons url actual-request) calls))
                 (values 200 (runtime-ready-response "request-1"))))))
        (check (length calls) => 1)
        (check (caar calls)
               => "http://provider.example/runtime/v1/provider-runtime")
        (check (cdar calls) => request)
        (check (hash-ref response "outcome") => "ready")))
    (test-case "response frame is bound to schema version and request identity"
      (let ((request (runtime-request "request-2"))
            (wrong-id (runtime-ready-response "other-request"))
            (wrong-schema (runtime-ready-response "request-2")))
        (hash-put! wrong-schema "schemaVersion" "2")
        (check (call-rejected?
                (lambda ()
                  (provider-http-json-request/transport!
                   "https://provider.example/"
                   request
                   (lambda (_url _request) (values 200 wrong-id)))))
               => #t)
        (check (call-rejected?
                (lambda ()
                  (provider-http-json-request/transport!
                   "https://provider.example/"
                   request
                   (lambda (_url _request) (values 200 wrong-schema)))))
               => #t)))
    (test-case "HTTP failure is terminal and never falls back to local query"
      (let ((calls 0))
        (check (call-rejected?
                (lambda ()
                  (provider-http-json-request/transport!
                   "http://provider.example/"
                   (runtime-request "request-3")
                   (lambda (_url _request)
                     (set! calls (+ calls 1))
                     (values 503 (hash ("error" "unavailable")))))))
               => #t)
        (check calls => 1)))
    (test-case "transport exception is propagated without retry"
      (let ((calls 0))
        (check (call-rejected?
                (lambda ()
                  (provider-http-json-request/transport!
                   "http://provider.example/"
                   (runtime-request "request-4")
                   (lambda (_url _request)
                     (set! calls (+ calls 1))
                     (error "connection refused")))))
               => #t)
        (check calls => 1)))))
