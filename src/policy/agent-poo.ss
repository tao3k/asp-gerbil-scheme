;;; -*- Gerbil -*-
;;; Agent-facing POO policy checks.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-poo-callees
        :asp-gerbil-scheme/src/policy/agent-poo-object-literal
        :asp-gerbil-scheme/src/policy/agent-poo-loop-performance
        :asp-gerbil-scheme/src/policy/agent-support
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/srfi/13 string-contains string-join string-prefix?)
        (only-in :std/sugar filter filter-map hash hash-get ormap)
        :asp-gerbil-scheme/src/types/findings)

(export poo-direct-writeenv-findings
        poo-direct-writeenv-finding
        poo-io-runtime-witness-findings
        poo-io-runtime-witness-finding
        poo-object-model-findings
        poo-object-model-finding
        poo-method-shape-findings
        poo-method-shape-finding
        poo-prototype-fixed-point-findings
        poo-prototype-fixed-point-finding
        poo-construction-performance-findings
        poo-construction-performance-finding
        poo-generated-receipt-boundary-findings
        poo-generated-receipt-boundary-finding
        poo-clone-override-loop-performance-findings
        poo-clone-override-loop-performance-finding
        poo-materialization-loop-performance-findings
        poo-materialization-loop-performance-finding
        poo-composition-loop-performance-findings
        poo-composition-loop-performance-finding
        poo-validation-loop-performance-findings
        poo-validation-loop-performance-finding
        poo-lens-loop-performance-findings
        poo-lens-loop-performance-finding
        poo-object-construction-loop-performance-findings
        poo-object-construction-loop-performance-finding
        poo-type-construction-loop-performance-findings
        poo-type-construction-loop-performance-finding
        poo-debug-instrumentation-loop-performance-findings
        poo-debug-instrumentation-loop-performance-finding
        poo-slot-spec-mutation-loop-performance-findings
        poo-slot-spec-mutation-loop-performance-finding
        poo-slot-predicate-loop-performance-findings
        poo-slot-predicate-loop-performance-finding
        poo-documentation-usage-findings
        poo-documentation-usage-finding)
;;; Direct-writeenv scan boundary:
;;; - The outer map keeps file ownership visible while inner filter-map drops
;;;   non-writeenv calls without constructing placeholder findings.
;;; - This stays expression-level so the policy reports only parser-owned
;;;   direct writeenv witnesses and does not grow a handwritten loop.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-direct-writeenv-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (call)
                   (and (direct-writeenv-call? call)
                        (poo-direct-writeenv-finding file call)))
                 (source-file-calls file)))
              (project-index-files index))))
;; : (-> CallFact Boolean )
(def (direct-writeenv-call? call)
  (equal? (call-fact-callee call) "writeenv"))
;; : (-> SourceFile CallFact TypeFinding )
(def (poo-direct-writeenv-finding file call)
  (make-type-finding
   (policy-rule-id +agent-poo-direct-writeenv-rule+)
   (policy-rule-severity +agent-poo-direct-writeenv-rule+)
   (source-file-path file)
   "direct writeenv calls bypass POO IO runtime-source evidence; query search runtime-source writeenv printer hook first"
   (call-fact-selector call)
   (hash (callee (call-fact-callee call))
         (selector (call-fact-selector call)))))
;;; Boundary:
;;; - poo-io-runtime-witness-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-io-runtime-witness-findings index)
  (filter-map
   (lambda (file)
     (and (index-source-runtime-file-path? index (source-file-path file))
          (poo-io-source-file? file)
          (poo-io-method-override-file? file)
          (poo-io-runtime-witness-finding file)))
   (project-index-files index)))
;;; Boundary:
;;; - poo-io-source-file? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile Boolean )
(def (poo-io-source-file? file)
  (ormap poo-io-import? (source-file-imports file)))
;; : (-> String Boolean )
(def (poo-io-import? import)
  (or (equal? import ":clan/poo/io")
      (equal? import "clan/poo/io")
      (string-contains import "clan/poo/io")))
