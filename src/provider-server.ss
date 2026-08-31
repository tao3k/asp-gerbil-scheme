;;; -*- Gerbil -*-
;;; Public resident provider entrypoint.

(import (only-in ./commands/provider-runtime provider-runtime-main)
        (rename-in :gslph/src/cli-launcher (main cli-main)))
(export main)

(def (main . args)
  (if (and (pair? args) (string=? (car args) "serve"))
    (provider-runtime-main (cdr args))
    (apply cli-main args)))
