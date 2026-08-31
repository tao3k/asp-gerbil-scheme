;;; -*- Gerbil -*-
;;; Macro and POO typeclass style signals for R013 Gerbil guidance.

(import :asp-gerbil-scheme/src/parser/facade
        (only-in :asp-gerbil-scheme/src/policy/agent-style-gerbil-signal-support
                 typed-combinator-style-facts->quality-facet
                 typed-combinator-style-facts->signals
                 typed-combinator-style-facts->targets
                 typed-contract-fact-mentions-any?)
        (only-in :std/misc/list unique)
        (only-in :std/sugar filter ormap))

(export typed-combinator-style-macro-family-quality-facets
        typed-combinator-style-macro-family-signals
        typed-combinator-style-macro-family-targets
        typed-combinator-style-macro-metaprogramming-decision-quality-facets
        typed-combinator-style-macro-metaprogramming-decision-signals
        typed-combinator-style-macro-metaprogramming-decision-targets
        typed-combinator-style-syntax-parameter-context-quality-facets
        typed-combinator-style-syntax-parameter-context-signals
        typed-combinator-style-syntax-parameter-context-targets
        typed-combinator-style-syntax-local-registry-quality-facets
        typed-combinator-style-syntax-local-registry-signals
        typed-combinator-style-syntax-local-registry-targets
        typed-combinator-style-phase-aware-macro-boundary-quality-facets
        typed-combinator-style-phase-aware-macro-boundary-signals
        typed-combinator-style-phase-aware-macro-boundary-targets
        typed-combinator-style-controlled-macro-quality-facets
        typed-combinator-style-controlled-macro-syntax-signals
        typed-combinator-style-controlled-macro-targets
        typed-combinator-style-match-extension-boundary-quality-facets
        typed-combinator-style-match-extension-boundary-signals
        typed-combinator-style-match-extension-boundary-targets
        typed-combinator-style-mop-class-macro-boundary-quality-facets
        typed-combinator-style-mop-class-macro-boundary-signals
        typed-combinator-style-mop-class-macro-boundary-targets
        typed-combinator-style-typeclass-quality-facets
        typed-combinator-style-typeclass-algebra-signals
        typed-combinator-style-typeclass-algebra-targets
        typed-combinator-style-typeclass-poo-forms)

;;; Macro-family facts catch repeated same-prefix thin macro wrappers before
;;; policy turns them into copy-pasted syntax APIs.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-macro-family-quality-facets file)
  (append
   (typed-combinator-style-facts->quality-facet
    (source-file-macro-family-facts file)
    "macro-family-boundary")
   (typed-combinator-style-facts->quality-facet
    (source-file-typed-contract-facts file)
    "typed-doc-block")))

;;; Signal boundary:
;;; - Family guidance is emitted only from parser-owned macro-family facts.
;;; - It does not make downstream projects depend on poo-flow or gerbil-utils.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-macro-family-signals file)
  (typed-combinator-style-facts->signals
   (source-file-macro-family-facts file)
   ["collapse repeated same-prefix macro wrappers into one macro family helper"
    "use defrules/syntax-rules for fixed macro families before reaching for syntax-case"
    "prefer a syntax-rules family table or stx helper over copy-pasted defrules"
    "split shared macro parsing from syntax generation when the family has more than one expansion shape"
    "keep runtime semantics in ordinary helpers and make macro expansion a thin surface"]))

;;; Target projection names the macro family prefix, not each repeated wrapper.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-macro-family-targets file)
  (typed-combinator-style-facts->targets
   (source-file-macro-family-facts file)
   macro-family-fact-prefix))

;;; Decision facts teach the agent when declarative macro patterns are enough
;;; and when procedural syntax-object metaprogramming is warranted.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-macro-metaprogramming-decision-quality-facets file)
  (if (typed-combinator-style-macro-metaprogramming-decision? file)
    (unique
     (append
      ["macro-metaprogramming-decision-boundary"
       "declarative-procedural-macro-selection"]
      (typed-combinator-style-procedural-macro-quality-facets file)))
    []))

