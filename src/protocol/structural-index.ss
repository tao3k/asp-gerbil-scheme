;;; -*- Gerbil -*-
;;; Lightweight structural index interface packets.

(import :asp-gerbil-scheme/src/constants
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/protocol/structural-facts
        (only-in :std/misc/list unique)
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 append-map take)
        (only-in :std/srfi/13 string-join)
        (only-in :std/sugar cut foldl hash hash-put! with-catch))

(export structural-index-packet-json
        structural-index-artifact-packet-json
        native-syntax-owner-facts-packet-json
        +semantic-structural-index-schema-id+
        +semantic-native-syntax-fact-index-schema-id+)

;; String
(def +semantic-structural-index-schema-id+
  "agent.semantic-protocols.semantic-structural-index")
;; String
(def +semantic-native-syntax-fact-index-schema-id+
  "agent.semantic-protocols.semantic-native-syntax-fact-index")
;; String
(def +semantic-language-protocol-id+
  "agent.semantic-protocols.semantic-language")
;; String
(def +structural-interface-required-owner-path+
  "src/commands/projection.ss")
;; Integer
(def +structural-interface-summary-preview-limit+ 20)

;;; Interface packet is the hot path: stable handles, counts, and commands.
;;; It avoids workspace syntaxFacts materialization because this provider
;;; exposes parser/interface facts, not a graph or ranking service.
;; : (-> ProjectIndex Json )
(def (structural-index-packet-json index)
  (let* ((files (project-index-files index))
         (summaries (map structural-interface-summary-json files))
         (generation-id
          (structural-interface-generation-id/summaries summaries))
         (artifact-id (string-append "structural-index/" generation-id ".json"))
         (symbol-total
          (structural-interface-summary-total summaries 'symbolCount))
         (fact-total
          (structural-interface-summary-total summaries 'facts))
         (dependency-total
          (structural-interface-summary-total summaries 'dependencyCount)))
    (hash
     (schemaId +semantic-structural-index-schema-id+)
     (schemaVersion "1")
     (protocolId +semantic-language-protocol-id+)
     (protocolVersion "1")
     (generationId generation-id)
     (languageId +language-id+)
     (providerId +provider-id+)
     (providerVersion "0.1.0")
     (exportMethod "index/structural")
     (projectRoot (project-index-root index))
     (packageRoot ".")
     (sourceAuthority "native-parser")
     (sourceArtifactId artifact-id)
     (rawSourceStored #f)
     (indexMode "interface")
     (fileHashes (map structural-interface-summary-file-hash-json summaries))
     (owners (map structural-owner-json files))
     (symbols [])
     (symbolTotal symbol-total)
     (syntaxFacts [])
     (nativeSyntaxFactTotal fact-total)
     (nativeSyntaxFactSummaries
      (map native-syntax-fact-summary-json
           (structural-interface-summary-source-files files)))
     (factInterface
      (structural-fact-interface-json index generation-id))
     (dependencyUsages [])
     (dependencyUsageTotal dependency-total))))

;;; Artifact packet is explicit validation/debug transport.
;;; It preserves the complete syntaxFacts shape while keeping that cost outside
;;; the default search and benchmark path.
;; : (-> ProjectIndex Json )
(def (structural-index-artifact-packet-json index)
  (let* ((generation-id (structural-index-generation-id index))
         (artifact-id (string-append "structural-index/" generation-id ".json"))
         (files (project-index-files index)))
    (hash
     (schemaId +semantic-structural-index-schema-id+)
     (schemaVersion "1")
     (protocolId +semantic-language-protocol-id+)
     (protocolVersion "1")
     (generationId generation-id)
     (languageId +language-id+)
     (providerId +provider-id+)
     (providerVersion "0.1.0")
     (exportMethod "index/structural")
     (projectRoot (project-index-root index))
     (packageRoot ".")
     (sourceAuthority "native-parser")
     (sourceArtifactId artifact-id)
     (rawSourceStored #f)
     (indexMode "artifact")
     (fileHashes (map (cut structural-file-hash-json index <>) files))
     (owners (map structural-owner-json files))
     (symbols (append-map structural-symbol-json files))
     (syntaxFacts (json-rows-by-id
                   (append-map structural-syntax-fact-json files)))
     (dependencyUsages (append-map structural-dependency-json files)))))

;;; Owner fact packet is the ASP fan-out unit.
;;; One owner keeps projection cost bounded and leaves any server-side
;;; aggregation, cache invalidation, and topology decisions outside this
;;; provider-local packet.
;; : (-> ProjectIndex SourceFile Json )
(def (native-syntax-owner-facts-packet-json index file)
  (let* ((package (project-index-package index))
         (facts (structural-syntax-fact-json file))
         (packet
          (hash
           (schemaId +semantic-native-syntax-fact-index-schema-id+)
           (schemaVersion "1")
           (protocolId +semantic-language-protocol-id+)
           (protocolVersion "1")
           (languageId +language-id+)
           (providerId +provider-id+)
           (projectRoot (project-index-root index))
           (scope "owner")
           (query (source-file-path file))
           (facts facts)
           (indexes (native-syntax-index-descriptors))
           (notes
            [(hash
              (kind "ownership-boundary")
              (message "This packet is owner-bounded parser evidence emitted by the Gerbil Scheme provider."))]))))
    (when package
      (hash-put! packet 'packageName (project-package-name package)))
    packet))

;; NativeSyntaxIndexDescriptors
(def (native-syntax-index-descriptors)
  [(hash (name "owner")
         (factKinds ["import" "export" "macro" "binding" "function"
                     "method" "class" "interface" "call" "custom" "comment"])
         (queryKeys ["ownerPath" "name" "languageKind"])
         (fields (hash (granularity "owner-bounded"))))
   (hash (name "quality")
         (factKinds ["function" "call" "custom" "comment"])
         (queryKeys ["typed-combinator-style"
                     "engineering-comment-quality"
                     "gerbil-utils-combinator-style"
                     "dependency-protocol-adapter"])
         (fields (hash (granularity "provider-local"))))])

;; : (-> ProjectIndex GenerationId Json )
(def (structural-fact-interface-json index generation-id)
  (hash
   (mode "lightweight-provider-interface")
   (granularity "workspace-manifest-plus-owner-facts")
   (producer +provider-id+)
   (factSchemaId +semantic-native-syntax-fact-index-schema-id+)
   (generationId generation-id)
   (manifestCommand "asp-gerbil-scheme projection --native-index --json --workspace .")
   (ownerFactsCommand
    "asp-gerbil-scheme projection --native-index --owner <path> --json --workspace .")
   (artifactCommand
    "asp-gerbil-scheme projection --native-index --artifact --json --workspace .")
   (performanceContract
    "Packet rendering and owner fact projection should stay millisecond-level after native parsing; full graph/index construction belongs to ASP Rust.")
   (projectRoot (project-index-root index))))

;;; Total facts is a cheap fold over already parsed owner structures.
;;; It gives ASP a workspace-size signal without forcing full fact JSON.
;; : (-> (List SourceFile) Integer )
(def (native-syntax-fact-total files)
  (foldl (lambda (file total)
           (+ total (source-file-native-syntax-fact-count file)))
         0
         files))

;;; Symbol totals are cheap scheduling signals for ASP Rust.
;;; Default interface mode does not materialize workspace symbol rows.
;; : (-> (List SourceFile) Integer )
(def (structural-symbol-total files)
  (foldl (lambda (file total)
           (+ total (length (source-file-definitions file))))
         0
         files))

;;; Dependency totals keep graph size visible without exporting edge rows.
;;; Full dependency rows stay on the explicit artifact path.
;; : (-> (List SourceFile) Integer )
(def (structural-dependency-total files)
  (foldl (lambda (file total)
           (+ total
              (length (source-file-imports file))
              (length (source-file-includes file))))
         0
         files))

;;; Owner summaries are the manifest rows consumed by ASP before fan-out.
;;; Family counts guide Rust-side scheduling and cache invalidation without
;;; moving heavy graph construction into Scheme.
;; : (-> SourceFile Json )
(def (native-syntax-fact-summary-json file)
  (hash
   (ownerPath (source-file-path file))
   (facts (source-file-native-syntax-fact-count file))
   (ownerFactsCommand
    (string-append "asp-gerbil-scheme projection --native-index --owner "
                   (source-file-path file)
                   " --json --workspace ."))))

;;; Interface summaries are the single owner pass used by the hot packet path.
;;; Counts, dependency totals, and fingerprints reuse this row so benchmarked
;;; interface rendering does not rescan every fact family.
;; : (-> SourceFile Json)
(def (structural-interface-summary-json file)
  (let* ((fact-count (source-file-native-syntax-fact-count file))
         (symbol-count (length (source-file-definitions file)))
         (dependency-count (+ (length (source-file-imports file))
                              (length (source-file-includes file))))
         (fingerprint
          (stable-hex64
           (string-join [(source-file-path file)
                         (number->string (source-file-line-count file))
                         (or (source-file-package file) "")
                         (or (source-file-namespace file) "")
                         (number->string symbol-count)
                         (number->string dependency-count)
                         (number->string fact-count)]
                        "|"))))
    (hash
     (ownerPath (source-file-path file))
     (facts fact-count)
     (symbolCount symbol-count)
     (dependencyCount dependency-count)
     (fingerprint fingerprint)
     (ownerFactsCommand
      (string-append "asp-gerbil-scheme projection --native-index --owner "
                     (source-file-path file)
                     " --json --workspace .")))))

;; : (-> (List Json) Symbol Integer)
(def (structural-interface-summary-total summaries key)
  (foldl (lambda (summary total)
           (+ total (hash-get summary key)))
         0
         summaries))

;;; Fact summaries are an interface preview, not a workspace fact manifest.
;;; ASP gets the complete owner list from `owners` and requests full facts with
;;; the owner-bounded command.
;; : (-> (List SourceFile) (List SourceFile))
(def (structural-interface-summary-source-files files)
  (let ((head (take files
                    (min +structural-interface-summary-preview-limit+
                         (length files))))
        (required (find-structural-interface-summary-source-file files)))
    (cond
     ((not required) head)
     ((structural-interface-source-file-present? head required) head)
     (else
      (append (take head
                    (min (- +structural-interface-summary-preview-limit+ 1)
                         (length head)))
              [required])))))

;; : (-> (List SourceFile) MaybeSourceFile)
(def (find-structural-interface-summary-source-file files)
  (cond
   ((null? files) #f)
   ((equal? (source-file-path (car files))
            +structural-interface-required-owner-path+)
    (car files))
   (else (find-structural-interface-summary-source-file (cdr files)))))

;; : (-> (List SourceFile) SourceFile Boolean)
(def (structural-interface-source-file-present? files required)
  (ormap (lambda (file)
           (equal? (source-file-path file)
                   (source-file-path required)))
         files))

;;; Fact count mirrors the owner packet families exactly.
;;; Counting struct lists is intentionally cheaper than rendering fact payloads.
;; : (-> SourceFile Integer )
(def (source-file-native-syntax-fact-count file)
  (+ (length (source-file-module-imports file))
     (length (source-file-module-exports file))
     (length (source-file-macros file))
     (length (source-file-bindings file))
     (length (source-file-poo-forms file))
     (length (source-file-higher-order-forms file))
     (length (source-file-control-flow-forms file))
     (length (source-file-predicate-family-facts file))
     (length (source-file-field-access-pattern-facts file))
     (length (source-file-boolean-condition-facts file))
     (length (source-file-loop-driver-facts file))
     (length (source-file-dependency-adapter-quality-facts file))
     (length (source-file-function-quality-profiles file))
     (length (source-file-typed-contract-facts file))
     (length (source-file-comment-quality-facts file))
     (length (source-file-calls file))))

;;; Family counts keep parser capabilities visible at owner granularity.
;;; ASP can decide which owners need graph-turbo analysis from these fields.
;; : (-> SourceFile Json )
(def (source-file-native-syntax-family-counts file)
  (hash
   (moduleImports (length (source-file-module-imports file)))
   (moduleExports (length (source-file-module-exports file)))
   (macros (length (source-file-macros file)))
   (bindings (length (source-file-bindings file)))
   (pooForms (length (source-file-poo-forms file)))
   (higherOrderForms (length (source-file-higher-order-forms file)))
   (controlFlowForms (length (source-file-control-flow-forms file)))
   (predicateFamilyFacts (length (source-file-predicate-family-facts file)))
   (fieldAccessPatternFacts
    (length (source-file-field-access-pattern-facts file)))
   (booleanConditionFacts (length (source-file-boolean-condition-facts file)))
   (loopDriverFacts (length (source-file-loop-driver-facts file)))
   (dependencyAdapterQualityFacts
    (length (source-file-dependency-adapter-quality-facts file)))
   (functionQualityProfiles
    (length (source-file-function-quality-profiles file)))
   (typedContractFacts (length (source-file-typed-contract-facts file)))
   (commentQualityFacts (length (source-file-comment-quality-facts file)))
   (calls (length (source-file-calls file)))))

;;; Artifact rows are globally sorted only on the explicit artifact path.
;;; Interface mode avoids this cost and leaves workspace indexing to ASP Rust.
;; : (-> (List JsonRow) (List JsonRow) )
(def (json-rows-by-id rows)
  (sort rows
        (lambda (a b)
          (string<? (hash-get a 'id) (hash-get b 'id)))))

;;; Artifact generation uses full parser fingerprints for validation stability.
;;; This path is intentionally outside the hot search and bench interface.
;; : (-> ProjectIndex String )
(def (structural-index-generation-id index)
  (string-append
   +language-id+
   "-structural-"
   (substring (stable-hex64
               (string-join (map (cut structural-file-fingerprint index <>)
                          (project-index-files index))
                     "|"))
              0
              16)))

;;; Interface generation uses cheap owner summary fingerprints.
;;; It changes when owner counts or package shape change, but avoids full fact
;;; rendering and sorting.
;; : (-> ProjectIndex String )
(def (structural-interface-generation-id index)
  (structural-interface-generation-id/summaries
   (map structural-interface-summary-json (project-index-files index))))

;; : (-> (List Json) String)
(def (structural-interface-generation-id/summaries summaries)
  (string-append
   +language-id+
   "-structural-interface-"
   (substring
    (stable-hex64
     (string-join
      (map (lambda (summary) (hash-get summary 'fingerprint)) summaries)
      "|"))
    0
    16)))

;;; Interface file hashes are summary hashes, not source-content hashes.
;;; The source marker makes that contract explicit for ASP cache consumers.
;; : (-> SourceFile Json )
(def (structural-interface-file-hash-json file)
  (structural-interface-summary-file-hash-json
   (structural-interface-summary-json file)))

;; : (-> Json Json)
(def (structural-interface-summary-file-hash-json summary)
  (hash (path (hash-get summary 'ownerPath))
        (sha256 (hash-get summary 'fingerprint))
        (source "native-parser-interface-fingerprint")))

;;; The interface fingerprint is based on stable owner metadata and counts.
;;; It is cheap enough for the manifest path and precise enough to schedule
;;; owner-fact refreshes.
;; : (-> SourceFile String )
(def (structural-interface-file-fingerprint file)
  (stable-hex64
   (string-join [(source-file-path file)
          (number->string (source-file-line-count file))
          (or (source-file-package file) "")
          (or (source-file-namespace file) "")
          (number->string (length (source-file-definitions file)))
          (number->string (length (source-file-imports file)))
          (number->string (length (source-file-exports file)))
          (number->string (source-file-native-syntax-fact-count file))]
         "|")))

;;; Artifact file hashes use the full parser fact fingerprint.
;;; They are reserved for explicit validation artifacts, not default search.
;; : (-> ProjectIndex SourceFile Json )
(def (structural-file-hash-json index file)
  (hash (path (source-file-path file))
        (sha256 (structural-file-fingerprint index file))
        (source "native-parser-fingerprint")))

;;; Full fingerprints prefer parser facts and fall back to source lines.
;;; The fallback exists only for artifact validation when fact-string assembly
;;; cannot cover a malformed owner.
;; : (-> ProjectIndex SourceFile StructuralFileFingerprint )
(def (structural-file-fingerprint index file)
  (with-catch
   (lambda (_)
     (stable-hex64 (structural-file-fact-string file)))
   (lambda ()
     (stable-hex64
      (string-join (read-file-lines
             (path-expand (source-file-path file)
                          (project-index-root index)))
            "\n")))))

;;; Fact strings collect stable parser-owned names, not raw source text.
;;; Artifact fingerprints therefore reflect semantic evidence shape without
;;; storing source payloads.
;; : (-> SourceFile String )
(def (structural-file-fact-string file)
  (string-join [(source-file-path file)
         (number->string (source-file-line-count file))
         (or (source-file-package file) "")
         (or (source-file-namespace file) "")
         (string-join (source-file-imports file) ",")
         (string-join (source-file-exports file) ",")
         (string-join (map definition-name (source-file-definitions file)) ",")
         (string-join (map call-fact-callee (source-file-calls file)) ",")
         (string-join (map macro-fact-name (source-file-macros file)) ",")
         (string-join (map binding-fact-name (source-file-bindings file)) ",")
         (string-join (map poo-form-fact-name (source-file-poo-forms file)) ",")
         (string-join (map higher-order-fact-name
                    (source-file-higher-order-forms file)) ",")
         (string-join (map dependency-adapter-quality-fact-name
                    (source-file-dependency-adapter-quality-facts file)) ",")]
        "|"))

;;; Owner rows are the manifest's stable workspace handles.
;;; Query keys include path, package, imports, and definitions so ASP can rank
;;; owners without requesting full owner facts first.
;; : (-> SourceFile Json )
(def (structural-owner-json file)
  (hash (ownerPath (source-file-path file))
        (ownerKind "source")
        (sourceAuthority "native-parser")
        (location (hash (path (source-file-path file))
                        (lineRange (string-append
                                    "1:"
                                    (number->string
                                     (max 1 (source-file-line-count file)))))))
        (queryKeys (unique (append [(source-file-path file)]
                                   (if (source-file-package file)
                                     [(source-file-package file)]
                                     '())
                                   (source-file-imports file)
                                   (map definition-name
                                        (source-file-definitions file)))))))

;;; Symbol rows are lightweight definition handles for the manifest.
;;; Qualified names are derived from parser namespace/package evidence and stay
;;; cheaper than full syntax fact projection.
;; : (-> SourceFile Json )
(def (structural-symbol-json file)
  (map (lambda (defn)
         (hash (ownerPath (definition-path defn))
               (name (definition-name defn))
               (qualifiedName (structural-qualified-name file defn))
               (kind (definition-kind defn))
               (visibility (if (member (definition-name defn)
                                       (source-file-exports file))
                             "public"
                             "private"))
               (sourceLocator (definition-selector defn))
               (queryKeys (unique [(definition-name defn)
                                   (structural-qualified-name file defn)
                                   (definition-kind defn)
                                   (definition-path defn)]))))
       (source-file-definitions file)))

;; : (-> SourceFile Definition StructuralQualifiedName )
(def (structural-qualified-name file defn)
  (let (ns (or (source-file-namespace file)
               (source-file-package file)
               (source-file-path file)))
    (string-append ns "::" (definition-name defn))))

;;; Dependency rows expose parser-owned imports and includes.
;;; ASP uses these as graph edges later.
;;; Scheme only reports the observed owner and module reference.
;; : (-> SourceFile Integer )
(def (structural-dependency-json file)
  (append
   (map (lambda (module-ref)
          (structural-dependency-row file module-ref "native-parser-import"))
        (source-file-imports file))
   (map (lambda (include-ref)
          (structural-dependency-row file include-ref "native-parser-include"))
        (source-file-includes file))))

;; : (-> SourceFile ModuleRef Source Integer )
(def (structural-dependency-row file module-ref source)
  (hash (ownerPath (source-file-path file))
        (packageName module-ref)
        (apiName module-ref)
        (importPath module-ref)
        (manifestPath "gerbil.pkg")
        (source source)
        (sourceLocator (string-append (source-file-path file) ":1:1"))
        (queryKeys (unique [module-ref (source-file-path file) source]))))

;; : (-> SourceLine StableHex64 )
(def (stable-hex64 text)
  (let (chunk (left-pad-hex (number->string (stable-hash text) 16) 16))
    (string-append chunk chunk chunk chunk)))

;; : (-> SourceLine StableHash )
(def (stable-hash text)
  (foldl (lambda (ch hash)
           (modulo (+ (* hash 16777619) (char->integer ch))
                   4294967296))
         2166136261
         (string->list text)))

;; : (-> SourceLine Width LeftPadHex )
(def (left-pad-hex text width)
  (if (fx>= (string-length text) width)
    text
    (left-pad-hex (string-append "0" text) width)))
