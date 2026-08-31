;;; -*- Gerbil -*-
;;; Package executable entrypoint for the Gerbil Scheme project harness.

(import (rename-in :gslph/src/cli-launcher
                   (main launcher-main)
                   (command-line-args launcher-command-line-args)
                   (provider-command-line-args launcher-provider-command-line-args)))

(export main
        command-line-args
        provider-command-line-args)

;; : (-> Args Integer)
(def (main . args)
  (apply launcher-main args))

;; : (-> (List String))
(def command-line-args launcher-command-line-args)
;; : (-> (List String))
(def provider-command-line-args launcher-provider-command-line-args)
