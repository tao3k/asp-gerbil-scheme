(registry
 (registryId "agent.semantic-protocols.semantic-language-registry")
 (registryVersion "1")
 (languageId "gerbil-scheme")
 (providerId "gerbil-scheme-harness")
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
           "query/direct-source-read"
           "guide"
           "info"
           "evidence/graph"
           "evidence/analyze"))
 (schemas
  ((schema
    (schemaId "agent.semantic-protocols.semantic-extension-pattern-mapping")
    (schemaVersion "1")
    (path "schemas/semantic-extension-pattern-mapping.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.gerbil-scheme-harness-info")
    (schemaVersion "2")
    (path "schemas/semantic-gerbil-scheme-harness-info.v2.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-runtime-source-acquisition")
    (schemaVersion "1")
    (path "schemas/semantic-runtime-source-acquisition.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-language-evidence")
    (schemaVersion "1")
    (path "schemas/semantic-language-evidence.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-type-proof")
    (schemaVersion "1")
    (path "schemas/semantic-type-proof.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-compare-packet")
    (schemaVersion "1")
    (path "schemas/semantic-compare-packet.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-structural-index")
    (schemaVersion "1")
    (path "schemas/semantic-structural-index.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-native-syntax-fact-index")
    (schemaVersion "1")
    (path "schemas/semantic-native-syntax-fact-index.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-evidence-graph")
    (schemaVersion "1")
    (path "schemas/semantic-evidence-graph.v1.schema.json"))
   (schema
    (schemaId "agent.semantic-protocols.semantic-graph-turbo-request")
    (schemaVersion "1")
    (path "schemas/semantic-graph-turbo-request.v1.schema.json"))))
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
    (method "evidence/graph")
    (command "evidence")
    (outputSchemaIds ("agent.semantic-protocols.semantic-evidence-graph")))
   (methodDescriptor
    (method "evidence/analyze")
    (command "evidence")
    (outputSchemaIds ("agent.semantic-protocols.semantic-graph-turbo-request"))))))
