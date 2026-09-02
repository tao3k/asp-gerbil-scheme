;;; -*- Gerbil -*-
;;; Baseline agent policy checks for ownership, entrypoints, and functional idioms.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-poo
        :asp-gerbil-scheme/src/policy/agent-support
        :asp-gerbil-scheme/src/policy/model
        :asp-gerbil-scheme/src/policy/modularity
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/1 take)
        (only-in :std/srfi/13
                 string-contains
                 string-prefix?
                 string-suffix?
                 string-trim)
        (only-in :std/sugar cut filter filter-map find hash ormap with-catch)
        :asp-gerbil-scheme/src/types/findings)

(export facade-intent-findings
        facade-intent-finding
        generic-owner-findings
        generic-owner-findings/files
        generic-owner-segment
        generic-owner-finding
        vague-definition-findings
        vague-definition-findings/files
        vague-definition-finding
        top-level-executable-findings
        top-level-executable-finding
        functional-idiom-advice-findings
        functional-idiom-advice-finding)

;; ConfigConstant
(def +generic-owner-segments+
  '("utils" "util" "utility" "common" "helpers" "misc" "shared"))
;; ConfigConstant
(def +vague-definition-names+
  '("helper" "helpers" "process" "handle" "convert" "transform" "thing" "stuff" "do-it" "run-it"))
;; String
(def +functional-idiom-roles+
  '("sequence-map"
    "sequence-filter"
    "sequence-filter-map"
    "sequence-append-map"
    "sequence-predicate"
    "sequence-search"
    "sequence-fold"
    "loop-fold"
    "partial-application"
    "function-curry"
    "function-composition"
    "list-builder"))
;; Integer
(def +functional-sequence-idioms+
  '("map" "filter" "filter-map" "append-map" "fold/foldl/foldr" "for/fold"))
;; Integer
(def +functional-predicate-idioms+
  '("andmap/ormap" "every/any" "find/list-index"))
;; Integer
(def +functional-composition-idioms+
  '("cut/cute" "curry/rcurry" "compose/compose1" "!>/!!>"))
;; Integer
(def +functional-native-lambda-idioms+
  '("fun" "lambda-match/λ-match" "λ" "case-lambda"))
;; Integer
(def +functional-typeclass-idioms+
  '("gerbil-poo/fun.ss Category." "Functor." "ParametricFunctor."
    "Wrapper./Wrap." "methods.table protocol slots"))
;; String
(def +functional-basic-syntax-smells+
  '("named-let rest/accumulator traversal"
    "manual null?/car/cdr branch over a list"
    "threaded accumulator state without IO or control preservation"
    "anonymous list tuple projection where values/call-with-values would name the protocol"
    "nested conditional shape dispatch where match/lambda-match would expose the data shape"))
;; String
(def +functional-native-repair-contract+
  '("sequence traversal -> map/filter/filter-map/fold/foldl/foldr/andmap/ormap"
    "shape dispatch -> match/lambda-match"
    "arity specialization -> case-lambda"
    "partial application -> cut/cute/curry/rcurry/compose/!>/!!>"
    "tuple projection -> values/call-with-values"
    "state/control boundary -> parameterize/dynamic-wind or preserve named-let"))
;; String
(def +functional-design-feature-priority+
  '("prefer a semantic Gerbil/Gambit feature over a surface syntax rewrite"
    "make the data-flow shape visible in the expression body"
    "keep named-let only when recursion is the actual control model"
    "use the smallest idiom that removes accumulator and projection boilerplate"))
;; String
(def +functional-preservation-control-roles+
  '("protected-control"
    "protected-handler"
    "cleanup-boundary"
    "continuation-control"
    "resource-scope"
    "parameter-state"
    "builder-control"
    "actor-control"
    "coroutine-control"))
;; String
(def +redundant-manual-loop-required-signals+
  '("named-let"
    "manual-loop-role"
    "multi-binding-loop-state"
    "no-functional-idiom-witness"
    "no-reader-boundary"
    "no-control-preservation-context"))
