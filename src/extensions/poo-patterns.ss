;;; -*- Gerbil -*-
;;; Gerbil-poo pattern specs and accessors for extension search packets.
;;; Boundary:
;;; - Owns source-backed pattern families and selector/schema payloads.
;;; - Keeps :asp-gerbil-scheme/src/extensions/poo focused on activation and origin dispatch.

(import :asp-gerbil-scheme/src/extensions/poo-pattern-support
        :asp-gerbil-scheme/src/extensions/poo-pattern-typeclass
        (only-in :std/srfi/13 string-join)
        (only-in :std/sugar hash))

(export poo-pattern-id
        poo-pattern-focus
        poo-pattern-source-owners
        poo-pattern-agent-scenario
        poo-pattern-agent-steering
        poo-pattern-intent
        poo-pattern-selectors
        poo-pattern-minimal-forms
        poo-pattern-failure-cases
        poo-pattern-quality-signals
        poo-pattern-witness
        poo-pattern-missing
        poo-pattern-next)

;;; Boundary:
;;; - Object-system is the base prototype for all POO pattern families.
;;; - Shared source owners and failure cases must stay inherited unless a family overrides them.
;; PatternSpec
(def +poo-object-system-pattern-spec+
  (make-poo-pattern-spec
  id: "poo-object-system"
  defaultFocus: "object-system"
  sourceOwners: ["object.ss"
                 "mop.ss"
                 "proto.ss"
                 "table.ss"
                 "trie.ss"
                 "type.ss"
                 "rationaldict.ss"
                 ":gerbil/runtime/c3"
                 "src/gerbil/test/c3-test.ss"]
  agentScenario: "agent-does-not-know-gerbil-poo-object-system"
  agentSteering: "follow the emitted selectors and minimal forms before writing Gerbil POO code; avoid Racket class or generic Scheme object guesses"
  intent: "write-gerbil-poo-object-system-without-racket-or-generic-scheme-guessing"
  selectors:
      [(poo-selector "class-definition"
                     "defclass"
                     "gerbil-poo://object.ss#defclass")
       (poo-selector "generic-definition"
                     ".defgeneric"
                     "gerbil-poo://mop.ss#.defgeneric")
       (poo-selector "method-dispatch"
                     "defmethod"
                     "gerbil-poo://mop.ss#defmethod")
       (poo-selector "protocol-composition"
                     "proto"
                     "gerbil-poo://mop.ss#proto")
       (poo-selector "prototype-composition"
                     "compose-proto"
                     "gerbil-poo://proto.ss#compose-proto")
       (poo-selector "thin-macro-bridge"
                     "@method"
                     "gerbil-poo://brace.ss#@method")
       (poo-selector "slot-resolution"
                     "compute-precedence-list!"
                     "gerbil-poo://object.ss#compute-precedence-list!")
       (poo-selector "slot-cache"
                     "compute-slot-funs!"
                     "gerbil-poo://object.ss#compute-slot-funs!")
       (poo-selector "io-serialization-method-family"
                     "marshal"
                     "gerbil-poo://io.ss#marshal")
       (poo-selector "required-slot-protocol"
                     "methods.table"
                     "gerbil-poo://table.ss#methods.table")
       (poo-selector "role-translation-adapter"
                     "Set<-Table."
                     "gerbil-poo://table.ss#Set<-Table.")
       (poo-selector "representation-invariant"
                     "$Costep"
                     "gerbil-poo://trie.ss#$Costep")
       (poo-selector "type-descriptor-composition"
                     "List."
                     "gerbil-poo://type.ss#List.")
       (poo-selector "dependency-backed-adapter"
                     "RationalSet"
                     "gerbil-poo://rationaldict.ss#RationalSet")
       (poo-selector "method-resolution-order"
                     "class-precedence-list"
                     "gerbil-runtime://c3.ss#class-precedence-list")
       (poo-selector "real-project-semantic-test"
                     "c3-test"
                     "gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test")]
  minimalForms:
      [(poo-form-mapping "class-definition"
                         "defclass"
                         "defclass"
                         ["(<Class> <Base>)" "(<slot> ...)"]
                         ["transparent: #t"]
                         "gerbil-poo://object.ss#defclass")
       (poo-form-mapping "generic-definition"
                         ".defgeneric"
                         ".defgeneric"
                         ["(<generic> <type> <arg>)"]
                         ["slot: .<slot>"]
                         "gerbil-poo://mop.ss#.defgeneric")
       (poo-form-mapping "method-dispatch"
                         "defmethod"
                         "defmethod"
                         ["(@@method <generic> <type>)"
                          "(lambda (self) ...)"]
                         []
                         "gerbil-poo://mop.ss#defmethod")
       (poo-form-mapping "protocol-composition"
                         "compose-proto"
                         "compose-proto"
                         ["<proto-a>" "<proto-b>"]
                         []
                         "gerbil-poo://proto.ss#compose-proto")
       (poo-form-mapping "thin-macro-bridge"
                         "@method"
                         "defsyntax-for-match"
                         ["{args ...}->.o/ctx"]
                         ["syntax-bridge-only"]
                         "gerbil-poo://brace.ss#@method")
       (poo-form-mapping "slot-resolution"
                         ".all-slots"
                         ".all-slots"
                         ["<object>"]
                         ["C3-precedence" "lazy-slot-cache"]
                         "gerbil-poo://object.ss#.all-slots")
       (poo-form-mapping "io-serialization-method-family"
                         "marshal"
                         ".defgeneric"
                         ["(marshal type x port)" "slot:.marshal"]
                         ["json<-" "<-json" "bytes<-" "<-bytes"]
                         "gerbil-poo://io.ss#marshal")
       (poo-form-mapping "required-slot-protocol"
                         "methods.table"
                         "define-type"
                         ["Key" "Value" ".empty" ".acons" ".ref"
                          ".remove" ".foldl" ".foldr"]
                         ["derive-secondary-capabilities"]
                         "gerbil-poo://table.ss#methods.table")
       (poo-form-mapping "role-translation-adapter"
                         "Set<-Table."
                         "define-type"
                         ["Table key/value callbacks" "set element callbacks"]
                         ["translate-role-not-storage"]
                         "gerbil-poo://table.ss#Set<-Table.")
       (poo-form-mapping "representation-invariant"
                         "$Costep"
                         "defstruct"
                         ["height" "key"]
                         ["height-before-next-step" "key-high-bits"]
                         "gerbil-poo://trie.ss#$Costep")
       (poo-form-mapping "type-descriptor-composition"
                         "List."
                         "define-type"
                         ["element protocol descriptor"]
                         ["derive-sexp-json-bytes-marshal"]
                         "gerbil-poo://type.ss#List.")
       (poo-form-mapping "mro-regression-test"
                         "class-precedence-list"
                         "check"
                         ["(map ##type-name (class-precedence-list <Class>::t))"
                          "'(<Class> <Base> ... object t)"]
                         []
                         "gerbil-runtime-test://src/gerbil/test/c3-test.ss#class-inheritance")
       (poo-form-mapping "slot-order-regression-test"
                         "class-type-slot-vector"
                         "check"
                         ["(class-type-slot-vector <Class>::t)"
                          "#(__class <base-slots> ... <class-slots> ...)"]
                         []
                         "gerbil-runtime-test://src/gerbil/test/c3-test.ss#slot-computation-order")]
  failureCases:
      [(poo-failure-case "racket-class-syntax"
                         "dialect-confusion"
                         "racket-class-or-generic-scheme-object"
                         "use-poo-form-mapping"
                         ["gerbil-poo://object.ss#defclass"
                          "gerbil-poo://mop.ss#.defgeneric"
                          "gerbil-poo://mop.ss#defmethod"])
       (poo-failure-case "missing-extension-activation"
                         "inactive-extension"
                         "poo-forms-without-gerbil.pkg-dependency"
                         "query-extension-before-pattern"
                         ["gerbil.pkg"])
       (poo-failure-case "method-without-generic"
                         "incomplete-method-contract"
                         "defmethod-without-generic-slot-contract"
                         "follow-generic-and-method-mappings-together"
                         ["gerbil-poo://mop.ss#.defgeneric"
                          "gerbil-poo://mop.ss#defmethod"])
       (poo-failure-case "unchecked-mro-assumption"
                         "semantic-regression-gap"
                         "class-hierarchy-without-c3-or-slot-order-test"
                         "add-c3-linearization-and-slot-vector-witnesses"
                         ["gerbil-runtime://c3.ss#class-precedence-list"
                          "gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test"
                          "gerbil-runtime-test://src/gerbil/test/c3-test.ss#slot-computation-order"])
       (poo-failure-case "macro-bridge-with-runtime-semantics"
                         "macro-overreach"
                         "brace-or-at-method-macro-that-owns-object-semantics"
                         "keep-brace-syntax-thin-and-put-semantics-in-object-or-mop-slots"
                         ["gerbil-poo://brace.ss#@method"
                          "gerbil-poo://object.ss#defclass"
                          "gerbil-poo://mop.ss#.defgeneric"])
       (poo-failure-case "direct-slot-hash-guess"
                         "missing-c3-and-lazy-slot-resolution"
                         "hash-or-alist-object-replacement-that-skips-slot-resolution"
                         "query-object-slot-resolution-before-editing"
                         ["gerbil-poo://object.ss#compute-precedence-list!"
                          "gerbil-poo://object.ss#compute-slot-funs!"
                          "gerbil-poo://object.ss#.all-slots"])
       (poo-failure-case "io-method-without-family"
                         "serializer-or-printer-drift"
                         "ad-hoc-json-or-bytes-helper-outside-the-method-family"
                         "follow-json-marshal-bytes-method-family-and-runtime-source-witnesses"
                         ["gerbil-poo://io.ss#marshal"
                          "gerbil-poo://io.ss#methods.bytes<-marshal"
                          "gerbil-poo://io.ss#@method:json"])
       (poo-failure-case "protocol-adapter-without-required-slots"
                         "adapter-contract-missing"
                         "table-or-set-adapter-that-skips-required-slot-protocol"
                         "follow-methods.table-and-set-from-table-role-translation"
                         ["gerbil-poo://table.ss#methods.table"
                          "gerbil-poo://table.ss#Set<-Table."])
       (poo-failure-case "dense-data-structure-without-local-invariants"
                         "representation-invariant-missing"
                         "trie-like-structure-without-adjacent-height-or-path-contracts"
                         "keep-representation-invariants-local-to-structs"
                         ["gerbil-poo://trie.ss#$Costep"
                          "gerbil-poo://trie.ss#$Unstep"])]
  qualitySignals: ["active-extension-fact" "dependency-backed-mapping"
                   "real-project-c3-test" "mro-linearization-witness"
                   "slot-order-witness" "thin-macro-bridge"
                   "object-slot-resolution-model"
                   "io-serialization-method-family"
                   "required-slot-protocol"
                   "role-translation-adapter"
                   "representation-invariant-locality"
                   "type-descriptor-composition"
                   "dependency-backed-adapter"
                   "minimal-forms"
                   "failure-cases"]
  witness: "dependency-backed-poo-mapping"
  missing: []
  next: "search extension poo syntax"))