;;; Boundary:
;;; - poo-io-method-override-file? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile Boolean )
(def (poo-io-method-override-file? file)
  (or (ormap (lambda (form)
               (member (top-form-head form)
                       ["defmethod" ".defmethod"]))
             (source-file-forms file))
      (ormap (lambda (call)
               (member (call-fact-callee call)
                       ["defmethod" ".defmethod"]))
             (source-file-calls file))))
;; : (-> SourceFile TypeFinding )
(def (poo-io-runtime-witness-finding file)
  (make-type-finding
   (policy-rule-id +agent-poo-io-runtime-witness-rule+)
   (policy-rule-severity +agent-poo-io-runtime-witness-rule+)
   (source-file-path file)
   "POO IO method overrides in src/ need runtime-source-backed writeenv/printer-hook witness coverage before being treated as verified"
   (source-file-path file)
   (hash (next "search runtime-source writeenv printer hook")
         (requiredWitness "writeenv-roundtrip-witness"))))
;;; Boundary:
;;; - poo-object-model-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-object-model-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (filter-map
                   (lambda (call)
                     (and (manual-object-model-call? index file call)
                          (poo-object-model-finding file call)))
                   (source-file-calls file)))
                (project-index-files index)))
    '()))
;; : (-> ProjectIndex SourceFile CallFact Boolean )
(def (manual-object-model-call? index file call)
  (let (caller (call-fact-caller call))
    (and (manual-object-model-owner? index file)
         (manual-object-model-callee? call)
         caller
         (manual-object-domain-constructor-caller? file caller))))

;; : (-> ProjectIndex SourceFile Boolean)
(def (manual-object-model-owner? index file)
  (and (index-source-runtime-file-path? index (source-file-path file))
       (null? (source-file-poo-forms file))))

;; : (-> CallFact Boolean)
(def (manual-object-model-callee? call)
  (member (call-fact-callee call) +manual-object-model-callees+))

;; : (-> SourceFile Caller Boolean)
(def (manual-object-domain-constructor-caller? file caller)
  (and (not (caller-builds-type-finding? file caller))
       (or (string-prefix? "make-" caller)
           (string-prefix? "new-" caller)
           (string-prefix? "build-" caller))))

;;; A hash nested in make-type-finding is typed diagnostic evidence, not an
;;; alternative domain object model. Require both calls in the same caller so
;;; ordinary build-/make-/new- constructors remain covered by POLICY-010.
;; caller-builds-type-finding?
;; : (-> SourceFile Caller Boolean)
;; | doc m%
;; Recognizes a typed diagnostic constructor in the same lexical caller.
;; # Examples
;; ```scheme
;; (caller-builds-type-finding? file "build-policy-findings")
;; => #t when that caller invokes make-type-finding
;; ```
;; Result: true only for parser-owned call evidence in one caller boundary.
(def (caller-builds-type-finding? file caller)
  (and (find (lambda (candidate)
               (and (equal? (call-fact-caller candidate) caller)
                    (equal? (call-fact-callee candidate)
                            "make-type-finding")))
             (source-file-calls file))
       #t))
;; : (-> SourceFile CallFact TypeFinding )
(def (poo-object-model-finding file call)
  (make-type-finding
   (policy-rule-id +agent-poo-object-model-rule+)
   (policy-rule-severity +agent-poo-object-model-rule+)
   (source-file-path file)
   (string-append "manual object constructor " (call-fact-caller call)
                  " uses " (call-fact-callee call)
                  " while POO/protocol capability is active; prefer parser-owned defclass/defgeneric/defmethod or cite why a raw data record is intentional")
   (call-fact-selector call)
   (hash (constructor (call-fact-caller call))
         (callee (call-fact-callee call))
         (selector (call-fact-selector call))
         (next "search pattern poo class"))))
;;; Boundary:
;;; - Detect outer constructor projection bursts, not isolated slot reads.
;;; - POO best practice keeps inherited/defaulted slot fixed points in one
;;;   prototype with brace syntax, =>, =>.+, ?, and .mix.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-prototype-fixed-point-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (and (index-source-runtime-file-path? index (source-file-path file))
                           (null? (source-file-poo-forms file)))
                    (poo-prototype-fixed-point-file-findings file)
                    '()))
                (project-index-files index)))
    '()))
