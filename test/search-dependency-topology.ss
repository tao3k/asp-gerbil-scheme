#!/usr/bin/env gxi

(import :std/text/json
        :asp-gerbil-scheme/src/commands/search)

(def (assert-equal label actual expected)
  (unless (equal? actual expected)
    (error "dependency-topology assertion failed" label actual expected)))

(def (find-graph-node nodes kind)
  (find (lambda (node)
          (equal? (hash-get node "kind") kind))
        nodes))

(let* ((output
        (with-output-to-string
          (lambda ()
            (search-main
             (list "dependency-topology"
                   "--json"
                   "--workspace"
                   ".")))))
       (packet (call-with-input-string output read-json))
       (graph (hash-get packet "graph"))
       (nodes (hash-get graph "nodes"))
       (edges (hash-get graph "edges"))
       (dependency-node (find-graph-node nodes "dependency"))
       (version-node (find-graph-node nodes "dependency-version"))
       (edge (and (pair? edges) (car edges)))
       (fingerprint (hash-get packet "fingerprint")))
  (assert-equal 'packet-kind
                (hash-get packet "packetKind")
                "dependency-topology")
  (unless (and (string? fingerprint)
               (= (string-length fingerprint) 71)
               (string-prefix? "sha256:" fingerprint))
    (error "dependency-topology fingerprint is not canonical" fingerprint))
  (assert-equal 'dependency-path
                (hash-get dependency-node "path")
                "gerbil.pkg")
  (assert-equal 'dependency-name
                (hash-get dependency-node "value")
                "github.com/mighty-gerbils/gerbil-poo")
  (assert-equal 'dependency-version
                (hash-get version-node "value")
                "unresolved")
  (assert-equal 'edge-relation
                (hash-get edge "relation")
                "version_locked")
  (assert-equal 'edge-source
                (hash-get edge "source")
                (hash-get dependency-node "id"))
  (assert-equal 'edge-target
                (hash-get edge "target")
                (hash-get version-node "id"))
  (displayln "[pass] search dependency-topology"))

(let* ((binary (path-expand "~/.local/bin/asp-gerbil-scheme"))
       (process
        (open-process
         (list path: binary
               arguments:
               (list "search"
                     "dependency-topology"
                     "--json"
                     "--workspace"
                     ".")
               stdout-redirection: #t)))
       (output (read-line process))
       (status (process-status process))
       (packet (call-with-input-string output read-json))
       (graph (hash-get packet "graph"))
       (nodes (hash-get graph "nodes"))
       (edges (hash-get graph "edges")))
  (assert-equal 'binary-exit status 0)
  (assert-equal 'binary-packet-kind
                (hash-get packet "packetKind")
                "dependency-topology")
  (assert-equal 'binary-node-count (length nodes) 2)
  (assert-equal 'binary-edge-count (length edges) 1)
  (displayln "[pass] asp-gerbil-scheme dependency-topology E2E"))

(let* ((manifest
        (call-with-input-file
         "schemas/asp-provider.json"
         read-json))
       (capabilities (hash-get manifest "searchCapabilities"))
       (routes (hash-get manifest "routeBindings")))
  (assert-equal 'manifest-capability
                (hash-get capabilities "dependencyTopology")
                #t)
  (assert-equal 'manifest-route
                (hash-get routes "dependencyTopology")
                "search/dependency-topology")
  (displayln "[pass] dependency-topology manifest contract"))
