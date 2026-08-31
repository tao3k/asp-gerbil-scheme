;;; -*- Gerbil -*-
(import :asp-gerbil-scheme/src/commands/evidence
        :asp-gerbil-scheme/src/commands/guide
        :asp-gerbil-scheme/src/protocol/registry
        :std/srfi/13
        :std/test)

(export check-evidence-graph-packet
        check-evidence-analysis-request-packet
        check-evidence-registry-and-guide)
;; String
(def (check-evidence-graph-packet)
  (let* ((packet (evidence-graph-packet "."))
         (summary (hash-get packet 'summary))
         (project (hash-get packet 'project))
         (producer (hash-get packet 'producer)))
    (check (hash-get packet 'schemaId)
           => "agent.semantic-protocols.semantic-evidence-graph")
    (check (hash-get packet 'protocolId)
           => "agent.semantic-protocols.evidence-graph")
    (check (hash-get packet 'graphId) => "gerbil-scheme.evidence.graph")
    (check (hash-get producer 'languageId) => "gerbil-scheme")
    (check (hash-get producer 'providerId) => "asp-gerbil-scheme")
    (check (hash-get project 'package) => "asp-gerbil-scheme")
    (check (hash-get summary 'nodes) => 4)
    (check (hash-get summary 'edges) => 3)
    (check (hash-get summary 'owners) => 1)
    (check (hash-get summary 'claims) => 1)
    (check (hash-get summary 'staleItems) => 0)
    (check (hash-get summary 'gaps) => 1)
    (check (packet-has-node-kind? packet "owner") => #t)
    (check (packet-has-edge-kind? packet "requires-evidence") => #t)
    (check (hash-get (hash-get (car (hash-get packet 'gaps)) 'fields)
                     'nextCommand)
           => "gxpkg env gxtest -q t/...")))
;; String
(def (check-evidence-analysis-request-packet)
  (let* ((packet (evidence-analysis-request-packet "."))
         (summary (hash-get packet 'summary))
         (graph (car (hash-get packet 'graphs))))
    (check (hash-get packet 'schemaId)
           => "agent.semantic-protocols.semantic-graph-turbo-request")
    (check (hash-get packet 'packetKind) => "graph-turbo-request")
    (check (hash-get packet 'surface) => "evidence-analyze")
    (check (hash-get packet 'profile) => "evidence-quality")
    (check (hash-get summary 'graphs) => 1)
    (check (hash-get summary 'nodes) => 4)
    (check (hash-get summary 'gaps) => 1)
    (check (hash-get graph 'graphId) => "gerbil-scheme.evidence.graph")
    (check (hash-get packet 'seedIds) => ["gerbil-scheme:owner:gerbil.pkg"])
    (check (analysis-graph-has-edge-relation? graph "requires-evidence") => #t)))
;; String
(def (check-evidence-registry-and-guide)
  (let* ((registry (language-registry "."))
         (language (car (hash-get registry 'languages)))
         (methods (hash-get language 'methods))
         (schemas (hash-get language 'schemas))
         (descriptors (hash-get language 'methodDescriptors))
         (guide (guide-lines)))
    (check (method-registered? methods "search/pattern") => #t)
    (check (method-registered? methods "search/runtime-source") => #t)
    (check (method-registered? methods "search/compare") => #t)
    (check (method-registered? methods "index/structural") => #t)
    (check (method-registered? methods "index/native-syntax-owner-facts") => #t)
    (check (method-registered? methods "evidence/graph") => #t)
    (check (method-registered? methods "evidence/analyze") => #t)
    (check (schema-registered? schemas
                               "agent.semantic-protocols.semantic-extension-pattern-mapping"
                               "schemas/semantic-extension-pattern-mapping.v1.schema.json")
           => #t)
    (check (schema-registered? schemas
                               "agent.semantic-protocols.semantic-runtime-source-acquisition"
                               "schemas/semantic-runtime-source-acquisition.v1.schema.json")
           => #t)
    (check (schema-registered? schemas
                               "agent.semantic-protocols.semantic-compare-packet"
                               "schemas/semantic-compare-packet.v1.schema.json")
           => #t)
    (check (schema-registered? schemas
                               "agent.semantic-protocols.semantic-structural-index"
                               "schemas/semantic-structural-index.v1.schema.json")
           => #t)
    (check (schema-registered? schemas
                               "agent.semantic-protocols.semantic-native-syntax-fact-index"
                               "schemas/semantic-native-syntax-fact-index.v1.schema.json")
           => #t)
    (check (descriptor-output-schema? descriptors
                                      "search/pattern"
                                      "agent.semantic-protocols.semantic-extension-pattern-mapping")
           => #t)
    (check (descriptor-output-schema? descriptors
                                      "search/runtime-source"
                                      "agent.semantic-protocols.semantic-runtime-source-acquisition")
           => #t)
    (check (descriptor-output-schema? descriptors
                                      "search/compare"
                                      "agent.semantic-protocols.semantic-compare-packet")
           => #t)
    (check (descriptor-output-schema? descriptors
                                      "index/structural"
                                      "agent.semantic-protocols.semantic-structural-index")
           => #t)
    (check (descriptor-output-schema? descriptors
                                      "index/native-syntax-owner-facts"
                                      "agent.semantic-protocols.semantic-native-syntax-fact-index")
           => #t)
    (check (guide-has-fragment? guide "evidence graph --json") => #t)
    (check (guide-has-fragment? guide "evidence analyze --json") => #t)
    (check (guide-has-fragment? guide "search structural --json") => #t)
    (check (guide-has-fragment? guide "search structural --owner <path> --json") => #t)))
;; : (-> Packet String Boolean )
(def (packet-has-node-kind? packet kind)
  (ormap (lambda (node)
           (equal? (hash-get node 'kind) kind))
         (hash-get packet 'nodes)))
;; : (-> Methods Method Boolean )
(def (method-registered? methods method)
  (not (not (member method methods))))
;; : (-> Packet String Boolean )
(def (packet-has-edge-kind? packet kind)
  (ormap (lambda (edge)
           (equal? (hash-get edge 'kind) kind))
         (hash-get packet 'edges)))
;; : (-> Graph Relation Boolean )
(def (analysis-graph-has-edge-relation? graph relation)
  (ormap (lambda (edge)
           (equal? (hash-get edge 'relation) relation))
         (hash-get graph 'edges)))
;; : (-> Guide Fragment Boolean )
(def (guide-has-fragment? guide fragment)
  (ormap (lambda (line)
           (not (not (string-contains line fragment))))
         guide))
;; : (-> Schemas SchemaId String Boolean )
(def (schema-registered? schemas schema-id path)
  (ormap (lambda (schema)
           (and (equal? (hash-get schema 'schemaId) schema-id)
                (equal? (hash-get schema 'path) path)))
         schemas))
;; : (-> Descriptors Method SchemaId Boolean )
(def (descriptor-output-schema? descriptors method schema-id)
  (ormap (lambda (descriptor)
           (and (equal? (hash-get descriptor 'method) method)
                (not (not (member schema-id
                                  (hash-get descriptor 'outputSchemaIds))))))
         descriptors))