;;; Projection-burst transform:
;;; - Filter to POO slot projection calls first, then emit at most one finding
;;;   per constructor caller through first-call selection.
;;; - This keeps normal isolated `.ref` reads legal while making repeated
;;;   constructor projection visible as a prototype-shape repair.
;; : (-> SourceFile (List TypeFinding) )
(def (poo-prototype-fixed-point-file-findings file)
  (let (calls (filter poo-prototype-ref-call? (source-file-calls file)))
    (filter-map
     (lambda (call)
       (let (caller (call-fact-caller call))
         (and caller
              (poo-constructor-caller? caller)
              (first-poo-prototype-ref-call-for-caller? calls call)
              (let (count (poo-prototype-ref-call-count calls caller))
                (and (>= count 2)
                     (poo-prototype-fixed-point-finding file call count))))))
     calls)))
;; : (-> CallFact Boolean )
(def (poo-prototype-ref-call? call)
  (member (call-fact-callee call) +poo-prototype-ref-callees+))
;; : (-> String Boolean )
(def (poo-constructor-caller? caller)
  (or (string-prefix? "make-" caller)
      (string-prefix? "new-" caller)
      (string-prefix? "build-" caller)))
;; : (-> (List CallFact) CallFact Boolean )
(def (first-poo-prototype-ref-call-for-caller? calls target)
  (cond
   ((null? calls) #f)
   ((equal? (call-fact-caller (car calls)) (call-fact-caller target))
    (equal? (call-fact-selector (car calls)) (call-fact-selector target)))
   (else
    (first-poo-prototype-ref-call-for-caller? (cdr calls) target))))
;;; Projection count:
;;; - Count only calls that share the constructor caller already selected by
;;;   the burst detector.
;;; - Keeping the filter local makes the threshold evidence explicit in finding
;;;   details without building a separate grouping table.
;; : (-> (List CallFact) String Integer )
(def (poo-prototype-ref-call-count calls caller)
  (length
   (filter (lambda (call)
             (equal? (call-fact-caller call) caller))
           calls)))
;; : (-> SourceFile CallFact Integer TypeFinding )
(def (poo-prototype-fixed-point-finding file call count)
  (make-type-finding
   (policy-rule-id +agent-poo-prototype-fixed-point-rule+)
   (policy-rule-severity +agent-poo-prototype-fixed-point-rule+)
   (source-file-path file)
   (string-append
    "POO constructor " (call-fact-caller call)
    " projects " (number->string count)
    " slots with " (call-fact-callee call)
    "; prefer prototype-local composition with {(:: @ super) slot: ...}, =>, =>.+, ?, and .mix so the object fixed point stays in one POO shape")
   (call-fact-selector call)
   (hash (constructor (call-fact-caller call))
         (callee (call-fact-callee call))
         (projectionCount count)
         (guidanceMode "soft-warning")
         (trigger "constructor projection burst")
         (allowedUse "isolated .ref/.@/.get boundary reads are valid POO API usage")
         (repairShape "define a base prototype and refine slots inside {(:: @ super) ...}; use => for slot transforms, =>.+ for object merges, ? for defaults, and .mix for instance materialization")
         (docsPath "docs/50-59-policy/51.02-gerbil-poo-programming-guidelines.org")
         (source "gerbil-poo doc/poo.md:299-319, t/object-test.ss, and t/mop-test.ss")
         (preferredSyntax "{(:: @ super) slot: ...}, =>, =>.+, ?, .mix")
         (next "read docs/50-59-policy/51.02-gerbil-poo-programming-guidelines.org; asp-gerbil-scheme agent guide . --poo"))))
;;; Boundary:
;;; - This is a POO performance policy, not a build policy.
;;; - Large data-shaped `.o` calls can create avoidable macro-expansion work.
;;; - Small user-facing `.o` objects stay idiomatic and are not reported.
;; : (-> ProjectIndex (List TypeFinding) )
;;; Retired global constructor boundary:
;;; - Large native `.o` declarations are idiomatic POO data/prototype values.
;;; - Performance policy now belongs to loop-local constructor rules, where
;;;   repeated object<-alist/object<-hash/object<-fun construction has concrete
;;;   hot-path evidence without rewriting native top-level `.o` objects.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-construction-performance-findings index)
  '())

