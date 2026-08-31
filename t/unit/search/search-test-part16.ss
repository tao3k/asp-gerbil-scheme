;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/test
        :asp-gerbil-scheme/src/commands/guide
        :asp-gerbil-scheme/src/commands/info
        :asp-gerbil-scheme/src/commands/search
        :asp-gerbil-scheme/src/support/args
        :std/misc/ports
        (only-in :std/text/json read-json)
        "../poo/runtime-witness"
        "./structural-index")
(export search-test-part-16)
;; : (-> Table Key Json )
(def (json-get table key)
  (hash-get table key))
;; : (-> (List String) String )
(def (search-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (search-main args)))))))
    (check status => 0)
    output))
;; : (-> (List String) String )
(def (guide-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (guide-main args)))))))
    (check status => 0)
    output))
;; : (-> (List String) String )
(def (info-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (info-main args)))))))
    (check status => 0)
    output))
;; : (-> OutputPort Fragment Boolean )
(def (contains? output fragment)
  (and (string-contains output fragment) #t))
;; : (-> OutputPort Boolean )
(def (guide-code-render-metadata-free? output)
  (not (or (contains? output "[guide")
           (contains? output "|primaryExemplar")
           (contains? output "|exemplar")
           (contains? output "|code begin")
           (contains? output "selector=")
           (contains? output "nextCommand=")
           (contains? output "\n|"))))
;; : (-> OutputPort Fragments Boolean )
(def (check-output-contains output fragments)
  (for-each
   (lambda (fragment)
     (check (contains? output fragment) => #t))
   fragments))
;; SearchTest
;; TestSuite
(def search-test-part-16
  (test-suite "gerbil scheme harness search part 16"
    (test-case "agent scenario exposes POO source gaps as partial pattern evidence"
          (let ((proto-output (search-output ["pattern" "poo" "prototype" "compose-proto" "."]))
                (trace-output (search-output ["pattern" "poo" "trace" "debug" "."]))
                (slot-output (search-output ["pattern" "poo" "slot" "cache" "computed" "."]))
                (io-output (search-output ["pattern" "poo" "json" "fallback" "."]))
                (lens-output (search-output ["pattern" "poo" "lens" "slot-lens" "."]))
                (type-output (search-output ["pattern" "poo" "sealed" "validate" "."])))
            (check-output-contains
             proto-output
             ["quality=verified"
              "|pattern id=poo-prototype-composition"
              "|agentScenario id=agent-composes-poo-prototypes-without-knowing-proto-order"
              "intent=query-proto-composition-source-before-composing-object-prototypes"
              "|selector role=prototype-instantiation symbol=instantiate-proto selector=gerbil-poo://proto.ss#instantiate-proto"
              "|selector role=prototype-composition symbol=compose-proto selector=gerbil-poo://proto.ss#compose-proto"
              "|selector role=prototype-composition-list symbol=compose-proto* selector=gerbil-poo://proto.ss#compose-proto*"
              "|form role=prototype-composition-list symbol=compose-proto* head=compose-proto*"
              "|failureCase id=proto-order-confusion"
              "|failureCase id=missing-prototype-runtime-witness"
              "|qualitySignal id=composition-order"
              "|qualitySignal id=runtime-prototype-composition-witness"
              "|quality verified missing=- selectorCount=3 formCount=3 failureCaseCount=2"
              "next=search pattern poo prototype composition witness"])
            (check-output-contains
             trace-output
             ["quality=verified"
              "|pattern id=poo-trace-debug"
              "|agentScenario id=agent-traces-poo-methods-without-preserving-computed-slot-superfun"
              "intent=query-trace-poo-and-computed-slot-wrapper-before-adding-debug-tracing"
              "|selector role=trace-function-wrapper symbol=traced-function selector=gerbil-poo://debug.ss#traced-function"
              "|selector role=trace-inherited-slot symbol=trace-inherited-slot selector=gerbil-poo://debug.ss#trace-inherited-slot"
              "|selector role=trace-poo-wrapper symbol=trace-poo selector=gerbil-poo://debug.ss#trace-poo"
              "|selector role=computed-slot-wrapper symbol=$computed-slot-spec selector=gerbil-poo://debug.ss#trace-inherited-slot"
              "|form role=computed-slot-trace symbol=$computed-slot-spec head=$computed-slot-spec"
              "|form role=trace-poo-wrapper symbol=trace-poo head=trace-poo"
              "|failureCase id=trace-without-superfun"
              "|failureCase id=eager-trace-wrapper"
              "|failureCase id=trace-mutates-source-poo"
              "|qualitySignal id=debug-source"
              "|qualitySignal id=superfun-chain-source"
              "|qualitySignal id=runtime-trace-poo-witness"
              "|quality verified missing=- selectorCount=4 formCount=4 failureCaseCount=3"
              "next=search pattern poo trace runtime witness"])
            (check-output-contains
             slot-output
             ["quality=verified"
              "|pattern id=poo-slot-cache-computed"
              "|agentScenario id=agent-adds-computed-poo-slot-without-cache-or-superfun-semantics"
              "intent=query-slot-cache-and-apply-slot-spec-before-adding-computed-slots"
              "|selector role=slot-spec-application symbol=apply-slot-spec selector=gerbil-poo://object.ss#apply-slot-spec"
              "|selector role=object-materialization symbol=instantiate-object! selector=gerbil-poo://object.ss#instantiate-object!"
              "|selector role=precedence-materialization symbol=compute-precedence-list! selector=gerbil-poo://object.ss#compute-precedence-list!"
              "|selector role=slot-function-materialization symbol=compute-slot-funs! selector=gerbil-poo://object.ss#compute-slot-funs!"
              "|selector role=slot-cache-read symbol=.ref selector=gerbil-poo://object.ss#.ref"
              "|selector role=slot-cache-read-existing symbol=.ref/cached selector=gerbil-poo://object.ss#.ref/cached"
              "|selector role=real-project-slot-cache-test symbol=putslot-test selector=gerbil-poo-test://t/object-test.ss#testing-putslot"
              "|form role=computed-slot symbol=computed-slot-spec head=computed-slot-spec"
              "|form role=slot-cache-regression-test symbol=putslot-test head=check"
              "|failureCase id=uncached-slot-side-effect"
              "|failureCase id=missing-superfun-chain"
              "|qualitySignal id=object-materialization-source"
              "|qualitySignal id=precedence-materialization-source"
              "|qualitySignal id=slot-function-materialization-source"
              "|qualitySignal id=ref-cache-source"
              "|qualitySignal id=real-project-slot-cache-test"
              "|qualitySignal id=superfun-witness"
              "|quality verified missing=- selectorCount=8 formCount=4 failureCaseCount=2"
              "next=search pattern poo slot cache computed"])
            (check-output-contains
             io-output
             ["quality=partial"
              "|pattern id=poo-io-json-fallback"
              "|agentScenario id=agent-customizes-poo-serialization-without-json-or-print-fallbacks"
              "intent=query-poo-io-fallbacks-before-overriding-json-or-print-behavior"
              "|selector role=print-fallback symbol=@method :pr selector=gerbil-poo://io.ss#@method:pr"
              "|selector role=writeenv-fallback symbol=@method :wr selector=gerbil-poo://io.ss#@method:wr-object"
              "|selector role=json-fallback symbol=@method :json selector=gerbil-poo://io.ss#@method:json"
              "|selector role=typed-value-writer symbol=TV selector=gerbil-poo://io.ss#@method:wr-TV"
              "|selector role=writeenv-runtime-boundary symbol=writeenv selector=gerbil-runtime://builtin#writeenv"
              "|selector role=writeenv-method-dispatch-witness symbol=method-ref selector=gerbil-poo-witness://t/unit/poo/runtime-witness.ss#writeenv-method-dispatch"
              "|selector role=object-value-mapping symbol=map-object-values selector=gerbil-poo://mop.ss#map-object-values"
              "|form role=writeenv-fallback symbol=@method :wr head=defmethod"
              "|form role=typed-value-writer symbol=TV head=defmethod"
              "|form role=writeenv-method-dispatch-witness symbol=method-ref head=method-ref"
              "|failureCase id=json-fallback-bypass"
              "|failureCase id=print-representation-bypass"
              "|failureCase id=typed-value-writer-bypass"
              "|failureCase id=direct-writeenv-construction"
              "|failureCase id=write-printer-hook-assumption"
              "|qualitySignal id=json-fallback-source"
              "|qualitySignal id=writeenv-fallback-source"
              "|qualitySignal id=typed-value-writer-source"
              "|qualitySignal id=json-roundtrip-witness"
              "|qualitySignal id=print-fallback-witness"
              "|qualitySignal id=writeenv-method-dispatch-witness"
              "|qualitySignal id=writeenv-roundtrip-witness-required"
              "|quality partial missing=writeenv-roundtrip-witness selectorCount=8 formCount=6 failureCaseCount=5"
              "next=search runtime-source writeenv printer hook"])
            (check-output-contains
             lens-output
             ["quality=verified"
              "|pattern id=poo-lens-slot"
              "|agentScenario id=agent-updates-poo-slots-without-lens-composition-semantics"
              "intent=query-slot-lens-and-lens-compose-before-writing-functional-slot-updates"
              "|selector role=lens-class symbol=Lens selector=gerbil-poo://mop.ss#Lens"
              "|selector role=lens-slot symbol=slot-lens selector=gerbil-poo://mop.ss#slot-lens"
              "|selector role=lens-compose symbol=.compose selector=gerbil-poo://mop.ss#Lens.compose"
              "|selector role=real-project-lens-test symbol=Lenses selector=gerbil-poo-test://t/mop-test.ss#Lenses"
              "|form role=lens-regression-test symbol=Lenses head=check-equal?"
              "|failureCase id=imperative-slot-update"
              "|qualitySignal id=lens-source"
              "|qualitySignal id=real-project-lens-test"
              "|qualitySignal id=functional-update-witness"
              "|quality verified missing=- selectorCount=4 formCount=3 failureCaseCount=1"
              "next=search pattern poo lens slot-lens"])
            (check-output-contains
             type-output
             ["quality=verified"
              "|pattern id=poo-type-validation-sealed"
              "|agentScenario id=agent-defines-poo-class-without-sealed-type-validation"
              "intent=query-sealed-class-and-validate-witness-before-writing-type-checked-poo-classes"
              "|selector role=class-descriptor symbol=Class. selector=gerbil-poo://mop.ss#Class."
              "|selector role=function-validator symbol=Function. selector=gerbil-poo://mop.ss#Function."
              "|selector role=generic-slot-validator symbol=slot-checker selector=gerbil-poo://mop.ss#slot-checker"
              "|selector role=real-project-validation-test symbol=mop-test selector=gerbil-poo-test://t/mop-test.ss#sealed-type-validation"
              "|form role=sealed-class-definition symbol=define-type head=define-type"
              "|form role=validation-regression-test symbol=validate head=validate"
              "|failureCase id=missing-required-typed-slot"
              "|failureCase id=sealed-extra-slot-assumption"
              "|failureCase id=unchecked-function-arity"
              "|qualitySignal id=real-project-mop-test"
              "|qualitySignal id=sealed-type-witness"
              "|qualitySignal id=validation-negative-witness"
              "|quality verified missing=- selectorCount=4 formCount=3 failureCaseCount=3"
              "next=search pattern poo sealed validate"])
            (check (not (contains? proto-output (string-append ".data" "/gerbil-poo"))) => #t)
            (check (not (contains? trace-output (string-append ".data" "/gerbil-poo"))) => #t)
            (check (not (contains? slot-output (string-append ".data" "/gerbil-poo"))) => #t)
            (check (not (contains? io-output (string-append ".data" "/gerbil-poo"))) => #t)
            (check (not (contains? lens-output (string-append ".data" "/gerbil-poo"))) => #t)
            (check (not (contains? type-output (string-append ".data" "/gerbil-poo"))) => #t)
            (check (not (contains? proto-output "pending")) => #t)
            (check (not (contains? trace-output "pending")) => #t)
            (check (not (contains? slot-output "pending")) => #t)
            (check (not (contains? io-output "pending")) => #t)
            (check (not (contains? lens-output "pending")) => #t)
            (check (not (contains? type-output "pending")) => #t)))
    (test-case "diverse POO pattern queries avoid generic object-system fallback"
          (let ((finite-output
                 (search-output ["pattern" "gerbil-poo" "finite" "field" "fq"
                                 "--view" "seeds"]))
                (trie-output
                 (search-output ["pattern" "gerbil-poo" "table" "trie" "adapter"
                                 "--view" "seeds"]))
                (slot-syntax-output
                 (search-output ["pattern" "gerbil-poo" "object" "slot" "syntax"
                                 "--view" "seeds"])))
            (check-output-contains
             finite-output
             ["|pattern id=poo-type-validation-sealed"
              "|agentScenario id=agent-defines-poo-class-without-sealed-type-validation"
              "intent=query-sealed-class-and-validate-witness-before-writing-type-checked-poo-classes"
              "|selector role=class-descriptor symbol=Class. selector=gerbil-poo://mop.ss#Class."
              "|selector role=generic-slot-validator symbol=slot-checker selector=gerbil-poo://mop.ss#slot-checker"
              "|failureCase id=missing-required-typed-slot"
              "|qualitySignal id=sealed-type-witness"
              "missing=-"])
            (check-output-contains
             trie-output
             ["|pattern id=poo-rationaldict-adapter"
              "|agentScenario id=agent-wraps-dependency-primitives-without-a-typed-protocol-adapter"
              "intent=query-rationaldict-adapter-shape-before-writing-dependency-backed-table-or-dict-boundaries"
              "|selector role=table-protocol symbol=methods.table selector=gerbil-poo://table.ss#methods.table"
              "|form role=typed-protocol-adapter symbol=RationalDict. head=define-type"
              "|failureCase id=manual-hash-or-alist-adapter"
              "|qualitySignal id=define-type-protocol-slots"
              "missing=-"])
            (check-output-contains
             slot-syntax-output
             ["|pattern id=poo-slot-cache-computed"
              "|agentScenario id=agent-adds-computed-poo-slot-without-cache-or-superfun-semantics"
              "intent=query-slot-cache-and-apply-slot-spec-before-adding-computed-slots"
              "|selector role=slot-spec-application symbol=apply-slot-spec selector=gerbil-poo://object.ss#apply-slot-spec"
              "|selector role=object-materialization symbol=instantiate-object! selector=gerbil-poo://object.ss#instantiate-object!"
              "|selector role=precedence-materialization symbol=compute-precedence-list! selector=gerbil-poo://object.ss#compute-precedence-list!"
              "|selector role=slot-function-materialization symbol=compute-slot-funs! selector=gerbil-poo://object.ss#compute-slot-funs!"
              "|selector role=slot-cache-read symbol=.ref selector=gerbil-poo://object.ss#.ref"
              "|form role=computed-slot symbol=computed-slot-spec head=computed-slot-spec"
              "|failureCase id=uncached-slot-side-effect"
              "|qualitySignal id=object-materialization-source"
              "|qualitySignal id=real-project-slot-cache-test"
              "missing=-"])
            (check (not (contains? finite-output "|pattern id=poo-object-system")) => #t)
            (check (not (contains? trie-output "|pattern id=poo-object-system")) => #t)
            (check (not (contains? slot-syntax-output "|pattern id=poo-object-system")) => #t)
            (check (not (contains? finite-output "pending")) => #t)
            (check (not (contains? trie-output "pending")) => #t)
            (check (not (contains? slot-syntax-output "pending")) => #t)))))