;; : (-> SourceFile Boolean )
(def (typed-combinator-style-macro-metaprogramming-decision? file)
  (and (pair? (source-file-macro-family-facts file))
       (pair? (typed-combinator-style-procedural-macro-facts file))))

;; : (-> SourceFile (List MacroFact) )
(def (typed-combinator-style-procedural-macro-facts file)
  (filter typed-combinator-style-procedural-macro-fact?
          (source-file-macros file)))

;; : (-> MacroFact Boolean )
(def (typed-combinator-style-procedural-macro-fact? fact)
  (or (member (macro-fact-transformer fact)
              ["syntax-case" "datum->syntax" "lambda-transformer"])
      (member "procedural-macro-transformer"
              (macro-fact-quality-facets fact))))

;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-procedural-macro-quality-facets file)
  (unique
   (apply append
          (map typed-combinator-style-procedural-macro-quality-facet-filter
               (typed-combinator-style-procedural-macro-facts file)))))

;; : (-> MacroFact (List QualityFacet) )
(def (typed-combinator-style-procedural-macro-quality-facet-filter fact)
  (filter (lambda (facet)
            (member facet
                    ["syntax-object-validation"
                     "identifier-reconstruction"
                     "with-syntax-reconstruction"
                     "source-aware-syntax-error"
                     "phase-extension-hook"]))
          (macro-fact-quality-facets fact)))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-macro-metaprogramming-decision-signals file)
  (if (typed-combinator-style-macro-metaprogramming-decision? file)
    ["choose defrules/syntax-rules for fixed grammar-like rewrites and repeated declaration families"
     "upgrade to syntax-case/with-syntax only when syntax-object validation, identifier reconstruction, or source-aware errors are required"
     "keep procedural macro parsing, syntax reconstruction, and runtime helpers as separate named boundaries"
     "document the expansion contract with one input form and one result form"]
    []))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-macro-metaprogramming-decision-targets file)
  (if (typed-combinator-style-macro-metaprogramming-decision? file)
    (unique
     (append (typed-combinator-style-macro-family-targets file)
             (map macro-fact-name
                  (typed-combinator-style-procedural-macro-facts file))))
    []))

;;; Syntax parameters are Gerbil's native answer for scoped compile-time
;;; context.  This boundary catches generated macro code that simulates that
;;; context with global phase state and mutation.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-syntax-parameter-context-quality-facets file)
  (if (pair? (typed-combinator-style-global-macro-state-facts file))
    ["syntax-parameterized-context-boundary"
     "global-macro-state-mutation"
     "manual-phase-context-threading"]
    []))

;; : (-> SourceFile (List MacroFact) )
(def (typed-combinator-style-global-macro-state-facts file)
  (filter typed-combinator-style-global-macro-state-fact?
          (source-file-macros file)))

;; : (-> MacroFact Boolean )
(def (typed-combinator-style-global-macro-state-fact? fact)
  (member "global-macro-state-mutation"
          (macro-fact-quality-facets fact)))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-syntax-parameter-context-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-global-macro-state-facts file)
   ["replace mutable compile-time globals with defsyntax-parameter* and syntax-parameterize"
    "bind context identifiers at the macro call boundary instead of threading hidden phase state"
    "use syntax-local-value/syntax-local-rewrap only inside the syntax-parameter support boundary"
    "raise syntax errors when a syntax parameter is used outside its dynamic macro context"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-syntax-parameter-context-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-global-macro-state-facts file)
   macro-fact-name))

;;; Gerbil macros usually attach compile-time metadata to identifiers through
;;; syntax-local-value.  Hand-written hash registries keyed by syntax->datum are
;;; both less hygienic and easier for generated code to desynchronize.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-syntax-local-registry-quality-facets file)
  (if (pair? (typed-combinator-style-manual-syntax-registry-facts file))
    ["syntax-local-registry-boundary"
     "manual-syntax-registry-table"
     "syntax-datum-registry-key"]
    []))