;;; Boundary:
;;; - Dependency adapter guidance is the high-risk bridge from raw package primitives to POO protocols.
;;; - Keep these selectors tied to rationaldict/table/type source witnesses.
;; PatternSpec
(def +poo-dependency-protocol-adapter-pattern-spec+
  (make-poo-pattern-spec base: +poo-object-system-pattern-spec+
  id: "poo-rationaldict-adapter"
  defaultFocus: "rationaldict dependency protocol adapter"
  sourceOwners: ["rationaldict.ss" "table.ss" "type.ss"]
  agentScenario: "agent-wraps-dependency-primitives-without-a-typed-protocol-adapter"
  agentSteering: "dependency already owns the storage primitives; build a typed protocol adapter with exact only-in imports, define-type Key/Value/validate/serialization/equality slots, derived table/set/list capabilities, and generic contract tests"
  intent: "query-rationaldict-adapter-shape-before-writing-dependency-backed-table-or-dict-boundaries"
  selectors:
       [(hash (role "typed-protocol-adapter")
              (symbol "RationalDict.")
              (selector "gerbil-poo://rationaldict.ss#RationalDict."))
        (hash (role "derived-set-adapter")
              (symbol "RationalSet")
              (selector "gerbil-poo://rationaldict.ss#RationalSet"))
        (hash (role "table-protocol")
              (symbol "methods.table")
              (selector "gerbil-poo://table.ss#methods.table"))
        (hash (role "typed-validation-boundary")
              (symbol ".validate")
              (selector "gerbil-poo://rationaldict.ss#RationalDict..validate"))
        (hash (role "serialization-boundary")
              (symbol ".sexp<-")
              (selector "gerbil-poo://rationaldict.ss#RationalDict..sexp<-"))
        (hash (role "equality-boundary")
              (symbol ".=?")
              (selector "gerbil-poo://rationaldict.ss#RationalDict..=?"))
        (hash (role "protocol-derived-capability")
              (symbol ".join")
              (selector "gerbil-poo://table.ss#methods.table.join"))
        (hash (role "reusable-contract-test")
              (symbol "table-tests")
              (selector "gerbil-poo-test://t/table-testing.ss#table-tests"))
        (hash (role "io-serialization-method-family")
              (symbol "methods.bytes<-marshal")
              (selector "gerbil-poo://io.ss#methods.bytes<-marshal"))]
  minimalForms:
       [(hash (role "typed-protocol-adapter")
              (symbol "RationalDict.")
              (template (hash (head "define-type")
                              (operands ["(RationalDict. @ [methods.table] Value)"
                                         "Key: Rational"
                                         "Value: Any"])
                              (keywords [".validate" ".empty" ".ref" ".acons"
                                         ".<-list" ".list<-" ".sexp<-" ".=?"])))
              (selector "gerbil-poo://rationaldict.ss#RationalDict."))
        (hash (role "exact-dependency-import")
              (symbol "only-in")
              (template (hash (head "only-in")
                              (operands [":clan/pure/dict/rationaldict"
                                         "rationaldict-put rationaldict-ref rationaldict->list list->rationaldict rationaldict=?"])
                              (keywords ["precise-import-surface"])))
              (selector "gerbil-poo://rationaldict.ss#import:rationaldict"))
        (hash (role "derived-set-adapter")
              (symbol "RationalSet")
              (template (hash (head "define-type")
                              (operands ["(RationalSet @ [Set<-Table.])"
                                         "Table: {(:: @T RationalDict.) Key: Elt Value: Unit}"])
                              (keywords [".list<-" ".min-elt" ".max-elt"])))
              (selector "gerbil-poo://rationaldict.ss#RationalSet"))
        (hash (role "generic-contract-witness")
              (symbol "table-contract-tests")
              (template (hash (head "table-contract-tests")
                              (operands ["<AdapterType>" "<sample-key>" "<sample-value>"])
                              (keywords ["t/ owner" "not line-number fixture"])))
              (selector "gerbil-poo-test://t/rationaldict-test.ss#rationaldict-test"))
        (hash (role "minimal-protocol-surface")
              (symbol "methods.table")
              (template (hash (head "define-type")
                              (operands ["Key" "Value" ".empty" ".acons"
                                         ".ref" ".remove" ".foldl" ".foldr"])
                              (keywords ["derive-secondary-capabilities"])))
              (selector "gerbil-poo://table.ss#methods.table"))
        (hash (role "reusable-contract-test")
              (symbol "table-tests")
              (template (hash (head "table-tests")
                              (operands ["<TypeDescriptor>"])
                              (keywords ["small-t-owner" "generic-contract"])))
              (selector "gerbil-poo-test://t/table-testing.ss#table-tests"))
        (hash (role "serialization-method-family")
              (symbol "methods.bytes<-marshal")
              (template (hash (head "define-type")
                              (operands [".marshal" ".unmarshal" ".bytes<-" ".<-bytes"])
                              (keywords ["method-family-not-ad-hoc-functions"])))
              (selector "gerbil-poo://io.ss#methods.bytes<-marshal"))]
  failureCases:
       [(hash (id "manual-hash-or-alist-adapter")
              (riskKind "dependency-boundary-bypass")
              (badPattern "hand-written-hash-or-alist-object-when-dependency-provides-dict-primitives")
              (correctiveAction "follow-rationaldict-define-type-adapter-shape")
              (selectors ["gerbil-poo://rationaldict.ss#RationalDict."
                          "gerbil-poo://table.ss#methods.table"]))
        (hash (id "scattered-primitive-calls")
              (riskKind "adapter-boundary-missing")
              (badPattern "call-rationaldict-primitives-from-many-owners-without-a-stable-protocol-surface")
              (correctiveAction "centralize-primitives-behind-define-type-slots")
              (selectors ["gerbil-poo://rationaldict.ss#import:rationaldict"
                          "gerbil-poo://rationaldict.ss#RationalDict."]))
        (hash (id "line-number-contract-witness")
              (riskKind "fragile-test-witness")
              (badPattern "satisfy-adapter-policy-with-line-number-or-single-check-fixture")
              (correctiveAction "add-generic-table-or-protocol-contract-tests")
              (selectors ["gerbil-poo-test://t/rationaldict-test.ss#rationaldict-test"]))
        (hash (id "copied-monolithic-contract-suite")
              (riskKind "modularity-policy-violation")
              (badPattern "copy-large-table-contract-assertion-suite-into-each-adapter-test")
              (correctiveAction "extract-reusable-contract-tests-into-small-t-owners")
              (selectors ["gerbil-poo-test://t/table-testing.ss#table-tests"
                          "gerbil-poo-test://t/rationaldict-test.ss#rationaldict-test"]))]
  qualitySignals: ["dependency-backed-mapping" "rationaldict-source-example"
                   "precise-only-in-import" "define-type-protocol-slots"
                   "validation-serialization-equality-boundaries"
                   "table-derived-set-capability"
                   "generic-contract-witness-required"
                   "minimal-protocol-surface"
                   "reusable-contract-test"
                   "serialization-method-family"
                   "poo-prototype-object-extension"]
  witness: "gerbil-poo-rationaldict-adapter-source-shape"
  next: "search pattern poo rationaldict adapter"))

