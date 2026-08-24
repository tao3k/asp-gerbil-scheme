;;; -*- Gerbil -*-
;;; Release-only static linker root for the native gslph executable.

(import (only-in :gslph/src/commands/search-structural
                 emit-structural-artifact)
        (rename-in :gslph/src/cli-launcher (main cli-main))
        (only-in :gslph/src/commands/agent agent-main)
        (only-in :gslph/src/commands/evidence evidence-main)
        (only-in :gslph/src/commands/fmt fmt-main)
        (only-in :gslph/src/commands/guide guide-main)
        (only-in :gslph/src/commands/info info-main)
        (only-in :gslph/src/commands/projection projection-main)
        (only-in :gslph/src/commands/query query-main)
        (only-in :gslph/src/commands/search search-main)
        (only-in :gslph/src/protocol/command-catalog
                 provider-command-descriptor-name
                 provider-command-descriptor-static-main
                 provider-command-descriptors)
        (only-in :gslph/src/support/args executable-argv))
(export main
        release-command-dispatch
        release-command-mains)

;;; Static release boundary:
;;; - The launcher keeps cold commands behind load-module.
;;; - This module exists only as the compile-exe root so the release binary
;;;   links the cold command modules into Gerbil's static module table.
;; : (-> ProviderCommandDescriptor CommandMain)
(def (release-command-main descriptor)
  (case (provider-command-descriptor-static-main descriptor)
    ((search-main) search-main)
    ((query-main) query-main)
    ((projection-main) projection-main)
    ((fmt-main) fmt-main)
    ((evidence-main) evidence-main)
    ((agent-main) agent-main)
    ((guide-main) guide-main)
    ((info-main) info-main)
    (else
     (error "missing static command root"
            (provider-command-descriptor-name descriptor)))))

;; : (List CommandMain)
(def release-command-dispatch
  (map (lambda (descriptor)
         [(provider-command-descriptor-name descriptor)
          (release-command-main descriptor)])
       provider-command-descriptors))

;; : (List CommandMain)
(def release-command-mains
  (map cadr release-command-dispatch))

(register-static-command-dispatch! release-command-dispatch)

;; : (-> Args Integer)
(def (main . args)
  (register-static-command-dispatch! release-command-dispatch)
  (exit (apply cli-main (executable-argv args))))

;; : (-> Args Args)
