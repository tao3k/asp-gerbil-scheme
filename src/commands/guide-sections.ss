;;; Boundary: guide sections are declarative command receipts. Keeping rows here
;;; prevents CLI argument handling from duplicating policy and search guidance.

(import :asp-gerbil-scheme/src/policy/catalog (only-in :std/misc/list unique))
(export guide-section-lines-for)
(def (make-guide-section id rows) (list id rows))
(def +guide-basic-section+
     (make-guide-section
      "basic"
      ["asp gerbil-scheme guide"
       "|cmd guide-code=asp gerbil-scheme guide --code [--topic <topic>|--rule <rule>|--intent <intent>|--more|--level advanced]"
       "|flow search-triage=exact owner/selector/symbol/dependency -> query/owner/lexical/dependency; unknown topology -> prime; ambiguous multi-axis frontier -> pipe; no hit -> compact noOutput receipt"
       "|flow prime=not mandatory; run once per language/root only when the owner map or active surface is unknown"
       "|flow pipe=not mandatory; run after a prior frontier shows ambiguity or query-set refinement need"
       "|flow build-ss=choose a native lane by package need: clan/building for src-root all-gerbil-modules packages, std/build-script for simple gxpkg packages, std/make build-spec for ssi:/gsc:/FFI; do not hand-write loadpath/srcdir/compiler/runtime routing"
       "|cmd prime=asp gerbil-scheme search prime --workspace . --view seeds"
       "|cmd pipe=asp gerbil-scheme search pipe '<term>' --workspace . --view seeds"
       "|cmd lexical=asp gerbil-scheme search lexical --query '<seed>' --query '<related-seed>' owner tests --workspace . --view seeds"
       "|cmd owner=asp gerbil-scheme search owner <path> --workspace . --view seeds"
       "|cmd owner-items=asp gerbil-scheme search owner <path> items --query <symbol> --workspace . --view seeds"
       "|cmd exact-source=asp gerbil-scheme query --selector <gerbil-scheme://owner#item/kind/name> --projection source --workspace ."
       "|cmd callable-skeleton=asp gerbil-scheme query --selector <gerbil-scheme://owner#item/kind/name> --projection callable-skeleton --workspace ."
       "|cmd env=asp gerbil-scheme search env [term ...] --workspace . --view seeds"
       "|cmd runtime-source=asp gerbil-scheme search runtime-source [term ...] --workspace . --view seeds"
       "|cmd compiler-evidence=asp gerbil-scheme search compiler-evidence optimizer subtype assertion --workspace . --view seeds"
       "|cmd proof=asp gerbil-scheme search proof subtype record alias --workspace . --view seeds"
       "|cmd lang=asp gerbil-scheme search lang [term ...] --workspace . --view seeds"
       "|cmd std=asp gerbil-scheme search std [term ...] --workspace . --view seeds"
       "|policy source-index-owner=asp-server; structural-index-owner=gerbil-scheme; Source Index lookup/cache is ASP Server IPC, while Gerbil search only renders provider parser facts and never invokes an asp subprocess"
       "|cmd runtime-source-acquire=asp cache runtime-source acquire --language-id gerbil-scheme --repository <gerbil-repo-or-path> --checkout <ref> --state-namespace runtime-source/gerbil-scheme --root ."
       "|cmd runtime-source-lookup=asp gerbil-scheme cache source-index lookup --query <symbol> --index-root . --limit 8"
       "|cmd capability=asp gerbil-scheme search capability [term ...] --workspace . --view seeds"
       "|cmd compare=asp gerbil-scheme search compare <axis> [left right] --workspace . --view seeds"
       "|cmd structural=asp gerbil-scheme search structural --workspace . --view seeds"
       "|cmd structural-interface-json=asp gerbil-scheme search structural --json ."
       "|cmd structural-owner-facts-json=asp gerbil-scheme search structural --owner <path> --json ."
       "|cmd structural-artifact-json=asp gerbil-scheme search structural --json --artifact ."
       "|cmd evidence-graph=asp gerbil-scheme evidence graph --json ."
       "|cmd evidence-analyze=asp gerbil-scheme evidence analyze --json ."
       "|cmd info=asp gerbil-scheme info --json ."
       "|more guide-detail=asp gerbil-scheme guide --downstream | --policy | --extensions | --poo | --exemplars | --all"]))
