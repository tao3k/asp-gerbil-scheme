;;; -*- Gerbil -*-
;;; Typed-contract boundary signals for R013 Gerbil style guidance.

(import :asp-gerbil-scheme/src/parser/facade
        (only-in :asp-gerbil-scheme/src/policy/agent-style-gerbil-signal-support
                 typed-combinator-style-facts->quality-facet
                 typed-combinator-style-facts->signals
                 typed-combinator-style-facts->targets
                 typed-contract-fact-mentions-any?)
        (only-in :std/sugar filter))

(export typed-combinator-style-serialization-boundary-quality-facets
        typed-combinator-style-serialization-boundary-signals
        typed-combinator-style-serialization-boundary-targets
        typed-combinator-style-serialization-boundary-facts
        typed-combinator-style-slot-lens-boundary-quality-facets
        typed-combinator-style-slot-lens-boundary-signals
        typed-combinator-style-slot-lens-boundary-targets
        typed-combinator-style-concurrency-control-quality-facets
        typed-combinator-style-concurrency-control-signals
        typed-combinator-style-concurrency-control-targets
        typed-combinator-style-ssxi-optimizer-metadata-boundary-quality-facets
        typed-combinator-style-ssxi-optimizer-metadata-boundary-signals
        typed-combinator-style-ssxi-optimizer-metadata-boundary-targets
        typed-combinator-style-expander-root-boundary-quality-facets
        typed-combinator-style-expander-root-boundary-signals
        typed-combinator-style-expander-root-boundary-targets
        typed-combinator-style-actor-runtime-boundary-quality-facets
        typed-combinator-style-actor-runtime-boundary-signals
        typed-combinator-style-actor-runtime-boundary-targets
        typed-combinator-style-mop-c3-linearization-boundary-quality-facets
        typed-combinator-style-mop-c3-linearization-boundary-signals
        typed-combinator-style-mop-c3-linearization-boundary-targets
        typed-combinator-style-exception-continuation-boundary-quality-facets
        typed-combinator-style-exception-continuation-boundary-signals
        typed-combinator-style-exception-continuation-boundary-targets)

;;; Serialization protocol boundaries are learned from reference corpus style,
;;; not from package dependencies.  A finding is only exposed when one contract
;;; collapses three or more representation layers into the same owner boundary.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-serialization-boundary-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-serialization-boundary-facts file)
   "protocol-serialization-boundary"))

;;; Guidance boundary:
;;; - Signals name local repair moves, not reference package APIs.
;;; - Empty output keeps ordinary typed-contract files out of serialization
;;;   guidance unless the mixed-representation fact is proven.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-serialization-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-serialization-boundary-facts file)
   ["split JSON/string/bytes/marshal representation layers"
    "keep marshal boundaries self-delimited"
    "keep raw bytes adapters non-self-delimited"
    "preserve reader/writer symmetry through local protocol helpers"]))

;;; Target boundary:
;;; - Report only definition names from parser-owned typed-contract facts.
;;; - The policy payload stays compact and avoids source snippets.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-serialization-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-serialization-boundary-facts file)
   typed-contract-fact-definition-name))

;;; Fact boundary:
;;; - Reuse typed-contract facts collected by the parser.
;;; - This avoids raw text scans while staying on Scheme-native typed blocks.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-serialization-boundary-facts file)
  (filter typed-combinator-style-serialization-boundary-fact?
          (source-file-typed-contract-facts file)))

;;; Predicate boundary:
;;; - Three representation categories mark a collapsed protocol owner.
;;; - One- or two-step local adapters remain valid expected repairs.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-serialization-boundary-fact? fact)
  (>= (length (typed-combinator-style-serialization-boundary-categories fact))
      3))

;;; Category boundary:
;;; - Categories are representation layers, not exact type names.
;;; - The list is intentionally small so ordinary domain names do not trigger.
;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-serialization-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["JSON" "Json" "json"])
                "json")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["String" "string"])
                "string")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Bytes" "Byte" "bytes" "u8vector" "U8Vector"])
                "bytes")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Marshal" "marshal" "Unmarshal" "unmarshal"])
                "marshal")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Sexp" "sexp" "Symbolic"])
                "sexp")]))

;;; Slot/lens boundaries are learned from gerbil-poo/mop.ss style, but the
;;; repair target is a local descriptor boundary, not a POO dependency.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-slot-lens-boundary-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-slot-lens-boundary-facts file)
   "slot-lens-boundary"))