;; String
(def +functional-preservation-reader-callees+
  '("read" "read-char" "read-line" "read-syntax"))
;;; Boundary:
;;; - facade-intent-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (facade-intent-findings index)
  (filter-map
   (lambda (file)
     (and (facade-source-file? index file)
          (not (facade-has-intent-doc? index file))
          (facade-intent-finding file)))
   (project-index-files index)))
;;; Boundary:
;;; - generic-owner-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (generic-owner-findings index)
  (generic-owner-findings/files (project-index-files index)))
;; : (-> (List SourceFile) (List TypeFinding) )
(def (generic-owner-findings/files files)
  (filter-map
   (lambda (file)
     (let (segment (generic-owner-segment (source-file-path file)))
       (and segment (generic-owner-finding file segment))))
   files))
;;; Boundary:
;;; - facade-has-intent-doc? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex SourceFile Boolean )
(def (facade-has-intent-doc? index file)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let (lines (read-file-lines
                  (path-expand (source-file-path file)
                               (project-index-root index))))
       (ormap intent-comment?
              (take lines (min 8 (length lines))))))))
;; : (-> SourceLine Boolean )
(def (intent-comment? line)
  (let (text (string-trim line))
    (and (string-prefix? ";;;" text)
         (not (string-contains text "-*-")))))
;; : (-> SourceFile TypeFinding )
(def (facade-intent-finding file)
  (make-type-finding
   (policy-rule-id +agent-intent-rule+)
   (policy-rule-severity +agent-intent-rule+)
   (source-file-path file)
   (string-append "facade " (source-file-path file)
                  " lacks an agent-readable intent comment")
   (source-file-path file)
   #f))
;;; Boundary:
;;; - generic-owner-segment composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> String GenericOwnerSegment )
(def (generic-owner-segment path)
  (find (lambda (segment) (path-has-owner-segment? path segment))
        +generic-owner-segments+))
;; : (-> String Segment Boolean )
(def (path-has-owner-segment? path segment)
  (or (equal? path (string-append "src/" segment ".ss"))
      (string-contains path (string-append "/" segment ".ss"))
      (string-contains path (string-append "/" segment "/"))))
;; : (-> SourceFile Segment TypeFinding )
(def (generic-owner-finding file segment)
  (make-type-finding
   (policy-rule-id +agent-generic-owner-rule+)
   (policy-rule-severity +agent-generic-owner-rule+)
   (source-file-path file)
   (string-append "generic owner segment " segment
                  " hides the Gerbil module responsibility")
   (source-file-path file)
   (hash (segment segment))))
;;; Boundary:
;;; - vague-definition-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (vague-definition-findings index)
  (vague-definition-findings/files (project-index-files index)))
;; : (-> (List SourceFile) (List TypeFinding) )
(def (vague-definition-findings/files files)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (definition)
                   (and (vague-definition-name? (definition-name definition))
                        (vague-definition-finding file definition)))
                 (source-file-definitions file)))
              files)))
;; : (-> String Boolean )
(def (vague-definition-name? name)
  (member name +vague-definition-names+))
;; : (-> SourceFile Definition TypeFinding )
(def (vague-definition-finding file definition)
  (make-type-finding
   (policy-rule-id +agent-vague-definition-rule+)
   (policy-rule-severity +agent-vague-definition-rule+)
   (source-file-path file)
   (string-append "definition " (definition-name definition)
                  " is too vague for agent-written Gerbil; name the domain or data flow")
   (definition-selector definition)
   (hash (definition (definition-name definition))
         (selector (definition-selector definition)))))
;;; Boundary:
;;; - top-level-executable-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (top-level-executable-findings index)
  (apply append
         (map (lambda (file)
              (filter-map
               (lambda (call)
                   (and (top-level-executable-call? index file call)
                        (top-level-executable-finding file call)))
                 (source-file-calls file)))
              (project-index-files index))))
;; : (-> ProjectIndex SourceFile CallFact Boolean )
(def (top-level-executable-call? index file call)
  (and (top-level-runtime-call? index call)
       (not (top-level-entrypoint-exempt-call? file call))))