;;; Boundary:
;;; - Prototype composition depends on source order and runtime instantiation witnesses.
;;; - Agents must query proto composition evidence before changing object extension order.
;; PatternSpec
(def +poo-prototype-composition-pattern-spec+
  (make-poo-pattern-spec base: +poo-object-system-pattern-spec+
  id: "poo-prototype-composition"
  defaultFocus: "prototype composition"
  sourceOwners: ["proto.ss"]
  agentScenario: "agent-composes-poo-prototypes-without-knowing-proto-order"
  intent: "query-proto-composition-source-before-composing-object-prototypes"
  selectors:
       [(poo-selector "prototype-instantiation"
                      "instantiate-proto"
                      "gerbil-poo://proto.ss#instantiate-proto")
        (poo-selector "prototype-composition"
                      "compose-proto"
                      "gerbil-poo://proto.ss#compose-proto")
        (poo-selector "prototype-composition-list"
                      "compose-proto*"
                      "gerbil-poo://proto.ss#compose-proto*")]
  minimalForms:
       [(poo-form-mapping "prototype-instantiation"
                          "instantiate-proto"
                          "instantiate-proto"
                          ["<proto>" "<base-object>"]
                          []
                          "gerbil-poo://proto.ss#instantiate-proto")
        (poo-form-mapping "prototype-composition"
                          "compose-proto"
                          "compose-proto"
                          ["<proto-a>" "<proto-b>"]
                          []
                          "gerbil-poo://proto.ss#compose-proto")
        (poo-form-mapping "prototype-composition-list"
                          "compose-proto*"
                          "compose-proto*"
                          ["[<proto-a> <proto-b> ...]"]
                          []
                          "gerbil-poo://proto.ss#compose-proto*")]
  failureCases:
       [(poo-failure-case "proto-order-confusion"
                          "composition-order"
                          "compose-proto-with-reversed-base-and-extension-order"
                          "follow-compose-proto-source-order-before-editing"
                          ["gerbil-poo://proto.ss#compose-proto"
                           "gerbil-poo://proto.ss#compose-proto*"])
        (poo-failure-case "missing-prototype-runtime-witness"
                          "untested-composition"
                          "prototype-stack-without-instantiation-witness"
                          "add-instantiate-proto-behavior-snapshot"
                          ["gerbil-poo://proto.ss#instantiate-proto"])]
  qualitySignals: ["dependency-backed-mapping" "proto-source"
                   "composition-order" "runtime-prototype-composition-witness"
                   "poo-prototype-object-extension"]
  witness: "runtime-prototype-composition-witness"
  missing: []
  next: "search pattern poo prototype composition witness"))

