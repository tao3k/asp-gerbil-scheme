;;; -*- Gerbil -*-
;;; Boundary:
;;; - This module projects parser-owned project facts into evidence packets.
;;; - Packet construction stays pure; display helpers own the serialization side effect.
;;; Invariant: packet fields and receipt commands name executable public surfaces.

(import :gslph/src/constants
        :gslph/src/parser/facade
        :gslph/src/protocol/json
        (only-in :std/sugar filter match unless)
        :gslph/src/support/args)

(export evidence-main
        evidence-graph-packet
        evidence-analysis-request-packet)
;; String
(def +evidence-graph-schema-id+
  "agent.semantic-protocols.semantic-evidence-graph")
;; String
(def +evidence-graph-protocol-id+
  "agent.semantic-protocols.evidence-graph")
;; String
(def +graph-turbo-request-schema-id+
  "agent.semantic-protocols.semantic-graph-turbo-request")
;; String
(def +semantic-language-protocol-id+
  "agent.semantic-protocols.semantic-language")
;; evidence-main
;;   : (-> (List String) Integer)
;;   | doc m%
;;       `evidence-main args` dispatches `graph` and `analyze` actions and
;;       returns zero after writing the selected evidence packet surface.
;;
;;       # Examples
;;
;;       ```scheme
;;       (evidence-main '("graph" "--workspace" "."))
;;       ;; => 0
;;       ```
;;     %
(def (evidence-main args)
  (match args
    ([] (error "expected evidence <graph|analyze>"))
    ([action . rest]
     (unless (member action '("graph" "analyze" "analysis"))
       (error "expected evidence <graph|analyze>"))
     (let* ((root (evidence-project-root rest))
            (json? (flag? "--json" rest)))
       (cond
        ((equal? action "graph")
         (let (packet (evidence-graph-packet root))
           (if json?
             (write-json-line packet)
             (display-evidence-graph packet))))
        (else
         (let (packet (evidence-analysis-request-packet root))
           (if json?
             (write-json-line packet)
             (display-evidence-analysis-request packet)))))
       0))))
;; : (-> (List String) String )
(def (evidence-project-root args)
  (let (workspace (option "--workspace" args))
    (if workspace workspace (project-root args))))
;;; Boundary:
;;; - evidence-graph-packet coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; evidence-graph-packet
;;   : (-> String Json)
;;   | doc m%
;;       `evidence-graph-packet root` builds the semantic evidence graph packet
;;       for the current Gerbil harness project and exposes the next receipt
;;       command as graph gap metadata.
;;
;;       # Examples
;;       ```scheme
;;       (hash-get (evidence-graph-packet ".") 'protocolId)
;;       ;; => "agent.semantic-protocols.evidence-graph"
;;       ```
;;     %
(def (evidence-graph-packet root)
  (let* ((index (collect-project-package-only root))
         (owner-path (evidence-owner-path index))
         (owner-id (evidence-node-id "gerbil-scheme:owner" owner-path))
         (claim-id (evidence-node-id "gerbil-scheme:claim" owner-path))
         (receipt-id (evidence-node-id "gerbil-scheme:receipt" "gerbil-harness-gxtest"))
         (action-id (evidence-node-id "gerbil-scheme:action" "run-gerbil-harness-gxtest"))
         (gap-id (evidence-node-id "gerbil-scheme:gap" (string-append owner-path ":receipt")))
         (test-command "gxpkg env gxtest -q t/...")
         (nodes [(evidence-node owner-id "owner" owner-path owner-path "current"
                                (hash (languageId +language-id+)
                                      (source "provider-project")))
                 (evidence-node claim-id "invariant-candidate"
                                "Gerbil Scheme provider behavior needs executable evidence"
                                owner-path "needs-injection"
                                (hash (candidateId "gerbil-scheme.evidence.project-harness")
                                      (sourceRuleId "GERBIL-SCHEME-EVIDENCE-GRAPH")
                                      (receiptKind "gxtest-policy")
                                      (summary "Project-level Gerbil Scheme search and policy behavior should be linked to GSLPH Testing Framework receipts.")))
                 (evidence-node receipt-id "verification-receipt" test-command
                                owner-path "needs-injection"
                                (hash (receiptId "gerbil-scheme.harness.gxtest")
                                      (command test-command)
                                      (summary "Run project tests through the GSLPH Testing Framework and attach the receipt before treating the claim as verified.")))
                 (evidence-node action-id "review-action"
                                (string-append "Run " test-command)
                                owner-path "missing"
                                (hash (actionId "gerbil-scheme.run-harness-gxtest")
                                      (priority "p0")
                                      (targetId "gerbil-scheme.evidence.project-harness")
                                      (summary "run-receipt")))])
         (edges [(evidence-edge "gerbil-scheme:edge:owner-claim"
                                "supports-claim" owner-id claim-id)
                 (evidence-edge "gerbil-scheme:edge:claim-receipt"
                                "requires-evidence" claim-id receipt-id)
                 (evidence-edge "gerbil-scheme:edge:action-claim"
                                "requires-evidence" action-id claim-id)])
         (gaps [(hash (gapId gap-id)
                      (ownerPath owner-path)
                      (summary "No attached GSLPH Testing Framework receipt for this evidence graph.")
                      (severity "warning")
                      (fields (hash (nextCommand test-command))))]))
    (hash
     (schemaId +evidence-graph-schema-id+)
     (schemaVersion "1")
     (protocolId +evidence-graph-protocol-id+)
     (protocolVersion "1")
     (graphId "gerbil-scheme.evidence.graph")
     (producer (evidence-producer))
     (project (evidence-project index))
     (summary (evidence-summary nodes edges gaps))
     (nodes nodes)
     (edges edges)
     (gaps gaps)
     (fields (hash (next "pipe JSON to `asp graph render --packet - --view seeds`"))))))
;; evidence-analysis-request-packet
;;   : (-> String Json)
;;   | doc m%
;;       `evidence-analysis-request-packet root` wraps the evidence graph in a
;;       graph-turbo request packet for downstream ranking.
;;
;;       # Examples
;;
;;       ```scheme
;;       (hash-get (evidence-analysis-request-packet ".") 'packetKind)
;;       ;; => "graph-turbo-request"
;;       ```
;;     %
(def (evidence-analysis-request-packet root)
  (let* ((graph (evidence-graph-packet root))
         (analysis-graph (evidence-analysis-graph graph))
         (graph-summary (hash-get graph 'summary))
         (request-summary (hash
                           (graphs 1)
                           (nodes (hash-get graph-summary 'nodes))
                           (edges (hash-get graph-summary 'edges))
                           (owners (hash-get graph-summary 'owners))
                           (claims (hash-get graph-summary 'claims))
                           (staleItems (hash-get graph-summary 'staleItems))
                           (gaps (hash-get graph-summary 'gaps)))))
    (hash
     (schemaId +graph-turbo-request-schema-id+)
     (schemaVersion "1")
     (protocolId +semantic-language-protocol-id+)
     (protocolVersion "1")
     (packetKind "graph-turbo-request")
     (requestId (string-append
                 "gerbil-scheme.evidence.analysis.graphs-1.nodes-"
                 (number->string (hash-get request-summary 'nodes))
                 ".gaps-"
                 (number->string (hash-get request-summary 'gaps))))
     (surface "evidence-analyze")
     (queryTerms ["gerbil scheme evidence quality"])
     (profile "evidence-quality")
     (algorithm "typed-ppr-diverse")
     (seedIds (evidence-analysis-seed-ids analysis-graph))
     (budget 8)
     (producer (evidence-producer))
     (project (hash (root root)
                    (fields (hash))))
     (summary request-summary)
     (graphs [analysis-graph])
     (fields (hash (next "pipe JSON to `asp graph render --packet - --view seeds`"))))))
;; : (-> Packet String )
(def (display-evidence-graph packet)
  (let (summary (hash-get packet 'summary))
    (displayln "evidence-graph nodes=" (hash-get summary 'nodes)
               " edges=" (hash-get summary 'edges)
               " owners=" (hash-get summary 'owners)
               " claims=" (hash-get summary 'claims)
               " stale-items=" (hash-get summary 'staleItems)
               " gaps=" (hash-get summary 'gaps))))
;; : (-> Packet String )
(def (display-evidence-analysis-request packet)
  (let (summary (hash-get packet 'summary))
    (displayln "evidence-analysis profile=" (hash-get packet 'profile)
               " graphs=" (hash-get summary 'graphs)
               " nodes=" (hash-get summary 'nodes)
               " edges=" (hash-get summary 'edges)
               " owners=" (hash-get summary 'owners)
               " claims=" (hash-get summary 'claims)
               " stale-items=" (hash-get summary 'staleItems)
               " gaps=" (hash-get summary 'gaps)
               " next=\"asp graph render --packet - --view seeds\"")))
;; : (-> ProjectIndex String )
(def (evidence-owner-path index)
  (let (package (project-index-package index))
    (cond
     (package (project-package-path package))
     ((pair? (project-index-files index))
      (source-file-path (car (project-index-files index))))
     (else "."))))
;; : (-> Prefix Value String )
(def (evidence-node-id prefix value)
  (string-append prefix ":" value))
;; : (-> NodeId String Label OwnerPath Status Fields String )
(def (evidence-node node-id kind label owner-path status fields)
  (hash (nodeId node-id)
        (kind kind)
        (label label)
        (ownerPath owner-path)
        (status status)
        (location (hash (path owner-path)
                        (line 1)
                        (column 0)))
        (fields fields)))
;; : (-> EdgeId String FromNodeId ToNodeId String )
(def (evidence-edge edge-id kind from-node-id to-node-id)
  (hash (edgeId edge-id)
        (kind kind)
        (fromNodeId from-node-id)
        (toNodeId to-node-id)))
;; : (-> Nodes Edges Gaps String )
(def (evidence-summary nodes edges gaps)
  (hash (nodes (length nodes))
        (edges (length edges))
        (owners (count-node-kind nodes "owner"))
        (claims (count-node-kind nodes "invariant-candidate"))
        (staleItems 0)
        (gaps (length gaps))))
;; count-node-kind
;;   : (-> (List Json) String Integer)
;;   | doc m%
;;       `count-node-kind nodes kind` counts graph nodes whose `kind` field
;;       matches `kind`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (count-node-kind [(hash (kind "owner")) (hash (kind "claim"))] "owner")
;;       ;; => 1
;;       ```
;;     %
(def (count-node-kind nodes kind)
  (length (filter (lambda (node)
                    (equal? (hash-get node 'kind) kind))
                  nodes)))
;; String
(def (evidence-producer)
  (hash (languageId +language-id+)
        (providerId +provider-id+)
        (namespace "agent.semantic-protocols.languages.gerbil-scheme.gerbil-scheme-harness")))
;; : (-> ProjectIndex String )
(def (evidence-project index)
  (let ((root (project-index-root index))
        (package (project-index-package index)))
    (hash (root root)
          (package (if package (project-package-name package) "gerbil-scheme-project"))
          (fields (hash)))))
;; evidence-analysis-graph
;;   : (-> Json Json)
;;   | doc m%
;;       `evidence-analysis-graph graph` projects the packet graph into the
;;       compact analysis graph shape consumed by graph-turbo.
;;
;;       # Examples
;;
;;       ```scheme
;;       (hash-get (evidence-analysis-graph (evidence-graph-packet ".")) 'graphId)
;;       ;; => "gerbil-scheme.evidence.graph"
;;       ```
;;     %
(def (evidence-analysis-graph graph)
  (hash (graphId (hash-get graph 'graphId))
        (summary (hash-get graph 'summary))
        (nodes (map evidence-analysis-node (hash-get graph 'nodes)))
        (edges (map evidence-analysis-edge (hash-get graph 'edges)))
        (gaps (hash-get graph 'gaps))))
;; : (-> Node String )
(def (evidence-analysis-node node)
  (let* ((location (hash-get node 'location))
         (path (hash-get node 'ownerPath))
         (line (hash-get location 'line)))
    (hash (id (hash-get node 'nodeId))
          (kind (hash-get node 'kind))
          (role (evidence-node-role (hash-get node 'kind)))
          (value (hash-get node 'label))
          (path path)
          (ownerPath path)
          (locator (string-append path ":" (number->string line) ":" (number->string line)))
          (startLine line)
          (endLine line)
          (fields (hash-get node 'fields)))))
;; : (-> Edge String )
(def (evidence-analysis-edge edge)
  (hash (source (hash-get edge 'fromNodeId))
        (target (hash-get edge 'toNodeId))
        (relation (hash-get edge 'kind))
        (fields (hash (edgeId (hash-get edge 'edgeId))))))
;; evidence-analysis-seed-ids
;;   : (-> Json (List String))
;;   | doc m%
;;       `evidence-analysis-seed-ids graph` returns the node ids whose role is
;;       `owner`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (evidence-analysis-seed-ids (hash (nodes [(hash (id "n1") (role "owner"))])))
;;       ;; => ("n1")
;;       ```
;;     %
(def (evidence-analysis-seed-ids graph)
  (map (lambda (node) (hash-get node 'id))
       (filter (lambda (node)
                 (equal? (hash-get node 'role) "owner"))
               (hash-get graph 'nodes))))
;; : (-> String String )
(def (evidence-node-role kind)
  (cond
   ((equal? kind "owner") "owner")
   ((equal? kind "invariant-candidate") "claim")
   ((equal? kind "verification-receipt") "receipt")
   ((equal? kind "review-action") "action")
   (else "evidence")))