(def +guide-downstream-section+
     (make-guide-section
      "downstream"
      ["|cmd downstream-install=from harness checkout run: gxpkg build"
       "|downstream gerbil.pkg-depend=(depend: (\"github.com/tao3k/asp-gerbil-scheme\"))"
       "|downstream gxtest-import=(import :asp-gerbil-scheme/src/policy/gxtest)"
       "|downstream gxtest-fixture=(def project-policy-test (make-project-policy-test \".\"))"
       "|cmd downstream-test=gxtest t/project-policy-test.ss"
       "|policy downstream-state-boundary=gxpkg package state belongs under ~/.gerbil; do not create, depend on, or commit repository-local .gerbil"
       "|policy downstream-policy-ownership=gerbil.pkg owns source-scope, runtime-roots, modularity config, and agent-policy overrides; gxtest should call the harness, not duplicate policy rules"
       "|policy downstream-reporting=make-project-policy-test prints gerbil-gxtest compact findings plus agent repair lines on failure; use project-policy-report plus gxtest-report-* accessors for custom structured status/files/definitions/findings"]))
(def +guide-extension-section+
     (make-guide-section
      "extensions"
      ["|cmd extension=asp-gerbil-scheme search extension <extension> [term ...] --view seeds"
       "|cmd dependency-frontier=asp-gerbil-scheme search extension <package-or-extension> [term ...] --view seeds"
       "|cmd pattern=asp-gerbil-scheme search pattern <feature-or-extension> [term ...] --view seeds"
       "|policy dependency-search-frontier=Gerbil currently exposes dependency evidence through package/import/extension/runtime-source facts, not a dedicated dependency view; keep manifest/package evidence before repository fallback"]))
(def +guide-policy-section+
     (make-guide-section
      "policy"
      (append ["|policy structural-json-boundary=search structural --json emits a provider-local parser/interface packet; use --owner <path> for owner-bounded native facts and --artifact only for explicit validation"
       "|policy structural-index-owner=Gerbil Scheme provider-local parser facts; ASP Server may route the packet, while graph topology, caching, and ranking are separate contracts"
               "|policy configurable-interface=downstream gerbil.pkg policy may declare source-scope roots/runtime-roots/exclude-directories and agent-policy enabled-rules/disabled-rules; without explicit source-scope, build.ss defbuild-script targets provide runtime-root evidence"
               "|policy package-build-canonical-lanes=build.ss has three native Gerbil lanes: :clan/building plus all-gerbil-modules for src-root package discovery, :std/build-script defbuild-script for simple gxpkg package templates, and :std/make build-spec for ssi:/gsc:/FFI/static/native build forms"
               "|policy package-build-forbidden-control=R025 should target handwritten GERBIL_LOADPATH/srcdir setup, manual compiler/process dispatch, shell pipelines, and runtime/CLI routing in build.ss; do not canonicalize valid std/make ssi:/gsc:/FFI builds into clan/building"
               "|policy cli-option-composition=keep src/cli.ss as a thin dispatcher with precise only-in imports; when command option surfaces grow, compose option objects instead of expanding dispatcher parsing logic"
               "|policy package-module-style=Gerbil package modules should preserve package:/namespace:/import/export style instead of flattening into generic Scheme files"]
              (agent-rule-policy-lines)
              ["|policy namespace-receipt=macro/module/type/poo edits should cite search env/lang/std/pattern/runtime-source/proof/compiler-evidence output before editing"
               "|policy runtime-source-code-comments=runtime-source results should expose selectorResolver/sourceExample/sourceComment lines before selector code reads"
               "|policy typed-combinator-style-criteria=three criteria are required: adjacent Gerbil contract projection block, compact expression-level composition, and optimization-boundary comments for specialized branches"
               "|policy typed-combinator-style-signature=ordinary helpers use ;; : (forall (a) (-> Input Output)) as a Gerbil contract/signature projection; exported helpers/macros/policy helpers use full form with matching leading name, | type/contract/requires/warning/rationale metadata when needed, | doc m% with # Examples fenced scheme input/result comments, and parser-owned typedComment.signatureType/docs.hasResultExamples diagnostics"
               "|policy typed-combinator-style-composition=prefer small helper functions and expression-level map/filter/fold/cut/curry/compose chains when behavior fits"
               "|policy typed-combinator-style-optimization-boundary=for case-lambda or common-case specializations, comment why the branch exists; do not restate the code mechanics"
               "|policy m3-policy-repair-loop=when gxtest policy emits findings, follow agentRepair.nextCommand and grouped repair phases; when findings=0, continue from POO-adjacent owner evidence and source-backed guide exemplars instead of adding isolated rules"
               "|policy engineering-comment-quality=Scheme-native typed blocks describe algebraic shape only; engineering comments should cover parserEvidence with concise prose, bullets, or optional Boundary/Invariant/Intent labels; split multi-clause rationale across adjacent lines"
               "|policy dependency-protocol-adapter=when a dependency provides durable data primitives, do not hand-write loose hash/alist objects; wrap primitives as a thin define-type/protocol adapter with Key/Value/validate/serialization/equality slots, derived table/set/list/sexp/json/marshal capabilities, precise only-in imports, and generic t/ contract witnesses"
               "|policy dependency-protocol-adapter-repair-action=R017 findings should run guide --code --rule GERBIL-SCHEME-AGENT-POLICY-017 --intent repair first; the --code flag prints the adapter code shape the agent should follow"
               "|policy protocol-surface-minimality=define the minimal protocol slot surface first, then derive secondary capabilities such as table/set/list/json/bytes/marshal from those slots instead of duplicating behavior"
               "|policy reusable-contract-tests=prefer small t/ owners that apply generic contract tests to type descriptors, such as table-contract-tests or protocol-contract-tests, over monolithic copied assertion suites"
               "|policy explicit-precise-import=runtime library, dependency, and owner-local helper imports should use (only-in <module> <symbols...>) so parser-owned moduleImportFacts expose the exact dependency surface to agents"
               "|policy guide-code-default=guide --code writes only extracted source comment plus source code; guide without --code carries selectors and next commands"
               "|policy guide-code-default-topic=guide --code defaults to typed-combinator-style so agents first see transform signatures plus compact expression-level helper functions"
               "|policy guide-code-progressive=guide --code defaults to one source-backed excerpt; --more adds one adjacent exemplar; --level advanced includes the macro runtime-source witness path"
               "|policy guide-code-routing=--rule/--finding route known policy ids to source-backed exemplars before agent repair; --intent witness routes to macro runtime-source evidence"
               "|policy compiler-evidence-boundary=type/proof repairs must cite search proof subtype record alias plus search compiler-evidence optimizer subtype assertion and remain medium-weight; do not claim full type theory without a dedicated typed core"
               "|policy guide-workspace=guide does not require a positional .; use --workspace . only when project-local exemplar selection needs context"])))