;; : (-> ProjectIndex CallFact Boolean )
(def (top-level-runtime-call? index call)
  (and (not (call-fact-caller call))
       (index-source-runtime-file-path? index (call-fact-path call))))

;; : (-> SourceFile CallFact Boolean )
(def (top-level-entrypoint-exempt-call? file call)
  (or (explicit-main-entrypoint-call? file call)
      (explicit-test-entrypoint-call? file call)
      (declarative-top-level-call? file call)))

;; (List TopFormHead)
(def +explicit-main-entrypoint-heads+
  '("main" "apply" "exit"))

;; (List TopFormHead)
(def +explicit-test-entrypoint-heads+
  '("run-tests!"))

;; (List TopFormHead)
(def +agent-declarative-top-level-heads+
  '("load!"
    "begin-syntax"
    "use-module"
    "use-live-case"
    "declare-gxtest-memory-exception"
    "define-entry-point"
    "define-multicall-main"
    "modularity-policy"
    "poo-flow-module-object"
    "poo-flow-module-field-contract"))

;; (List Callee)
(def +agent-declarative-list-member-callees+
  '("poo-flow-module-object"
    "poo-flow-module-field-contract"))

;;; Boundary:
;;; - Explicit entrypoints are language-level contracts, not path hacks.
;;; - Exported main plus a top-level main/apply/exit form is treated as the
;;;   script boundary.
;;; - Arbitrary top-level calls still fail R005.
;; : (-> SourceFile CallFact Boolean )
(def (explicit-main-entrypoint-call? file call)
  (and (member "main" (source-file-exports file))
       (ormap (lambda (form)
                (and (member (top-form-head form)
                             +explicit-main-entrypoint-heads+)
                     (call-within-top-form-range? call form)))
              (source-file-forms file))))

;;; Boundary:
;;; - Test harness entrypoints are explicit execution boundaries.
;;; - Keep this shape-based: only test owners with a run-tests! top form are
;;;   exempt, not every arbitrary call in t/.
;; : (-> SourceFile CallFact Boolean )
(def (explicit-test-entrypoint-call? file call)
  (and (test-owner-path? (source-file-path file))
       (ormap (lambda (form)
                (and (member (top-form-head form)
                             +explicit-test-entrypoint-heads+)
                     (call-within-top-form-range? call form)))
              (source-file-forms file))))

;; : (-> Path Boolean )
(def (test-owner-path? path)
  (or (string-prefix? "t/" path)
      (string-contains path "/t/")
      (string-suffix? "-test.ss" path)))

;; : (-> SourceFile CallFact Boolean )
(def (declarative-top-level-call? file call)
  (or (poo-declarative-call? file call)
      (agent-declarative-call? file call)
      (data-alist-declarative-call? file call)
      (ffi-declarative-call? file call)))

;;; Boundary:
;;; - A file containing only one alist datum is declarative metadata, not a
;;;   runtime entrypoint.
;;; - Keep the exemption shape-owned: no definitions/imports/exports, one
;;;   pair-looking top form, and the call fact must live inside that form.
;; : (-> SourceFile CallFact Boolean )
(def (data-alist-declarative-call? file call)
  (and (data-alist-source-file? file)
       (ormap (lambda (form)
                (and (data-alist-top-form? form)
                     (call-within-top-form-range? call form)))
              (source-file-forms file))))

;; : (-> SourceFile Boolean )
(def (data-alist-source-file? file)
  (and (null? (source-file-definitions file))
       (null? (source-file-imports file))
       (null? (source-file-exports file))
       (let (forms (source-file-forms file))
         (and (pair? forms)
              (null? (cdr forms))
              (data-alist-top-form? (car forms))))))

;; : (-> TopForm Boolean )
(def (data-alist-top-form? form)
  (let (head (top-form-head form))
    (and (string-prefix? "(" head)
         (string-contains head " . "))))

