(import ./support)
(export main)

(def (main . _args)
  (displayln (downstream-build-script-probe-message)))
