;;; -*- Gerbil -*-
;;; Public resident provider entrypoint.

(import (only-in ./commands/provider-runtime provider-runtime-main))
(export main)

(def (main command)
  (unless (string=? command "serve")
    (error "usage: asp-gerbil-scheme serve" command))
  (provider-runtime-main '()))
