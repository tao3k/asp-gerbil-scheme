;;; -*- Gerbil -*-
;;; Structural search interface renderer.

(import :gslph/src/commands/search-render
        :gslph/src/parser/facade
        :gslph/src/parser/source-class
        :gslph/src/protocol/json
        :gslph/src/support/args
        :gslph/src/support/io
        (only-in :std/srfi/1 take))

(export emit-structural-index)
;; String
(def +structural-interface-owner-path+ "src/commands/search-structural.ss")
;; Integer
(def +structural-interface-preview-limit+ 20)

;;; Boundary:
;;; - emit-structural-index routes interface, owner facts, and explicit artifacts.
;;; - Default output stays lightweight so ASP Rust owns full index construction.
;; : (-> ProjectIndex (List String) Json Integer )
(def (emit-structural-index index args json?)
  (let ((owner (option "--owner" args))
        (artifact? (or (flag? "--artifact" args) (flag? "--full" args))))
    (cond
     (owner (emit-structural-owner-facts index owner json?))
     (artifact? (emit-structural-artifact index json?))
     (else (emit-structural-interface index json?)))))

;;; Interface mode reports stable owner handles, counts, and consumer commands.
;;; The hot path must not materialize workspace syntaxFacts.
;;; ASP Rust fans out owner facts through --owner.
;;; ASP Rust owns graph topology, cache state, and ranking.
;; : (-> ProjectIndex Json Integer )
(def (emit-structural-interface index json?)
  (let* ((packet (structural-index-packet-json index))
         (file-hashes (hash-get packet 'fileHashes))
         (owners (hash-get packet 'owners))
         (symbols (hash-get packet 'symbols))
         (summaries (hash-get packet 'nativeSyntaxFactSummaries))
         (fact-interface (hash-get packet 'factInterface))
         (dependency-usages (hash-get packet 'dependencyUsages)))
    (if json?
      (write-json-line packet)
      (begin
        (emit-field-line
         "[gerbil-search-structural]"
         [(line-field "root" (project-index-root index))
          (line-field "generationId" (hash-get packet 'generationId))
          (line-field "mode" (hash-get packet 'indexMode))
          (line-field "files" (length file-hashes))
          (line-field "owners" (length owners))
          (line-field "symbols" (length symbols))
          (line-field "syntaxFacts" (hash-get packet 'nativeSyntaxFactTotal))
          (line-field "dependencyUsages" (length dependency-usages))])
        (emit-field-line
         "|artifact"
         [(line-field "id" (hash-get packet 'sourceArtifactId))
          (line-field "schemaId" (hash-get packet 'schemaId))
          (line-field "rawSourceStored" "false")])
        (emit-field-line
         "|factInterface"
         [(line-field "mode" (hash-get fact-interface 'mode))
          (line-field "granularity" (hash-get fact-interface 'granularity))
          (line-field "indexOwner" (hash-get fact-interface 'indexOwner))
          (line-field "heavyIndexOwner" (hash-get fact-interface 'heavyIndexOwner))
          (line-field "graphTurboOwner" (hash-get fact-interface 'graphTurboOwner))
          (line-field "factSchemaId" (hash-get fact-interface 'factSchemaId))])
        (emit-field-line
         "|projectionVocabulary"
         [(line-field "facts" "macroFacts,bindingFacts,pooFormFacts,higherOrderFacts,controlFlowFacts,predicateFamilyFacts,fieldAccessPatternFacts,booleanConditionFacts,loopDriverFacts,dependencyAdapterQualityFacts,functionQualityProfiles,typedContractFacts,commentQualityFacts,dependencyUsageFacts")
          (line-field "consumer" "asp-rust-structural-index")
          (line-field "graphTurbo" "asp-graph-turbo")])
        (for-each
         (lambda (owner)
           (emit-field-line
            "|owner"
            [(line-field "path" (hash-get owner 'ownerPath))
             (line-field "kind" (hash-get owner 'ownerKind))
             (line-field "authority" (hash-get owner 'sourceAuthority))
             (line-field "sourceClass"
                         (source-path-class (hash-get owner 'ownerPath)))]))
	         (structural-interface-preview owners))
	        (for-each
	         (lambda (summary)
	           (emit-field-line
              "|ownerFactSummary"
              [(line-field "path" (hash-get summary 'ownerPath))
               (line-field "facts" (hash-get summary 'facts))
               (line-field "command"
                           (string-append "\""
                                          (hash-get summary 'ownerFactsCommand)
                                          "\""))]))
	         (structural-interface-preview summaries))
	        (emit-text-line
           "nextCommand=gerbil-scheme-harness search structural --owner <path> --json ."))))
	  0)

;;; Boundary:
;;; - Interface preview stays bounded while retaining the command owner that
;;;   explains structural fan-out to ASP clients.
;; : (-> (List Json) (List Json) )
(def (structural-interface-preview rows)
  (let ((head (take rows (min +structural-interface-preview-limit+
                              (length rows))))
        (required (find-structural-interface-row rows)))
    (cond
     ((not required) head)
     ((structural-interface-row-present? head required) head)
     (else
      (append (take head
                    (min (- +structural-interface-preview-limit+ 1)
                         (length head)))
              [required])))))
;;; Boundary:
;;; - Required owner lookup is path-based so preview stabilization does not
;;;   depend on current parser ordering or newly added command files.
;; : (-> (List Json) MaybeJson )
(def (find-structural-interface-row rows)
  (cond
   ((null? rows) #f)
   ((equal? (hash-get (car rows) 'ownerPath) +structural-interface-owner-path+)
    (car rows))
   (else (find-structural-interface-row (cdr rows)))))
;;; Invariant:
;;; - Presence checks compare the stable ownerPath key only.
;;; - The ormap predicate keeps preview membership expression-level and avoids
;;;   a manual loop that could drift from the same ownerPath invariant.
;; : (-> (List Json) Json Boolean )
(def (structural-interface-row-present? rows required)
  (ormap (lambda (row)
           (equal? (hash-get row 'ownerPath)
                   (hash-get required 'ownerPath)))
         rows))

;;; Owner mode projects one source file's parser facts for ASP-side fan-out.
;;; It may render native facts, but it never builds the workspace artifact or
;;; graph/index topology inside the Scheme provider.
;; : (-> ProjectIndex OwnerPath Json Integer )
(def (emit-structural-owner-facts index owner json?)
  (let (file (find-owner index owner))
    (unless file (error "owner not found" owner))
    (let* ((packet (native-syntax-owner-facts-packet-json index file))
           (facts (hash-get packet 'facts)))
      (if json?
        (write-json-line packet)
        (begin
          (displayln "[gerbil-search-structural-owner] root="
                     (project-index-root index)
                     " owner=" (source-file-path file)
                     " facts=" (length facts)
                     " schemaId=" (hash-get packet 'schemaId))
          (emit-structural-syntax-fact-lines facts)
          (displayln "nextCommand=asp gerbil-scheme search owner <owner-path> items --query <symbol> --workspace . --view seeds")))))
  0)

;;; Artifact mode is explicit validation/debug transport.
;;; The complete syntaxFacts packet remains available for schema tests, but it
;;; is not the agent-facing default and is not part of the hot performance path.
;; : (-> ProjectIndex Json Integer )
(def (emit-structural-artifact index json?)
  (let* ((packet (structural-index-artifact-packet-json index))
         (file-hashes (hash-get packet 'fileHashes))
         (owners (hash-get packet 'owners))
         (symbols (hash-get packet 'symbols))
         (syntax-facts (hash-get packet 'syntaxFacts))
         (dependency-usages (hash-get packet 'dependencyUsages)))
    (if json?
      (write-json-line packet)
      (begin
        (displayln "[gerbil-search-structural-artifact] root="
                   (project-index-root index)
                   " generationId=" (hash-get packet 'generationId)
                   " mode=" (hash-get packet 'indexMode)
                   " files=" (length file-hashes)
                   " owners=" (length owners)
                   " symbols=" (length symbols)
                   " syntaxFacts=" (length syntax-facts)
                   " dependencyUsages=" (length dependency-usages))
        (displayln "|artifact id=" (hash-get packet 'sourceArtifactId)
                   " schemaId=" (hash-get packet 'schemaId)
                   " rawSourceStored=false")
        (emit-structural-syntax-fact-lines syntax-facts)
        (displayln "nextCommand=gerbil-scheme-harness search structural --owner <path> --json ."))))
  0)
