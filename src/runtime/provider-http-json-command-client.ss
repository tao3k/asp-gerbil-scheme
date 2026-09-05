;;; -*- Gerbil -*-
;;; Thin CLI adapter for an already admitted resident provider HTTP runtime.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/protocol/json-output write-json-line)
        (only-in :asp-gerbil-scheme/src/runtime/provider-http-json-client
                 provider-http-json-request!)
        (only-in :asp-gerbil-scheme/src/support/args flag? option)
        (only-in :std/text/json read-json))

(export provider-http-json-query-main)

;; : (-> (List String) Integer)
(def (provider-http-json-query-main args)
  (unless (flag? "--runtime-request-frame-stdin" args)
    (error "HTTP query requires one typed Runtime request frame on stdin"))
  (let (endpoint (option "--server-endpoint" args))
    (unless endpoint
      (error "HTTP query requires an explicitly injected server endpoint"))
    (write-json-line
     (provider-http-json-request!
      endpoint
      (read-json (current-input-port))))
    0))