;;; Boundary:
;;; - Trace/debug guidance preserves computed-slot and superfun behavior.
;;; - The pattern prevents instrumentation from bypassing POO method dispatch.
;; PatternSpec
(def +poo-trace-debug-pattern-spec+
  (make-poo-pattern-spec base: +poo-object-system-pattern-spec+
  id: "poo-trace-debug"
  defaultFocus: "trace debug computed slot"
  sourceOwners: ["debug.ss" "object.ss"]
  agentScenario: "agent-traces-poo-methods-without-preserving-computed-slot-superfun"
  intent: "query-trace-poo-and-computed-slot-wrapper-before-adding-debug-tracing"
  selectors:
  [(hash (role "trace-function-wrapper")
         (symbol "traced-function")
         (selector "gerbil-poo://debug.ss#traced-function"))
   (hash (role "trace-inherited-slot")
         (symbol "trace-inherited-slot")
         (selector "gerbil-poo://debug.ss#trace-inherited-slot"))
   (hash (role "trace-poo-wrapper")
         (symbol "trace-poo")
         (selector "gerbil-poo://debug.ss#trace-poo"))
   (hash (role "computed-slot-wrapper")
         (symbol "$computed-slot-spec")
         (selector "gerbil-poo://debug.ss#trace-inherited-slot"))]
  minimalForms:
  [(hash (role "trace-function-wrapper")
         (symbol "traced-function")
         (template (hash (head "traced-function")
                         (operands ["`(.@ ,name ,slot-name)" "<procedure>"])
                         (keywords [])))
         (selector "gerbil-poo://debug.ss#traced-function"))
   (hash (role "trace-inherited-slot")
         (symbol "trace-inherited-slot")
         (template (hash (head "trace-inherited-slot")
                         (operands ["<poo-name>" "'<slot-symbol>"])
                         (keywords [])))
         (selector "gerbil-poo://debug.ss#trace-inherited-slot"))
   (hash (role "computed-slot-trace")
         (symbol "$computed-slot-spec")
         (template (hash (head "$computed-slot-spec")
                         (operands ["(lambda (self superfun) ...)"])
                         (keywords ["call-superfun-before-wrapping"])))
         (selector "gerbil-poo://debug.ss#trace-inherited-slot"))
   (hash (role "trace-poo-wrapper")
         (symbol "trace-poo")
         (template (hash (head "trace-poo")
                         (operands ["<poo>" "<name>"])
                         (keywords [])))
         (selector "gerbil-poo://debug.ss#trace-poo"))]
  failureCases:
  [(hash (id "trace-without-superfun")
         (riskKind "computed-slot-contract")
         (badPattern "trace-wrapper-that-never-calls-inherited-superfun")
         (correctiveAction "call-superfun-inside-trace-inherited-slot-before-wrapping")
         (selectors ["gerbil-poo://debug.ss#trace-inherited-slot"]))
   (hash (id "eager-trace-wrapper")
         (riskKind "debug-tracing-semantics")
         (badPattern "wraps-slot-value-before-computed-slot-inheritance-runs")
         (correctiveAction "use-$computed-slot-spec-to-delay-inherited-slot-wrapper")
         (selectors ["gerbil-poo://debug.ss#trace-inherited-slot"
                     "gerbil-poo://object.ss#apply-slot-spec"]))
   (hash (id "trace-mutates-source-poo")
         (riskKind "debug-object-isolation")
         (badPattern "mutates-original-poo-while-adding-trace-slots")
         (correctiveAction "create-traced-variant-with-trace-poo-wrapper")
         (selectors ["gerbil-poo://debug.ss#trace-poo"
                     "gerbil-poo://debug.ss#trace-inherited-slot"]))]
  qualitySignals: ["dependency-backed-mapping" "debug-source"
                   "computed-slot-source" "superfun-chain-source"
                   "trace-wrapper-source" "runtime-trace-poo-witness"]
  witness: "runtime-trace-poo-witness"
  next: "search pattern poo trace runtime witness"))