;;; Boundary: FFI top forms run at expansion time, so nested call facts are declarations.
;; : (-> SourceFile CallFact Boolean )
(def (ffi-declarative-call? file call)
  (ormap (lambda (form)
           (and (declarative-top-form? form)
                (call-within-top-form-range? call form)))
         (source-file-forms file)))
;; : (-> CallFact TopForm Boolean )
(def (call-within-top-form-range? call form)
  (and (<= (top-form-start form) (call-fact-start call))
       (>= (top-form-end form) (call-fact-end call))))
;;; Boundary:
;;; - Agent configuration and module-object fragments are declarative data.
;;; - The list exemption is narrow: it only applies when the list top form owns
;;;   an embedded known declarative object constructor.
;; : (-> SourceFile CallFact Boolean )
(def (agent-declarative-call? file call)
  (ormap (lambda (form)
           (and (agent-declarative-top-form? file form)
                (call-within-top-form-range? call form)))
         (source-file-forms file)))

;; : (-> SourceFile TopForm Boolean )
(def (agent-declarative-top-form? file form)
  (or (member (top-form-head form) +agent-declarative-top-level-heads+)
      (and (equal? (top-form-head form) "list")
           (agent-declarative-list-top-form? file form))))

;;; List top forms are executable-looking syntax, so this exemption requires a
;;; nested parser-owned call to a known declarative constructor inside the same
;;; top-form range before suppressing the top-level executable warning.
;; : (-> SourceFile TopForm Boolean )
(def (agent-declarative-list-top-form? file form)
  (ormap (lambda (candidate)
           (and (member (call-fact-callee candidate)
                        +agent-declarative-list-member-callees+)
                (call-within-top-form-range? candidate form)))
         (source-file-calls file)))
;;; Boundary:
;;; - poo-declarative-call? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile CallFact Boolean )
(def (poo-declarative-call? file call)
  (and (poo-source-file? file)
       (ormap (lambda (form)
                (and (member (top-form-head form) +poo-declarative-heads+)
                     (call-within-top-form-range? call form)))
              (source-file-forms file))))
;; : (-> SourceFile CallFact TypeFinding )
(def (top-level-executable-finding file call)
  (make-type-finding
   (policy-rule-id +agent-top-level-executable-rule+)
   (policy-rule-severity +agent-top-level-executable-rule+)
   (source-file-path file)
   (string-append "top-level executable call " (call-fact-callee call)
                  " should move behind a named definition or explicit entrypoint")
   (call-fact-selector call)
   (hash (callee (call-fact-callee call))
         (selector (call-fact-selector call)))))

;;; Boundary:
;;; - functional-idiom-advice-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List TypeFinding) )
(def (functional-idiom-advice-findings index)
  (filter-map (cut functional-idiom-advice-finding index <>)
              (project-index-files index)))
