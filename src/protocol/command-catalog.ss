;;; -*- Gerbil -*-
;;; Single declarative owner for public provider commands.

(import :gerbil/gambit
        (only-in :std/sort sort))

(export provider-command-descriptor
        provider-command-descriptor?
        make-provider-command-descriptor
        provider-command-descriptor-name
        provider-command-descriptor-module
        provider-command-descriptor-dynamic-main
        provider-command-descriptor-static-main
        provider-command-descriptor-usage-lines
        provider-command-descriptor-registry-order
        provider-command-descriptor-registry-methods
        provider-command-descriptors
        provider-command-names
        provider-recognized-command-names
        provider-dynamic-command-dispatch
        provider-registry-methods
        provider-command-help)

;;; Boundary:
;;; - This record owns command identity and public projections.
;;; - Static procedure identity remains explicit in cli-release-linker.ss.
(defstruct provider-command-descriptor
  (name module dynamic-main static-main usage-lines registry-order registry-methods)
  transparent: #t)

;; : (List ProviderCommandDescriptor)
(def provider-command-descriptors
  [(make-provider-command-descriptor
    "query"
    "asp-gerbil-scheme/src/commands/query"
    'asp-gerbil-scheme/src/commands/query#query-main
    'query-main
    ["query --selector <gerbil-scheme-structural-selector> --projection source --workspace PROJECT_ROOT"
     "query --selector <gerbil-scheme-callable-selector> --projection callable-skeleton --workspace PROJECT_ROOT"]
    20
    ["query/selector" "query/exact-selector-native-v1"])
   (make-provider-command-descriptor
    "projection"
    "asp-gerbil-scheme/src/commands/projection"
    'asp-gerbil-scheme/src/commands/projection#projection-main
    'projection-main
    ["projection <owner-path> --workspace PROJECT_ROOT --json"]
    0
    ["index/structural" "index/native-syntax-owner-facts"])
   (make-provider-command-descriptor
    "fmt"
    "asp-gerbil-scheme/src/commands/fmt"
    'asp-gerbil-scheme/src/commands/fmt#fmt-main
    'fmt-main
    ["fmt [--check] [--json] [--workspace PROJECT_ROOT] [PATH ...]"]
    0
    [])
   (make-provider-command-descriptor
    "evidence"
    "asp-gerbil-scheme/src/commands/evidence"
    'asp-gerbil-scheme/src/commands/evidence#evidence-main
    'evidence-main
    ["evidence graph [--json] [PROJECT_ROOT]"
     "evidence analyze [--json] [PROJECT_ROOT]"]
    50
    ["evidence/graph" "evidence/analyze"])
   (make-provider-command-descriptor
    "agent"
    "asp-gerbil-scheme/src/commands/agent"
    'asp-gerbil-scheme/src/commands/agent#agent-main
    'agent-main
    ["agent doctor [--json] [PROJECT_ROOT]"
     "agent guide [PROJECT_ROOT]"]
    0
    [])
   (make-provider-command-descriptor
    "guide"
    "asp-gerbil-scheme/src/commands/guide"
    'asp-gerbil-scheme/src/commands/guide#guide-main
    'guide-main
    ["guide [--json] [PROJECT_ROOT]"]
    30
    ["guide"])
   (make-provider-command-descriptor
    "info"
    "asp-gerbil-scheme/src/commands/info"
    'asp-gerbil-scheme/src/commands/info#info-main
    'info-main
    ["info [--json] [PROJECT_ROOT]"]
    40
    ["info"])])

;; : (List String)
(def provider-command-names
  (map provider-command-descriptor-name provider-command-descriptors))

;; : (List String)
(def provider-recognized-command-names
  (append provider-command-names ["help" "-h" "--help"]))

;; : (List CommandDispatch)
(def provider-dynamic-command-dispatch
  (map (lambda (descriptor)
         [(provider-command-descriptor-name descriptor)
          (provider-command-descriptor-module descriptor)
          (provider-command-descriptor-dynamic-main descriptor)])
       provider-command-descriptors))

;; : (-> (List String))
(def (provider-registry-methods)
  (let (registry-descriptors
        (sort
         (filter (lambda (descriptor)
                   (pair? (provider-command-descriptor-registry-methods descriptor)))
                 provider-command-descriptors)
         (lambda (left right)
           (< (provider-command-descriptor-registry-order left)
              (provider-command-descriptor-registry-order right)))))
    (apply append
           (map provider-command-descriptor-registry-methods
                registry-descriptors))))

;; : (-> String String)
(def (provider-command-help cli-id)
  (call-with-output-string
   (lambda (port)
     (display cli-id port)
     (display " - Gerbil Scheme semantic search and project harness\n\nUsage:\n" port)
     (for-each
      (lambda (descriptor)
        (for-each
         (lambda (usage)
           (display "  " port)
           (display cli-id port)
           (display " " port)
           (display usage port)
           (newline port))
         (provider-command-descriptor-usage-lines descriptor)))
      provider-command-descriptors))))