;;; Boundary:
;;; - Slot-cache guidance covers computed slot materialization and cached reads.
;;; - It keeps cache semantics anchored to object.ss and mop.ss witnesses.
;; PatternSpec
(def +poo-slot-cache-pattern-spec+
  (make-poo-pattern-spec base: +poo-object-system-pattern-spec+
  id: "poo-slot-cache-computed"
  defaultFocus: "slot cache computed slot"
  sourceOwners: ["object.ss" "mop.ss"]
  agentScenario: "agent-adds-computed-poo-slot-without-cache-or-superfun-semantics"
  intent: "query-slot-cache-and-apply-slot-spec-before-adding-computed-slots"
  selectors:
  [(hash (role "slot-spec-application")
         (symbol "apply-slot-spec")
         (selector "gerbil-poo://object.ss#apply-slot-spec"))
   (hash (role "object-materialization")
         (symbol "instantiate-object!")
         (selector "gerbil-poo://object.ss#instantiate-object!"))
   (hash (role "precedence-materialization")
         (symbol "compute-precedence-list!")
         (selector "gerbil-poo://object.ss#compute-precedence-list!"))
   (hash (role "slot-function-materialization")
         (symbol "compute-slot-funs!")
         (selector "gerbil-poo://object.ss#compute-slot-funs!"))
   (hash (role "slot-cache-read")
         (symbol ".ref")
         (selector "gerbil-poo://object.ss#.ref"))
   (hash (role "slot-cache-read-existing")
         (symbol ".ref/cached")
         (selector "gerbil-poo://object.ss#.ref/cached"))
   (hash (role "slot-lens")
         (symbol "slot-lens")
         (selector "gerbil-poo://mop.ss#slot-lens"))
   (hash (role "real-project-slot-cache-test")
         (symbol "putslot-test")
         (selector "gerbil-poo-test://t/object-test.ss#testing-putslot"))]
  minimalForms:
  [(hash (role "computed-slot")
         (symbol "computed-slot-spec")
         (template (hash (head "computed-slot-spec")
                         (operands ["(lambda (self superfun) ...)"])
                         (keywords [])))
         (selector "gerbil-poo://object.ss#apply-slot-spec"))
   (hash (role "slot-cache-read")
         (symbol ".ref")
         (template (hash (head ".ref")
                         (operands ["<object>" "<slot-symbol>"])
                         (keywords [])))
         (selector "gerbil-poo://object.ss#.ref"))
   (hash (role "slot-cache-read-existing")
         (symbol ".ref/cached")
         (template (hash (head ".ref/cached")
                         (operands ["<object>" "<slot-symbol>" "<default>"])
                         (keywords [])))
         (selector "gerbil-poo://object.ss#.ref/cached"))
   (hash (role "slot-cache-regression-test")
         (symbol "putslot-test")
         (template (hash (head "check")
                         (operands ["(.@ <object> <computed-slot>)"
                                    "'<expected-cached-value>"])
                         (keywords [])))
         (selector "gerbil-poo-test://t/object-test.ss#testing-putslot"))]
  failureCases:
  [(hash (id "uncached-slot-side-effect")
         (riskKind "slot-cache-semantics")
         (badPattern "computed-slot-with-side-effects-assumed-to-run-every-ref")
         (correctiveAction "use-ref-cache-and-ref-cached-selectors")
         (selectors ["gerbil-poo://object.ss#.ref"
                     "gerbil-poo://object.ss#.ref/cached"]))
   (hash (id "missing-superfun-chain")
         (riskKind "computed-slot-contract")
         (badPattern "computed-slot-ignores-superfun")
         (correctiveAction "follow-apply-slot-spec-superfun-form")
         (selectors ["gerbil-poo://object.ss#apply-slot-spec"]))]
  qualitySignals: ["dependency-backed-mapping" "apply-slot-spec-source"
                   "object-materialization-source"
                   "precedence-materialization-source"
                   "slot-function-materialization-source"
                   "ref-cache-source" "real-project-slot-cache-test"
                   "superfun-witness"]
  witness: "real-project-slot-cache-witness"
  next: "search pattern poo slot cache computed"))

