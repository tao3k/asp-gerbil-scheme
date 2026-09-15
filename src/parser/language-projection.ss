;;; -*- Gerbil -*-
;;; Query-free projection artifacts from the native Gerbil parser.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/facade)

(export parse-owner-language-projection
        source-file->language-projection)

;; : ProjectionSchemaId
(def +language-projection-schema-id+
  "agent.semantic-protocols.semantic-language-projection")

;; : ProjectionProtocolId
(def +language-projection-protocol-id+
  "agent.semantic-protocols.language-projection")

;;; Parse exactly one owner through the native parser.  Search, lifecycle
;;; identity, hashing, cache reuse, and Turso import belong to ASP Rust.
;; : (-> WorkspaceRoot ParserOwnerPath LanguageProjectionArtifact)
(def (parse-owner-language-projection workspace owner)
  (source-file->language-projection (parse-source-file workspace owner)))

;;; Convert parser-owned facts into the shared language projection shape.
;; : (-> ParserSourceFile LanguageProjectionArtifact)
(def (source-file->language-projection source)
  (let* ((path (source-file-path source))
         (source-id (source-id-for path))
         (owner-id (owner-id-for path))
         (items (source-items->projection owner-id
                                          (source-file-definitions source))))
    (hash (schemaId +language-projection-schema-id+)
          (schemaVersion "1")
          (protocolId +language-projection-protocol-id+)
          (protocolVersion "1")
          (languageId "gerbil-scheme")
          (harness (hash (harnessId "asp-gerbil-scheme")
                         (parserAbi "gerbil-scheme-parser-v1")
                         (selectorDialect "gerbil-scheme")))
          (sources [(hash (sourceId source-id)
                         (path path)
                         (sourceKind "source"))])
          (owners [(hash (ownerId owner-id)
                        (sourceId source-id)
                        (kind "module")
                        (name path))])
          (items items)
          (relations (append
                      [(projection-relation "source" source-id
                                            "contains"
                                            "owner" owner-id)]
                      (map (lambda (item)
                             (projection-relation "owner" owner-id
                                                  "contains"
                                                  "item"
                                                  (hash-get item 'itemId)))
                           items))))))

;; : (-> ProjectionOwnerId (List ParserDefinition) (List ProjectionItem))
(def (source-items->projection owner-id definitions)
  (map (lambda (definition)
         (let* ((name (projection-string (definition-name definition)))
                (kind (projection-string (definition-kind definition)))
                (selector (definition-selector definition)))
           (hash (itemId (item-id-for selector))
                 (ownerId owner-id)
                 (kind kind)
                 (name name)
                 (selector selector))))
       definitions))

;; : (-> ProjectionNodeKind ProjectionNodeId ProjectionRelationKind ProjectionNodeKind ProjectionNodeId ProjectionRelation)
(def (projection-relation from-kind from-id relation-kind to-kind to-id)
  (hash (from (hash (kind from-kind) (id from-id)))
        (kind relation-kind)
        (to (hash (kind to-kind) (id to-id)))))

;; : (-> ParserFactValue ProjectionText)
(def (projection-string value)
  (cond
   ((string? value) value)
   ((symbol? value) (symbol->string value))
   (else (call-with-output-string (lambda (port) (display value port))))))

;; : (-> ParserOwnerPath ProjectionSourceId)
(def (source-id-for path)
  (string-append "source:" path))

;; : (-> ParserOwnerPath ProjectionOwnerId)
(def (owner-id-for path)
  (string-append "owner:" path))

;; : (-> ParserStructuralSelector ProjectionItemId)
(def (item-id-for selector)
  (string-append "item:" selector))