;;; Retired large-constructor finding boundary:
;;; - Kept only for callers that still import the symbol directly.
;;; - Main policy no longer calls this because large native `.o` declarations
;;;   are valid POO source. Loop-local repeated construction is handled by the
;;;   dedicated loop-performance policies.
;; : (-> SourceFile CallFact TypeFinding )
(def (poo-construction-performance-finding file call)
  (make-type-finding
   (policy-rule-id +agent-poo-construction-performance-rule+)
   (policy-rule-severity +agent-poo-construction-performance-rule+)
   (source-file-path file)
   (string-append
    "retired global POO construction warning for " (call-fact-callee call)
    "; preserve native .o declarations and rely on loop-local construction policies for hot-path performance")
   (call-fact-selector call)
   (hash (kind "poo-construction-performance")
         (constructor (or (call-fact-caller call) "top-level"))
         (callee (call-fact-callee call))
         (argumentCount (length (call-fact-arguments call)))
         (slotSpecCount (poo-object-literal-slot-spec-count call))
         (slotSpecThreshold +poo-data-object-literal-min-slot-specs+)
         (guidanceMode "retired-warning")
         (trigger "retired global large .o construction rule")
         (allowedUse "large native .o profile/config declarations remain idiomatic POO")
         (preferredConstruction "preserve native .o declarations; optimize only loop-local repeated object construction")
         (performanceEvidence "loop-local policies own concrete hot-path evidence for object<-alist/object<-hash/object<-fun and small .o construction")
         (publicApiBoundary "keep POO declarations native and parser-visible")
         (sourceEvidence "gerbil-poo object.ss:149-158")
         (next "use GERBIL-SCHEME-AGENT-POLICY-032 for loop-local object construction performance"))))

(def +poo-generated-boundary-keywords+
  '("receipt" "manifest" "snapshot" "handoff" "diagnostic"))

;;; Boundary:
;;; - Generated runtime receipts are fixed data state, not user-authored POO
;;;   declarations.
;;; - Adapter constructors remain valid for external ingestion, but generated
;;;   receipt/handoff/manifest builders should use defstruct internally and
;;;   serialize once through an explicit ->alist boundary.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-generated-receipt-boundary-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (and (poo-generated-receipt-boundary-call? file call)
                            (poo-generated-receipt-boundary-finding
                             file
                             call)))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact Boolean )
(def (poo-generated-receipt-boundary-call? file call)
  (and (member (call-fact-callee call) +poo-super-constructor-callees+)
       (poo-generated-boundary-context? file call)))

;; : (-> SourceFile CallFact Boolean )
(def (poo-generated-boundary-context? file call)
  (or (poo-generated-boundary-name? (source-file-path file))
      (poo-generated-boundary-name? (or (call-fact-caller call) ""))))

;; : (-> String Boolean )
(def (poo-generated-boundary-name? name)
  (ormap (lambda (fragment)
           (and (string-contains name fragment) #t))
         +poo-generated-boundary-keywords+))

;; : (-> SourceFile CallFact TypeFinding )
(def (poo-generated-receipt-boundary-finding file call)
  (make-type-finding
   (policy-rule-id +agent-poo-generated-receipt-boundary-rule+)
   (policy-rule-severity +agent-poo-generated-receipt-boundary-rule+)
   (source-file-path file)
   (string-append
    "generated runtime boundary " (or (call-fact-caller call) "top-level")
    " constructs receipt-like state with " (call-fact-callee call)
    "; use a fixed defstruct internally and one explicit ->alist projection at the ABI boundary")
   (call-fact-selector call)
   (hash (kind "poo-generated-receipt-boundary")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (guidanceMode "quality-performance-warning")
         (trigger "receipt/manifest/snapshot/handoff context uses POO adapter constructor for generated state")
         (allowedUse "native .o/.def user POO declarations and adapter constructors at external ingestion boundaries remain valid")
         (preferredConstruction "defstruct for generated receipt state plus explicit receipt->alist projection at presentation/runtime ABI boundary")
         (performanceEvidence "fixed Gerbil structs keep generated receipt construction stable; object<-alist/object<-hash rebuild object shape and hide the boundary behind adapter conversion")
         (sourceEvidence "gerbil runtime-response defstruct->alist pattern and gerbil-poo object.ss adapter constructors")
         (next "replace generated receipt object<-alist/object<-hash/object<-fun with defstruct fields and a named ->alist serializer"))))

;;; Boundary:
;;; - poo-method-shape-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-method-shape-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (fact)
                   (and (equal? (poo-form-fact-role fact) "method")
                        (let (missing (poo-method-shape-missing index fact))
                          (and (pair? missing)
                               (poo-method-shape-finding file fact missing)))))
                 (source-file-poo-forms file)))
              (project-index-files index))))