;;; Boundary:
;;; - IO fallback guidance owns JSON, print, and writeenv repair evidence.
;;; - Serialization overrides must preserve gerbil-poo fallback behavior.
;; PatternSpec
(def +poo-io-json-fallback-pattern-spec+
  (make-poo-pattern-spec base: +poo-object-system-pattern-spec+
  id: "poo-io-json-fallback"
  defaultFocus: "io json print fallback"
  sourceOwners: ["io.ss" "mop.ss" "object.ss"]
  agentScenario: "agent-customizes-poo-serialization-without-json-or-print-fallbacks"
  intent: "query-poo-io-fallbacks-before-overriding-json-or-print-behavior"
  selectors:
  [(hash (role "print-fallback")
         (symbol "@method :pr")
         (selector "gerbil-poo://io.ss#@method:pr"))
   (hash (role "writeenv-fallback")
         (symbol "@method :wr")
         (selector "gerbil-poo://io.ss#@method:wr-object"))
   (hash (role "json-fallback")
         (symbol "@method :json")
         (selector "gerbil-poo://io.ss#@method:json"))
   (hash (role "json-writer")
         (symbol "@method :write-json")
         (selector "gerbil-poo://io.ss#@method:write-json"))
   (hash (role "typed-value-writer")
         (symbol "TV")
         (selector "gerbil-poo://io.ss#@method:wr-TV"))
   (hash (role "writeenv-runtime-boundary")
         (symbol "writeenv")
         (selector "gerbil-runtime://builtin#writeenv"))
   (hash (role "writeenv-method-dispatch-witness")
         (symbol "method-ref")
         (selector "gerbil-poo-witness://t/unit/poo/runtime-witness.ss#writeenv-method-dispatch"))
   (hash (role "object-value-mapping")
         (symbol "map-object-values")
         (selector "gerbil-poo://mop.ss#map-object-values"))]
  minimalForms:
  [(hash (role "print-fallback")
         (symbol "@method :pr")
         (template (hash (head "defmethod")
                         (operands ["(@method :pr object)"
                                    "(lambda (self port options) ...)"])
                         (keywords [])))
         (selector "gerbil-poo://io.ss#@method:pr"))
   (hash (role "writeenv-fallback")
         (symbol "@method :wr")
         (template (hash (head "defmethod")
                         (operands ["(@method :wr object)"
                                    "(lambda (self writeenv) ...)"])
                         (keywords [])))
         (selector "gerbil-poo://io.ss#@method:wr-object"))
   (hash (role "json-fallback")
         (symbol "@method :json")
         (template (hash (head "defmethod")
                         (operands ["(@method :json object)"
                                    "(lambda (self) ...)"])
                         (keywords [])))
         (selector "gerbil-poo://io.ss#@method:json"))
   (hash (role "json-writer")
         (symbol "@method :write-json")
         (template (hash (head "defmethod")
                         (operands ["(@method :write-json object)"
                                    "(lambda (self port) ...)"])
                         (keywords [])))
         (selector "gerbil-poo://io.ss#@method:write-json"))
   (hash (role "typed-value-writer")
         (symbol "TV")
         (template (hash (head "defmethod")
                         (operands ["(@method :wr TV)"
                                    "(lambda (self writeenv) ...)"])
                         (keywords ["write-object" ".json<-" ".string<-" ".sexp<-"])))
         (selector "gerbil-poo://io.ss#@method:wr-TV"))
   (hash (role "writeenv-method-dispatch-witness")
         (symbol "method-ref")
         (template (hash (head "method-ref")
                         (operands ["<object-or-TV>" "`:wr"])
                         (keywords [])))
         (selector "gerbil-poo-witness://t/unit/poo/runtime-witness.ss#writeenv-method-dispatch"))]
  failureCases:
  [(hash (id "json-fallback-bypass")
         (riskKind "serialization-contract")
         (badPattern "manual-json-writer-that-skips-type-json<-and-sexp")
         (correctiveAction "follow-json-fallback-order-before-overriding")
         (selectors ["gerbil-poo://io.ss#@method:json"
                     "gerbil-poo://io.ss#@method:write-json"]))
   (hash (id "print-representation-bypass")
         (riskKind "display-contract")
         (badPattern "manual-printer-that-skips-print-representation-and-sexp")
         (correctiveAction "follow-pr-fallback-order-before-overriding")
         (selectors ["gerbil-poo://io.ss#@method:pr"]))
   (hash (id "typed-value-writer-bypass")
         (riskKind "typed-value-serialization-contract")
         (badPattern "manual-TV-printer-that-skips-write-object-json-string-sexp-precedence")
         (correctiveAction "follow-TV-writeenv-fallback-order-before-specializing")
         (selectors ["gerbil-poo://io.ss#@method:wr-TV"
                     "gerbil-poo://io.ss#@method:wr-object"]))
   (hash (id "direct-writeenv-construction")
         (riskKind "runtime-internal-boundary")
         (badPattern "agent-constructs-writeenv-or-calls-:wr-directly")
         (correctiveAction "use-write-json-pr-or-method-ref-dispatch-witness-until-writeenv-roundtrip-is-owned")
         (selectors ["gerbil-runtime://builtin#writeenv"
                     "gerbil-poo-witness://t/unit/poo/runtime-witness.ss#writeenv-method-dispatch"]))
   (hash (id "write-printer-hook-assumption")
         (riskKind "printer-hook-contract")
         (badPattern "agent-assumes-write-output-roundtrips-through-poo-:wr")
         (correctiveAction "treat-writeenv-roundtrip-as-missing-until-a-runtime-owner-exposes-a-stable-writeenv-entrypoint")
         (selectors ["gerbil-poo://io.ss#@method:wr-object"
                     "gerbil-poo://io.ss#@method:wr-TV"
                     "gerbil-runtime://builtin#writeenv"]))]
  qualitySignals: ["dependency-backed-mapping" "json-fallback-source"
                   "print-fallback-source" "writeenv-fallback-source"
                   "typed-value-writer-source" "json-roundtrip-witness"
                   "print-fallback-witness" "writeenv-method-dispatch-witness"
                   "writeenv-roundtrip-witness-required"]
  witness: "runtime-json-print-writeenv-method-source-backed-io-fallback"
  missing: ["writeenv-roundtrip-witness"]
  next: "search runtime-source writeenv printer hook"))

