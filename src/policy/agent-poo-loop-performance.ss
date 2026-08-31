;;; -*- Gerbil -*-
;;; POO loop-performance policy checks.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-poo-callees
        :asp-gerbil-scheme/src/policy/agent-poo-object-literal
        :asp-gerbil-scheme/src/policy/agent-support
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/sugar filter-map hash ormap)
        :asp-gerbil-scheme/src/types/findings)

(export poo-clone-override-loop-performance-findings
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
        poo-slot-predicate-loop-performance-finding)

;;; Boundary:
;;; - This catches repeated pure clone overrides in loop bodies.
;;; - A single `.cc` remains idiomatic; hot loops should not copy the full slot
;;;   list on every iteration when only one override changes.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-clone-override-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-clone-override-loop-driver file call))
                         (and loop
                              (poo-clone-override-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-clone-override-loop-driver file call)
  (and (member (call-fact-callee call) +poo-clone-override-callees+)
       (poo-call-loop-driver file call)))

;;; Loop lookup boundary:
;;; - Match a POO call back to the parser-owned loop driver for the same caller.
;;; - ormap keeps the search expression-level and stops at the first witness.
;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-call-loop-driver file call)
  (and (call-fact-caller call)
       (ormap (lambda (loop)
                (and (equal? (loop-driver-fact-caller loop)
                             (call-fact-caller call))
                     (poo-call-inside-loop-driver? call loop)
                     loop))
              (source-file-loop-driver-facts file))))

;;; Loop locality boundary:
;;; - Caller-level loop facts are not enough; a function can hoist one POO
;;;   boundary value before or after the loop.
;;; - Require the call selector to fall inside the parser-owned loop range.
;; : (-> CallFact LoopDriverFact Boolean )
(def (poo-call-inside-loop-driver? call loop)
  (and (number? (call-fact-start call))
       (number? (call-fact-end call))
       (number? (loop-driver-fact-start loop))
       (number? (loop-driver-fact-end loop))
       (>= (call-fact-start call) (loop-driver-fact-start loop))
       (<= (call-fact-end call) (loop-driver-fact-end loop))))

;; : (-> LoopDriverFact String )
(def (poo-loop-driver-agent-role loop)
  (let (role (loop-driver-fact-role loop))
    (if (equal? role "manual-loop-classification")
      "manual-loop"
      role)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-clone-override-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-clone-override-loop-performance-rule+)
   (policy-rule-severity +agent-poo-clone-override-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly clones with " (call-fact-callee call)
    "; prefer accumulating scalar state and applying one final .cc, or use .put! only when mutation is intentional")
   (call-fact-selector call)
   (hash (kind "poo-clone-override-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (poo-loop-driver-agent-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated .cc clone override")
         (allowedUse "single .cc clone overrides and non-loop object refinement remain idiomatic POO")
         (preferredConstruction "accumulate loop state and apply one final .cc; use .put! only for intentional mutable objects")
         (performanceEvidence "gerbil-poo .cc copies the full slot list for each override; measured loop probes show .cc scales with slot count while .put! stays near constant")
         (sourceEvidence "gerbil-poo object.ss:462-494")
         (next "move .cc outside the loop or switch to an explicit stateful update boundary"))))

;;; Boundary:
;;; - This catches full-object materialization inside loop bodies.
;;; - Boundary serialization remains valid; hot loops should materialize once
;;;   or use direct slot access instead of walking/sorting every slot each pass.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-materialization-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-materialization-loop-driver file call))
                         (and loop
                              (poo-materialization-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-materialization-loop-driver file call)
  (and (member (call-fact-callee call) +poo-materialization-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-materialization-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-materialization-loop-performance-rule+)
   (policy-rule-severity +agent-poo-materialization-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly materializes or iterates object slots with "
    (call-fact-callee call)
    "; materialize or iterate once outside the loop, or read only the required slots")
   (call-fact-selector call)
   (hash (kind "poo-materialization-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (poo-loop-driver-agent-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO materialization or iteration")
         (allowedUse "one-time boundary serialization and non-loop inspection remain valid POO usage")
         (preferredConstruction "materialize, iterate, or project once outside the loop, or use direct .ref access for specific slots")
         (performanceEvidence "gerbil-poo .for-each! walks .all-slots and calls .ref for every slot, .alist walks all slots, .alist/sort sorts them each call, force-object forces every slot, and .refs/slots maps selected slots; measured loop probes show materialize/project/iterate-once stays lower")
         (sourceEvidence "gerbil-poo object.ss:120-229")
         (next "hoist .for-each!/.alist/.alist/sort/.all-slots/.refs/slots/hash<-object/force-object out of the loop or narrow the loop to required scalar state"))))