;;; Boundary:
;;; - functional-idiom-advice-finding coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> ProjectIndex SourceFile TypeFinding )
(def (functional-idiom-advice-finding index file)
  (and (source-file-path file)
       (index-source-runtime-file-path? index (source-file-path file))
       (let (fact (manual-loop-control-flow file))
         (and fact
              (make-type-finding
               (policy-rule-id +agent-functional-idiom-advice-rule+)
              (policy-rule-severity +agent-functional-idiom-advice-rule+)
              (source-file-path file)
               "basic named-let/rest-accumulator loop looks like a redundant pure transform; rewrite toward Gerbil/Gambit idioms such as fold/filter-map, lambda-match/match, cut/curry/compose, case-lambda, or values/call-with-values unless parser facts show IO, stateful control flow, C3-style fixpoint selection, or generator/continuation driver"
               (control-flow-fact-selector fact)
               (hash (name (control-flow-fact-name fact))
                     (kind (control-flow-fact-kind fact))
                     (selector (control-flow-fact-selector fact))
                     (caller (or (control-flow-fact-caller fact) ""))
                     (namedLetPolicy "warn-on-redundant-pure-transform-only")
                     (detectionSignals
                      (manual-loop-detection-signals file fact))
                     (advice "replace basic Scheme scaffolding with parser-owned Gerbil/Gambit idioms for pure transforms")
                     (basicSyntaxSmells +functional-basic-syntax-smells+)
                     (nativeRepairContract
                      +functional-native-repair-contract+)
                     (designFeaturePriority
                      +functional-design-feature-priority+)
                     (sequenceIdioms +functional-sequence-idioms+)
                     (predicateIdioms +functional-predicate-idioms+)
                     (compositionIdioms +functional-composition-idioms+)
                     (nativeLambdaIdioms +functional-native-lambda-idioms+)
                     (typeclassIdioms +functional-typeclass-idioms+)
                     (builderIdioms '("with-list-builder"))
                     (styleGuide "typed-combinator-style")
                     (styleCommand "asp gerbil-scheme guide --code --topic typed-combinator-style --intent style")
                     (detectedControlContexts
                      (functional-preservation-control-contexts file))
                     (callerControlContexts
                      (caller-functional-preservation-control-contexts
                       file
                       (control-flow-fact-caller fact)))
                     (keepNamedLetWhen "IO/stateful control flow, C3-style fixpoint selection, or generator/continuation driver")
                     (preserveNamedLetWhen
                      '("local recursion without accumulator boilerplate"
                        "reader or port EOF loops"
                        "stateful control flow"
                        "C3-style fixpoint selection"
                        "generator, coroutine, actor, or continuation driver"))
                     (learnedFrom "gerbil:// and gerbil-utils/base.ss expose λ/lambda-match/compose/!>/curry/rcurry/fun for compact higher-order helpers; Gambit values/call-with-values and dynamic-wind keep tuple/control protocols explicit; gerbil-poo/fun.ss models Category./Functor./ParametricFunctor. algebra; table.ss methods.table shows protocol slots plus derived table/list/sexp/json/marshal capability; named let remains valid for C3 selection, reader IO, and coroutine control")))))))
;;; Boundary:
;;; Manual-loop advice is caller scoped and multi-signal.
;;; Named let remains valid Gerbil.
;;; Only redundant pure-transform shapes warn.
;; : (-> SourceFile (List ControlFlowFact) )
(def (manual-loop-control-flow file)
  (find (cut redundant-manual-loop-control-flow? file <>)
        (source-file-control-flow-forms file)))
;;; Signal gate: R009 should only fire when every native-parser witness points
;;; at redundant pure-transform boilerplate, not at named-let usage itself.
;; : (-> SourceFile ControlFlowFact Boolean )
(def (redundant-manual-loop-control-flow? file fact)
  (and (manual-loop-pure-transform-driver? file fact)
       (let (signals (manual-loop-detection-signals file fact))
         (not (find (lambda (signal)
                      (not (member signal signals)))
                    +redundant-manual-loop-required-signals+)))))

;;; Driver-kind gate:
;;; - Control-flow facts identify named-let syntax.
;;; - Loop-driver facts carry parser-owned preservation classification.
;;; - R009 must not bypass that classification or stateful loops become false positives.
;; : (-> SourceFile ControlFlowFact Boolean)
(def (manual-loop-pure-transform-driver? file fact)
  (ormap (cut manual-loop-matching-pure-driver? fact <>)
         (source-file-loop-driver-facts file)))

;; : (-> ControlFlowFact LoopDriverFact Boolean)
(def (manual-loop-matching-pure-driver? fact driver)
  (and (manual-loop-same-source-range? fact driver)
       (manual-loop-same-caller? fact driver)
       (pure-transform-loop-driver? driver)
       (manual-loop-drift-driver? driver)))
;; : (-> ControlFlowFact LoopDriverFact Boolean)
(def (manual-loop-same-source-range? fact driver)
  (and (equal? (control-flow-fact-start fact)
               (loop-driver-fact-start driver))
       (equal? (control-flow-fact-end fact)
               (loop-driver-fact-end driver))))
;; : (-> ControlFlowFact LoopDriverFact Boolean)
(def (manual-loop-same-caller? fact driver)
  (equal? (or (control-flow-fact-caller fact) "")
          (or (loop-driver-fact-caller driver) "")))