;;; Boundary:
;;; - poo-method-shape-missing composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex Fact PooMethodShapeMissing )
(def (poo-method-shape-missing index fact)
  (filter identity
          [(and (blank-string? (poo-form-fact-generic fact)) "generic")
           (and (not (blank-string? (poo-form-fact-generic fact)))
                (not (poo-generic-fact-exists? index (poo-form-fact-generic fact)))
                "defgeneric")
           (and (blank-string? (poo-form-fact-receiver-type fact)) "receiver-type")
           (and (not (blank-string? (poo-form-fact-receiver-type fact)))
                (not (poo-receiver-evidence-exists?
                      index
                      (poo-form-fact-receiver-type fact)))
                "defclass-or-defprotocol")]))
;;; Boundary:
;;; - poo-generic-fact-exists? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex Generic Boolean )
(def (poo-generic-fact-exists? index generic)
  (ormap
   (lambda (fact)
     (and (equal? (poo-form-fact-role fact) "generic")
          (equal? (poo-form-fact-generic fact) generic)))
   (project-poo-forms index)))
;; : (-> ProjectIndex String Boolean )
(def (poo-receiver-evidence-exists? index name)
  (or (poo-class-fact-exists? index name)
      (poo-protocol-fact-exists? index name)))
;; : (-> SourceFile Fact Missing TypeFinding )
(def (poo-method-shape-finding file fact missing)
  (make-type-finding
   (policy-rule-id +agent-poo-method-shape-rule+)
   (policy-rule-severity +agent-poo-method-shape-rule+)
   (source-file-path file)
   (string-append "POO method " (poo-form-fact-name fact)
                  " is missing parser-owned "
                  (string-join missing ",")
                  " facts; query POO pattern evidence and add defgeneric/defclass/defprotocol structure before extending methods")
   (poo-form-fact-selector fact)
   (hash (generic (or (poo-form-fact-generic fact) ""))
         (receiverType (or (poo-form-fact-receiver-type fact) ""))
         (missing missing)
         (next "search pattern poo class protocol"))))

;; (List Callee)
(def +poo-documentation-usage-callees+
  '(".putslot!" ".putdefault!" ".setslot!" ".setslots!" ".set!"
    "putslot!" "putdefault!" "setslot!" "setslots!"))

;; (List String)
(def +poo-documentation-usage-doc-terms+
  '(".o" ".def" "defpoo" ".mix" ".ref" ".get"
    ".putslot!" ".putdefault!" ".setslot!" ".setslots!" ".set!"
    "putslot!" "putdefault!" "setslot!" "setslots!"
    "slot" "slots" "prototype" "fixed point" "default"))

