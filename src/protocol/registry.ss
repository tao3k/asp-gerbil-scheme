;;; -*- Gerbil -*-
;;; Provider registry projection.

(import :asp-gerbil-scheme/src/constants
        :asp-gerbil-scheme/src/parser/facade
        (only-in :asp-gerbil-scheme/src/protocol/command-catalog provider-registry-methods)
        (only-in :std/sugar hash))

(export language-registry)
;;; Boundary:
;;; - language-registry coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> String LanguageRegistry )
(def (language-registry root)
  (hash
   (registryId "agent.semantic-protocols.semantic-language-registry")
   (registryVersion "1")
   (protocolId "agent.semantic-protocols.semantic-language")
   (protocolVersion "1")
   (languages
    [(hash
      (languageId +language-id+)
      (providerId +provider-id+)
      (binary "asp-gerbil-scheme")
      (execution "external-process")
      (namespace "agent.semantic-protocols.languages.gerbil-scheme.asp-gerbil-scheme")
      (displayName +display-name+)
      (packageRoots [root])
      (methods (provider-registry-methods))
      (schemas [(hash (schemaId "agent.semantic-protocols.asp-gerbil-scheme-info")
                      (schemaVersion "1")
                      (path "schemas/semantic-asp-gerbil-scheme-info.v1.schema.json"))])
      (methodDescriptors
       [(hash (method "info")
              (command "info")
              (summary "Emit provider-local Gerbil package, configurable interface, agent steering, and closure command facts.")
              (outputSchemaIds ["agent.semantic-protocols.asp-gerbil-scheme-info"]))
         (hash (method "index/structural")
               (command "projection --native-index --json")
              (summary "Emit a lightweight native-parser structural interface; ASP Rust owns full index construction, graph topology, caching, and refresh planning.")
              (outputSchemaIds ["agent.semantic-protocols.semantic-structural-index"]))
         (hash (method "index/native-syntax-owner-facts")
               (command "projection --native-index --owner <path> --json")
              (summary "Emit owner-bounded native syntax facts for ASP-side fan-out and incremental structural indexing.")
              (outputSchemaIds ["agent.semantic-protocols.semantic-native-syntax-fact-index"]))
        (hash (method "query/exact-selector-native-v1")
              (command "query")
              (view "exact-selector")
              (acceptsStdin #t)
              (requiresQuery #t)
              (supportsJson #t)
              (supportsCompact #f)
              (supportsPackageScope #f)
              (outputSchemaIds
               ["agent.semantic-protocols.provider-native-exact-projection"])
              (packetSchemas
               ["provider-native-exact-request.v1"
                "provider-native-exact-response.v1"])
              (invocation
               (hash (argv
                      ["asp-gerbil-scheme"
                       "query"
                       "--server-endpoint"
                       "<resident-runtime-endpoint>"
                       "--runtime-request-frame-stdin"]))))
        (hash (method "evidence/graph")
              (command "evidence")
              (summary "Emit a portable semantic evidence graph for Gerbil Scheme provider evidence.")
              (outputSchemaIds ["agent.semantic-protocols.semantic-evidence-graph"]))
        (hash (method "evidence/analyze")
              (command "evidence")
              (summary "Emit a graph-turbo request for evidence-quality ranking.")
              (outputSchemaIds ["agent.semantic-protocols.semantic-graph-turbo-request"]))])
      (source (hash
               (defaultExtensions +source-extensions+)
               (defaultConfigFiles +config-files+)
               (defaultSourceRoots ["src" "test" "tests" "doc" "docs" "examples" "tutorial"])
               (defaultScopeIncludedDirs ["src" "test" "tests" "doc" "docs" "examples" "tutorial"]))))])))