;; : (-> SourceFile (List MacroFact) )
(def (typed-combinator-style-manual-syntax-registry-facts file)
  (filter typed-combinator-style-manual-syntax-registry-fact?
          (source-file-macros file)))

;; : (-> MacroFact Boolean )
(def (typed-combinator-style-manual-syntax-registry-fact? fact)
  (let (facets (macro-fact-quality-facets fact))
    (and (member "manual-syntax-registry-table" facets)
         (member "syntax-datum-registry-key" facets))))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-syntax-local-registry-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-manual-syntax-registry-facts file)
   ["replace syntax->datum keyed macro hash registries with defsyntax metadata objects"
    "lookup compile-time metadata with syntax-local-value and validate its class before expansion"
    "keep generated runtime bindings separate from the compile-time metadata owner"
    "raise source-aware syntax errors when a referenced identifier has no registered metadata"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-syntax-local-registry-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-manual-syntax-registry-facts file)
   macro-fact-name))

;;; Phase-aware macro facts catch one owner mixing meta-syntactic tower,
;;; phase/context state, transformer parsing, expansion, and runtime helper
;;; responsibilities. Detection stays parser-owned: macro facts prove the file
;;; has a syntax owner, and typed-contract facts prove the mixed boundary.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-phase-aware-macro-boundary-quality-facets file)
  (if (pair? (typed-combinator-style-phase-aware-macro-boundary-facts file))
    ["phase-aware-macro-boundary"
     "meta-syntactic-tower-boundary"]
    []))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-phase-aware-macro-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-phase-aware-macro-boundary-facts file)
   ["split phase/context parsing from runtime helper generation"
    "keep transformer expansion as a thin hygienic syntax boundary"
    "move reusable runtime behavior into ordinary helpers"
    "document the expansion contract and phase boundary"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-phase-aware-macro-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-phase-aware-macro-boundary-facts file)
   typed-contract-fact-definition-name))

;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-phase-aware-macro-boundary-facts file)
  (if (pair? (source-file-macros file))
    (filter typed-combinator-style-phase-aware-macro-boundary-fact?
            (source-file-typed-contract-facts file))
    []))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-phase-aware-macro-boundary-fact? fact)
  (>= (length
       (typed-combinator-style-phase-aware-macro-boundary-categories fact))
      5))

;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-phase-aware-macro-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["Phase" "phase" "Phi" "phi"])
                "phase")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Macro" "macro" "Syntax" "syntax"])
                "macro")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Context" "context" "Expander" "expander"])
                "context")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Transformer" "transformer" "Transform" "transform"])
                "transformer")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Expansion" "expansion" "Expand" "expand"])
                "expansion")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Runtime" "runtime" "Helper" "helper"])
                "runtime")]))

;;; Macro facts already classify syntax owners.  R013 exposes the engineering
;;; steering so macro-heavy files use upstream macro-library idioms without
;;; inventing a project-specific DSL.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-controlled-macro-quality-facets file)
  (append
   (typed-combinator-style-facts->quality-facet
    (source-file-macros file)
    "controlled-macro-syntax-boundary")
   (typed-combinator-style-macro-metaprogramming-decision-quality-facets file)
   (typed-combinator-style-macro-template-optimizer-quality-facets file)))

(def (typed-combinator-style-macro-template-optimizer-quality-facets file)
  (if (ormap macro-template-optimizer-visible? (source-file-macros file))
    ["macro-phase-optimizer-visible-fast-path"
     "phase-macro-generated-wrapper"
     "generated-runtime-helper"
     "optimizer-visible-call-shape"]
    []))

(def (macro-template-optimizer-visible? fact)
  (let (facets (macro-fact-quality-facets fact))
    (and (member "generated-runtime-helper" facets)
         (member "macro-template-dynamic-apply" facets))))

