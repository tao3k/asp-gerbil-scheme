;;; -*- Gerbil -*-
;;; Thin HTTP client for an already admitted resident provider runtime.
;;; The caller supplies the bootstrap endpoint. This owner never discovers a
;;; workspace, starts a server, reads source, or falls back to local semantics.

(import :gerbil/gambit
        (only-in :std/net/request
                 http-post
                 request-json
                 request-status)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :std/text/json write-json))

(export provider-http-json-request!
        provider-http-json-request/transport!
        provider-http-json-runtime-url
        provider-runtime-response-frame-valid?)

;; : String
(def +provider-runtime-request-schema-id+
  "agent.semantic-protocols.provider-runtime-request-frame")
;; : String
(def +provider-runtime-response-schema-id+
  "agent.semantic-protocols.provider-runtime-response-frame")
;; : String
(def +provider-runtime-schema-version+ "1")
;; : String
(def +provider-runtime-route+ "v1/provider-runtime")

;; : (-> String String)
(def (provider-http-json-runtime-url endpoint)
  (unless (and (string? endpoint)
               (> (string-length endpoint) 0)
               (or (string-prefix? "http://" endpoint)
                   (string-prefix? "https://" endpoint)))
    (error "resident provider endpoint must be explicitly injected as HTTP(S)"
           endpoint))
  (string-append
   (if (string-suffix? "/" endpoint)
     endpoint
     (string-append endpoint "/"))
   +provider-runtime-route+))

;; : (-> JsonObject Boolean)
(def (provider-runtime-request-frame-valid? request)
  (and (hash-table? request)
       (string=? (hash-ref request "schemaId" "")
                 +provider-runtime-request-schema-id+)
       (string=? (hash-ref request "schemaVersion" "")
                 +provider-runtime-schema-version+)
       (let ((request-id (hash-ref request "requestId" #f))
             (operation (hash-ref request "operation" #f))
             (payload (hash-ref request "payload" #f)))
         (and (string? request-id) (> (string-length request-id) 0)
              (string? operation) (> (string-length operation) 0)
              (hash-table? payload)))))

;; : (-> JsonObject JsonObject Boolean)
(def (provider-runtime-response-frame-valid? request response)
  (and (provider-runtime-request-frame-valid? request)
       (hash-table? response)
       (provider-runtime-response-identity-valid? request response)
       (provider-runtime-response-outcome-valid? response)))

;; : (-> JsonObject JsonObject Boolean)
(def (provider-runtime-response-identity-valid? request response)
  (and (string=? (hash-ref response "schemaId" "")
                 +provider-runtime-response-schema-id+)
       (string=? (hash-ref response "schemaVersion" "")
                 +provider-runtime-schema-version+)
       (string=? (hash-ref response "requestId" "")
                 (hash-ref request "requestId" ""))))

;; : (-> JsonObject Boolean)
(def (provider-runtime-response-outcome-valid? response)
  (let (outcome (hash-ref response "outcome" #f))
    (cond
     ((and (string? outcome) (string=? outcome "ready"))
      (hash-table? (hash-ref response "payload" #f)))
     ((and (string? outcome) (string=? outcome "error"))
      (string? (hash-ref response "error" #f)))
     (else #f))))

;; : (-> Json String)
(def (json->string value)
  (call-with-output-string ""
    (lambda (output) (write-json value output))))

;;; Native transport uses Gerbil's upstream HTTP client. It returns a compact
;;; status/JSON pair so the admission logic is independently testable without a
;;; socket or a resident process.
;; : (-> String JsonObject (Values Integer JsonObject))
(def (native-http-json-post url request)
  (let (response
        (http-post url
                   headers: '(("Content-Type" . "application/json"))
                   data: (json->string request)))
    (values (request-status response)
            (request-json response))))

;; : (-> String JsonObject JsonObject)
(def (provider-http-json-request! endpoint request)
  (provider-http-json-request/transport!
   endpoint request native-http-json-post))

;;; One transport call is the complete client attempt. Any endpoint, HTTP,
;;; transport, or frame failure is terminal and propagates to the caller.
;; : (-> String JsonObject (-> String JsonObject (Values Integer JsonObject))
;;        JsonObject)
(def (provider-http-json-request/transport! endpoint request post-json)
  (unless (provider-runtime-request-frame-valid? request)
    (error "resident provider request frame is invalid"))
  (let (url (provider-http-json-runtime-url endpoint))
    (call-with-values
     (lambda () (post-json url request))
     (lambda (status response)
      (unless (and (integer? status) (hash-table? response))
        (error "resident provider HTTP transport result is invalid"))
      (unless (and (>= status 200) (< status 300))
        (error "resident provider HTTP request failed" status response))
      (unless (provider-runtime-response-frame-valid? request response)
        (error "resident provider response frame is invalid" response))
      response))))