(def +guide-poo-section+
     (make-guide-section
      "poo"
      ["|cmd pattern-poo=asp-gerbil-scheme search pattern poo [term ...] --view seeds"
       "|cmd guide-code-poo-repair=asp-gerbil-scheme guide --code --topic poo-policy --intent repair"
       "|policy gerbil-feature-use=when POO/protocol capability is active, prefer parser-owned defclass/defgeneric/defmethod evidence over raw hash/alist object constructors; cite search pattern poo class when intentionally staying raw"
       "|policy poo-thin-macro-bridge=POO syntax macros such as brace/@method should stay thin syntax bridges; semantic behavior belongs in object, MOP, protocol, or method-family slots"
       "|policy poo-slot-resolution=POO object edits must account for C3 precedence and lazy slot cache resolution; query object/mop slot-resolution selectors before replacing objects with hash/alist guesses"
       "|policy poo-prototype-fixed-point=soft guidance: isolated .ref/.@/.get boundary reads are allowed; when constructor/build functions repeatedly project slots, model the object as one prototype fixed point with {(:: @ super) slot: ...}, =>, =>.+, ?, and .mix; docs=docs/50-59-policy/51.02-gerbil-poo-programming-guidelines.org; rule=GERBIL-SCHEME-AGENT-POLICY-026"
       "|policy poo-guidance-corpus=soft scenarios cover Class./Slot descriptors, serialization method families, Functor./Wrapper. algebra, Polynomial. domain descriptors, and .ref/.@/.get false-positive boundaries; snapshot=t/snapshots/policy-poo-guidance-corpus.ss"
       "|policy poo-serialization-method-family=json<-/<-json, marshal/unmarshal, bytes<-/<-bytes, and string<-/<-string should be modeled as method/type slots, not scattered helper functions"
       "|policy poo-protocol-conversion-fixtures=protocol conversion fixtures should expose methods.string<-json and methods.bytes<-marshal as define-type adapters with derived string/bytes slots before adding style warnings"
       "|policy poo-representation-invariant-fixtures=table/trie/type fixtures should expose required-slot protocols, role translation adapters, representation invariants, and nested type descriptor composition through structural owner facts"
       "|policy poo-structural-facts=search structural --owner <path> --json exposes parser-owned POO forms as custom/generic/method owner facts with role,supers,slots,options,specializers,specializerTypes,dispatchArity; query owner facts before editing POO object/type/method forms"
       "|policy poo-io-runtime-source=POO :wr/writeenv changes should cite search runtime-source writeenv printer hook; hook guidance remains soft until real-project noise is reviewed"]))