;;; Signal boundary:
;;; - Controlled macro guidance is driven by parser macro facts, not text matching.
;;; - The suggestions keep transformer shape separate from runtime helpers.
;;; - This is Gerbil Scheme macro usage, not a license to create a DSL.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-controlled-macro-syntax-signals file)
  (typed-combinator-style-facts->signals
   (source-file-macros file)
   ["syntax-case/with-syntax transformer shape"
    "syntax-rules thin macro DSL"
    "choose declarative defrules/syntax-rules before procedural syntax-case when the shape is a fixed rewrite"
    "upgrade to procedural syntax-case only for validation, identifier synthesis, local IR parsing, or source-aware errors"
    "hygienic macro boundary"
    "parameterize phase/context state instead of mutating global macro state"
    "typed context records for macro/import/export state"
    "raise-syntax-error keeps source-aware failure paths"
    "parse complex syntax into a small local IR before generating output"
    "separate syntax validation, pattern parsing, and output reconstruction helpers"
    "stx-lambda or def-stx helper boundary"
    "macro syntax stays a thin hygienic syntax wrapper"
    "runtime behavior remains in ordinary helpers"
    "docs explain the expansion contract and example result"]))

;;; Target projection mirrors macro-fact ownership exactly.
;;; The map is intentionally direct: policy details should cite macro names
;;; already emitted by the parser, not derive display names from syntax text.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-controlled-macro-targets file)
  (typed-combinator-style-facts->targets
   (source-file-macros file)
   macro-fact-name))

;;; Gerbil core/match.ss supports match-specific extension macros through
;;; defsyntax-for-match, syntax-local match macro lookup, applicative
;;; destructuring, and struct/class accessor extraction.  Detection stays
;;; parser-owned: macro facts prove the syntax surface, while typed contracts
;;; prove the owner mixes match extension responsibilities.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-match-extension-boundary-quality-facets file)
  (if (pair? (typed-combinator-style-match-extension-boundary-facts file))
    ["match-extension-boundary"
     "match-macro-destructuring-boundary"]
    []))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-match-extension-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-match-extension-boundary-facts file)
   ["use defsyntax-for-match for match-only pattern extensions"
    "keep pattern parsing separate from runtime predicate helpers"
    "prefer applicative destructuring or struct/class accessors over manual dispatcher tables"
    "raise syntax errors at the pattern boundary with source context"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-match-extension-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-match-extension-boundary-facts file)
   typed-contract-fact-definition-name))

;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-match-extension-boundary-facts file)
  (if (pair? (source-file-macros file))
    (filter typed-combinator-style-match-extension-boundary-fact?
            (source-file-typed-contract-facts file))
    []))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-match-extension-boundary-fact? fact)
  (>= (length
       (typed-combinator-style-match-extension-boundary-categories fact))
      5))

;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-match-extension-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["Match" "match" "Pattern" "pattern"])
                "match-pattern")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Macro" "macro" "Syntax" "syntax"])
                "macro-syntax")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["SyntaxLocal" "syntax-local" "syntax local" "Expander" "expander"])
                "syntax-local")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Struct" "struct" "Class" "class"])
                "struct-class")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Accessor" "accessor" "Field" "field" "Slot" "slot"])
                "accessor")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Apply" "apply" "Applicative" "applicative"])
                "applicative")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Parse" "parse" "Parser" "parser"])
                "parser")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Error" "error" "Source" "source"])
                "source-error")]))

