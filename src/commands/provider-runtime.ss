(import (only-in :gslph/src/runtime/provider-http-json-server
                 serve-provider-http-json-runtime!))

(export provider-runtime-main)

(def (provider-runtime-main args)
  (unless (null? args)
    (error "usage: asp-gerbil-scheme serve"))
  (serve-provider-http-json-runtime!)
  0)