;;; Boundary:
;;; - This catches POO composition chains built inside loop bodies.
;;; - One-time composition remains idiomatic; hot loops should accumulate scalar
;;;   state and apply the composition once at the boundary.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-composition-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-composition-loop-driver file call))
                         (and loop
                              (poo-composition-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-composition-loop-driver file call)
  (and (poo-composition-loop-call? call)
       (poo-call-loop-driver file call)))

;; : (-> CallFact Boolean )
(def (poo-composition-loop-call? call)
  (or (member (call-fact-callee call) +poo-composition-callees+)
      (and (member (call-fact-callee call) +poo-super-constructor-callees+)
           (poo-call-has-keyword-argument? call "supers:"))))

;;; Keyword argument predicate:
;;; - POO constructor options are represented as parser-owned argument strings.
;;; - The predicate stays local so loop policies share one exact option match.
;; : (-> CallFact String Boolean )
(def (poo-call-has-keyword-argument? call keyword)
  (ormap (lambda (arg)
           (equal? arg keyword))
         (call-fact-arguments call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-composition-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-composition-loop-performance-rule+)
   (policy-rule-severity +agent-poo-composition-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly composes object supers with " (call-fact-callee call)
    "; accumulate loop state and compose the object once at the boundary")
   (call-fact-selector call)
   (hash (kind "poo-composition-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (poo-loop-driver-agent-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO composition")
         (allowedUse "one-time .mix/.extend/.+ composition and boundary object assembly remain idiomatic POO")
         (preferredConstruction "accumulate scalar loop state and apply one final POO composition outside the loop")
         (performanceEvidence "gerbil-poo composition creates new supers chains; first .ref computes precedence-list and slot-funs across supers")
         (sourceEvidence "gerbil-poo object.ss:47-95,160-180")
         (next "move .mix/.extend/.+/supers: object construction outside the loop or replace the loop state with scalar accumulation"))))

;;; Boundary:
;;; - This catches repeated POO/MOP validation over the same object shape inside
;;;   loop bodies.
;;; - Boundary validation remains valid; hot loops should consume an already
;;;   validated value or validate only changed scalar fields.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-validation-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-validation-loop-driver file call))
                         (and loop
                              (poo-validation-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-validation-loop-driver file call)
  (and (member (call-fact-callee call) +poo-validation-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-validation-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-validation-loop-performance-rule+)
   (policy-rule-severity +agent-poo-validation-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly validates object shape with " (call-fact-callee call)
    "; validate once before the loop or validate only changed scalar fields")
   (call-fact-selector call)
   (hash (kind "poo-validation-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (poo-loop-driver-agent-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO validation")
         (allowedUse "boundary validation and one-time type checks remain valid POO/MOP usage")
         (preferredConstruction "validate once outside the loop, then operate on the validated object or scalar fields")
         (performanceEvidence "gerbil-poo MonomorphicObject validation walks all object values; measured loop probes show validate-once stays near constant")
         (sourceEvidence "gerbil-poo mop.ss:80-230")
         (next "hoist validate/element? out of the loop or narrow the loop to direct .ref/scalar predicates"))))