(def +guide-exemplar-section+
     (make-guide-section
      "exemplars"
      ["|guideExemplar id=gerbil.typed-combinator-style.policy-coverage topic=typed-combinator-style intent=style rule=GERBIL-SCHEME-AGENT-POLICY-013 level=normal locator=parser-definition owner=src/policy/agent-style.ss symbols=typed-combinator-style-findings,typed-combinator-style-function-definitions,typed-combinator-style-evidence-callers comments=leading nextCommand=\"asp-gerbil-scheme guide --code --topic typed-combinator-style --intent style\" moreCommand=\"asp-gerbil-scheme guide --code --topic typed-combinator-style --intent style --more\""
       "|guideExemplar id=gerbil.typed-combinator-style.policy-filter-map topic=typed-combinator-style intent=style rule=GERBIL-SCHEME-AGENT-POLICY-013 level=more locator=parser-definition owner=src/policy/agent.ss symbols=functional-idiom-advice-findings comments=leading nextCommand=\"asp-gerbil-scheme guide --code --topic typed-combinator-style --intent style --more\""
       "|guideExemplar id=gerbil.m3-policy-repair-loop.typed-style topic=m3-policy-repair-loop intent=repair rule=milestone-M3 level=normal locator=parser-definition owner=src/policy/agent-style.ss symbols=typed-combinator-style-details,typed-combinator-style-quality-repair-triggered? comments=leading nextCommand=\"asp-gerbil-scheme guide --code --topic m3-policy-repair-loop --intent repair\" moreCommand=\"asp-gerbil-scheme guide --code --topic m3-policy-repair-loop --intent repair --more\""
       "|guideExemplar id=gerbil.poo-policy.parser-facts topic=poo-policy intent=repair rule=GERBIL-SCHEME-AGENT-POLICY-008 level=normal locator=parser-definition owner=src/parser/poo.ss symbols=poo-form-facts-from-form comments=file-purpose+leading nextCommand=\"asp-gerbil-scheme guide --code --topic poo-policy --intent repair\""
       "|guideExemplar id=gerbil.poo-policy.structural-owner-facts topic=poo-policy intent=witness rule=GERBIL-SCHEME-AGENT-POLICY-008 level=normal locator=structural-owner-facts owner=t/fixtures/parser/poo-method-dispatch.ss symbols=distance,:intersect fields=generic,specializers,specializerTypes,receiver,receiverType,dispatchArity nextCommand=\"asp-gerbil-scheme search structural --owner t/fixtures/parser/poo-method-dispatch.ss --json .\""
       "|guideExemplar id=gerbil.poo-policy.protocol-conversion-fixture topic=poo-policy intent=witness rule=GERBIL-SCHEME-AGENT-POLICY-008 level=normal locator=structural-owner-facts owner=t/fixtures/parser/poo-io-hooks.ss symbols=methods.string<-json,methods.bytes<-marshal fields=role,slots nextCommand=\"asp-gerbil-scheme search structural --owner t/fixtures/parser/poo-io-hooks.ss --json .\""
       "|guideExemplar id=gerbil.poo-policy.adapter-invariant-fixtures topic=poo-policy intent=witness rule=GERBIL-SCHEME-AGENT-POLICY-008 level=normal locator=structural-owner-facts owner=t/fixtures/parser/poo-trie-descriptor.ss symbols=Costep.,Trie. fields=supers,slots nextCommand=\"asp-gerbil-scheme search structural --owner t/fixtures/parser/poo-trie-descriptor.ss --json .\""
       "|guideExemplar id=gerbil.poo-policy.prototype-fixed-point topic=poo-policy intent=repair rule=GERBIL-SCHEME-AGENT-POLICY-026 level=normal locator=runtime-source owner=gerbil-poo/t/object-test.ss symbols={(:: @ p) x:=>,x:=>.+,x:? fields=brace,super,slot-transform,default nextCommand=\"asp-gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-026 --intent repair\""
       "|guideExemplar id=gerbil.macro-runtime-source.witness topic=macro-runtime-source intent=witness rule=GERBIL-SCHEME-AGENT-POLICY-011 level=advanced locator=parser-definition owner=src/commands/search.ss symbols=matching-language-evidence-facts comments=file-purpose+leading nextCommand=\"asp-gerbil-scheme guide --code --topic macro-runtime-source --intent witness\""
       "|guideExemplar id=gerbil.controlled-branch-shape.bounded-selector topic=controlled-branch-shape intent=style rule=GERBIL-SCHEME-AGENT-POLICY-014 level=normal locator=parser-definition owner=src/commands/search-render.ss symbols=ranked-syntax-facts,select-ranked-syntax-facts comments=file-purpose+leading nextCommand=\"asp-gerbil-scheme guide --code --topic controlled-branch-shape --intent style\""
       "|guideExemplar id=gerbil.engineering-comment-quality.contract-boundary topic=engineering-comment-quality intent=style rule=GERBIL-SCHEME-AGENT-POLICY-015 level=normal locator=parser-definition owner=src/policy/agent-comment.ss symbols=comment-quality-details,comment-quality-fact-summary,weak-required-comment-quality-fact? comments=leading nextCommand=\"asp-gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-015 --intent style\""
       "|guideExemplar id=gerbil.predicate-family-combinator.native-facts topic=predicate-family-combinator intent=style rule=GERBIL-SCHEME-AGENT-POLICY-016 level=normal locator=parser-definition owner=src/parser/quality-shape.ss symbols=predicate-family-facts-from-source,field-access-pattern-facts-from-source comments=file-purpose+leading nextCommand=\"asp-gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-016 --intent style\""
       "|guideExemplar id=gerbil.dependency-protocol-adapter.rationaldict-shape topic=dependency-protocol-adapter intent=repair rule=GERBIL-SCHEME-AGENT-POLICY-017 level=normal locator=runtime-source owner=gerbil-poo/rationaldict.ss symbols=RationalDict.,RationalSet comments=file-purpose+leading repairAction=inspect-code-shape guideCodeFlag=--code nextCommand=\"asp-gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-017 --intent repair\" moreCommand=\"asp-gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-017 --intent repair --more\""
       "|guideExemplar id=gerbil.explicit-precise-import.policy-shape topic=explicit-precise-import intent=repair rule=GERBIL-SCHEME-AGENT-POLICY-018 level=normal locator=parser-definition owner=src/policy/agent-import.ss symbols=explicit-precise-import-finding,imprecise-runtime-import?,explicit-precise-import-details comments=file-purpose+leading nextCommand=\"asp-gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-018 --intent repair\""
       "|guideExemplar id=gerbil.package-build-canonical-shape.native-build topic=package-build-canonical-shape intent=repair rule=GERBIL-SCHEME-AGENT-POLICY-025 level=normal locator=parser-definition owner=src/policy/agent-build.ss symbols=package-build-canonical-shape-finding,package-build-spec-call?,package-build-manual-compiler-dispatch-call? comments=file-purpose+leading nextCommand=\"asp-gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-POLICY-025 --intent repair\""]))
(def (guide-section-flag? args flag) (and (member flag args) #t))
(def (guide-section-rows section) (cadr section))
(def (guide-section-when all? selected? section)
     (and (or all? selected?) section))
(def (selected-guide-sections args)
     (let ((all? (guide-section-flag? args "--all"))
           (policy? (guide-section-flag? args "--policy"))
           (extensions?
            (or (guide-section-flag? args "--extensions")
                (guide-section-flag? args "--extension")))
           (downstream? (guide-section-flag? args "--downstream"))
           (poo? (guide-section-flag? args "--poo"))
           (exemplars?
            (or (guide-section-flag? args "--exemplars")
                (guide-section-flag? args "--exemplar"))))
       (cons +guide-basic-section+
             (filter-map
              (lambda (entry)
                (guide-section-when all? (car entry) (cdr entry)))
              [(cons downstream? +guide-downstream-section+)
               (cons policy? +guide-policy-section+)
               (cons extensions? +guide-extension-section+)
               (cons poo? +guide-poo-section+)
               (cons exemplars? +guide-exemplar-section+)]))))
(def (guide-section-lines-for args)
     (unique (apply append
                    (map guide-section-rows (selected-guide-sections args)))))
