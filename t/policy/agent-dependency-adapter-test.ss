;;; -*- Gerbil -*-
;;; gerbil scheme harness dependency adapter policy tests.

(import :gerbil/gambit
        :std/test
        (only-in :clan/poo/object .call)
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/policy/prototype
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(export agent-dependency-adapter-policy-test)

;; : (-> TableAdapter TableSample Boolean )
(def (table-contract-tests adapter sample)
  (let* ((updated (.call adapter .update 'alpha (lambda (value) (+ value 10)) sample 0))
         (merged (.call adapter
                        .merge
                        (lambda (_key left right) (or right left))
                        sample
                        '((beta . 3) (gamma . 4)))))
    (and (.call adapter .key? sample 'alpha)
         (equal? (.call adapter .ref sample 'alpha) 1)
         (equal? (.call adapter .ref sample 'missing (lambda _ 'fallback))
                 'fallback)
         (equal? (.call adapter .ref updated 'alpha) 11)
         (equal? (.call adapter .ref merged 'beta) 3)
         (equal? (.call adapter .foldl (lambda (_key _value count) (1+ count)) 0 sample)
                 2)
         (equal? (.call adapter .list<- (.call adapter .<-list (.call adapter .list<- sample)))
                 (.call adapter .list<- sample))
         (.call adapter .=? sample sample))))

;; : (-> Boolean )
(def (slot-prototype-table-contract-witness)
  (table-contract-tests SlotPrototypeTable. '((alpha . 1) (beta . 2))))

;; PolicyTest
(def agent-dependency-adapter-policy-test
  (test-suite "gerbil scheme harness dependency adapter policy"
    (test-case "slot prototype table adapter has generic contract witness"
          (let* ((sample '((alpha . 1) (beta . 2)))
                 (updated (.call SlotPrototypeTable.
                                  .update
                                  'alpha
                                  (lambda (value) (+ value 10))
                                  sample
                                  0))
                 (merged (.call SlotPrototypeTable.
                                 .merge
                                 (lambda (_key left right) (or right left))
                                 sample
                                 '((beta . 3) (gamma . 4)))))
            (check (.call SlotPrototypeTable. .ref sample 'alpha) => 1)
            (check (.call SlotPrototypeTable. .ref updated 'alpha) => 11)
            (check (.call SlotPrototypeTable. .ref merged 'beta) => 3)
            (check (.call SlotPrototypeTable. .foldl
                          (lambda (_key _value count) (1+ count))
                          0
                          sample)
                   => 2)
            (check (.call SlotPrototypeTable. .list<- sample) => sample)
            (check (slot-prototype-ref sample 'missing 'fallback) => 'fallback)))
    (test-case "agent policy reports weak dependency protocol adapters"
          (let* ((root ".run/policy-dependency-protocol-adapter")
                 (_ (write-dependency-protocol-adapter-project root #f #f))
                 (index (collect-project root))
                 (findings (run-policy-checks index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-017" findings))
                 (finding (car matching))
                 (details (type-finding-details finding))
                 (repair (finding-agent-repair-json finding)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/dict.ss")
            (check (hash-get details 'styleGuide) => "dependency-protocol-adapter")
            (check (hash-get details 'dependency) => ":clan/pure/dict/orderdict")
            (check (hash-get details 'quality) => "weak")
            (check (not (not (member "typed-validation-boundary"
                                      (hash-get details 'missingEvidence))))
                   => #t)
            (check (not (not (member "generic-contract-test-witness"
                                      (hash-get details 'missingEvidence))))
                   => #t)
            (check (hash-get details 'manualObjectEncodingRisk) => "none")
            (check (hash-get details 'genericContractWitnessKind)
                   => "table-protocol-contract-witness")
            (check (hash-get details 'contractWitnessKind) => "missing")
            (check (not (not (member "table"
                                      (hash-get details 'derivedCapabilities))))
                   => #t)
            (check (hash-get details 'agentRepairStandard)
                   => "current dependency already provides the bottom data structure; do not hand-write loose hash/alist objects. Build a typed protocol adapter: precise only-in imports for primitives, define-type Key/Value plus primitive methods.table slots (.empty/.ref/.acons/.remove/.foldl/.foldr), iteration/conversion/update/selection/equality/lens/serialization slots, behavior on protocol slots, derived table/set/list/iteration/lens/sexp/json/bytes/marshal capabilities when slots exist, and generic contract tests")
            (check (hash-get details 'repairAction)
                   => "search-forwarded-example-then-guide-code")
            (check (hash-get details 'guideCodeFlag) => "--code")
            (check (hash-get details 'searchExampleCommand)
                   => "asp gerbil-scheme search pattern poo rationaldict adapter --workspace . --view seeds")
            (check (hash-get details 'repairCodeCommand)
                   => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-017 --intent repair")
            (check (hash-get details 'codeShapeExemplar)
                   => "gerbil-poo rationaldict-style typed protocol adapter")
            (check (hash-get details 'profileComposition)
                   => "clan/list c3-compute-precedence-list + clan/poo/proto compose-proto*")
            (check (hash-get details 'profileOverlays)
                   => ["dependency-protocol-surface"
                       "dependency-poo-lineage"
                       "dependency-build-cli-lineage"
                       "dependency-repair-commands"])
            (check (hash-get details 'profilePrecedence)
                   => ["dependency-adapter-standard"
                       "dependency-profile-composition"
                       "dependency-repair-commands"
                       "dependency-build-cli-lineage"
                       "dependency-poo-lineage"
                       "dependency-protocol-surface"])
            (check (hash-get details 'sourcePatternLineage)
                   => "gerbil-poo build/cli/rationaldict/table/brace/object/mop/io patterns")
            (check (hash-get details 'protocolSurface)
                   => "minimal protocol slots first; derive table/set/list/iteration/lens/sexp/json/bytes/marshal-facing capabilities from the slot surface")
            (check (hash-get details 'protocolSurfaceReference)
                   => "gerbil-poo table.ss methods.table")
            (check (hash-get details 'methodTablePrimitiveSlots)
                   => [".empty" ".ref" ".acons" ".remove" ".foldl" ".foldr"])
            (check (not (not (member "update/merge: .acons/opt .merge .union .join .join/list .update/opt .update"
                                      (hash-get details 'methodTableDerivedFamilies))))
                   => #t)
            (check (not (not (member "iteration/fold: .for-each .for-each/reverse .<-iter .iter<-"
                                      (hash-get details 'methodTableDerivedFamilies))))
                   => #t)
            (check (not (not (member "lens/binding: .lens .Binding .Bindings"
                                      (hash-get details 'methodTableDerivedFamilies))))
                   => #t)
            (check (not (not (member "set algebra: .union .inter .diff .compare"
                                      (hash-get details 'methodTableDerivedFamilies))))
                   => #t)
            (check (hash-get details 'reusableContractTestPattern)
                   => "small t/ owner calls generic table-contract-tests or protocol-contract-tests against the adapter type descriptor")
            (check (hash-get details 'macroBridgeBoundary)
                   => "syntax forms should stay thin bridges like gerbil-poo brace.ss @method; runtime semantics belong in object/mop/protocol slots")
            (check (hash-get details 'slotResolutionModel)
                   => "POO objects resolve slots through C3 precedence plus lazy slot function cache; do not replace this with raw hash/alist guesses")
            (check (hash-get details 'ioSerializationMethodFamily)
                   => "json<-/<-json, marshal/unmarshal, bytes<-/<-bytes, and string<-/<-string are method/type slots")
            (check (hash-get details 'buildPattern)
                   => "use :std/make + :clan/base + :clan/building discovery, while filtering non-module policy/config files for this harness")
            (check (hash-get details 'cliOptionPattern)
                   => "keep src/cli.ss as a thin dispatcher; compose option objects when command option surfaces grow")
            (check (not (not (string-contains
                              (hash-get details 'adapterRepairShape)
                              "query the search-forwarded rationaldict adapter example first")))
                   => #t)
            (check (not (not (member "run asp gerbil-scheme search pattern poo rationaldict adapter --workspace . --view seeds to inspect the dependency example before editing"
                                      (hash-get details 'allowedMoves))))
                   => #t)
            (check (not (not (member "run asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-017 --intent repair to inspect local R017 parser/policy repair code"
                                      (hash-get details 'allowedMoves))))
                   => #t)
            (check (not (not (member "derive table/set/list/iteration/lens/sexp/json/bytes/marshal-facing capability from protocol slots"
                                      (hash-get details 'allowedMoves))))
                   => #t)
            (check (not (not (member "do not replace dependency primitives with hand-written hash/alist storage"
                                      (hash-get details 'disallowedMoves))))
                   => #t)
            (check (hash-get repair 'guideTopic) => "dependency-protocol-adapter")
            (check (hash-get repair 'nextCommand)
                   => "asp gerbil-scheme search pattern poo rationaldict adapter --workspace . --view seeds")))
    (test-case "agent policy rejects manual object encoding inside dependency adapters"
          (let* ((root ".run/policy-dependency-manual-object-adapter")
                 (_ (write-dependency-manual-object-adapter-project root))
                 (index (collect-project root))
                 (facts (project-dependency-adapter-quality-facts index))
                 (fact (car facts))
                 (findings (run-policy-checks index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-017" findings))
                 (finding (car matching))
                 (details (type-finding-details finding)))
            (check (not (not (member ".remove"
                                      (dependency-adapter-quality-fact-slots fact))))
                   => #t)
            (check (not (not (member ".foldr"
                                      (dependency-adapter-quality-fact-slots fact))))
                   => #t)
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/dict.ss")
            (check (hash-get details 'manualObjectEncodingRisk)
                   => "manual-object-encoding-risk")
            (check (not (not (member "manual-object-encoding-risk"
                                      (hash-get details 'missingEvidence))))
                   => #t)
            (check (not (not (member "no-manual-object-encoding"
                                      (hash-get details 'qualityFacets))))
                   => #f)))
    (test-case "agent policy accepts complete dependency protocol adapters with contract witnesses"
          (let* ((root ".run/policy-dependency-protocol-adapter-positive")
                 (_ (write-dependency-protocol-adapter-project root #t #t))
                 (index (collect-project root))
                 (facts (project-dependency-adapter-quality-facts index))
                 (fact (car facts))
                 (findings (run-policy-checks index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-017" findings)))
            (check (length facts) => 1)
            (check (dependency-adapter-quality-fact-quality fact) => "complete")
            (check (not (not (member "precise-only-in-import"
                                      (dependency-adapter-quality-fact-quality-facets fact))))
                   => #t)
            (check (not (not (member "table"
                                      (dependency-adapter-quality-fact-derived-capabilities fact))))
                   => #t)
            (check (dependency-adapter-quality-fact-manual-object-encoding-risk fact)
                   => "none")
            (check (dependency-adapter-quality-fact-generic-contract-witness-kind fact)
                   => "table-protocol-contract-witness")
            (check (not (not (member ".remove"
                                      (dependency-adapter-quality-fact-slots fact))))
                   => #t)
            (check (not (not (member ".foldr"
                                      (dependency-adapter-quality-fact-slots fact))))
                   => #t)
            (check matching => [])))
    (test-case "agent policy accepts generic witnesses that pass POO adapters as values"
          (let* ((root ".run/policy-dependency-protocol-adapter-argument-witness")
                 (_ (write-dependency-protocol-adapter-argument-witness-project root))
                 (index (collect-project root))
                 (facts (project-dependency-adapter-quality-facts index))
                 (fact (car facts))
                 (findings (run-policy-checks index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-017" findings)))
            (check (length facts) => 1)
            (check (dependency-adapter-quality-fact-quality fact) => "complete")
            (check matching => [])))))