;; : (-> LoopDriverFact Boolean)
(def (pure-transform-loop-driver? driver)
  (equal? (loop-driver-fact-driver-kind driver)
          "pure-transform-candidate"))
;; : (-> LoopDriverFact Boolean)
(def (manual-loop-drift-driver? driver)
  (member "manual-loop-drift"
          (loop-driver-fact-quality-facets driver)))
;;; Evidence packet: keep positive and negative witnesses visible so repair
;;; agents can explain why this loop is redundant before rewriting it.
;; : (-> SourceFile ControlFlowFact (List String) )
(def (manual-loop-detection-signals file fact)
  (let (caller (control-flow-fact-caller fact))
    (filter identity
            [(and (equal? (control-flow-fact-kind fact) "named-let")
                  "named-let")
             (and (equal? (control-flow-fact-role fact) "manual-loop")
                  "manual-loop-role")
             (and (manual-loop-multi-binding-state? fact)
                  "multi-binding-loop-state")
             (and (not (caller-has-functional-idiom? file caller))
                  "no-functional-idiom-witness")
             (and (not (caller-has-reader-boundary? file caller))
                  "no-reader-boundary")
             (and (not (caller-has-preservation-control-context? file caller))
                  "no-control-preservation-context")])))
;;; Shape signal: two or more loop bindings usually means threaded rest/acc
;;; state, so it is only advisory when the other absence witnesses also agree.
;; : (-> ControlFlowFact Boolean )
(def (manual-loop-multi-binding-state? fact)
  (>= (control-flow-fact-binding-count fact) 2))
;;; Boundary:
;;; - caller-has-functional-idiom? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile Caller Boolean )
(def (caller-has-functional-idiom? file caller)
  (ormap (lambda (fact)
           (and (equal? (or (higher-order-fact-caller fact) "") (or caller ""))
                (member (higher-order-fact-role fact) +functional-idiom-roles+)))
         (source-file-higher-order-forms file)))
;;; Boundary:
;;; Reader callees are native parser witnesses for port state and EOF handling.
;;; The ormap/lambda pair keeps preservation caller-scoped, so one reader loop
;;; does not suppress unrelated manual-loop repair in the same file.
;; : (-> SourceFile Caller Boolean )
(def (caller-has-reader-boundary? file caller)
  (ormap (lambda (fact)
           (and (equal? (or (call-fact-caller fact) "") (or caller ""))
                (reader-boundary-callee? (call-fact-callee fact))))
         (source-file-calls file)))

;; : (-> Callee Boolean )
(def (reader-boundary-callee? callee)
  (and callee
       (or (member callee +functional-preservation-reader-callees+)
           (string-prefix? "read-" callee))))
;;; Suppression gate: preservation evidence must live in the same caller as the
;;; named-let; an unrelated continuation in the file must not hide a bad loop.
;; : (-> SourceFile Caller Boolean )
(def (caller-has-preservation-control-context? file caller)
  (pair? (caller-functional-preservation-control-contexts file caller)))
;;; Boundary:
;;; Preservation contexts are caller scoped for suppression.
;;; File-level contexts still surface in finding details as repair evidence.
;; : (-> SourceFile Caller FunctionalPreservationControlContexts )
(def (caller-functional-preservation-control-contexts file caller)
  (map control-flow-fact-role
       (filter (lambda (fact)
                 (and (equal? (or (control-flow-fact-caller fact) "")
                              (or caller ""))
                      (member (control-flow-fact-role fact)
                              +functional-preservation-control-roles+)))
               (source-file-control-flow-forms file))))
;;; Boundary:
;;; - functional-preservation-control-contexts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile FunctionalPreservationControlContexts )
(def (functional-preservation-control-contexts file)
  (map control-flow-fact-role
       (filter (lambda (fact)
                 (member (control-flow-fact-role fact)
                         +functional-preservation-control-roles+))
               (source-file-control-flow-forms file))))
