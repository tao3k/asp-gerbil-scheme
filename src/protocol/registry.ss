;;; -*- Gerbil -*-
;;; Provider registry projection.

(import :asp-gerbil-scheme/src/constants
        :asp-gerbil-scheme/src/parser/facade
        (only-in :asp-gerbil-scheme/src/protocol/provider-operation-catalog
                 provider-operation-contract-operation
                 provider-operation-contract->json
                 provider-operation-contracts)
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
      (execution "provider")
      (transport "http-json")
      (namespace "agent.semantic-protocols.languages.gerbil-scheme.asp-gerbil-scheme")
      (displayName +display-name+)
      (packageRoots [root])
      (methods
       (map provider-operation-contract-operation
            provider-operation-contracts))
      (schemas [(hash (schemaId "agent.semantic-protocols.asp-gerbil-scheme-info")
                      (schemaVersion "1")
                      (path "schemas/semantic-asp-gerbil-scheme-info.v1.schema.json"))])
      (methodDescriptors
       (map provider-operation-contract->json
            provider-operation-contracts))
      (source (hash
               (defaultExtensions +source-extensions+)
               (defaultConfigFiles +config-files+)
               (defaultSourceRoots ["src" "test" "tests" "doc" "docs" "examples" "tutorial"])
               (defaultScopeIncludedDirs ["src" "test" "tests" "doc" "docs" "examples" "tutorial"]))))])))
