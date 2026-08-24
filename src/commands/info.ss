;;; -*- Gerbil -*-
;;; Machine-readable harness info and verification receipt.

(import :gslph/src/constants
        :gslph/src/parser/facade
        :gslph/src/policy/catalog
        :gslph/src/protocol/json
        :gslph/src/support/args
        :gslph/src/support/io
        (only-in :std/srfi/13 string-join))

(export info-main
        info-packet
        display-info-packet)
;; String
(def +info-schema-id+
  "agent.semantic-protocols.gerbil-scheme-harness-info")
;; : (-> String JsonPacket )
(def (info-packet root)
  (let* ((index (collect-project-package-only root))
         (package (project-index-package index)))
    (hash (schemaId +info-schema-id+)
          (schemaVersion "1")
          (languageId +language-id+)
          (providerId +provider-id+)
          (projectRoot root)
          (files 0)
          (definitions 0)
          (indexStatsStatus "rust-owned-not-materialized")
          (package (package-info-json package))
          (configurableInterface (configurable-interface-json))
          (agentSteering (agent-steering-json))
          (closureCommands (closure-commands-json)))))
;; : (-> Package Json )
(def (package-info-json package)
  (and package
       (hash (path (project-package-path package))
             (name (project-package-name package))
             (packageManager (project-package-manager package))
             (dependencies (project-package-dependencies package)))))
;; Json
(def (configurable-interface-json)
  (hash (sourceScope
         (hash (owner "gerbil.pkg policy")
               (fields ["roots" "runtime-roots" "exclude-directories" "explanation"])
               (buildFallback
                "build.ss defbuild-script targets provide runtimeRoots when explicit source-scope is absent")))
        (agentPolicy
         (hash (owner "gerbil.pkg policy")
               (fields ["enabled-rules" "disabled-rules"])))))
;; Json
(def (agent-steering-json)
  (hash (facts (agent-steering-facts))
        (rules (agent-steering-rule-json))))
;; Json
(def (closure-commands-json)
  (hash (selfApply "gxi build.ss")))
;;; Boundary:
;;; - The info command emits line protocol and keeps packet field selection here.
;;; - Callers provide the already-built packet so command routing stays projection-free.
;; : (-> Packet JsonPacket )
(def (display-info-packet packet)
  (emit-field-line
   "[gerbil-info]"
   [(line-field "language" (hash-get packet 'languageId))
    (line-field "provider" (hash-get packet 'providerId))
    (line-field "files" (hash-get packet 'files))
    (line-field "definitions" (hash-get packet 'definitions))])
  (let (package (hash-get packet 'package))
    (when package
      (emit-field-line
       "|package"
       [(line-field "path" (hash-get package 'path))
        (line-field "name" (hash-get package 'name))
        (line-field "manager" (hash-get package 'packageManager))])))
  (emit-text-line
   "|interface source-scope=gerbil.pkg-policy fields=roots,runtime-roots,exclude-directories explanation=required-for-overrides")
  (emit-text-line
   "|interface build-scope=build.ss defbuild-script targets -> runtime-roots when explicit source-scope is absent")
  (emit-text-line
   "|interface agent-policy=gerbil.pkg-policy fields=enabled-rules,disabled-rules")
  (emit-field-line
   "|agent-steering"
   [(line-field "facts" (string-join (agent-steering-facts) ","))])
  (emit-field-line
   "|agent-steering"
   [(line-field "rules" (agent-steering-rule-id-string))])
  (let (closure (hash-get packet 'closureCommands))
    (emit-field-line
     "|closure"
     [(line-field "self-apply" (hash-get closure 'selfApply))])))
;; info-main
;;   : (-> (List String) Integer)
;;   | doc m%
;;       `info-main args` emits the harness information packet and returns a
;;       process-style status code.
;;
;;       # Examples
;;
;;       ```scheme
;;       (info-main '("--workspace" "."))
;;       ;; => 0
;;       ```
;;     %
(def (info-main args)
  (let* ((root (project-root args))
         (json? (flag? "--json" args))
         (packet (info-packet root)))
    (if json?
      (write-json-line packet)
      (display-info-packet packet))
    0))