;;; Boundary:
;;; - POO usage docs are required for defaults and slot mutation, not ordinary
;;;   construction, composition, or boundary reads.
;;; - The rule consumes parser-owned calls and typed-comment metadata only.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-documentation-usage-findings index)
  (if (poo-capability-active? index)
    (filter-map
     (lambda (file)
       (and (index-source-runtime-file-path? index (source-file-path file))
            (pair? (poo-documentation-usage-calls file))
            (not (poo-documentation-usage-documented? file))
            (poo-documentation-usage-finding file)))
     (project-index-files index))
    '()))

;; : (-> SourceFile (List CallFact) )
(def (poo-documentation-usage-calls file)
  (filter poo-documentation-usage-call? (source-file-calls file)))

;; : (-> CallFact Boolean )
(def (poo-documentation-usage-call? call)
  (member (call-fact-callee call) +poo-documentation-usage-callees+))

;; : (-> SourceFile Boolean )
(def (poo-documentation-usage-documented? file)
  (ormap poo-documentation-typed-contract-complete?
         (source-file-typed-contract-facts file)))

;; : (-> TypedContractFact Boolean )
(def (poo-documentation-typed-contract-complete? fact)
  (let (typed-comment (typed-contract-fact-typed-comment fact))
    (and typed-comment
         (hash-get typed-comment 'fullForm)
         (poo-documentation-docs-complete
          (or (hash-get typed-comment 'docs) [])))))

;; : (-> (List Json) Boolean )
(def (poo-documentation-docs-complete docs)
  (and (poo-documentation-docs-have-body? docs)
       (poo-documentation-docs-have-result-example? docs)
       (poo-documentation-docs-mention-usage? docs)))

;; : (-> (List Json) Boolean )
(def (poo-documentation-docs-have-body? docs)
  (ormap (lambda (doc)
           (not (blank-string? (poo-documentation-doc-body doc))))
         docs))

;; : (-> (List Json) Boolean )
(def (poo-documentation-docs-have-result-example? docs)
  (ormap (lambda (doc)
           (poo-documentation-doc-has-result-example? doc))
         docs))

;; : (-> Json String )
(def (poo-documentation-doc-body doc)
  (or (hash-get doc 'body) ""))

;; : (-> Json (List Json) )
(def (poo-documentation-doc-examples doc)
  (or (hash-get doc 'examples) []))

;; : (-> Json Boolean )
(def (poo-documentation-doc-has-result-example? doc)
  (or (hash-get doc 'hasResultExamples)
      (ormap poo-documentation-example-has-result?
             (poo-documentation-doc-examples doc))))

;; : (-> Json Boolean )
(def (poo-documentation-example-has-result? example)
  (if (hash-get example 'hasExpectedResult) #t #f))

;; : (-> (List Json) Boolean )
(def (poo-documentation-docs-mention-usage? docs)
  (ormap (lambda (doc)
           (poo-documentation-text-mentions-usage?
            (string-append (poo-documentation-doc-body doc)
                           "\n"
                           (poo-documentation-examples-text
                            (poo-documentation-doc-examples doc)))))
         docs))

;; : (-> (List Json) String )
(def (poo-documentation-examples-text examples)
  (string-join
   (filter-map (lambda (example)
                 (or (hash-get example 'code)
                     (hash-get example 'body)
                     (hash-get example 'text)))
               examples)
   "\n"))

;; : (-> String Boolean )
(def (poo-documentation-text-mentions-usage? text)
  (ormap (lambda (term)
           (string-contains text term))
         +poo-documentation-usage-doc-terms+))

;; : (-> SourceFile TypeFinding )
(def (poo-documentation-usage-finding file)
  (let (calls (poo-documentation-usage-calls file))
    (make-type-finding
     (policy-rule-id +agent-poo-documentation-usage-rule+)
     (policy-rule-severity +agent-poo-documentation-usage-rule+)
     (source-file-path file)
     "POO defaults and slot mutation APIs need a full-form typed doc with body, result example, and POO usage terms"
     (call-fact-selector (car calls))
     (hash (apiCallees (map call-fact-callee calls))
           (requiredEvidence ["full-form typed doc" "body" "result-example" "poo-usage-terms"])
           (triggerApis ".putslot!,.putdefault!,.setslot!,.setslots!,.set!,putslot!,putdefault!,setslot!,setslots!")
           (coveredApis ".o,.def,defpoo,.mix,.ref,.get,.putslot!,.putdefault!,.setslot!,.setslots!,.set!,putslot!,putdefault!,setslot!,setslots!")
           (source "gerbil-poo doc/poo.md:30-50, 655-720")
           (next
            (string-append
             "asp-gerbil-scheme projection --native-index --owner "
             (source-file-path file)
             " --json --workspace ."))))))
