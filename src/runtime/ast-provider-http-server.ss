;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;;
;;; Converged Provider Core HTTP-JSON Server for `asp-gerbil-scheme` (RFC 10.36).
;;; Built directly on Gerbil 0.19 `:std/net/http/server` + `:std/encoding/json`
;;; + pure native reader AST ops (`./ast-ops.ss`).

(import :std/encoding/json
        :std/interface
        :std/io
        :std/list/walist
        :std/log
        :std/net/address
        :std/net/http/server
        :std/net/url
        :std/sync/channel
        :std/time/timeout
        "./ast-ops.ss")

(export main)

(defclass (silent-log-sink BasicLogger) () final: #t)
(defmethod {log silent-log-sink} (lambda (_self _record) (void)) interface: Logger)
(defmethod {start! silent-log-sink} void interface: LogSink)
(defmethod {stop! silent-log-sink} void interface: LogSink)
(@implement Logger silent-log-sink)
(@implement LogSink silent-log-sink)

(def (mk-obj . pairs)
  (list->hash-table pairs))

(def (normalize-json val)
  (cond
   ((WAList? val)
    (let ((tbl (make-hash-table)))
      (for-each
       (lambda (kv)
         (let ((k (car kv))
               (v (cdr kv)))
           (hash-put! tbl (if (symbol? k) (symbol->string k) k) (normalize-json v))))
       (walist->list val))
      tbl))
   ((hash-table? val)
    (let ((tbl (make-hash-table)))
      (hash-for-each
       (lambda (k v)
         (hash-put! tbl (if (symbol? k) (symbol->string k) k) (normalize-json v)))
       val)
      tbl))
   ((list? val) (map normalize-json val))
   ((vector? val) (map normalize-json (vector->list val)))
   (else val)))

(def (json->utf8-bytes value)
  (string->utf8
   (call-with-output-string ""
     (lambda (out) (write-json out value)))))

(def (write-json-http! response status value)
  (let* ((body-str (call-with-output-string "" (lambda (out) (write-json out value))))
         (bytes (string->utf8 body-str))
         (writer (ResponseHandler-begin!
                  response
                  status
                  (list (cons "Content-Type" "application/json")
                        (cons "Content-Length" (number->string (u8vector-length bytes)))
                        (cons "Connection" "close")))))
    (BufferedWriter-write-string-utf8 writer body-str)
    (BufferedWriter-flush writer)))

(def (resolve-bind-address requested)
  (if (string=? requested "127.0.0.1:0")
    (let* ((sock (tcp-listen (InetAddress localhost4 0)))
           (addr (Socket-address sock))
           (port (InetAddress-port addr)))
      (Socket-close sock)
      (string-append "127.0.0.1:" (number->string port)))
    requested))

(def (health-payload)
  (mk-obj
   (cons "schemaId" "agent.semantic-protocols.provider-runtime-contract-receipt")
   (cons "schemaVersion" "1")
   (cons "providerId" (getenv "ASP_PROVIDER_ID" "asp-gerbil-scheme"))
   (cons "languageId" (getenv "ASP_PROVIDER_LANGUAGE_ID" "gerbil-scheme"))
   (cons "artifactDigest" (getenv "ASP_PROVIDER_ARTIFACT_DIGEST" ""))
   (cons "registrationDigest" (getenv "ASP_PROVIDER_REGISTRATION_DIGEST" ""))
   (cons "contractDigest" (getenv "ASP_PROVIDER_RUNTIME_CONTRACT_DIGEST" ""))
   (cons "transport" "http-json")
   (cons "operations"
         (list
          (mk-obj
           (cons "operation" "ast-inspect")
           (cons "requestSchema" (mk-obj (cons "schemaId" "agent.semantic-protocols.ast-inspect") (cons "schemaVersion" "1")))
           (cons "responseSchema" (mk-obj (cons "schemaId" "agent.semantic-protocols.ast-inspect") (cons "schemaVersion" "1"))))
          (mk-obj
           (cons "operation" "ast-verify")
           (cons "requestSchema" (mk-obj (cons "schemaId" "agent.semantic-protocols.ast-verify") (cons "schemaVersion" "1")))
           (cons "responseSchema" (mk-obj (cons "schemaId" "agent.semantic-protocols.ast-verify") (cons "schemaVersion" "1"))))))))

(def (dispatch-runtime-frame frame)
  (let* ((request-id (or (hash-ref frame "requestId" #f) "unknown"))
         (operation (or (hash-ref frame "operation" #f) ""))
         (payload (or (hash-ref frame "payload" #f) (mk-obj))))
    (cond
     ((string=? operation "ast-inspect")
      (mk-obj
       (cons "schemaId" "agent.semantic-protocols.provider-runtime-response-frame")
       (cons "schemaVersion" "1")
       (cons "requestId" request-id)
       (cons "outcome" "ready")
       (cons "payload" (handle-gerbil-ast-inspect payload))))
     ((string=? operation "ast-verify")
      (mk-obj
       (cons "schemaId" "agent.semantic-protocols.provider-runtime-response-frame")
       (cons "schemaVersion" "1")
       (cons "requestId" request-id)
       (cons "outcome" "ready")
       (cons "payload" (handle-gerbil-ast-verify payload))))
     (else
      (mk-obj
       (cons "schemaId" "agent.semantic-protocols.provider-runtime-response-frame")
       (cons "schemaVersion" "1")
       (cons "requestId" request-id)
       (cons "outcome" "error")
       (cons "error" (string-append "unsupported provider operation: " operation)))))))

(def (method-is? method expected)
  (let ((s (cond ((string? method) method)
                 ((symbol? method) (symbol->string method))
                 (else ""))))
    (string=? s expected)))

(def (make-provider-handler shutdown-ch)
  (lambda (request response)
    (let ((path (or (URL-path (Request-url request)) "/"))
          (method (Request-method request)))
      (cond
       ((and (equal? path "/health") (method-is? method "GET"))
        (write-json-http! response OK (health-payload)))
       ((and (equal? path "/v1/provider-runtime") (method-is? method "POST"))
        (with-catch
         (lambda (err)
           (write-json-http!
            response
            OK
            (mk-obj
             (cons "schemaId" "agent.semantic-protocols.provider-runtime-response-frame")
             (cons "schemaVersion" "1")
             (cons "requestId" "invalid-request")
             (cons "outcome" "error")
             (cons "error" (call-with-output-string "" (lambda (p) (display-exception err p)))))))
         (lambda ()
           (let* ((raw (read-all-from-reader (Request-body request)))
                  (frame (normalize-json (read-json (open-input-string (utf8->string raw))))))
             (write-json-http! response OK (dispatch-runtime-frame frame))))))
       ((and (equal? path "/shutdown") (method-is? method "POST"))
        (write-json-http! response OK (mk-obj (cons "state" "draining")))
        (channel-try-put shutdown-ch #t))
       (else
        (write-json-http! response 404 (mk-obj (cons "error" "route not found"))))))))

(def (main . _args)
  (let* ((address (resolve-bind-address (getenv "ASP_CLIENT_SERVER_HOST" "127.0.0.1:0")))
         (endpoint (string-append "http://" address "/"))
         (shutdown-ch (make-channel 1))
         (server
          (new-http-server
           (ServerConfig
            mux: (new-static-mux
                  path: "/health" (new-closure-handler (make-provider-handler shutdown-ch))
                  path: "/v1/provider-runtime" (new-closure-handler (make-provider-handler shutdown-ch))
                  path: "/shutdown" (new-closure-handler (make-provider-handler shutdown-ch)))
            log: (LogSink (silent-log-sink name: "asp-gerbil-scheme" level: ERROR))
            listen: (list (string-append "inet4:" address))
            response-timeout: (IOTimeout 30))))
         (out (current-output-port)))
    (using (s server : Server)
      (s.start!))
    (write-json
     out
     (mk-obj
      (cons "schemaId" "agent.semantic-protocols.asp-client-server-bootstrap")
      (cons "schemaVersion" "1")
      (cons "providerId" (getenv "ASP_PROVIDER_ID" "asp-gerbil-scheme"))
      (cons "languageId" (getenv "ASP_PROVIDER_LANGUAGE_ID" "gerbil-scheme"))
      (cons "transport" "http-json")
      (cons "state" "ready")
      (cons "endpoint" endpoint)))
    (newline out)
    (force-output out)
    (channel-get shutdown-ch)
    (using (s server : Server)
      (s.stop!))))
