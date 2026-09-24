;;; -*- Gerbil -*-
;;; Boundary:
;;; - Wire encoding keeps JSON strings, raw bytes, and framed marshal output in
;;;   separate local protocol helpers.
(package: sample/wire)
(import (only-in :clan/base compose cut))
(export encode-wire)

;; payload-json-string
;;   : (-> JSON String String)
;;   | doc m%
;;       `payload-json-string` renders the logical payload and tag to a JSON
;;       string representation.
;;
;;       # Examples
;;
;;       ```scheme
;;       (payload-json-string payload "order")
;;       ;; => "{\"tag\":\"order\",...}"
;;       ```
;;     %
(def (payload-json-string payload tag)
  (string-append "{\"tag\":\"" tag "\",\"payload\":" payload "}"))

;; wire-string-bytes
;;   : (-> String Bytes)
;;   | doc m%
;;       `wire-string-bytes` owns the raw string to bytes representation.
;;
;;       # Examples
;;
;;       ```scheme
;;       (wire-string-bytes "payload")
;;       ;; => bytes
;;       ```
;;     %
(def (wire-string-bytes body)
  (string->bytes body))

;; marshal-frame
;;   : (-> String Bytes)
;;   | doc m%
;;       `marshal-frame` owns the self-delimited wire frame before the raw bytes
;;       conversion.
;;
;;       # Examples
;;
;;       ```scheme
;;       (marshal-frame "{}")
;;       ;; => bytes
;;       ```
;;     %
(def (marshal-frame json)
  (wire-string-bytes
   (string-append "marshal:" json)))

;; encode-wire
;;   : (-> JSON String Bytes)
;;   | doc m%
;;       `encode-wire` composes the local representation adapters.
;;
;;       # Examples
;;
;;       ```scheme
;;       (encode-wire payload "order")
;;       ;; => bytes
;;       ```
;;     %
(def (encode-wire payload tag)
  ((compose marshal-frame
            (cut payload-json-string <> tag))
   payload))
