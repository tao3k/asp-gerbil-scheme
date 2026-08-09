;;; Representative exact owner used by the provider projection scenario.

(def +request-schema-id+ "request-v1")

(def (run-language-command request registry)
  (if request
    (registry request)
    #f))

(def (owner-item-name item)
  (car item))