;;; Guidance boundary:
;;; - Signals describe local helpers the agent can introduce in any package.
;;; - Empty output keeps ordinary hash or slot code out of lens advice unless a
;;;   typed contract collapses slot/get/set/modify/validation responsibilities.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-slot-lens-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-slot-lens-boundary-facts file)
   ["introduce local slot descriptor or lens helpers"
    "centralize get/set/modify around the slot boundary"
    "keep validation attached to the slot update boundary"
    "use Gerbil `using (value :- Type)` when repeated slot access has a known local class or interface descriptor"
    "model descriptor state as a small defclass/defstruct before adding ad hoc get/set branches"
    "preserve reader/writer symmetry without gerbil-poo or gerbil-utils dependencies"]))

;;; Target boundary:
;;; - Report only definition names from parser-owned typed-contract facts.
;;; - The target list points at the collapsed owner, not the reference corpus.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-slot-lens-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-slot-lens-boundary-facts file)
   typed-contract-fact-definition-name))

;;; Fact boundary:
;;; - Reuse typed-contract facts collected by the parser.
;;; - This detector must not scan implementation text or infer package usage.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-slot-lens-boundary-facts file)
  (filter typed-combinator-style-slot-lens-boundary-fact?
          (source-file-typed-contract-facts file)))

;;; Predicate boundary:
;;; - Four slot/lens categories mark a collapsed descriptor owner.
;;; - Split local helpers should mention only one or two categories each.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-slot-lens-boundary-fact? fact)
  (>= (length (typed-combinator-style-slot-lens-boundary-categories fact))
      4))

;;; Category boundary:
;;; - Categories model responsibilities, not exact library names.
;;; - Keep the vocabulary small so normal domain fields do not trigger R013.
;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-slot-lens-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["Slot" "slot" "Descriptor" "descriptor"])
                "slot")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Lens" "lens"])
                "lens")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Get" "get" "Getter" "getter" "Ref" "ref"])
                "get")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Set" "set" "Setter" "setter" "Put" "put"])
                "set")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Modify" "modify" "Update" "update"])
                "modify")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Validate" "validate" "Valid" "valid" "Check" "check"])
                "validate")]))

;;; Concurrency control quality is learned from gerbil:// runtime control and
;;; gerbil-utils/concurrency.ss. The repair target is a local concurrency
;;; boundary that preserves reentry/cleanup semantics while naming spawn, join,
;;; sequentialization, race, and parameter propagation responsibilities.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-concurrency-control-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-concurrency-control-facts file)
   "concurrency-control-boundary"))

;;; Guidance boundary:
;;; - Signals describe local helper responsibilities, not reference imports.
;;; - Empty output keeps ordinary threaded helpers out of concurrency advice
;;;   unless a typed contract collapses several scheduling responsibilities.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-concurrency-control-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-concurrency-control-facts file)
   ["split spawn/join/mutex/race responsibilities"
    "preserve reentry guards and cleanup around dynamic-wind/unwind boundaries"
    "name the sequentialization boundary before sharing state"
    "keep parallel map join boundaries explicit"
    "preserve thread parameter propagation at the spawn boundary"]))

;;; Target boundary:
;;; - Report only parser-owned typed-contract definition names.
;;; - The target is the collapsed local owner, not the reference corpus file.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-concurrency-control-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-concurrency-control-facts file)
   typed-contract-fact-definition-name))

;;; Fact boundary:
;;; - Reuse typed-contract facts collected by the parser.
;;; - This detector must not infer package dependencies from implementation text.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-concurrency-control-facts file)
  (filter typed-combinator-style-concurrency-control-fact?
          (source-file-typed-contract-facts file)))

;;; Predicate boundary:
;;; - Four concurrency categories mark a collapsed control owner.
;;; - Narrow spawn wrappers, lock helpers, or join helpers remain valid repairs.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-concurrency-control-fact? fact)
  (>= (length
       (typed-combinator-style-concurrency-control-categories fact))
      4))

;;; Category boundary:
;;; - Categories are control responsibilities, not exact API names.
;;; - Keep the vocabulary small so normal domain task names do not trigger R013.
;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-concurrency-control-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["Thread" "thread"])
                "thread")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Spawn" "spawn"])
                "spawn")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Join" "join"])
                "join")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Mutex" "mutex" "Lock" "lock" "Sequentialize"
                  "sequentialize"])
                "mutex")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Race" "race" "Shutdown" "shutdown"])
                "race")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Parallel" "parallel" "Worker" "worker"])
                "parallel")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Parameter" "parameter" "Dynamic" "dynamic"])
                "parameter")]))

