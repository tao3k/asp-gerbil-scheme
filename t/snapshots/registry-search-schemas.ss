(registry
 (registryId "agent.semantic-protocols.semantic-language-registry")
 (registryVersion "1")
 (languageId "gerbil-scheme")
 (providerId "asp-gerbil-scheme")
 (methods ("search/prime"
           "search/owner"
           "search/lexical"
           "search/ingest"
           "search/pattern"
           "search/runtime-source"
           "search/compare"
           "search/proof"
           "search/compiler-evidence"
           "index/structural"
           "index/native-syntax-owner-facts"
           "query/selector"
           "query/exact-selector-native-v1"
           "guide"
           "info"
           "evidence/graph"
           "evidence/analyze"))
 (schemas
  ((schema
    (schemaId "agent.semantic-protocols.gerbil-scheme-harness-info")
    (schemaVersion "1")
    (path "schemas/semantic-gerbil-scheme-harness-info.v1.schema.json"))))
 (methodDescriptors
  ((methodDescriptor
    (method "info")
    (command "info")
    (outputSchemaIds ("agent.semantic-protocols.gerbil-scheme-harness-info")))
   (methodDescriptor
    (method "search/pattern")
    (command "search pattern")
    (outputSchemaIds ("agent.semantic-protocols.semantic-extension-pattern-mapping")))
   (methodDescriptor
    (method "search/runtime-source")
    (command "search runtime-source")
    (outputSchemaIds ("agent.semantic-protocols.semantic-runtime-source-acquisition")))
   (methodDescriptor
    (method "search/compiler-evidence")
    (command "search compiler-evidence")
    (outputSchemaIds ("agent.semantic-protocols.semantic-language-evidence")))
   (methodDescriptor
    (method "search/proof")
    (command "search proof")
    (outputSchemaIds ("agent.semantic-protocols.semantic-type-proof")))
   (methodDescriptor
    (method "search/compare")
    (command "search compare")
    (outputSchemaIds ("agent.semantic-protocols.semantic-compare-packet")))
   (methodDescriptor
    (method "index/structural")
    (command "search structural --json")
    (outputSchemaIds ("agent.semantic-protocols.semantic-structural-index")))
   (methodDescriptor
    (method "index/native-syntax-owner-facts")
    (command "search structural --owner <path> --json")
    (outputSchemaIds ("agent.semantic-protocols.semantic-native-syntax-fact-index")))
   (methodDescriptor
    (method "query/exact-selector-native-v1")
    (command "query")
    (outputSchemaIds ("agent.semantic-protocols.provider-native-exact-projection")))
   (methodDescriptor
    (method "evidence/graph")
    (command "evidence")
    (outputSchemaIds ("agent.semantic-protocols.semantic-evidence-graph")))
   (methodDescriptor
    (method "evidence/analyze")
    (command "evidence")
    (outputSchemaIds ("agent.semantic-protocols.semantic-graph-turbo-request"))))))
