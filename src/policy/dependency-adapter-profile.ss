;;; -*- Gerbil -*-
;;; POO-composed dependency adapter repair profiles for policy payloads.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/prototype
        (only-in :std/srfi/1 take)
        (only-in :std/sugar hash))

(export dependency-adapter-profile
        dependency-adapter-profile-extend
        dependency-adapter-profile-override
        dependency-adapter-profile-ref
        dependency-adapter-standard-profile
        dependency-adapter-profile-details)

;; : (-> ProfileName (List ProfileSlot) DependencyAdapterProfile )
(def (dependency-adapter-profile name slots)
  (slot-profile name (cons (cons 'profileName name) slots)))

;; : (-> DependencyAdapterProfile DependencyAdapterProfile ... DependencyAdapterProfile )
(def (dependency-adapter-profile-extend base . overlays)
  (apply slot-profile-extend base overlays))

;; : (-> DependencyAdapterProfile DependencyAdapterProfile DependencyAdapterProfile )
(def (dependency-adapter-profile-override base overlay)
  (slot-profile-override base overlay))

;; : (-> DependencyAdapterProfile Symbol Value Value )
(def (dependency-adapter-profile-ref profile key fallback)
  (slot-profile-ref profile key fallback))

;; : (-> DependencyAdapterProfile (List String) )
(def (dependency-adapter-profile-precedence profile)
  (slot-profile-precedence-names profile))

;;; Boundary:
;;; - This profile is the protocol-surface repair payload for dependency adapters.
;;; - Keep the long slot-family guidance cohesive so R017 can explain one repair shape.
;; DependencyAdapterProfile
(def +dependency-adapter-protocol-surface-profile+
  (dependency-adapter-profile
   "dependency-protocol-surface"
   [(cons 'styleGuide "dependency-protocol-adapter")
    (cons 'styleCommand
          "asp gerbil-scheme guide --code --topic dependency-protocol-adapter --intent repair")
    (cons 'repairAction "provider-facts-then-guide-code")
    (cons 'guideCodeFlag "--code")
    (cons 'codeShapeExemplar "gerbil-poo rationaldict-style typed protocol adapter")
    (cons 'protocolSurface
          "minimal protocol slots first; derive table/set/list/iteration/lens/sexp/json/bytes/marshal-facing capabilities from the slot surface")
    (cons 'protocolSurfaceReference "gerbil-poo table.ss methods.table")
    (cons 'methodTablePrimitiveSlots
          [".empty" ".ref" ".acons" ".remove" ".foldl" ".foldr"])
    (cons 'methodTableDerivedFamilies
          ["membership: .empty? .key? .ref/opt"
           "iteration/fold: .for-each .for-each/reverse .<-iter .iter<-"
           "conversion: .list<- .<-list .sexp<- .<-sexp .json<- .<-json .bytes<- .<-bytes .marshal .unmarshal"
           "update/merge: .acons/opt .merge .union .join .join/list .update/opt .update"
           "selection: .min-binding/opt .max-binding/opt .min-binding .max-binding .choose/opt .choose .find-first/opt .find-last/opt .find-first .find-last"
           "equality/division: .=? .divide .divide/list .validate .count .every .any"
           "lens/binding: .lens .Binding .Bindings"
           "set algebra: .union .inter .diff .compare"])
    (cons 'reusableContractTestPattern
          "small t/ owner calls generic table-contract-tests or protocol-contract-tests against the adapter type descriptor")
    (cons 'adapterRepairShape
          "inspect provider-native dependency facts first, then use R017 guide --code for the source-backed rationaldict exemplar and local repair shape; follow exact only-in dependency import -> define-type protocol surface -> Key/Value -> primitive methods.table slots (.empty/.ref/.acons/.remove/.foldl/.foldr) -> iteration/conversion/update/selection/equality/lens/serialization slots when dependency primitives exist -> generic contract tests")
    (cons 'agentRepairStandard
          "current dependency already provides the bottom data structure; do not hand-write loose hash/alist objects. Build a typed protocol adapter: precise only-in imports for primitives, define-type Key/Value plus primitive methods.table slots (.empty/.ref/.acons/.remove/.foldl/.foldr), iteration/conversion/update/selection/equality/lens/serialization slots, behavior on protocol slots, derived table/set/list/iteration/lens/sexp/json/bytes/marshal capabilities when slots exist, and generic contract tests")
    (cons 'agentFlexibility
          "agent may choose helper names, exact slot grouping, and generic test helper shape; preserve public adapter name and dependency primitive semantics")
    (cons 'nativeFactSource
          "parser-owned dependencyAdapterQualityFacts joined with moduleImportFacts; do not use raw text heuristics")]))

;; DependencyAdapterProfile
(def +dependency-adapter-poo-lineage-profile+
  (dependency-adapter-profile
   "dependency-poo-lineage"
   [(cons 'sourcePatternLineage
          "gerbil-poo build/cli/rationaldict/table/brace/object/mop/io patterns")
    (cons 'macroBridgeBoundary
          "syntax forms should stay thin bridges like gerbil-poo brace.ss @method; runtime semantics belong in object/mop/protocol slots")
    (cons 'slotResolutionModel
          "POO objects resolve slots through C3 precedence plus lazy slot function cache; do not replace this with raw hash/alist guesses")
    (cons 'ioSerializationMethodFamily
          "json<-/<-json, marshal/unmarshal, bytes<-/<-bytes, and string<-/<-string are method/type slots")]))

;; DependencyAdapterProfile
(def +dependency-adapter-build-cli-profile+
  (dependency-adapter-profile
   "dependency-build-cli-lineage"
   [(cons 'buildPattern
          "use :std/make + :clan/base + :clan/building discovery, while filtering non-module policy/config files for this harness")
    (cons 'cliOptionPattern
          "keep src/cli.ss as a thin dispatcher; compose option objects when command option surfaces grow")]))

;; : (-> Command Command DependencyAdapterProfile )
(def (dependency-adapter-repair-command-profile fact-command repair-command)
  (dependency-adapter-profile
   "dependency-repair-commands"
   [(cons 'factProjectionCommand fact-command)
    (cons 'repairCodeCommand repair-command)
    (cons 'allowedMoves
          [(string-append "run " fact-command
                          " to inspect provider-native dependency facts before editing")
           (string-append "run " repair-command
                          " to inspect local R017 parser/policy repair code")
           "add or tighten only-in dependency primitive imports"
           "wrap dependency primitives with define-type and protocol slots"
           "implement primitive methods.table slots .empty/.ref/.acons/.remove/.foldl/.foldr before relying on derived table helpers"
           "add iteration/conversion/update/selection/equality/lens/serialization boundaries when behavior exists"
           "derive table/set/list/iteration/lens/sexp/json/bytes/marshal-facing capability from protocol slots"
           "add t/ generic contract tests such as table-contract-tests or protocol-contract-tests"])
    (cons 'disallowedMoves
          ["do not replace dependency primitives with hand-written hash/alist storage"
           "do not satisfy R017 with a line-number fixture or a single incidental check call"
           "do not call imported primitives directly from scattered owners when a typed adapter boundary is missing"
           "do not invent protocol capabilities that are not backed by slots or dependency primitives"])]))

;;; Practice profile:
;;; - This is the production POO use site for R017 repair guidance.
;;; - Each overlay contributes one adapter concern instead of one large hash.
;;; - The final composition overlay makes POO provenance visible in details.
;; : (-> Command Command DependencyAdapterProfile )
(def (dependency-adapter-standard-profile fact-command repair-command)
  (slot-profile-compose
   "dependency-adapter-standard"
   [(dependency-adapter-profile
     "dependency-profile-composition"
     [(cons 'profileComposition
            "clan/list c3-compute-precedence-list + clan/poo/proto compose-proto*")
      (cons 'profileOverlays
            ["dependency-protocol-surface"
             "dependency-poo-lineage"
             "dependency-build-cli-lineage"
             "dependency-repair-commands"])])
    (dependency-adapter-repair-command-profile fact-command repair-command)
    +dependency-adapter-build-cli-profile+
    +dependency-adapter-poo-lineage-profile+
    +dependency-adapter-protocol-surface-profile+]))

;;; Details boundary:
;;; - Parser facts fill dynamic adapter evidence.
;;; - The composed profile owns stable repair vocabulary and POO lineage.
;;; - Additional profile slots can be added without editing finding assembly.
;; : (-> DependencyAdapterProfile DependencyAdapterQualityFact MissingEvidence Boolean WitnessKind Json )
(def (dependency-adapter-profile-details profile fact missing
                                         contract-witness-present?
                                         contract-witness-kind)
  (hash (styleGuide (dependency-adapter-profile-ref profile 'styleGuide "dependency-protocol-adapter"))
        (styleCommand (dependency-adapter-profile-ref profile 'styleCommand ""))
        (profileComposition (dependency-adapter-profile-ref profile 'profileComposition ""))
        (profileOverlays (dependency-adapter-profile-ref profile 'profileOverlays '()))
        (profilePrecedence (dependency-adapter-profile-precedence profile))
        (repairAction (dependency-adapter-profile-ref profile 'repairAction ""))
        (guideCodeFlag (dependency-adapter-profile-ref profile 'guideCodeFlag ""))
        (factProjectionCommand (dependency-adapter-profile-ref profile 'factProjectionCommand ""))
        (repairCodeCommand (dependency-adapter-profile-ref profile 'repairCodeCommand ""))
        (codeShapeExemplar (dependency-adapter-profile-ref profile 'codeShapeExemplar ""))
        (sourcePatternLineage (dependency-adapter-profile-ref profile 'sourcePatternLineage ""))
        (definition (dependency-adapter-quality-fact-name fact))
        (dependency (dependency-adapter-quality-fact-dependency fact))
        (imports (dependency-adapter-quality-fact-imports fact))
        (importedSymbols
         (let (symbols (dependency-adapter-quality-fact-imported-symbols fact))
           (take symbols (min 12 (length symbols)))))
        (usedSymbols
         (let (symbols (dependency-adapter-quality-fact-used-symbols fact))
           (take symbols (min 12 (length symbols)))))
        (protocolRefs (dependency-adapter-quality-fact-protocol-refs fact))
        (slots (dependency-adapter-quality-fact-slots fact))
        (derivedCapabilities
         (dependency-adapter-quality-fact-derived-capabilities fact))
        (protocolSurface (dependency-adapter-profile-ref profile 'protocolSurface ""))
        (protocolSurfaceReference
         (dependency-adapter-profile-ref profile 'protocolSurfaceReference ""))
        (methodTablePrimitiveSlots
         (dependency-adapter-profile-ref profile 'methodTablePrimitiveSlots '()))
        (methodTableDerivedFamilies
         (dependency-adapter-profile-ref profile 'methodTableDerivedFamilies '()))
        (reusableContractTestPattern
         (dependency-adapter-profile-ref profile 'reusableContractTestPattern ""))
        (macroBridgeBoundary
         (dependency-adapter-profile-ref profile 'macroBridgeBoundary ""))
        (slotResolutionModel
         (dependency-adapter-profile-ref profile 'slotResolutionModel ""))
        (ioSerializationMethodFamily
         (dependency-adapter-profile-ref profile 'ioSerializationMethodFamily ""))
        (buildPattern (dependency-adapter-profile-ref profile 'buildPattern ""))
        (cliOptionPattern (dependency-adapter-profile-ref profile 'cliOptionPattern ""))
        (manualObjectEncodingRisk
         (dependency-adapter-quality-fact-manual-object-encoding-risk fact))
        (genericContractWitnessKind
         (dependency-adapter-quality-fact-generic-contract-witness-kind fact))
        (quality (dependency-adapter-quality-fact-quality fact))
        (qualityFacets (dependency-adapter-quality-fact-quality-facets fact))
        (missingEvidence missing)
        (contractWitnessPresent contract-witness-present?)
        (contractWitnessKind contract-witness-kind)
        (contractWitnessSource
         "project-level t/ owner with adapter call plus generic table/protocol contract tests; basic check calls are diagnostic but not sufficient")
        (adapterRepairShape
         (dependency-adapter-profile-ref profile 'adapterRepairShape ""))
        (agentRepairStandard
         (dependency-adapter-profile-ref profile 'agentRepairStandard ""))
        (allowedMoves (dependency-adapter-profile-ref profile 'allowedMoves '()))
        (disallowedMoves (dependency-adapter-profile-ref profile 'disallowedMoves '()))
        (agentFlexibility
         (dependency-adapter-profile-ref profile 'agentFlexibility ""))
        (nativeFactSource
         (dependency-adapter-profile-ref profile 'nativeFactSource ""))
        (advice (dependency-adapter-quality-fact-advice fact))
        (next (dependency-adapter-profile-ref profile 'factProjectionCommand ""))))
