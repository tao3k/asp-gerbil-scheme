(policyScenario
 (id "dependency-manual-object-adapter")
 (before (finding ("GERBIL-SCHEME-AGENT-POLICY-017"
                   "src/orders/dict.ss"
                   "src/orders/dict.ss:10-23"
                   "dependency adapter OrderDict. wraps :clan/pure/dict/orderdict but is missing manual-object-encoding-risk; lift dependency primitives into a thin typed protocol adapter and add a contract witness"))
         (adapter ((styleGuide "dependency-protocol-adapter")
                   (dependency ":clan/pure/dict/orderdict")
                   (quality "partial")
                   (manualObjectEncodingRisk "manual-object-encoding-risk")
                   (genericContractWitnessKind
                    "table-protocol-contract-witness")
                   (contractWitnessPresent #t)
                   (contractWitnessKind "generic-contract-test")
                   (missingEvidence ("manual-object-encoding-risk"))
                   (qualityFacets
                    ("dependency-protocol-adapter"
                     "precise-only-in-import"
                     "declared-protocol-or-type-surface"
                     "protocol-slot-surface"
                     "table-method-surface"
                     "typed-validation-boundary"
                     "conversion-boundary"
                     "equality-boundary"
                     "thin-wrapper-over-dependency-api"
                     "protocol-derived-capability"
                     "table-derived-capability"
                     "set-derived-capability"
                     "list-derived-capability"
                     "sexp-derived-capability"
                     "poo-define-type-adapter"))
                   (derivedCapabilities ("table" "set" "list" "sexp"))
                   (methodTablePrimitiveSlots
                    (".empty" ".ref" ".acons" ".remove" ".foldl" ".foldr"))
                   (methodTableDerivedFamilies
                    ("membership: .empty? .key? .ref/opt"
                     "iteration/fold: .for-each .for-each/reverse .<-iter .iter<-"
                     "conversion: .list<- .<-list .sexp<- .<-sexp .json<- .<-json .bytes<- .<-bytes .marshal .unmarshal"
                     "update/merge: .acons/opt .merge .union .join .join/list .update/opt .update"
                     "selection: .min-binding/opt .max-binding/opt .min-binding .max-binding .choose/opt .choose .find-first/opt .find-last/opt .find-first .find-last"
                     "equality/division: .=? .divide .divide/list .validate .count .every .any"
                     "lens/binding: .lens .Binding .Bindings"
                     "set algebra: .union .inter .diff .compare"))
                   (adapterRepairShape
                    "inspect provider-native dependency facts first, then use R017 guide --code for the source-backed rationaldict exemplar and local repair shape; follow exact only-in dependency import -> define-type protocol surface -> Key/Value -> primitive methods.table slots (.empty/.ref/.acons/.remove/.foldl/.foldr) -> iteration/conversion/update/selection/equality/lens/serialization slots when dependency primitives exist -> generic contract tests")
                   (agentRepairStandard
                    "current dependency already provides the bottom data structure; do not hand-write loose hash/alist objects. Build a typed protocol adapter: precise only-in imports for primitives, define-type Key/Value plus primitive methods.table slots (.empty/.ref/.acons/.remove/.foldl/.foldr), iteration/conversion/update/selection/equality/lens/serialization slots, behavior on protocol slots, derived table/set/list/iteration/lens/sexp/json/bytes/marshal capabilities when slots exist, and generic contract tests"))))
 (after (r017Findings ())))