;;; Boundary:
;;; - Lens guidance is the functional slot-update path for POO objects.
;;; - Keep slot-lens and composition examples tied to real mop tests.
;; PatternSpec
(def +poo-lens-pattern-spec+
  (make-poo-pattern-spec base: +poo-object-system-pattern-spec+
  id: "poo-lens-slot"
  defaultFocus: "lens slot-lens"
  sourceOwners: ["mop.ss" "t/mop-test.ss"]
  agentScenario: "agent-updates-poo-slots-without-lens-composition-semantics"
  intent: "query-slot-lens-and-lens-compose-before-writing-functional-slot-updates"
  selectors:
  [(hash (role "lens-class")
         (symbol "Lens")
         (selector "gerbil-poo://mop.ss#Lens"))
   (hash (role "lens-slot")
         (symbol "slot-lens")
         (selector "gerbil-poo://mop.ss#slot-lens"))
   (hash (role "lens-compose")
         (symbol ".compose")
         (selector "gerbil-poo://mop.ss#Lens.compose"))
   (hash (role "real-project-lens-test")
         (symbol "Lenses")
         (selector "gerbil-poo-test://t/mop-test.ss#Lenses"))]
  minimalForms:
  [(hash (role "slot-lens")
         (symbol "slot-lens")
         (template (hash (head "slot-lens")
                         (operands ["'<slot-symbol>"])
                         (keywords [])))
         (selector "gerbil-poo://mop.ss#slot-lens"))
   (hash (role "lens-compose")
         (symbol ".compose")
         (template (hash (head ".call")
                         (operands ["<lens>" ".compose" "<nested-lens>"])
                         (keywords [])))
         (selector "gerbil-poo://mop.ss#Lens.compose"))
   (hash (role "lens-regression-test")
         (symbol "Lenses")
         (template (hash (head "check-equal?")
                         (operands ["(.alist (.call Lens .modify (slot-lens '<slot>) <fn> <object>))"
                                    "'((<slot> . <value>) ...)"])
                         (keywords [])))
         (selector "gerbil-poo-test://t/mop-test.ss#Lenses"))]
  failureCases:
  [(hash (id "imperative-slot-update")
         (riskKind "functional-update-contract")
         (badPattern "manual-slot-mutation-instead-of-slot-lens")
         (correctiveAction "use-slot-lens-and-lens-compose")
         (selectors ["gerbil-poo://mop.ss#slot-lens"
                     "gerbil-poo://mop.ss#Lens.compose"]))]
  qualitySignals: ["dependency-backed-mapping" "lens-source"
                   "slot-lens-source" "real-project-lens-test"
                   "functional-update-witness"]
  witness: "real-project-lens-witness"
  next: "search pattern poo lens slot-lens"))

;;; Boundary:
;;; - Type-validation guidance covers sealed classes and validate witnesses.
;;; - It prevents agent edits from treating POO classes as untyped records.
;; PatternSpec
(def +poo-type-validation-pattern-spec+
  (make-poo-pattern-spec base: +poo-object-system-pattern-spec+
  id: "poo-type-validation-sealed"
  defaultFocus: "sealed type validation"
  sourceOwners: ["mop.ss" "t/mop-test.ss"]
  agentScenario: "agent-defines-poo-class-without-sealed-type-validation"
  intent: "query-sealed-class-and-validate-witness-before-writing-type-checked-poo-classes"
  selectors:
  [(hash (role "class-descriptor")
         (symbol "Class.")
         (selector "gerbil-poo://mop.ss#Class."))
   (hash (role "function-validator")
         (symbol "Function.")
         (selector "gerbil-poo://mop.ss#Function."))
   (hash (role "generic-slot-validator")
         (symbol "slot-checker")
         (selector "gerbil-poo://mop.ss#slot-checker"))
   (hash (role "real-project-validation-test")
         (symbol "mop-test")
         (selector "gerbil-poo-test://t/mop-test.ss#sealed-type-validation"))]
  minimalForms:
  [(hash (role "sealed-class-definition")
         (symbol "define-type")
         (template (hash (head "define-type")
                         (operands ["(<Class> @ <Base>)"
                                    "slots: =>.+ {<slot>: {type: <Type>} ...}"])
                         (keywords ["sealed: #t"])))
         (selector "gerbil-poo://mop.ss#Class."))
   (hash (role "generic-slot-validator")
         (symbol ".defgeneric")
         (template (hash (head ".defgeneric")
                         (operands ["(<accessor> x)"])
                         (keywords ["slot: <slot>" "default: <value>"])))
         (selector "gerbil-poo://mop.ss#slot-checker"))
   (hash (role "validation-regression-test")
         (symbol "validate")
         (template (hash (head "validate")
                         (operands ["<Type>" "<object>"])
                         (keywords [])))
         (selector "gerbil-poo-test://t/mop-test.ss#sealed-type-validation"))]
  failureCases:
  [(hash (id "missing-required-typed-slot")
         (riskKind "type-validation-gap")
         (badPattern "class-instance-created-without-required-typed-slot")
         (correctiveAction "validate-against-real-mop-test-required-slot-failures")
         (selectors ["gerbil-poo-test://t/mop-test.ss#sealed-type-validation"
                     "gerbil-poo://mop.ss#Class."]))
   (hash (id "sealed-extra-slot-assumption")
         (riskKind "sealed-class-contract")
         (badPattern "sealed-class-accepts-extra-slots")
         (correctiveAction "respect-Class.-sealed-effective-slots-check")
         (selectors ["gerbil-poo://mop.ss#Class."
                     "gerbil-poo-test://t/mop-test.ss#sealed-type-validation"]))
   (hash (id "unchecked-function-arity")
         (riskKind "function-validation-contract")
         (badPattern "function-slot-without-arity-or-type-validation")
         (correctiveAction "use-Function.-validate-row-witness")
         (selectors ["gerbil-poo://mop.ss#Function."]))]
  qualitySignals: ["dependency-backed-mapping" "class-descriptor-source"
                   "function-validator-source" "real-project-mop-test"
                   "sealed-type-witness" "validation-negative-witness"]
  witness: "real-project-sealed-type-validation-witness"
  next: "search pattern poo sealed validate"))

