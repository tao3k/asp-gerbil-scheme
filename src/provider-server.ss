;;; -*- Gerbil -*-
;;; Public resident provider entrypoint.

(import (only-in ./commands/provider-runtime provider-runtime-main))
(export main)

(def (main . args)
  (if (and (pair? args) (string=? (car args) "serve"))
    (provider-runtime-main (cdr args))
    (error "resident provider accepts only the serve command" args)))
