;;; -*- Gerbil -*-
;;; Policy bridge for learned Gerbil quality metadata.
;;; This module keeps research corpus references structured without turning
;;; gerbil-utils, gerbil-poo, or gerbil:// references into runtime dependencies.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/detection
        :asp-gerbil-scheme/src/policy/prototype
        (only-in :std/srfi/1 find)
        (only-in :std/sugar ormap))

(export gerbil-utils-source-detection-overlay
        gerbil-utils-source-details
        quality-reference-details
        typed-combinator-style-quality-reference-details
        typed-combinator-style-gerbil-utils-source-details)

;;; Base profile:
;;; - gerbil-utils source evidence is now a C3 slot profile like other policy
;;;   descriptors, not a side table bolted onto detection.
;;; - Source owners remain advisory strings until gerbil-utils:// selectors are
;;;   provider-owned facts.
;; SourceBackedProfile
(def +gerbil-utils-source-base-profile+
  (slot-profile
   "gerbil-utils-source-base"
   [(cons 'profileComposition
          "policy/prototype slot-profile + POO/C3 source-profile overlay")
    (cons 'sourceFamily "gerbil-utils")]))

;;; Constructor boundary:
;;; - Keep profile literals compact while preserving named record fields.
;;; - gerbil-utils entries are study examples for style and quality, not
;;;   downstream dependency requirements.
;; : (-> PatternKind SourcePattern (List SourceOwner) (List QualitySignal) Witness SourceBackedProfile )
(def (make-gerbil-utils-source-profile kind source-pattern source-owners quality-signals witness)
  (slot-profile
   source-pattern
   [(cons 'kind kind)
    (cons 'source-pattern source-pattern)
    (cons 'source-owners source-owners)
    (cons 'quality-signals quality-signals)
    (cons 'witness witness)]
   supers: [+gerbil-utils-source-base-profile+]))

;;; Reference profile table boundary:
;;; - These profiles are research-backed policy overlays, not activation state.
;;; - Each entry names corpus examples, repair signals, and one witness sentence.
;;; - Keep exemplar expansion here so downstream policies stay compact.
;; (List SourceBackedProfile)
(def +gerbil-utils-source-profiles+
  [(make-gerbil-utils-source-profile
    'predicate-combinator
    "gerbil-utils-predicate-combinator"
    ["gerbil-utils/base.ss#lambda-match/lambda-ematch"
     "gerbil-utils/base.ss#fun"
     "gerbil-utils/base.ss#compose/rcompose"
     "gerbil-utils/base.ss#cut/curry/rcurry"
     "gerbil-utils/base.ss#ensure-function"
     "gerbil-utils/generator.ss#generating-map/fold"]
    ["small-selector-helper"
     "lambda-match-destructuring"
     "lambda-match-rewrite-opportunity"
     "named-lambda-helper"
     "expression-level-composition"
     "predicate-combinator"
     "function-pipeline-abstraction"
     "generator-aware-transform"]
    "gerbil-utils study: lambda-match/lambda-ematch, fun, compose/rcompose, cut/curry/rcurry, and generator map/fold are style witnesses for bounded predicate or selector repair")
   (make-gerbil-utils-source-profile
    'higher-order-expression
    "gerbil-utils-higher-order-expression"
    ["gerbil-utils/base.ss#lambda-match/lambda-ematch"
     "gerbil-utils/base.ss#fun"
     "gerbil-utils/base.ss#compose/rcompose/!>/!!>"
     "gerbil-utils/base.ss#left-to-right"
     "gerbil-utils/base.ss#cut/curry/rcurry"
     "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
     "gerbil-utils/base.ss#case-lambda specializers"
     "gerbil-utils/generator.ss#compose-backed-generating-map"]
   ["lambda-match-destructuring"
     "lambda-match-rewrite-opportunity"
     "named-lambda-helper"
     "function-specialization-abstraction"
     "function-pipeline-abstraction"
     "pipeline-composition"
     "cut-prefix-predicate"
     "thin-wrapper-elimination"
     "multi-arity-abstraction"
     "generator-composition"]
    "gerbil-utils and gerbil:// study: prefer real higher-order expression idioms before inventing helper-only rewrites")
   (make-gerbil-utils-source-profile
    'macro-phase-optimizer-visible-fast-path
    "macro-phase-optimizer-visible-fast-path"
    ["gerbil://README.md#meta-syntactic-tower"
     "gerbil://gerbil/expander/top.ss#begin-syntax-phi-plus-one"
     "gerbil://gerbil/compiler/ssxi.ss#declare-inline-rule!"
     "gerbil://gerbil/compiler/optimize-call.ss#%#call-unchecked"
     "gerbil://gerbil/compiler/method.ss#defcompile-method"]
    ["phase-aware-macro-boundary"
     "generated-runtime-helper"
     "lexical-direct-helper"
     "optimizer-visible-call-shape"
     "known-call-fast-path-preserved"]
   "gerbil:// study: the strongest Gerbil macro DSLs keep expansion powerful while generating ordinary lexical runtime helpers that remain visible to SSXI metadata and known-call optimization")
   (make-gerbil-utils-source-profile
    'phase-aware-macro-boundary
    "gerbil-phase-aware-macro-boundary"
    ["gerbil://README.md#meta-syntactic-tower"
     "gerbil://gerbil/expander/top.ss#begin-syntax-phi-plus-one"
     "gerbil://gerbil/expander/core.ss#core-context-shift"
     "gerbil://gerbil/expander/module.ss#core-expand-module-begin"
     "gerbil-utils/syntax.ss#begin-syntax-parse-formals"]
    ["meta-syntactic-tower-boundary"
     "phase-aware-macro-boundary"
     "phase-shift-context-boundary"
     "hygienic-transformer-boundary"
     "runtime-helper-boundary"
     "expansion-contract-doc"]
    "gerbil:// expander study: phase-aware macro quality comes from separating phase/context parsing, hygienic transformer expansion, and ordinary runtime helpers instead of mixing the meta-syntactic tower into one runtime-facing owner")
   (make-gerbil-utils-source-profile
    'gerbil-upstream-idiom-performance
    "gerbil-upstream-idiom-performance"
    ["gerbil://gerbil/core/match.ss#match/match*"
     "gerbil://gerbil/core/match.ss#with/with*"
     "gerbil://gerbil/compiler/optimize-spec.ss#make-hash-table-eq-method-calls"
     "gerbil://gerbil/compiler/optimize-spec.ss#cut-compile-e"
     "gerbil://gerbil/compiler/optimize-top.ss#optimizer-cache-facts"]
   ["gerbil-upstream-idiom-boundary"
     "match-shape-dispatch"
     "with-destructuring-boundary"
     "eq-hash-index-hot-path"
     "cut-helper-plumbing"
     "hash-index-outside-traversal"]
    "gerbil:// core/compiler study: high-value AI-scaffold repair starts with match/with shape dispatch, precomputed eq hash indexes for repeated symbol or identifier lookups, and cut/curry helper plumbing instead of broad manual loops or wrapper lambdas")
   (make-gerbil-utils-source-profile
    'gambit-numeric-primitive-domain-boundary
    "gambit-numeric-primitive-domain-boundary"
    ["gerbil://doc/reference/dev/optimizing.md#specialized-arithmetic"
     "gerbil://doc/reference/dev/optimizing.md#declare-fixnum-flonum"
     "gerbil://gerbil/compiler/optimize-call.ss#unchecked-signature"
     "gambit://tests/unit-tests/01-fixnum/fxadd.scm#fx+"
     "gambit://tests/unit-tests/01-fixnum/fxadd.scm#fixnum-overflow-exception"
     "gambit://tests/unit-tests/02-flonum/fladd.scm#fl+"]
    ["numeric-domain-contract"
     "fixnum-overflow-covered"
     "flonum-type-covered"
     "hot-loop-primitive-family"
     "gambit-fx-fl-lane"]
    "gerbil:// and gambit:// study: numeric hot-loop quality comes from proving the fixnum/flonum domain at the boundary, testing failure modes, and using fx/fl primitive families only in that bounded lane")
   (make-gerbil-utils-source-profile
    'gerbil-inline-rule-call-shape
    "gerbil-builtin-inline-rule-call-shape"
    ["gerbil://gerbil/runtime/util.ss#declare-inline"
     "gerbil://gerbil/builtin-inline-rules.ssxi.ss#declare-inline-rules!"
     "gerbil://gerbil/builtin-inline-rules.ssxi.ss#ast-rules"
     "gerbil://gerbil/compiler/ssxi.ss#declare-inline-rule!"
     "gerbil://gerbil/compiler/optimize-call.ss#call-unchecked"
     "gerbil://gerbil/compiler/optimize-top.ss#dispatch-lambda-form?"]
    ["lexical-primitive-call"
     "direct-call-shape"
     "fixnum-boundary"
     "no-dynamic-apply"
     "compiler-inline-rule-visible"]
   "gerbil:// compiler study: inline-rule quality comes from lexical direct primitive calls and bounded fixnum lanes instead of dynamic tables or repeated apply that hide call shape from the optimizer")
   (make-gerbil-utils-source-profile
    'ssxi-optimizer-metadata-boundary
    "gerbil-ssxi-optimizer-metadata-boundary"
    ["gerbil://gerbil/compiler/ssxi.ss#declare-inline-rule!"
     "gerbil://gerbil/builtin-inline-rules.ssxi.ss#declare-inline-rules!"
     "gerbil://gerbil/builtin-inline-rules.ssxi.ss#ast-rules"
     "gerbil://gerbil/compiler/optimize-call.ss#call-unchecked"
     "gerbil://gerbil/compiler/optimize-top.ss#dispatch-lambda-form?"
     "gerbil://gerbil/runtime/util.ss#declare-inline"]
    ["ssxi-metadata-boundary"
     "declare-inline-rule-boundary"
     "lexical-primitive-call"
     "direct-call-shape"
     "unchecked-call-visibility"
     "no-dynamic-primitive-table"]
    "gerbil:// compiler study: SSXI metadata is useful only when inline rules, direct primitive calls, and unchecked-call assumptions remain visible at one named optimizer boundary instead of being hidden behind dynamic dispatch tables")
   (make-gerbil-utils-source-profile
    'list-combinator-boundary
    "list-combinator-boundary"
    ["gerbil://std/actor-v13/rpc/proto/cipher.ss#foldl-chunk-accumulator"
     "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
     "gerbil-utils/list.ss#list-map"
     "gerbil-utils/list.ss#list<-monoid"
     "gerbil-utils/list.ss#with-deduplicated-list-builder"
     "gerbil-utils/list.ss#merge-lists"
     "gerbil-utils/base.ss#lambda-match"
     "gerbil-utils/base.ss#compose/rcompose"]
    ["list-combinator-boundary"
     "fold-reducer-boundary"
     "cut-predicate-specialization"
     "map-fold-boundary"
     "filter-map-selection-projection"
     "lambda-match-list-destructuring"
     "list-builder-output-shape"
     "deduplicated-builder-boundary"]
   "gerbil:// source corpus, gerbil-utils/list.ss, and base.ss study: list traversal quality comes from fold reducers, cut-shaped predicates, small mapper/reducer/selector boundaries, lambda-match when pair shape matters, and builders only when output construction needs them")
   (make-gerbil-utils-source-profile
    'loop-driver-combinator-boundary
    "loop-driver-combinator-boundary"
    ["gerbil://std/actor-v13/rpc/proto/cipher.ss#foldl-chunk-accumulator"
     "gerbil-utils/list.ss#list-map"
     "gerbil-utils/list.ss#list<-monoid"
     "gerbil-utils/base.ss#lambda-match"
     "gerbil-utils/base.ss#compose/rcompose"]
    ["manual-loop-drift"
     "pure-loop-driver-combinator-boundary"
     "fold-reducer-boundary"
     "map-fold-boundary"
     "lambda-match-list-destructuring"]
   "gerbil:// source corpus, gerbil-utils/list.ss, and base.ss study: pure named-let drivers should become fold/map/filter-map style transform boundaries when parser facts show no IO, state, generator, or higher-order witness")
   (make-gerbil-utils-source-profile
    'parser-combinator-boundary
    "gerbil-std-parser-combinator-boundary"
    ["gerbil://std/parser/defparser.ss#defparser"
     "gerbil://std/parser/defparser.ss#parser-fail"
     "gerbil://std/parser/defparser.ss#parser-rewind"
     "gerbil://std/parser/rx-parser.ss#raise-parse-error"
     "gerbil://std/parser/rx-parser.ss#make-token"]
    ["parser-combinator-boundary"
     "manual-parser-state-machine"
     "defparser-grammar-boundary"
     "parser-rewind-fail-boundary"
     "source-aware-parse-error"
     "token-construction-boundary"]
    "gerbil:// std/parser study: parser quality comes from defparser grammar owners, parser-fail/parser-rewind control, source-aware parse errors, and token construction at the grammar boundary instead of hand-written string cursor state machines")
   (make-gerbil-utils-source-profile
    'destructuring-combinator-boundary
    "destructuring-combinator-boundary"
    ["gerbil://gerbil/core/match.ss#applicative-destructuring"
     "gerbil://gerbil/core/match.ss#syntax-local-match-macro"
     "gerbil://gerbil/core/match.ss#syntax-local-value-class-accessors"
     "gerbil://gerbil/core/match.ss#defsyntax-for-match"
     "gerbil-utils/base.ss#lambda-match"
     "gerbil-utils/base.ss#let-match"
     "gerbil-utils/base.ss#when-match"
     "gerbil-utils/base.ss#compose/rcompose"
     "gerbil-poo/mop.ss#slot-lens"
     "gerbil-poo/mop.ss#Lens.compose"]
    ["destructuring-combinator-boundary"
     "applicative-destructuring-boundary"
     "syntax-local-match-extension"
     "compile-time-metadata-lookup"
     "early-syntax-error-boundary"
     "lambda-match-destructuring"
     "named-selector-boundary"
     "slot-lens-boundary"
     "temporary-binding-collapse"
     "object-slot-access-boundary"]
    "gerbil:// core match, gerbil-utils/base.ss, and gerbil-poo/mop.ss study: repeated pair/alist/object destructuring should collapse into native match/applicative destructuring, syntax-local metadata lookup, a selector, or local slot/lens boundary instead of generated temporary let scaffolding")
   (make-gerbil-utils-source-profile
    'projection-builder
    "gerbil-utils-projection-builder"
    ["gerbil-utils/base.ss#compose"
     "gerbil-utils/base.ss#cut/curry/rcurry"
     "gerbil/std/cli/getopt.ss#with-list-builder"
     "gerbil/std/actor-v18/server.ss#for/fold"]
    ["projection-helper"
     "line-renderer-boundary"
     "list-builder-output-shape"
     "expression-level-composition"]
    "gerbil-utils/base and Gerbil std show projection/rendering should be split into selectors, line builders, and compact folds instead of hash-get/display walls")
   (make-gerbil-utils-source-profile
    'sequence-protocol
    "gerbil-utils-sequence-protocol"
    ["gerbil-utils/generator.ss#generating<-for-each"
     "gerbil-utils/generator.ss#generating-map"
     "gerbil-utils/generator.ss#generating-fold"
     "gerbil-utils/peekable-iterator.ss#cursor-state"]
    ["named-traversal-protocol"
     "map-fold-boundary"
     "observable-cursor-state"]
    "gerbil-utils study: generator protocol makes traversal state explicit before adding streaming or coroutine behavior")
   (make-gerbil-utils-source-profile
    'generator-control
    "gerbil-utils-generator-control"
    ["gerbil-utils/generator.ss#generating<-for-each"
     "gerbil-utils/generator.ss#yield-continuation-boundary"
     "gerbil-utils/generator.ss#unexpected-yield"
     "gerbil-utils/generator.ss#eof!"
     "gerbil-utils/generator.ss#list<-generating"
     "gerbil-utils/generator.ss#generating<-cothread"]
    ["push-pull-control-inversion"
     "call/cc-yield-boundary"
     "one-shot-generator-protocol"
     "out-of-band-eof-boundary"
     "unexpected-yield-guard"
     "list-adapter-boundary"
     "cothread-finalization-boundary"]
    "gerbil-utils study: generators are push/pull control-inversion boundaries with one-shot semantics, explicit yield continuations, out-of-band EOF, and adapter functions at the stream boundary")
   (make-gerbil-utils-source-profile
    'protocol-serialization-boundary
    "protocol-serialization-boundary"
    ["gerbil-poo/io.ss#marshal"
     "gerbil-poo/io.ss#unmarshal"
     "gerbil-poo/io.ss#bytes<-"
     "gerbil-poo/io.ss#<-bytes"
     "gerbil-poo/io.ss#methods.string<-json"
     "gerbil-poo/io.ss#methods.bytes<-marshal"
     "gerbil-poo/io.ss#methods.marshal<-bytes"
     "gerbil-poo/io.ss#methods.marshal<-fixed-length-bytes"]
   ["protocol-serialization-boundary"
     "self-delimited-marshal-boundary"
     "bytes-non-self-delimited-boundary"
     "json-string-adapter-boundary"
     "reader-writer-symmetry"
     "local-protocol-adapter"]
    "gerbil-poo/io.ss study: serialization quality comes from separating local JSON/string/bytes/marshal protocol adapters, keeping marshal self-delimited, keeping raw bytes representation non-self-delimited, and preserving reader/writer symmetry")
   (make-gerbil-utils-source-profile
    'slot-lens-boundary
    "slot-lens-boundary"
    ["gerbil-poo/mop.ss#slot-checker"
     "gerbil-poo/mop.ss#slot-definer"
     "gerbil-poo/mop.ss#Class.effective-slots"
     "gerbil-poo/mop.ss#Lens.modify"
     "gerbil-poo/mop.ss#Lens.compose"
     "gerbil-poo/mop.ss#slot-lens"]
   ["slot-descriptor-boundary"
     "lens-get-set-modify-boundary"
     "slot-validation-boundary"
     "slot-serialization-boundary"
     "local-lens-helper"
     "reader-writer-symmetry"]
   "gerbil-poo/mop.ss study: slot quality comes from local descriptor/lens boundaries that centralize get/set/modify, validation, and serialization symmetry without requiring a gerbil-poo dependency")
   (make-gerbil-utils-source-profile
    'typeclass-wrapper-adapter
    "typeclass-wrapper-adapter"
    ["gerbil-poo/fun.ss#Category."
     "gerbil-poo/fun.ss#Functor."
     "gerbil-poo/fun.ss#ParametricFunctor."
     "gerbil-poo/fun.ss#methods.io<-wrap"
     "gerbil-poo/fun.ss#Wrapper."
     "gerbil-poo/fun.ss#Wrap."
     "gerbil-poo/fun.ss#Wrap^."]
   ["typeclass-algebra-boundary"
     "functor-map-ap-boundary"
     "wrapper-adapter-lift"
     "wrap-unwrap-boundary"
     "method-protocol-lift"
     "cut-backed-runtime-parameterization"]
    "gerbil-poo/fun.ss study: wrapper and functor quality comes from keeping wrap/unwrap as the only representation crossing, lifting IO/JSON/bytes/marshal methods through local adapters, and preserving map/ap algebra without requiring a gerbil-poo dependency")
   (make-gerbil-utils-source-profile
    'compiler-method-pass-boundary
    "gerbil-compiler-method-pass-boundary"
    ["gerbil://gerbil/compiler/method.ss#defcompile-method"
     "gerbil://gerbil/compiler/method.ss#compile-e"
     "gerbil://gerbil/compiler/method.ss#apply-begin%"
     "gerbil://gerbil/compiler/method.ss#xform-wrap-source"
     "gerbil://gerbil/compiler/optimize-top.ss#apply-collect-type-info"
     "gerbil://gerbil/compiler/optimize-top.ss#dispatch-lambda-form?"
     "gerbil://gerbil/compiler/optimize-top.ss#lift-case-lambda-clauses"]
    ["method-table-pass-boundary"
     "ast-case-shape-dispatch"
     "delayed-method-binding"
     "sealed-compile-method-class"
     "source-preserving-transform"
     "typed-pass-pipeline"
     "dispatch-lambda-delegate-boundary"]
    "gerbil:// compiler study: method-table quality comes from table-driven AST pass methods, delayed method binding, ast-case shape predicates, source-preserving transforms, and typed pass pipelines instead of broad cond dispatch or ad hoc method bodies")
   (make-gerbil-utils-source-profile
   'concurrency-control-boundary
   "concurrency-control-boundary"
    ["gerbil://gerbil/runtime/control.ss#make-atomic-promise"
     "gerbil://gerbil/runtime/control.ss#call-with-parameters"
     "gerbil://gerbil/runtime/control.ss#with-unwind-protect"
     "gerbil-utils/concurrency.ss#sequentialize/mutex"
     "gerbil-utils/concurrency.ss#race/list"
     "gerbil-utils/concurrency.ss#parallel-map"
     "gerbil-utils/concurrency.ss#spawn/name/params"
     "gerbil-utils/concurrency.ss#all-thread-parameters"]
    ["concurrency-control-boundary"
     "dynamic-wind-reentry-guard"
     "unwind-cleanup-boundary"
     "spawn-join-helper-boundary"
     "mutex-sequentialization-boundary"
     "race-shutdown-boundary"
     "parallel-map-join-boundary"
     "thread-parameter-propagation"]
   "gerbil:// runtime control and gerbil-utils/concurrency.ss study: concurrency quality comes from preserving dynamic-wind reentry guards and unwind cleanup while naming spawn/join, mutex sequentialization, race shutdown, parallel map, and thread-parameter propagation boundaries without requiring a gerbil-utils dependency")
   (make-gerbil-utils-source-profile
    'dynamic-scope-cleanup-boundary
    "gerbil-runtime-dynamic-scope-cleanup-boundary"
    ["gerbil://gerbil/runtime/control.ss#dynamic-wind"
     "gerbil://gerbil/runtime/control.ss#with-unwind-protect"
     "gerbil://gerbil/runtime/control.ss#call-with-parameters"
     "poo-flow/build.ss#poo-flow-with-directory"
     "asp-gerbil-scheme/src/build-api/source-coverage.ss#with-directory"]
    ["dynamic-scope-cleanup-boundary"
     "manual-dynamic-scope-restore"
     "dynamic-wind-cleanup-boundary"
     "parameterize-state-boundary"
     "unwind-cleanup-boundary"]
    "gerbil:// runtime control, poo-flow, and harness build helpers show dynamic state quality: current-directory/current-port changes must restore through dynamic-wind, with-unwind-protect, or parameterize instead of a post-thunk manual setter")
   (make-gerbil-utils-source-profile
    'actor-runtime-boundary
    "gerbil-actor-runtime-boundary"
    ["gerbil://std/actor-v18/executor.ss#spawn-actor-worker"
     "gerbil://std/actor-v18/server.ss#actor-server-loop"
     "gerbil://std/actor-v18/message.ss#mailbox-message"
     "gerbil://gerbil/runtime/control.ss#call-with-parameters"
     "gerbil-utils/concurrency.ss#spawn/name/params"]
    ["actor-runtime-boundary"
     "mailbox-protocol-boundary"
     "actor-lifecycle-helper"
     "actor-shutdown-boundary"
     "actor-parameter-propagation"
     "supervision-cleanup-boundary"]
    "gerbil:// actor/runtime study: actor quality comes from explicit mailbox protocol, lifecycle, shutdown, supervision, and parameter propagation helpers instead of a single collapsed handler loop")
   (make-gerbil-utils-source-profile
    'exception-continuation-boundary
    "exception-continuation-boundary"
    ["gerbil-utils/exception.ss#string<-exception"
     "gerbil-utils/exception.ss#with-catch/cont"
     "gerbil-utils/exception.ss#escaping-handler"
     "gerbil-utils/exception.ss#call-with-logged-exceptions"
     "gerbil-utils/exception.ss#thunk-with-logged-exceptions"
     "gerbil-utils/exception.ss#with-logged-exceptions"]
    ["exception-continuation-boundary"
     "handler-restoration-boundary"
     "contextual-exception-logging"
     "re-raise-after-logging"
     "printable-exception-fallback"
     "local-exception-wrapper"]
    "gerbil-utils/exception.ss study: exception quality comes from capturing continuation context, restoring the prior handler before escaping, logging contextual diagnostics, and re-raising instead of swallowing failures")
   (make-gerbil-utils-source-profile
    'stateful-structure
    "gerbil-utils-stateful-structure"
    ["gerbil-utils/stateful-avl-map.ss#avl-map-update-height!"
     "gerbil-utils/stateful-avl-map.ss#avl-map-rotate-left!/right!"
     "gerbil-utils/stateful-avl-map.ss#avl-map-balance!"
     "gerbil-utils/stateful-avl-map.ss#avl-map-put!/remove!"
     "gerbil-utils/stateful-avl-map.ss#generating<-avl-map"
     "gerbil-utils/stateful-avl-map.ss#table<-avl-map/alist<-avl-map"]
    ["bounded-mutable-invariant"
     "height-cache-maintenance"
     "rotation-comment-boundary"
     "local-structural-mutation"
     "generator-adapter-boundary"
     "table-alist-conversion-boundary"]
    "gerbil-utils study: stateful AVL mutation is acceptable when it is local to a data-structure invariant, documents rotations, maintains cached height, and exposes generator/table/alist adapters at the boundary")
   (make-gerbil-utils-source-profile
    'macro-helper
    "gerbil-utils-controlled-macro-helper"
   ["gerbil://gerbil/compiler/method.ss#ast-case-with-syntax-map-cut"
    "gerbil://gerbil/expander/core.ss#current-expander-context"
    "gerbil://gerbil/expander/core.ss#core-apply-user-macro"
    "gerbil://gerbil/expander/core.ss#core-context-shift"
    "gerbil://gerbil/expander/module.ss#core-expand-module-begin"
    "gerbil://gerbil/expander/module.ss#core-expand-import%"
     "gerbil-utils/syntax.ss#defsyntax-stx"
     "gerbil-utils/syntax.ss#syntax-case"
     "gerbil-utils/syntax.ss#begin-syntax parse-formals"
     "gerbil-utils/autocurry.ss#syntax-rules"
     "gerbil-utils/base.ss#nest"
     "gerbil-utils/base.ss#left-to-right"]
   ["controlled-macro-helper"
     "macro-hygiene-boundary"
     "parameterized-expander-state"
     "typed-context-record-boundary"
     "phase-shift-context-boundary"
     "source-aware-syntax-error"
     "ast-case-transformer-boundary"
     "with-syntax-reconstruction-boundary"
     "syntax-case-with-local-parser"
     "syntax-rules-thin-dsl"
     "thin-syntax-bridge"
     "runtime-helper-boundary"
     "expansion-contract-doc"]
   "gerbil:// source corpus and gerbil-utils study: macros are allowed when they are thin hygienic syntax wrappers, use ast-case/syntax-case or syntax-rules for local parsing, reconstruct with with-syntax, parameterize expander phase/context state instead of mutating globals, and keep reusable runtime behavior outside the transformer")
   (make-gerbil-utils-source-profile
    'macro-metaprogramming-decision-boundary
    "gerbil-macro-metaprogramming-decision-boundary"
    ["gerbil://gerbil/core/sugar.ss#defrules"
     "gerbil://gerbil/core/sugar.ss#defrule"
     "gerbil://std/sugar.ss#chain"
     "gerbil://std/sugar.ss#let-hash"
     "gerbil://gerbil/core/match.ss#defsyntax-for-match"
     "gerbil://gerbil/core/mop.ss#defclass"]
    ["macro-metaprogramming-decision-boundary"
     "declarative-macro-pattern"
     "syntax-rules-macro-family"
     "procedural-macro-transformer"
     "syntax-object-validation"
     "identifier-reconstruction"
     "with-syntax-reconstruction"
     "with-syntax-reconstruction-boundary"
     "source-aware-syntax-error"
     "phase-extension-hook"
     "runtime-helper-boundary"
     "expansion-contract-doc"]
    "gerbil:// core and std/sugar study: use declarative defrules/syntax-rules when the syntax is a fixed rewrite family, and reserve procedural syntax-case/with-syntax for syntax-object validation, identifier reconstruction, source-aware errors, or phase-specific extension points")
   (make-gerbil-utils-source-profile
    'syntax-parameterized-context-boundary
    "gerbil-syntax-parameterized-context-boundary"
    ["gerbil://std/stxparam.ss#defsyntax-parameter"
     "gerbil://std/stxparam.ss#defsyntax-parameter*"
     "gerbil://std/stxparam.ss#syntax-parameterize"
     "gerbil://std/text/csv.ss#ambient-csv-options"
     "gerbil://std/actor-v18/message.ss#@envelope"]
    ["syntax-parameterized-context-boundary"
     "syntax-parameter-definition"
     "syntax-parameterized-context"
     "syntax-local-context-lookup"
     "phase-local-syntax-binding"
     "global-macro-state-mutation"
     "manual-phase-context-threading"
     "source-aware-syntax-error"]
    "gerbil:// std/stxparam study: use defsyntax-parameter* and syntax-parameterize for scoped compile-time context instead of mutable global macro state or hidden phase context threading")
   (make-gerbil-utils-source-profile
    'syntax-local-registry-boundary
    "gerbil-syntax-local-registry-boundary"
    ["gerbil://std/generic/macros.ss#generic-info"
     "gerbil://std/generic/macros.ss#defgeneric"
     "gerbil://std/protobuf/macros.ss#syntax-local-type"
     "gerbil://std/protobuf/proto.ss#syntax-local-value"
     "gerbil://std/actor-v13/proto.ss#defproto"]
    ["syntax-local-registry-boundary"
     "manual-syntax-registry-table"
     "syntax-datum-registry-key"
     "syntax-local-registry-lookup"
     "compile-time-metadata-binding"
     "source-aware-syntax-error"
     "runtime-helper-boundary"]
    "gerbil:// generic/protobuf/actor proto study: attach compile-time metadata to identifiers with defsyntax metadata objects and read it with syntax-local-value instead of maintaining syntax->datum keyed macro hash tables")
   (make-gerbil-utils-source-profile
    'match-extension-boundary
    "gerbil-core-match-extension-boundary"
    ["gerbil://gerbil/core/match.ss#match-macro"
     "gerbil://gerbil/core/match.ss#syntax-local-match-macro?"
     "gerbil://gerbil/core/match.ss#parse-match-pattern"
     "gerbil://gerbil/core/match.ss#struct-field-accessors"
     "gerbil://gerbil/core/match.ss#defsyntax-for-match"
     "gerbil://gerbil/core/match.ss#defrules-for-match"]
    ["match-extension-boundary"
     "match-macro-destructuring-boundary"
     "syntax-local-match-macro-boundary"
     "applicative-destructuring-boundary"
     "struct-class-accessor-boundary"
     "source-aware-pattern-error-boundary"]
    "gerbil:// core/match.ss study: match extension quality comes from defsyntax-for-match, syntax-local match macro lookup, applicative destructuring, struct/class accessor extraction, and source-aware pattern errors instead of table-shaped runtime dispatchers")
   (make-gerbil-utils-source-profile
    'mop-class-macro-boundary
    "gerbil-core-mop-class-macro-boundary"
    ["gerbil://gerbil/core/mop.ss#defclass"
     "gerbil://gerbil/core/mop.ss#defmethod"
     "gerbil://gerbil/core/mop.ss#generate-defclass"
     "gerbil://gerbil/core/mop.ss#class-type-info"
     "gerbil://gerbil/core/mop.ss#get-mixin-slots"
     "gerbil://gerbil/core/mop.ss#bind-method!"]
    ["mop-class-macro-boundary"
     "class-descriptor-macro-boundary"
     "class-type-info-boundary"
     "mixin-slot-accessor-boundary"
     "method-binding-boundary"
     "constructor-predicate-metadata-boundary"
     "slot-contract-metadata-boundary"]
    "gerbil:// core/mop.ss study: class macro quality comes from expansion-time class-type-info descriptors, generated slot/mixin accessors and mutators, explicit constructor/predicate/metaclass metadata, and narrow runtime method binding instead of table-shaped class DSLs")
   (make-gerbil-utils-source-profile
    'default
    "gerbil-utils-quality-pattern"
    ["gerbil-utils/base.ss"
     "gerbil-utils/generator.ss"
     "gerbil-utils/syntax.ss"]
    ["compact-helper"
     "source-backed-style-exemplar"]
    "gerbil-utils study: source-backed style exemplar for compact, typed, expression-level Gerbil helpers")])

;;; Boundary:
;;; - gerbil-utils is a style and engineering exemplar, not an activation
;;;   protocol like gerbil-poo.
;;; - Keep reference examples as advisory evidence, not downstream import
;;;   requirements.
;; : (-> PatternKind DetectionPrototype )
(def (gerbil-utils-source-detection-overlay kind)
  (let (profile (gerbil-utils-source-profile kind))
    (detection-prototype-extend
     (detection-prototype-source-overlay
      (gerbil-utils-source-pattern-id kind)
      (gerbil-utils-source-owners kind)
      (gerbil-utils-quality-signals kind)
      (gerbil-utils-source-witness kind))
     (slot-profile
      (string-append (gerbil-utils-source-pattern-id kind)
                     "-source-profile-overlay")
      [(cons 'source-profile-composition
             (gerbil-utils-source-profile-composition profile))
       (cons 'source-profile-precedence
             (slot-profile-precedence-names profile))]))))

;;; JSON detail boundary:
;;; - TypeFinding details need plain hash data for provider output.
;;; - The profile record remains the internal source of truth.
;;; - Expose learned quality references, not source-owner requirements.
;; : (-> PatternKind PolicyDetails )
(def (gerbil-utils-source-details kind)
  (let (profile (gerbil-utils-source-profile kind))
    (hash (referencePattern (source-backed-profile-source-pattern profile))
          (referenceExamples (source-backed-profile-source-owners profile))
          (qualitySignals (source-backed-profile-quality-signals profile))
          (witness (source-backed-profile-witness profile))
          (profileComposition
           (gerbil-utils-source-profile-composition profile))
          (profilePrecedence (slot-profile-precedence-names profile)))))

;;; Neutral reference boundary:
;;; - Callers should use this name for agent-facing quality references.
;;; - The old gerbil-utils-source name remains only as an internal storage
;;;   owner while the corpus includes gerbil-utils and gerbil-poo examples.
;; : (-> PatternKind PolicyDetails )
(def (quality-reference-details kind)
  (gerbil-utils-source-details kind))

;;; Typed-combinator bridge:
;;; - Select the learned reference from parser-owned quality facets.
;;; - The returned payload is neutral quality evidence, never an import
;;;   recommendation for the reference corpus package.
;; : (-> SourceFile QualityFacets PolicyDetails )
(def (typed-combinator-style-quality-reference-details file quality-facets)
  (quality-reference-details
   (typed-combinator-style-gerbil-utils-source-kind file quality-facets)))

;;; Typed-combinator bridge:
;;; - Select the source-backed profile from parser-owned facts and facets.
;;; - The result is report evidence; R013 triggering remains in agent-style.ss.
;; : (-> SourceFile QualityFacets PolicyDetails )
(def (typed-combinator-style-gerbil-utils-source-details file quality-facets)
  (typed-combinator-style-quality-reference-details file quality-facets))

;;; Selection boundary:
;;; - Specific parser-owned risk facets win before broad higher-order style.
;;; - The ordering prevents a serialization or generator protocol warning from
;;;   being flattened into a generic expression-composition reference.
;;; - Returned kinds are quality references, not package dependency choices.
;; : (-> SourceFile QualityFacets PatternKind )
(def (typed-combinator-style-gerbil-utils-source-kind file quality-facets)
  (cond
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["macro-phase-optimizer-visible-fast-path"
      "phase-macro-generated-wrapper"
      "optimizer-visible-call-shape"])
    'macro-phase-optimizer-visible-fast-path)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["phase-aware-macro-boundary"
      "meta-syntactic-tower-boundary"])
    'phase-aware-macro-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["mop-class-macro-boundary"
      "class-descriptor-macro-boundary"])
    'mop-class-macro-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["macro-metaprogramming-decision-boundary"
      "declarative-procedural-macro-selection"])
    'macro-metaprogramming-decision-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["syntax-parameterized-context-boundary"
      "manual-phase-context-threading"])
    'syntax-parameterized-context-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["syntax-local-registry-boundary"
      "manual-syntax-registry-table"])
    'syntax-local-registry-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["match-extension-boundary"
      "match-macro-destructuring-boundary"])
    'match-extension-boundary)
   ((pair? (source-file-macros file)) 'macro-helper)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["protocol-serialization-boundary"])
    'protocol-serialization-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["slot-lens-boundary"])
    'slot-lens-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["poo-typeclass-algebra-boundary"])
    'typeclass-wrapper-adapter)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["method-table-combinator-body"
      "method-table-lambda-drift"
      "method-table-low-level-body"])
    'compiler-method-pass-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["concurrency-control-boundary"])
    'concurrency-control-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["dynamic-scope-cleanup-boundary"
      "manual-dynamic-scope-restore"])
    'dynamic-scope-cleanup-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["actor-runtime-boundary"
      "mailbox-protocol-boundary"])
    'actor-runtime-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["exception-continuation-boundary"])
    'exception-continuation-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["generator-combinator-boundary"])
    'generator-control)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["gerbil-inline-rule-call-shape"
      "dynamic-apply-hot-loop"
      "compiler-inline-rule-obscured"])
    'gerbil-inline-rule-call-shape)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["gambit-numeric-primitive-boundary"
      "numeric-domain-contract"
      "generic-numeric-hot-loop"])
    'gambit-numeric-primitive-domain-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["ssxi-optimizer-metadata-boundary"
      "optimizer-metadata-contract"])
    'ssxi-optimizer-metadata-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["list-combinator-boundary"])
    'list-combinator-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["manual-loop-drift"])
    'loop-driver-combinator-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["destructuring-combinator-boundary"])
    'destructuring-combinator-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["gerbil-upstream-idiom-boundary"])
    'gerbil-upstream-idiom-performance)
   ((or (pair? (source-file-higher-order-forms file))
        (gerbil-utils-source-quality-facet-any?
         quality-facets
         ["base-style-combinator-composition"
          "higher-order-constructor-abstraction"
          "arity-specialized-function-factory"
          "wrapper-lambda-drift"
          "function-specialization-opportunity"
          "eta-wrapper-drift"
          "lambda-match-destructuring"
          "lambda-match-rewrite-opportunity"
          "function-specialization-abstraction"
          "function-pipeline-abstraction"]))
    'higher-order-expression)
   (else 'default)))

;;; Facet helper stays local so this source bridge does not depend on the main
;;; R013 policy owner's private predicate vocabulary.
;; : (-> QualityFacets (List QualityFacet) Boolean )
(def (gerbil-utils-source-quality-facet-any? facets candidates)
  (ormap (lambda (candidate)
           (if (member candidate facets) #t #f))
         candidates))

;;; Accessor boundary:
;;; - Public helpers expose stable policy fields.
;;; - Internal profile representation can change without touching callers.
;; : (-> PatternKind String )
(def (gerbil-utils-source-pattern-id kind)
  (source-backed-profile-source-pattern (gerbil-utils-source-profile kind)))

;;; Example accessor keeps advisory anchors grouped as reference evidence.
;; : (-> PatternKind (List SourceOwner) )
(def (gerbil-utils-source-owners kind)
  (source-backed-profile-source-owners (gerbil-utils-source-profile kind)))

;;; Quality accessor feeds parser-owned repair steering.
;; : (-> PatternKind (List QualitySignal) )
(def (gerbil-utils-quality-signals kind)
  (source-backed-profile-quality-signals (gerbil-utils-source-profile kind)))

;;; Witness accessor keeps prose at the report edge instead of policy logic.
;; : (-> PatternKind Witness )
(def (gerbil-utils-source-witness kind)
  (source-backed-profile-witness (gerbil-utils-source-profile kind)))

;;; Lookup boundary:
;;; - Unknown patterns intentionally fall back to the default exemplar.
;;; - The default keeps repair guidance available without inventing a match.
;; : (-> PatternKind SourceBackedProfile )
(def (gerbil-utils-source-profile kind)
  (or (find (lambda (profile)
              (eq? (source-backed-profile-kind profile) kind))
            +gerbil-utils-source-profiles+)
      (find (lambda (profile)
              (eq? (source-backed-profile-kind profile) 'default))
            +gerbil-utils-source-profiles+)))

;; : (-> SourceBackedProfile PatternKind )
(def (source-backed-profile-kind profile)
  (slot-profile-ref profile 'kind 'default))

;; : (-> SourceBackedProfile SourcePattern )
(def (source-backed-profile-source-pattern profile)
  (slot-profile-ref profile 'source-pattern "gerbil-utils-quality-pattern"))

;; : (-> SourceBackedProfile (List SourceOwner) )
(def (source-backed-profile-source-owners profile)
  (slot-profile-ref profile 'source-owners '()))

;; : (-> SourceBackedProfile (List QualitySignal) )
(def (source-backed-profile-quality-signals profile)
  (slot-profile-ref profile 'quality-signals '()))

;; : (-> SourceBackedProfile Witness )
(def (source-backed-profile-witness profile)
  (slot-profile-ref profile 'witness ""))

;; : (-> SourceBackedProfile String )
(def (gerbil-utils-source-profile-composition profile)
  (slot-profile-ref profile 'profileComposition ""))