;;; Boundary:
;;; - This catches Lens .modify inside loop bodies because slot-lens .set
;;;   delegates to `.cc`, which clones the POO object on every update.
;;; - Lens remains valid as a boundary abstraction; hot loops should carry
;;;   scalar state and apply one final object update.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-lens-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-lens-loop-driver file call))
                         (and loop
                              (poo-lens-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-lens-loop-driver file call)
  (and (poo-lens-modify-call? call)
       (poo-call-loop-driver file call)))

;; : (-> CallFact Boolean )
(def (poo-lens-modify-call? call)
  (or (and (equal? (call-fact-callee call) ".call")
           (poo-call-has-argument? call "Lens")
           (poo-call-has-argument? call ".modify"))
      (and (member (call-fact-callee call) +poo-lens-modify-callees+)
           (poo-call-has-argument? call "slot-lens"))))

;;; Argument predicate:
;;; - Lens and constructor policies inspect parser-owned call arguments only.
;;; - The ormap shape preserves short-circuit behavior for compact scans.
;; : (-> CallFact String Boolean )
(def (poo-call-has-argument? call value)
  (ormap (lambda (arg)
           (equal? arg value))
         (call-fact-arguments call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-lens-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-lens-loop-performance-rule+)
   (policy-rule-severity +agent-poo-lens-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly updates through Lens .modify; slot-lens .set delegates to .cc, so each loop step can clone the full object")
   (call-fact-selector call)
   (hash (kind "poo-lens-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (poo-loop-driver-agent-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated Lens .modify over POO object")
         (allowedUse "one-time Lens .modify and non-loop lens composition remain valid POO/MOP usage")
         (preferredConstruction "accumulate scalar lens target state and apply one final .cc outside the loop")
         (performanceEvidence "gerbil-poo Lens .modify calls .set after .get, and slot-lens .set calls .cc; measured 2000 updates: 100 slots 1132ms, 500 slots 4489ms, scalar-final-.cc 0ms")
         (sourceEvidence "gerbil-poo mop.ss:424-484")
         (next "replace loop-local Lens .modify with direct .ref/scalar accumulation and a final .cc boundary update"))))

;;; Boundary:
;;; - This catches object construction from collection-like inputs inside loop
;;;   bodies.
;;; - Object construction remains valid at boundaries; hot loops should carry
;;;   scalar/list/hash state and build one POO object outside the loop.
;;; - If the same loop already has POO composition, R030 owns the repair to
;;;   avoid duplicate findings.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-object-construction-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-object-construction-loop-driver
                                   file call))
                         (and loop
                              (poo-object-construction-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-object-construction-loop-driver file call)
  (let (loop (poo-call-loop-driver file call))
    (and loop
         (poo-loop-local-object-constructor-call? call)
         (not (poo-loop-caller-has-composition-call? file call))
         loop)))

;;; Loop-local constructor predicate:
;;; - Keep constructor membership, supers exclusion, and broad .o filtering as
;;;   separate predicates so later policy changes do not grow one boolean wall.
;; : (-> CallFact Boolean )
(def (poo-loop-local-object-constructor-call? call)
  (and (poo-object-constructor-callee? call)
       (not (poo-call-has-keyword-argument? call "supers:"))
       (poo-loop-local-object-constructor-small-enough? call)))

;; : (-> CallFact Boolean )
(def (poo-object-constructor-callee? call)
  (member (call-fact-callee call) +poo-object-constructor-callees+))

;; : (-> CallFact Boolean )
(def (poo-loop-local-object-constructor-small-enough? call)
  (or (not (equal? (call-fact-callee call) ".o"))
      (not (poo-object-literal-slot-spec-count>=?
            call
            +poo-data-object-literal-min-slot-specs+))))