;; PatternSpec
(def +poo-c3-mro-pattern-spec+
  (make-poo-pattern-spec base: +poo-object-system-pattern-spec+
  id: "poo-c3-mro-regression"
  defaultFocus: "c3 mro slot order"
  sourceOwners: ["object.ss" ":gerbil/runtime/c3" "src/gerbil/test/c3-test.ss"]
  agentScenario: "agent-writes-poo-inheritance-without-knowing-c3-linearization"
  intent: "force-agent-to-query-poo-and-runtime-c3-witnesses-before-editing-inheritance"
  qualitySignals: ["active-extension-fact" "dependency-backed-mapping"
                   "real-project-c3-test" "mro-linearization-witness"
                   "slot-order-witness" "failure-cases"]
  witness: "real-project-c3-and-slot-order-witness"
  next: "search extension poo pattern c3"))

;; PatternSpecRegistry
(def +poo-pattern-spec-registry+
  (list (cons 'dependency-protocol-adapter +poo-dependency-protocol-adapter-pattern-spec+)
        (cons 'prototype-composition +poo-prototype-composition-pattern-spec+)
        (cons 'trace-debug +poo-trace-debug-pattern-spec+)
        (cons 'slot-cache +poo-slot-cache-pattern-spec+)
        (cons 'io-json-fallback +poo-io-json-fallback-pattern-spec+)
        (cons 'lens +poo-lens-pattern-spec+)
        (cons 'type-validation +poo-type-validation-pattern-spec+)
        (cons 'c3-mro +poo-c3-mro-pattern-spec+)
        (cons 'typeclass-algebra +poo-typeclass-algebra-pattern-spec+)
        (cons 'object-system +poo-object-system-pattern-spec+)))

;; : (-> Kind PatternSpec )
(def (poo-pattern-spec kind)
  (let (entry (assq kind +poo-pattern-spec-registry+))
    (and entry (cdr entry))))

;;; Boundary:
;;; - Public accessors stay stable while storage is POO-backed static data.
;;; - Unknown slots return #f instead of exposing storage details to packet builders.
;; : (-> Kind Slot Value )
(def (poo-pattern-spec-slot kind slot)
  (let (spec (poo-pattern-spec kind))
    (and spec
         (case slot
           ((id defaultFocus sourceOwners agentScenario agentSteering intent
                selectors minimalForms failureCases qualitySignals witness
                missing next)
            (poo-pattern-object-slot spec slot))
           (else #f)))))

;; : (-> String (List PooFormFact) PooPatternFocus )
(def (poo-pattern-focus kind terms)
  (if (and (pair? terms) (pair? (cdr terms)))
    (string-join (cdr terms) " ")
    (poo-pattern-default-focus kind)))
;; : (-> String String )
(def (poo-pattern-id kind)
  (poo-pattern-spec-slot kind 'id))
;; : (-> String PooPatternDefaultFocus )
(def (poo-pattern-default-focus kind)
  (poo-pattern-spec-slot kind 'defaultFocus))
;; : (-> String (List String) )
(def (poo-pattern-source-owners kind)
  (poo-pattern-spec-slot kind 'sourceOwners))
;; : (-> String PooPatternAgentScenario )
(def (poo-pattern-agent-scenario kind)
  (poo-pattern-spec-slot kind 'agentScenario))
;; : (-> String AgentSteering )
(def (poo-pattern-agent-steering kind)
  (poo-pattern-spec-slot kind 'agentSteering))
;; : (-> String PooPatternIntent )
(def (poo-pattern-intent kind)
  (poo-pattern-spec-slot kind 'intent))
;; : (-> String (List Selector) )
(def poo-pattern-selectors
  (case-lambda
   (() (poo-pattern-spec-slot 'object-system 'selectors))
   ((kind) (poo-pattern-spec-slot kind 'selectors))))
;; : (-> String (List FormMapping) )
(def poo-pattern-minimal-forms
  (case-lambda
   (() (poo-pattern-spec-slot 'object-system 'minimalForms))
   ((kind) (poo-pattern-spec-slot kind 'minimalForms))))
;; : (-> String (List FailureCase) )
(def poo-pattern-failure-cases
  (case-lambda
   (() (poo-pattern-spec-slot 'object-system 'failureCases))
   ((kind) (poo-pattern-spec-slot kind 'failureCases))))
;; : (-> String PooPatternQualitySignals )
(def (poo-pattern-quality-signals kind)
  (poo-pattern-spec-slot kind 'qualitySignals))
;; : (-> String PooPatternWitness )
(def (poo-pattern-witness kind)
  (poo-pattern-spec-slot kind 'witness))
;; : (-> String PooPatternMissing )
(def (poo-pattern-missing kind)
  (poo-pattern-spec-slot kind 'missing))
;; : (-> String String )
(def (poo-pattern-next kind)
  (poo-pattern-spec-slot kind 'next))