;;; SSXI optimizer metadata quality is learned from Gerbil compiler metadata,
;;; builtin inline rules, and unchecked-call visibility. The repair target is a
;;; local declaration/call-shape boundary, not a dynamic primitive registry.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-ssxi-optimizer-metadata-boundary-quality-facets file)
  (if (pair? (typed-combinator-style-ssxi-optimizer-metadata-boundary-facts
              file))
    ["ssxi-optimizer-metadata-boundary"
     "optimizer-metadata-contract"]
    []))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-ssxi-optimizer-metadata-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-ssxi-optimizer-metadata-boundary-facts file)
   ["keep SSXI metadata adjacent to the primitive boundary"
    "preserve lexical direct calls for inline-rule visibility"
    "do not hide compiler-known primitives behind dynamic tables"
    "keep unchecked-call assumptions inside a named local boundary"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-ssxi-optimizer-metadata-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-ssxi-optimizer-metadata-boundary-facts file)
   typed-contract-fact-definition-name))

;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-ssxi-optimizer-metadata-boundary-facts file)
  (filter typed-combinator-style-ssxi-optimizer-metadata-boundary-fact?
          (source-file-typed-contract-facts file)))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-ssxi-optimizer-metadata-boundary-fact? fact)
  (>= (length
       (typed-combinator-style-ssxi-optimizer-metadata-boundary-categories
        fact))
      5))

;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-ssxi-optimizer-metadata-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["SSXI" "ssxi"])
                "ssxi")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Inline" "inline"])
                "inline")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Rule" "rule"])
                "rule")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Optimizer" "optimizer" "Optimize" "optimize"])
                "optimizer")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Metadata" "metadata"])
                "metadata")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Primitive" "primitive"])
                "primitive")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Direct" "direct" "Unchecked" "unchecked"])
                "direct")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Apply" "apply" "Dynamic" "dynamic"])
                "dynamic")]))

;;; Expander-root quality is learned from Gerbil's phase-aware module expander:
;;; module import, syntax expansion, phase state, and delayed eval are one staged
;;; language substrate. Emit only when a typed owner collapses those boundaries.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-expander-root-boundary-quality-facets file)
  (if (pair? (typed-combinator-style-expander-root-boundary-facts file))
    ["expander-root-boundary"
     "phase-aware-module-boundary"]
    []))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-expander-root-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-expander-root-boundary-facts file)
   ["keep module import, expansion context, and runtime helper boundaries separate"
    "preserve phase/phi state at the expander boundary"
    "store syntax/code artifacts at the module context boundary"
    "avoid hiding delayed eval or runtime behavior inside transformer parsing"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-expander-root-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-expander-root-boundary-facts file)
   typed-contract-fact-definition-name))

;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-expander-root-boundary-facts file)
  (filter typed-combinator-style-expander-root-boundary-fact?
          (source-file-typed-contract-facts file)))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-expander-root-boundary-fact? fact)
  (>= (length
       (typed-combinator-style-expander-root-boundary-categories fact))
      5))

;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-expander-root-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["Expander" "expander"])
                "expander")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Phase" "phase" "Phi" "phi"])
                "phase")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Module" "module" "Import" "import" "Export" "export"])
                "module")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Context" "context" "Marks" "marks"])
                "context")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Syntax" "syntax" "Macro" "macro" "Transformer" "transformer"])
                "syntax")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Eval" "eval" "Runtime" "runtime" "Delayed" "delayed"])
                "eval")]))

;;; Actor runtime quality is learned from Gerbil's actor/runtime boundary. It
;;; names mailbox protocol, send/receive, spawn/join, shutdown, and parameter
;;; propagation separately so agents do not collapse all actor behavior into
;;; one all-purpose control loop.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-actor-runtime-boundary-quality-facets file)
  (if (pair? (typed-combinator-style-actor-runtime-boundary-facts file))
    ["actor-runtime-boundary"
     "mailbox-protocol-boundary"]
    []))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-actor-runtime-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-actor-runtime-boundary-facts file)
   ["split actor spawn, mailbox send/receive, and shutdown boundaries"
    "keep mailbox protocol helpers explicit"
    "preserve supervision and cleanup at the actor boundary"
    "propagate thread parameters at actor spawn instead of inside handlers"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-actor-runtime-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-actor-runtime-boundary-facts file)
   typed-contract-fact-definition-name))

;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-actor-runtime-boundary-facts file)
  (filter typed-combinator-style-actor-runtime-boundary-fact?
          (source-file-typed-contract-facts file)))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-actor-runtime-boundary-fact? fact)
  (>= (length (typed-combinator-style-actor-runtime-boundary-categories fact))
      5))