;;; Composition guard:
;;; - Object-construction warnings defer to the composition-loop warning when
;;;   both facts belong to the same loop caller.
;;; - Excluding the target selector prevents a call from matching itself.
;; : (-> SourceFile CallFact Boolean )
(def (poo-loop-caller-has-composition-call? file target)
  (and (call-fact-caller target)
       (ormap (lambda (call)
                (and (not (equal? (call-fact-selector call)
                                  (call-fact-selector target)))
                     (equal? (call-fact-caller call)
                             (call-fact-caller target))
                     (poo-composition-loop-call? call)))
              (source-file-calls file))))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-object-construction-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-object-construction-loop-performance-rule+)
   (policy-rule-severity +agent-poo-object-construction-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly constructs objects with " (call-fact-callee call)
    "; hoist stable object construction or accumulate scalar/list/hash state and build one object at the boundary")
   (call-fact-selector call)
   (hash (kind "poo-object-construction-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (poo-loop-driver-agent-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO object construction")
         (allowedUse "boundary object construction and per-iteration construction with genuinely changing object shape remain valid POO usage")
         (preferredConstruction "hoist stable object construction or accumulate scalar/list/hash state and construct one final POO object")
         (performanceEvidence "gerbil-poo object<-alist/object<-hash allocate a new object shape; measured 2000 loop constructions: object<-alist 500 slots 4114ms, object<-hash 500 slots 9522ms, hoisted object 0ms")
         (sourceEvidence "gerbil-poo object.ss:136-151")
         (next "move object<-alist/object<-hash/object<-fun/.o construction outside the loop or return scalar/list/hash loop state and construct once"))))

;;; Boundary:
;;; - This catches loop-local construction of uncached POO/MOP type objects.
;;; - Type construction remains valid at module/boundary scope; hot loops
;;;   should reuse a named type object and then validate/check values.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-type-construction-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-type-construction-loop-driver
                                   file call))
                         (and loop
                              (poo-type-construction-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-type-construction-loop-driver file call)
  (and (member (call-fact-callee call) +poo-type-constructor-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-type-construction-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-type-construction-loop-performance-rule+)
   (policy-rule-severity +agent-poo-type-construction-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly constructs type objects with " (call-fact-callee call)
    "; hoist stable type construction to a named binding outside the loop")
   (call-fact-selector call)
   (hash (kind "poo-type-construction-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (poo-loop-driver-agent-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO/MOP type construction")
         (allowedUse "module-level and boundary type construction remain idiomatic POO/MOP usage")
         (preferredConstruction "hoist stable POO/MOP type objects to a named binding outside the loop")
         (performanceEvidence "gerbil-poo MonomorphicObject constructs a fresh type object with closure slots; Function validates input/output type lists and builds a type descriptor object; F_q builds a finite-field type object and nested Z/pZ descriptor; Z/ and IntegerRange build fresh numeric type descriptors while UIntN/IntN are cached with hash-ensure-ref; measured MonomorphicObject 100000 loop constructions 6358ms vs hoisted 67ms, Function 1017ms vs hoisted 8ms, F_q 524ms vs hoisted 5ms, Z/ 392ms vs hoisted 12ms, IntegerRange 739ms vs hoisted 4ms")
         (sourceEvidence "gerbil-poo mop.ss:188-240, fq.ss:24-95, and number.ss:90-160")
         (next "define stable MonomorphicObject, Function, F_q, Z/, or IntegerRange type objects once outside the loop, then reuse them for validation or projection"))))

;;; Boundary:
;;; - This catches loop-local debug instrumentation over POO objects.
;;; - trace-poo walks all slots and installs traced slot wrappers; it should be
;;;   a boundary/debug setup operation, not repeated hot-loop work.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-debug-instrumentation-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-debug-instrumentation-loop-driver
                                   file call))
                         (and loop
                              (poo-debug-instrumentation-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-debug-instrumentation-loop-driver file call)
  (and (member (call-fact-callee call) +poo-debug-instrumentation-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-debug-instrumentation-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-debug-instrumentation-loop-performance-rule+)
   (policy-rule-severity +agent-poo-debug-instrumentation-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly installs debug instrumentation with " (call-fact-callee call)
    "; trace the object once at a debug boundary and reuse the traced value")
   (call-fact-selector call)
   (hash (kind "poo-debug-instrumentation-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (poo-loop-driver-agent-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO debug instrumentation")
         (allowedUse "boundary trace-poo setup and one-off debugging remain valid POO diagnostics")
         (preferredConstruction "hoist trace-poo outside the loop and reuse the traced object")
         (performanceEvidence "gerbil-poo trace-poo walks .all-slots and installs traced wrappers; measured 500 slots x 50 constructions 2942ms, hoisted traced object 0ms")
         (sourceEvidence "gerbil-poo debug.ss:57-77")
         (next "move trace-poo to a debug setup boundary before the loop, or guard it behind a one-time diagnostic flag"))))

