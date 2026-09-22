;;; -*- Gerbil -*-
;;; Lightweight JSON output primitives for provider transport adapters.

(import (only-in :std/encoding/json write-json))

(export write-json-line)

;; Keep transport output independent from parser/search projection modules.
;; : (-> Json Void)
(def (write-json-line obj)
  (write-json (current-output-port) obj)
  (newline))
