;;; This command is only the process entry boundary for the provider runtime.
;;; HTTP lifecycle and request semantics remain owned by the runtime library;
;;; argument validation here must not grow into build or server policy.
(import (only-in :asp-gerbil-scheme/src/runtime/provider-http-json-server
                 serve-provider-http-json-runtime!))

(export provider-runtime-main)

;; : (-> (List String) Integer)
(def (provider-runtime-main args)
  (unless (null? args)
    (error "usage: asp-gerbil-scheme serve"))
  (serve-provider-http-json-runtime!)
  0)