;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-actor-runtime-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["Actor" "actor"])
                "actor")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Mailbox" "mailbox"])
                "mailbox")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Send" "send" "Message" "message"])
                "send")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Receive" "receive" "Recv" "recv"])
                "receive")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Spawn" "spawn" "Thread" "thread"])
                "spawn")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Join" "join" "Shutdown" "shutdown" "Stop" "stop"])
                "shutdown")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Supervisor" "supervisor" "Supervision" "supervision"])
                "supervision")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Parameter" "parameter" "Dynamic" "dynamic"])
                "parameter")]))

;;; MOP/C3 quality is learned from Gerbil runtime/interface.ss and runtime/c3.ss.
;;; It keeps class/interface descriptors separate from precedence-list merging.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-mop-c3-linearization-boundary-quality-facets file)
  (if (pair? (typed-combinator-style-mop-c3-linearization-boundary-facts file))
    ["mop-c3-linearization-boundary"
     "c3-precedence-boundary"]
    []))

;; : (-> SourceFile (List String) )
(def (typed-combinator-style-mop-c3-linearization-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-mop-c3-linearization-boundary-facts file)
   ["separate MOP descriptors from C3 precedence-list merging"
    "keep superclass tail extraction in a local helper"
    "name struct/class compatibility checks at the linearization boundary"
    "avoid broad ad hoc superclass walkers when precedence facts are present"]))

;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-mop-c3-linearization-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-mop-c3-linearization-boundary-facts file)
   typed-contract-fact-definition-name))

;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-mop-c3-linearization-boundary-facts file)
  (filter typed-combinator-style-mop-c3-linearization-boundary-fact?
          (source-file-typed-contract-facts file)))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-mop-c3-linearization-boundary-fact? fact)
  (>= (length
       (typed-combinator-style-mop-c3-linearization-boundary-categories fact))
      4))

;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-mop-c3-linearization-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["MOP" "mop" "Interface" "interface" "Descriptor" "descriptor"
                  "Prototype" "prototype"])
                "mop")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["C3" "C4" "Linearization" "linearization" "Linearize"
                  "linearize"])
                "c3")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Precedence" "precedence" "Order" "order"])
                "precedence")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Class" "class" "Struct" "struct"])
                "class")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Super" "super" "Superclass" "superclass" "Supers" "supers"])
                "super")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Merge" "merge" "Tail" "tail"])
                "merge")]))

;;; Exception/continuation quality is learned from gerbil-utils/exception.ss.
;;; The repair target is a local error boundary that preserves context and
;;; re-raise behavior, not a dependency on the reference package.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-exception-continuation-boundary-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-exception-continuation-boundary-facts file)
   "exception-continuation-boundary"))

;;; Guidance boundary:
;;; - Signals name the exception-control invariants an agent should preserve.
;;; - Empty output keeps ordinary try/catch code out of this guidance unless a
;;;   typed contract collapses exception, continuation, handler, and context.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-exception-continuation-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-exception-continuation-boundary-facts file)
   ["capture exception and continuation at the local boundary"
    "restore the prior exception handler before escaping"
    "log exception context before re-raising"
    "keep printable exception fallback local to diagnostics"]))

;;; Target boundary:
;;; - Report parser-owned typed-contract definition names only.
;;; - Reference corpus owners stay in qualityReference, not in target names.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-exception-continuation-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-exception-continuation-boundary-facts file)
   typed-contract-fact-definition-name))

;;; Fact boundary:
;;; - Reuse typed-contract facts collected by the parser.
;;; - Avoid text scans so exception advice remains schema-owned.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-exception-continuation-boundary-facts file)
  (filter typed-combinator-style-exception-continuation-boundary-fact?
          (source-file-typed-contract-facts file)))

;;; Predicate boundary:
;;; - Four exception-control categories mark a collapsed owner.
;;; - A narrow try/catch wrapper or printable-exception helper should not fire.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-exception-continuation-boundary-fact? fact)
  (>= (length
       (typed-combinator-style-exception-continuation-boundary-categories fact))
      4))

;;; Category boundary:
;;; - Categories are exception-control responsibilities, not exact APIs.
;;; - Keep the vocabulary small so domain error names do not trigger R013.
;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-exception-continuation-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["Exception" "exception" "Error" "error" "Exn" "exn"])
                "exception")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Continuation" "continuation" "Cont" "cont"])
                "continuation")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Handler" "handler" "Catch" "catch"])
                "handler")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Context" "context" "Log" "log" "Backtrace" "backtrace"])
                "context")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Raise" "raise" "Reraise" "reraise"])
                "raise")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Thunk" "thunk" "Try" "try"])
                "thunk")]))