;;; Gerbil core/mop.ss shows that class macros should keep expansion-time
;;; class descriptors, slot layout, mixin accessors, and runtime method binding
;;; as named boundaries.  Detection stays parser-owned: macro facts prove the
;;; owner is a syntax surface, and typed contracts prove the mixed MOP surface.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-mop-class-macro-boundary-quality-facets file)
  (if (pair? (typed-combinator-style-mop-class-macro-boundary-facts file))
    ["mop-class-macro-boundary"
     "class-descriptor-macro-boundary"]
    []))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-mop-class-macro-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-mop-class-macro-boundary-facts file)
   ["split defclass-style descriptor generation from runtime helpers"
    "keep slot layout, mixin slots, accessors, and mutators in named MOP helpers"
    "bind methods through a narrow runtime method boundary"
    "keep constructor, predicate, metaclass, and slot contract metadata explicit"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-mop-class-macro-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-mop-class-macro-boundary-facts file)
   typed-contract-fact-definition-name))

;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-mop-class-macro-boundary-facts file)
  (if (pair? (source-file-macros file))
    (filter typed-combinator-style-mop-class-macro-boundary-fact?
            (source-file-typed-contract-facts file))
    []))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-mop-class-macro-boundary-fact? fact)
  (>= (length
       (typed-combinator-style-mop-class-macro-boundary-categories fact))
      6))

;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-mop-class-macro-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["MOP" "mop" "Metaobject" "metaobject"])
                "mop")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Class" "class" "Defclass" "defclass"])
                "class")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Descriptor" "descriptor" "TypeInfo" "type-info"])
                "descriptor")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Slot" "slot" "Layout" "layout"])
                "slot")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Mixin" "mixin" "Super" "super"])
                "mixin")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Accessor" "accessor" "Mutator" "mutator"])
                "accessor-mutator")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Method" "method" "Bind" "bind"])
                "method")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Constructor" "constructor" "Predicate" "predicate"])
                "constructor-predicate")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Metaclass" "metaclass" "Contract" "contract" "Default" "default"])
                "metadata")]))

;;; POO typeclass facts come from the parser's options, not source text scans.
;;; The details expose concrete targets for gerbil-poo/fun.ss style repair.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-typeclass-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-typeclass-poo-forms file)
   "poo-typeclass-algebra-boundary"))

;;; Signal boundary:
;;; - POO algebra guidance is emitted only for parser-owned POO option facts.
;;; - This keeps typeclass repair tied to gerbil-poo semantics.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-typeclass-algebra-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-typeclass-poo-forms file)
   ["Category. compose/identity algebra"
    "Functor. map/tap/ap algebra"
    "Wrapper. wrap/unwrap/bind/map algebra"
    "ParametricFunctor. higher-kinded adapter boundary"
    "methods.io<-wrap lifts IO/JSON/bytes/marshal through wrap/unwrap"
    "method bodies stay protocol-shaped instead of table-shaped"]))

;;; Target projection keeps typeclass advice attached to the POO declaration.
;;; The upstream filter owns algebra recognition, so this function only exposes
;;; the repair target names.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-typeclass-algebra-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-typeclass-poo-forms file)
   poo-form-fact-name))

;;; Boundary:
;;; - Typeclass detection consumes POO options emitted by parser/poo.ss.
;;; - The option vocabulary mirrors gerbil-poo/fun.ss algebra families.
;; : (-> SourceFile (List PooFormFact) )
(def (typed-combinator-style-typeclass-poo-forms file)
  (filter typed-combinator-style-typeclass-poo-form?
          (source-file-poo-forms file)))

;;; Option predicate:
;;; - Compare only parser-owned option tokens from parser/poo.ss.
;;; - The inline lambda keeps the accepted algebra vocabulary local and avoids
;;;   spreading raw typeclass strings through policy assembly.
;; : (-> PooFormFact Boolean )
(def (typed-combinator-style-typeclass-poo-form? fact)
  (ormap (lambda (option)
           (member option
                   ["typeclass:category"
                    "typeclass:functor"
                    "typeclass:parametric-functor"
                    "typeclass:wrapper"
                    "categoryAlgebra:compose-identity"
                    "functorAlgebra:tap-ap-map"
                    "wrapperAlgebra:wrap-unwrap-bind-map"]))
         (poo-form-fact-options fact)))
