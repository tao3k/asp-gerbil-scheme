;;; -*- Gerbil -*-
;;; Parser-owned dependency protocol adapter quality facts.

(import :gerbil/expander
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/support
        (only-in :std/misc/list unique)
        (only-in :std/misc/string string-trim-suffix)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-contains string-prefix? string-suffix?))

(export dependency-adapter-candidates-from-form
        dependency-adapter-quality-facts-from-candidates)

;; DependencyAdapterCandidateStruct
(defstruct dependency-adapter-candidate (name path start end protocol-refs slots body-symbols))
;; DependencyAdapterMaterializationStruct
(defstruct dependency-adapter-materialization
  (matched-imports primary used-symbols derived-capabilities manual-object-risk facets missing quality))

;; (List String)
(def +internal-module-prefixes+
  '("." ":std/" ":gerbil/" ":parser/" ":policy/" ":protocol/"
    ":support/" ":types/" ":commands/" ":checker/" ":snapshot/"
    ":language/" ":extensions/" ":package-manager/" ":asp-gerbil-scheme/src/constants"))

;; (List String)
(def +validation-slots+ '(".validate" ".element?"))
;; (List String)
(def +conversion-slots+
  '(".list<-" ".<-list" ".sexp<-" ".<-sexp" ".json<-" ".<-json"
    ".bytes<-" ".<-bytes" ".marshal" ".unmarshal"))