;;; Boundary:
;;; - This catches loop-local mutation of POO slot specifications.
;;; - Slot-spec mutation changes object shape; value updates should use .put!
;;;   when mutation is intentional, or pure loop state plus one boundary update.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-slot-spec-mutation-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-slot-spec-mutation-loop-driver
                                   file call))
                         (and loop
                              (poo-slot-spec-mutation-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-slot-spec-mutation-loop-driver file call)
  (and (member (call-fact-callee call) +poo-slot-spec-mutation-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-slot-spec-mutation-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-slot-spec-mutation-loop-performance-rule+)
   (policy-rule-severity +agent-poo-slot-spec-mutation-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly mutates slot specs with " (call-fact-callee call)
    "; keep slot definitions at setup boundaries and use .put! or scalar state for loop values")
   (call-fact-selector call)
   (hash (kind "poo-slot-spec-mutation-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (poo-loop-driver-agent-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO slot-spec mutation")
         (allowedUse "setup-time .def!/.putslot! shape definition remains valid POO usage")
         (preferredConstruction "define slots once at setup; use .put! for intentional value mutation or scalar loop state plus one final object update")
         (performanceEvidence "gerbil-poo .putslot! mutates object slot specs; measured .def! 500 slots x 5000 at 2020ms while .put! value updates stayed 0ms")
         (cacheEvidence "after object instantiation, .def! changes slot specs but existing cached values remain visible until cache reset")
         (sourceEvidence "gerbil-poo object.ss:424-450")
         (next "move .def!/.putslot!/.setslot! outside the loop; if changing only the value, use .put! for mutable objects or final .cc for pure updates"))))

;;; Boundary:
;;; - This catches loop-local construction/use of multi-slot POO predicates.
;;; - Single-slot .slot? checks stay valid; stable multi-slot shape predicates
;;;   should be hoisted when the object shape does not change in the loop.
;; : (-> ProjectIndex (List TypeFinding) )
(def (poo-slot-predicate-loop-performance-findings index)
  (if (poo-capability-active? index)
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (call)
                       (let (loop (poo-slot-predicate-loop-driver file call))
                         (and loop
                              (poo-slot-predicate-loop-performance-finding
                               file call loop))))
                     (source-file-calls file))
                    '()))
                (project-index-files index)))
    '()))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (poo-slot-predicate-loop-driver file call)
  (and (member (call-fact-callee call) +poo-slot-predicate-callees+)
       (poo-call-loop-driver file call)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (poo-slot-predicate-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-poo-slot-predicate-loop-performance-rule+)
   (policy-rule-severity +agent-poo-slot-predicate-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "POO loop " (loop-driver-fact-name loop)
    " repeatedly builds or applies a multi-slot predicate with " (call-fact-callee call)
    "; hoist the predicate result when object shape is stable")
   (call-fact-selector call)
   (hash (kind "poo-slot-predicate-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (poo-loop-driver-agent-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated POO multi-slot predicate")
         (allowedUse "single .slot? checks and boundary o?/slots predicates remain valid POO usage")
         (preferredConstruction "hoist stable o?/slots predicate results outside the loop; hoist the predicate closure when only the slot list is stable")
         (performanceEvidence "gerbil-poo o?/slots maps .slot? across the slot list; measured 500 slots, 50 keys, 2000 loop checks 524ms, hoisted predicate result 0ms")
         (sourceEvidence "gerbil-poo object.ss:169-217")
         (next "move o?/slots outside the loop when the object shape is stable; keep loop state to changed values only"))))