;; (List String)
(def +equality-slots+ '(".=?" ".equal?"))
;; (List String)
(def +core-table-slots+
  '(".empty" ".empty?" ".ref" ".key?" ".acons" ".remove" ".foldl" ".foldr"))
;; (List String)
(def +set-capability-slots+ '(".empty?" ".key?" ".remove" ".contains?"))
;; (List String)
(def +list-capability-slots+ '(".list<-" ".<-list"))
;; (List String)
(def +json-capability-slots+ '(".json<-" ".<-json"))
;; (List String)
(def +sexp-capability-slots+ '(".sexp<-" ".<-sexp"))
;; (List String)
(def +marshal-capability-slots+ '(".marshal" ".unmarshal" ".bytes<-" ".<-bytes"))
;; (List String)
(def +manual-object-encoding-symbols+
  '("hash" "make-hash-table" "list->hash-table" "hash-get" "hash-put!"
    "hash-ref" "hash-set!" "alist" "assoc" "assq"))

;;; Form pass: record define-type adapter candidates with source ranges.
;;; Import matching happens after the file pass so only-in dependency evidence
;;; can be joined without re-reading source.
;; : (-> Relpath Form Datum (List DependencyAdapterCandidate) )
(def (dependency-adapter-candidates-from-form relpath form datum)
  (let (head (and (pair? datum) (car datum)))
    (if (eq? head 'define-type)
      (let* ((spec (safe-cadr datum))
             (name (define-type-name spec))
             (loc (stx-source form)))
        (if name
          [(make-dependency-adapter-candidate
            name
            relpath
            (source-start-line loc)
            (source-end-line loc)
            (define-type-protocol-refs spec)
            (define-type-slots datum)
            (define-type-body-symbols datum))]
          '()))
      '())))

;; : (-> Datum String )
(def (define-type-name spec)
  (cond
   ((symbol? spec) (datum->string spec))
   ((and (pair? spec) (symbol? (car spec))) (datum->string (car spec)))
   (else #f)))

;;; Boundary:
;;; - Protocol refs are shape tokens from define-type metadata.
;;; - Nested specs are flattened once, then filtered to durable protocol names.
;; : (-> Datum (List String) )
(def (define-type-protocol-refs spec)
  (if (pair? spec)
    (unique
     (filter protocol-ref-token?
             (filter string?
                     (map datum->string (flatten (cdr spec))))))
    '()))

;; : (-> String Boolean )
(def (protocol-ref-token? token)
  (and (not (member token '("@" "[]")))
       (not (string-suffix? ":" token))))

;;; Slot extraction intentionally keeps field and method slots in one list.
;;; Policy can distinguish Key/Value fields from method slots through names,
;;; while search can still explain the whole adapter surface.
;; : (-> Datum (List String) )
(def (define-type-slots datum)
  (unique
   (filter-map slot-token (safe-cddr datum))))

;; : (-> Datum SlotName )
(def (slot-token item)
  (cond
   ((keyword? item) (string-trim-suffix ":" (datum->string item)))
   ((symbol? item)
    (let (text (symbol->string item))
      (and (or (string-prefix? "." text)
               (string-suffix? ":" text))
           (string-trim-suffix ":" text))))
   (else #f)))

;;; Boundary:
;;; - Body symbol extraction feeds import-use joins.
;;; - Keep this as a pure token projection so adapter evidence stays parser-owned.
;; : (-> Datum (List String) )
(def (define-type-body-symbols datum)
  (unique
   (filter string?
           (map datum->string (flatten (safe-cddr datum))))))

;;; Materialization pass: only emit facts when a define-type body uses imported
;;; dependency primitives. This prevents std/local helper imports from becoming
;;; noisy adapter facts.
;; : (-> Relpath Candidates Imports (List DependencyAdapterQualityFact) )
(def (dependency-adapter-quality-facts-from-candidates relpath candidates imports)
  (filter-map
   (lambda (candidate)
     (dependency-adapter-quality-fact-from-candidate relpath imports candidate))
   candidates))

;;; Boundary:
;;; - Candidate materialization joins define-type shape with precise imports.
;;; - Emit one fact only when dependency usage is proven by imported symbols.
;;; - Quality remains evidence data.
;;; - Policy decides whether repair is required.
;; : (-> Relpath Imports DependencyAdapterCandidate DependencyAdapterQualityFact )
(def (dependency-adapter-quality-fact-from-candidate relpath imports candidate)
  (let (materialization
        (dependency-adapter-materialization-from-candidate imports candidate))
    (and materialization
         (dependency-adapter-quality-fact-from-materialization
          relpath
          candidate
          materialization))))

;; : (-> Imports DependencyAdapterCandidate DependencyAdapterMaterialization )
(def (dependency-adapter-materialization-from-candidate imports candidate)
  (let* ((matched-imports
          (dependency-adapter-matched-imports
           imports
           (dependency-adapter-candidate-body-symbols candidate)))
         (primary (primary-dependency-import matched-imports
                                             (dependency-adapter-candidate-body-symbols candidate))))
    (and primary
         (dependency-adapter-materialization-from-matches
          candidate
          matched-imports
          primary))))

;;; Boundary:
;;; - Materialization freezes all evidence derived from matched dependency imports.
;;; - Quality, missing evidence, and capability facets must be computed together.
;;; - Later packet projection must not recompute these fields differently.
;; : (-> DependencyAdapterCandidate Imports ModuleImportFact DependencyAdapterMaterialization )
(def (dependency-adapter-materialization-from-matches candidate matched-imports primary)
  (let* ((used-symbols
          (dependency-adapter-used-symbols
           matched-imports
           (dependency-adapter-candidate-body-symbols candidate)))
         (derived-capabilities
          (dependency-adapter-derived-capabilities candidate used-symbols))
         (manual-object-risk
          (dependency-adapter-manual-object-encoding-risk
           candidate
           used-symbols))
         (facets
          (dependency-adapter-quality-facets candidate
                                             matched-imports
                                             used-symbols
                                             derived-capabilities
                                             manual-object-risk))
         (missing
          (dependency-adapter-missing-evidence candidate
                                               matched-imports
                                               used-symbols
                                               derived-capabilities
                                               manual-object-risk))
         (quality (dependency-adapter-quality missing facets)))
    (make-dependency-adapter-materialization
     matched-imports
     primary
     used-symbols
     derived-capabilities
     manual-object-risk
     facets
     missing
     quality)))

;;; Boundary:
;;; - Fact construction is a pure projection from materialized parser evidence.
;;; - Derived capabilities stay adjacent to dependency and protocol fields.
;;; - This keeps policy, guide, and structural JSON aligned on one fact shape.
;; : (-> Relpath DependencyAdapterCandidate DependencyAdapterMaterialization DependencyAdapterQualityFact )
(def (dependency-adapter-quality-fact-from-materialization relpath candidate materialization)
  (let ((matched-imports
         (dependency-adapter-materialization-matched-imports materialization))
        (primary (dependency-adapter-materialization-primary materialization))
        (used-symbols
         (dependency-adapter-materialization-used-symbols materialization))
        (derived-capabilities
         (dependency-adapter-materialization-derived-capabilities materialization))
        (manual-object-risk
         (dependency-adapter-materialization-manual-object-risk materialization))
        (facets (dependency-adapter-materialization-facets materialization))
        (missing (dependency-adapter-materialization-missing materialization))
        (quality (dependency-adapter-materialization-quality materialization)))
    (make-dependency-adapter-quality-fact
     (dependency-adapter-candidate-name candidate)
     "dependency-protocol-adapter"
     relpath
     (dependency-adapter-candidate-start candidate)
     (dependency-adapter-candidate-end candidate)
     "dependency-protocol-adapter"
     (module-import-fact-module primary)
     (map module-import-fact-module matched-imports)
     (dependency-adapter-imported-symbols matched-imports)
     used-symbols
     (dependency-adapter-candidate-protocol-refs candidate)
     (dependency-adapter-candidate-slots candidate)
     derived-capabilities
     manual-object-risk
     (dependency-adapter-generic-contract-witness-kind derived-capabilities)
     quality
     facets
     missing
     (dependency-adapter-advice quality missing))))

;;; Boundary:
;;; - Imported symbols are dependency API evidence, not local owner symbols.
;;; - Dedupe preserves a compact query key set for ASP graph consumers.
;; : (-> Imports (List SymbolName) )
(def (dependency-adapter-imported-symbols imports)
  (if (null? imports)
    '()
    (unique (apply append (map module-import-fact-symbols imports)))))

;;; Boundary:
;;; - Matched imports are the only dependency authority for adapter facts.
;;; - The filter prevents std/local helper imports from becoming dependency edges.
;; : (-> Imports BodySymbols (List ModuleImportFact) )
(def (dependency-adapter-matched-imports imports body-symbols)
  (filter
   (lambda (import)
     (and (dependency-module-import? import)
          (pair? (dependency-adapter-import-used-symbols import body-symbols))))
   imports))

;; : (-> ModuleImportFact Boolean )
(def (dependency-module-import? import)
  (let (module (module-import-fact-module import))
    (and module
         (not (internal-module-ref? module))
         (pair? (module-import-fact-symbols import)))))

;;; Boundary:
;;; - Internal module filtering keeps project and std helpers out of adapter facts.
;;; - Prefix membership is intentionally data-only so policy can audit the list.
;; : (-> ModuleRef Boolean )
(def (internal-module-ref? module)
  (ormap (lambda (prefix) (string-prefix? prefix module))
         +internal-module-prefixes+))

;;; Boundary:
;;; - Primary dependency selection ranks imports by proven symbol use.
;;; - Stable ordering keeps the chosen dependency deterministic for snapshots.
;; : (-> Imports BodySymbols ModuleImportFact )
(def (primary-dependency-import imports body-symbols)
  (and (pair? imports)
       (car
        (sort imports
              (lambda (left right)
                (> (dependency-adapter-import-score left body-symbols)
                   (dependency-adapter-import-score right body-symbols)))))))

;; : (-> ModuleImportFact BodySymbols Integer )
(def (dependency-adapter-import-score import body-symbols)
  (length (dependency-adapter-import-used-symbols import body-symbols)))

;;; Boundary:
;;; - Used symbols are the thin-wrapper witness.
;;; - Dedupe after fan-in so repeated import clauses do not inflate quality.
;; : (-> Imports BodySymbols (List String) )
(def (dependency-adapter-used-symbols imports body-symbols)
  (unique
   (apply append
          (map (cut dependency-adapter-import-used-symbols <> body-symbols)
               imports))))

;;; Boundary:
;;; - Per-import symbol use is a set intersection over parser facts.
;;; - No source text matching is allowed on this path.
;; : (-> ModuleImportFact BodySymbols (List String) )
(def (dependency-adapter-import-used-symbols import body-symbols)
  (filter (lambda (symbol) (member symbol body-symbols))
          (module-import-fact-symbols import)))

;;; Boundary:
;;; - Facets describe why the adapter looks like a durable protocol boundary.
;;; - The list is additive evidence, not a policy verdict.
;; : (-> Candidate Imports UsedSymbols Capabilities ManualRisk (List QualityFacet) )
(def (dependency-adapter-quality-facets candidate imports used-symbols derived-capabilities manual-object-risk)
  (let (slots (dependency-adapter-candidate-slots candidate))
    (unique
     (filter identity
             [(and (pair? imports) "dependency-protocol-adapter")
              (and (ormap precise-only-in-import? imports)
                   "precise-only-in-import")
              (and (pair? (dependency-adapter-candidate-protocol-refs candidate))
                   "declared-protocol-or-type-surface")
              (and (>= (length slots) 6) "protocol-slot-surface")
              (and (adapter-slot-any? slots +core-table-slots+)
                   "table-method-surface")
              (and (adapter-slot-any? slots +validation-slots+)
                   "typed-validation-boundary")
              (and (adapter-slot-any? slots +conversion-slots+)
                   "conversion-boundary")
              (and (adapter-slot-any? slots +equality-slots+)
                   "equality-boundary")
              (and (>= (length used-symbols) 3)
                   "thin-wrapper-over-dependency-api")
              (and (pair? derived-capabilities)
                   "protocol-derived-capability")
              (and (member "table" derived-capabilities)
                   "table-derived-capability")
              (and (member "set" derived-capabilities)
                   "set-derived-capability")
              (and (member "list" derived-capabilities)
                   "list-derived-capability")
              (and (member "json" derived-capabilities)
                   "json-derived-capability")
              (and (member "sexp" derived-capabilities)
                   "sexp-derived-capability")
              (and (member "marshal" derived-capabilities)
                   "marshal-derived-capability")
              (and (equal? manual-object-risk "none")
                   "no-manual-object-encoding")
              "poo-define-type-adapter"]))))

;;; Boundary:
;;; - Derived capabilities describe what the protocol surface exposes above the
;;;   imported primitive dependency.
;;; - Capabilities are additive facts, not requirements for every adapter.
;; : (-> Candidate UsedSymbols (List Capability) )
(def (dependency-adapter-derived-capabilities candidate used-symbols)
  (let* ((slots (dependency-adapter-candidate-slots candidate))
         (tokens (append slots
                         (dependency-adapter-candidate-protocol-refs candidate)
                         used-symbols)))
    (unique
     (filter identity
             [(and (or (adapter-slot-any? slots +core-table-slots+)
                       (tokens-contain-any? tokens ["table" "dict"]))
                   "table")
              (and (or (adapter-slot-any? slots +set-capability-slots+)
                       (tokens-contain-any? tokens ["set"]))
                   "set")
              (and (or (adapter-slot-any? slots +list-capability-slots+)
                       (tokens-contain-any? tokens ["->list" "list->" "list"]))
                   "list")
              (and (or (adapter-slot-any? slots +json-capability-slots+)
                       (tokens-contain-any? tokens ["json"]))
                   "json")
              (and (or (adapter-slot-any? slots +sexp-capability-slots+)
                       (tokens-contain-any? tokens ["sexp"]))
                   "sexp")
              (and (or (adapter-slot-any? slots +marshal-capability-slots+)
                       (tokens-contain-any? tokens ["marshal" "unmarshal" "bytes"]))
                   "marshal")]))))

;;; Boundary:
;;; - Capability inference treats dependency/API names as evidence tokens.
;;; - The predicate stays case-insensitive and expression-level so capability
;;;   additions extend the token table, not the adapter scanner.
;; : (-> (List String) (List String) Boolean )
(def (tokens-contain-any? tokens needles)
  (ormap (lambda (token) (token-contains-any? token needles))
         tokens))

;;; Boundary:
;;; - A single token can carry a qualified dependency primitive or slot name.
;;; - Substring matching is intentional here because imported APIs encode
;;;   capability families with suffixes such as ->list or unmarshal.
;; : (-> String (List String) Boolean )
(def (token-contains-any? token needles)
  (and token
       (ormap (lambda (needle) (string-contains token needle))
              needles)))

;;; Boundary:
;;; - Manual object encoding risk catches adapters that import a real data
;;;   structure dependency but still construct loose hash/alist state.
;;; - Imported symbols are excluded so a dependency primitive named hash would
;;;   not be misclassified as hand-written encoding.
;; : (-> Candidate UsedSymbols Risk )
(def (dependency-adapter-manual-object-encoding-risk candidate used-symbols)
  (let (local-symbols
        (filter (lambda (symbol) (not (member symbol used-symbols)))
                (dependency-adapter-candidate-body-symbols candidate)))
    (if (ormap (lambda (symbol)
                 (member symbol +manual-object-encoding-symbols+))
               local-symbols)
      "manual-object-encoding-risk"
      "none")))

;; : (-> (List Capability) WitnessKind )
(def (dependency-adapter-generic-contract-witness-kind derived-capabilities)
  (cond
   ((member "table" derived-capabilities) "table-protocol-contract-witness")
   ((member "json" derived-capabilities) "json-protocol-contract-witness")
   ((member "marshal" derived-capabilities) "marshal-protocol-contract-witness")
   ((member "list" derived-capabilities) "list-protocol-contract-witness")
   (else "dependency-adapter-contract-witness")))

;; : (-> ModuleImportFact Boolean )
(def (precise-only-in-import? import)
  (equal? (module-import-fact-modifier import) "only-in"))

;;; Boundary:
;;; - Slot membership keeps protocol-surface checks declarative.
;;; - Policy can extend slot families without changing traversal code.
;; : (-> Slots ExpectedSlots Boolean )
(def (adapter-slot-any? slots expected)
  (ormap (lambda (slot) (member slot slots)) expected))

;;; Boundary:
;;; - Missing evidence is the repair frontier for dependency adapters.
;;; - Each item maps to a concrete parser fact or project witness the agent can add.
;; : (-> Candidate Imports UsedSymbols Capabilities ManualRisk (List MissingEvidence) )
(def (dependency-adapter-missing-evidence candidate imports used-symbols derived-capabilities manual-object-risk)
  (let (slots (dependency-adapter-candidate-slots candidate))
    (filter identity
            [(and (not (ormap precise-only-in-import? imports))
                  "precise-only-in-import")
             (and (< (length slots) 6) "protocol-slot-surface")
             (and (not (adapter-slot-any? slots +core-table-slots+))
                  "table-method-surface")
             (and (not (adapter-slot-any? slots +validation-slots+))
                  "typed-validation-boundary")
             (and (not (adapter-slot-any? slots +conversion-slots+))
                  "conversion-boundary")
             (and (not (adapter-slot-any? slots +equality-slots+))
                  "equality-boundary")
             (and (< (length used-symbols) 3)
                  "thin-wrapper-symbol-use")
             (and (null? derived-capabilities)
                  "derived-protocol-capability")
             (and (equal? manual-object-risk "manual-object-encoding-risk")
                  "manual-object-encoding-risk")])))

;; : (-> MissingEvidence QualityFacets Quality )
(def (dependency-adapter-quality missing facets)
  (cond
   ((null? missing) "complete")
   ((and (member "dependency-protocol-adapter" facets)
         (member "protocol-slot-surface" facets))
    "partial")
   (else "weak")))

;; : (-> Quality MissingEvidence Advice )
(def (dependency-adapter-advice quality missing)
  (cond
   ((equal? quality "complete")
    "preserve the thin typed protocol adapter; add or keep contract tests as the project-level witness")
   ((member "protocol-slot-surface" missing)
    "lift dependency primitives behind a define-type protocol surface with validation, conversion, equality, and table/set style slots")
   ((member "thin-wrapper-symbol-use" missing)
    "keep the adapter thin: delegate to imported dependency primitives instead of reimplementing the data structure")
   ((member "manual-object-encoding-risk" missing)
    "remove loose hash/alist state from the adapter; delegate storage behavior to the imported dependency primitives")
   (else
    "complete the dependency adapter boundary before adding direct primitive calls elsewhere")))
