;;; -*- Gerbil -*-
;;; Agent-facing style policy checks.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-style-steering
        :asp-gerbil-scheme/src/policy/agent-style-details
        :asp-gerbil-scheme/src/policy/agent-style-quality
        :asp-gerbil-scheme/src/policy/agent-style-gerbil-signals
        :asp-gerbil-scheme/src/policy/agent-style-destructuring-signals
        :asp-gerbil-scheme/src/policy/agent-style-docs
        :asp-gerbil-scheme/src/policy/agent-style-message
        :asp-gerbil-scheme/src/policy/agent-style-performance-signals
        :asp-gerbil-scheme/src/policy/gerbil-utils-source
        :asp-gerbil-scheme/src/policy/agent-support
        :asp-gerbil-scheme/src/policy/agent-style-shape
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-empty?)
        (only-in :std/sugar cut filter filter-map foldl hash hash-get ormap)
        :asp-gerbil-scheme/src/types/findings)

(export typed-combinator-style-findings
        typed-combinator-style-finding
        controlled-branch-shape-findings
        controlled-branch-shape-finding
        predicate-family-combinator-findings
        predicate-family-combinator-finding)
;; (List String)
(def +typed-combinator-style-higher-order-roles+
  '("partial-application" "function-curry" "function-composition"
    "pipeline-composition" "higher-order-combinator"
    "anonymous-function" "named-lambda-abstraction"
    "eta-wrapper-lambda"
    "lambda-match-opportunity" "pattern-matching-function"
    "multi-arity-function" "autocurry-semantics"
    "sequence-map" "sequence-filter" "sequence-filter-map"
    "sequence-append-map" "sequence-predicate" "sequence-search"
    "sequence-fold" "loop-fold" "list-builder"))
;; (List String)
(def +typed-combinator-style-call-heads+
  '("!>" "!!>" "left-to-right" "rcompose" "compose" "compose1"
    "fun" "lambda-match" "λ" "λ-match"
    "match" "match*" "with" "with*" "ast-case"
    "curry" "rcurry" "cut" "cute" "chain" "if-let" "when-let"
    "map" "filter" "filter-map"
    "append-map" "fold" "foldl" "foldr" "fold-left" "fold-right"
    "andmap" "ormap" "every" "any" "find" "list-index"
    "with-list-builder"
    "generating-map" "generating-fold" "generating-filter"
    "generating-partition" "generating-merge" "generating<-list"
    "generating<-cothread"))
;; (List String)
(def +poo-declarative-definition-kinds+
  '(".def" "define-type" "defclass" ".defclass" "defmethod" ".defmethod"
    "defgeneric" ".defgeneric" "defprotocol" ".defprotocol"))

;; : Nat
(def +typed-combinator-style-file-evidence-floor+ 5)

;;; Entry boundary: emit at most one typed-combinator finding per owner so repair stays file-scoped.
;; : (-> ProjectIndex (List TypeFinding) )
(def (typed-combinator-style-findings index)
  (filter-map (cut typed-combinator-style-finding index <>)
              (project-index-files index)))
;;; Policy gate: combine typed contracts, parser-owned implementation evidence, and coverage before repair.
;; : (-> ProjectIndex SourceFile TypeFinding )
(def (typed-combinator-style-finding index file)
  (and (source-file-path file)
       (typed-combinator-style-source-file? index file)
       (pair? (source-file-definitions file))
       (let* ((definition-count (length (source-file-definitions file)))
              (function-definitions
               (typed-combinator-style-function-definitions file))
              (function-definition-count
               (length function-definitions))
              (typed-comment-summary
               (file-typed-combinator-style-summary index file))
              (typed-comment-line-count (car typed-comment-summary))
              (valid-typed-comment-count (cadr typed-comment-summary))
              (invalid-typed-comment-count (caddr typed-comment-summary))
              (missing-count
               (typed-combinator-style-missing-count function-definition-count
                                                     valid-typed-comment-count))
              (missing-contract-coverage?
               (typed-combinator-style-missing-contract-triggered?
                function-definition-count
                missing-count))
              (implementation-evidence
               (typed-combinator-style-implementation-evidence file))
              (implementation-evidence-count
               (length implementation-evidence))
              (quality-facets
               (typed-combinator-style-quality-facets file))
              (repair-evidence
               (typed-combinator-style-repair-evidence file))
              (typed-doc-missing-targets
               (typed-combinator-style-missing-doc-targets file))
              (typed-doc-missing?
               (pair? typed-doc-missing-targets))
              (typed-forall-missing-targets
               (typed-combinator-style-missing-forall-targets file))
              (typed-forall-missing?
               (pair? typed-forall-missing-targets))
              (quality-repair-triggered?
               (and (typed-combinator-style-quality-repair-source-file? file)
                    (typed-combinator-style-quality-repair-triggered?
                     file quality-facets)))
              (module-engineering-comment?
               (source-file-has-engineering-module-comment? file))
              (implementation-evidence-callers
               (typed-combinator-style-evidence-callers implementation-evidence))
              (covered-definition-names
               (typed-combinator-style-covered-definition-names
                file implementation-evidence-callers))
              (covered-definition-count
               (length covered-definition-names))
              (minimum-covered-definition-count
               (typed-combinator-style-minimum-covered-definition-count
                function-definition-count))
              (uncovered-definition-names
               (typed-combinator-style-uncovered-definition-names
                file implementation-evidence-callers))
              (missing-implementation-evidence?
               (typed-combinator-style-missing-implementation-evidence?
                function-definition-count
                valid-typed-comment-count
                invalid-typed-comment-count
                missing-count
                implementation-evidence-count
                module-engineering-comment?))
              (implementation-coverage-insufficient?
               (typed-combinator-style-implementation-coverage-insufficient?
                function-definition-count
                covered-definition-count
                minimum-covered-definition-count
                implementation-evidence-count
                valid-typed-comment-count
                invalid-typed-comment-count
                missing-count
                module-engineering-comment?)))
         (and (ormap (lambda (triggered?) triggered?)
                     [missing-contract-coverage?
                      (> invalid-typed-comment-count 0)
                      missing-implementation-evidence?
                      implementation-coverage-insufficient?
                      typed-doc-missing?
                      typed-forall-missing?
                      quality-repair-triggered?])
              (make-type-finding
               (policy-rule-id +agent-typed-combinator-style-rule+)
               (policy-rule-severity +agent-typed-combinator-style-rule+)
               (source-file-path file)
               (typed-combinator-style-message definition-count
                                               valid-typed-comment-count
                                               invalid-typed-comment-count
                                               missing-implementation-evidence?
                                               implementation-coverage-insufficient?
                                               typed-doc-missing?
                                               typed-forall-missing?
                                               quality-repair-triggered?
                                               (length typed-doc-missing-targets)
                                               (length typed-forall-missing-targets)
                                               covered-definition-count
                                               function-definition-count
                                               minimum-covered-definition-count)
               (source-file-path file)
               (typed-combinator-style-details
                file
                definition-count
                typed-comment-line-count
                valid-typed-comment-count
                invalid-typed-comment-count
                missing-count
                implementation-evidence
                implementation-evidence-count
                missing-implementation-evidence?
                implementation-evidence-callers
                covered-definition-names
                covered-definition-count
                function-definition-count
                minimum-covered-definition-count
                uncovered-definition-names
                implementation-coverage-insufficient?
                typed-doc-missing-targets
                typed-forall-missing-targets
                quality-facets
                repair-evidence
                typed-doc-missing?
                typed-forall-missing?
                quality-repair-triggered?))))))

;;; Scope boundary:
;;; - Runtime source and real tests must keep typed-combinator contracts.
;;; - t/scenarios contains fixture projects that intentionally encode bad shapes.
;; : (-> ProjectIndex SourceFile Boolean)
;;; Source-class scope guard:
;;; - Parser source classes own fixture/scenario/generated classification.
;;; - Policy only decides which parser-owned classes are actionable.
;; : (-> ProjectIndex SourceFile Boolean )
(def (typed-combinator-style-source-file? index file)
  (let (path (source-file-path file))
    (and path
         (typed-combinator-style-actionable-source-class? (source-path-class path))
         (index-source-runtime-file-path? index path))))

;;; Quality-trigger scope excludes parser fixtures: fixture owners intentionally
;;; encode bad and unusual syntax that policy tests assert elsewhere.
;; : (-> SourceFile Boolean )
(def (typed-combinator-style-quality-repair-source-file? file)
  (let (path (source-file-path file))
    (and path
         (typed-combinator-style-actionable-source-class? (source-path-class path)))))

;;; Actionable source classes:
;;; - Generated data, fixtures, snapshots, and policy scenario projects are
;;;   evidence fixtures, not owners the agent should repair in place.
;;; - New parser-owned classes can be excluded here without path matching.
;; : (-> SourceClass Boolean )
(def (typed-combinator-style-actionable-source-class? source-class)
  (not (member source-class
               ["policy-scenario"
                "fixture"
                "snapshot-output"
                "generated"])))

;;; Evidence absence boundary:
;;; - Fire only after typed contracts are complete and valid.
;;; - A module-level engineering comment can intentionally waive expression
;;;   evidence when the owner explains the boundary.
;; : (-> Nat Nat Nat Nat Nat Boolean )
(def (typed-combinator-style-missing-implementation-evidence? definition-count valid-typed-comment-count invalid-typed-comment-count missing-count implementation-evidence-count module-engineering-comment?)
  (and (> definition-count 1)
       (> valid-typed-comment-count 0)
       (= invalid-typed-comment-count 0)
       (= missing-count 0)
       (= implementation-evidence-count 0)
       (not module-engineering-comment?)))

;;; Boundary: module-level engineering comments count only when the native
;;; parser attached concrete comment lines to the module owner.
;; : (-> SourceFile Boolean )
(def (source-file-has-engineering-module-comment? file)
  (ormap
   (lambda (fact)
     (and (equal? (comment-quality-fact-target-kind fact) "module")
          (pair? (comment-quality-fact-comment-lines fact))))
   (source-file-comment-quality-facts file)))

;;; Boundary:
;;; - Full-form documentation is required when parser facts show semantic risk.
;;; - Exported status alone is not enough; it must combine with role or facet evidence.
;;; - Ordinary public constructors and accessors may keep the short `;; :` form.
;;; Coverage threshold boundary:
;;; - Valid typed contracts are necessary before coverage warnings fire.
;;; - Module engineering comments may waive coverage-ratio pressure for
;;;   declarative or boundary modules, but never waive missing contracts,
;;;   invalid contracts, missing evidence, or parser-owned quality repairs.
;; : (-> Nat Nat Nat Nat Nat Nat Nat Boolean )
(def (typed-combinator-style-implementation-coverage-insufficient? function-definition-count covered-definition-count minimum-covered-definition-count implementation-evidence-count valid-typed-comment-count invalid-typed-comment-count missing-count module-engineering-comment?)
  (and (typed-combinator-style-coverage-gate-open?
        function-definition-count
        valid-typed-comment-count
        invalid-typed-comment-count
        missing-count
        module-engineering-comment?)
       (typed-combinator-style-below-coverage-floor?
        covered-definition-count
        minimum-covered-definition-count
        implementation-evidence-count)))
;; : (-> Nat Nat Nat Nat Boolean Boolean )
(def (typed-combinator-style-coverage-gate-open? function-definition-count valid-typed-comment-count invalid-typed-comment-count missing-count module-engineering-comment?)
  (and (> function-definition-count 2)
       (> valid-typed-comment-count 0)
       (= invalid-typed-comment-count 0)
       (= missing-count 0)
       (not module-engineering-comment?)))
;; : (-> Nat Nat Nat Boolean )
(def (typed-combinator-style-below-coverage-floor? covered-definition-count minimum-covered-definition-count implementation-evidence-count)
  (and (< covered-definition-count minimum-covered-definition-count)
       (< implementation-evidence-count
          (typed-combinator-style-minimum-file-evidence-count
           minimum-covered-definition-count))))

;;; Absolute evidence floor:
;;; - Large orchestration/parser owners should not fail solely because every
;;;   tiny wrapper lacks its own combinator witness when the file already has
;;;   several parser-owned Gerbil-native idiom witnesses.
;;; - Sparse owners still fail, preserving the policy's repair signal.
;; : (-> Nat Nat)
(def (typed-combinator-style-minimum-file-evidence-count minimum-covered-definition-count)
  (min minimum-covered-definition-count
       +typed-combinator-style-file-evidence-floor+))

;;; Minimum coverage boundary:
;;; - Require roughly two thirds of arity-bearing helpers to have Gerbil-native
;;;   expression evidence.
;;; - Zero-definition owners stay valid and do not force artificial witnesses.
;; : (-> Nat Nat )
(def (typed-combinator-style-minimum-covered-definition-count function-definition-count)
  (if (zero? function-definition-count)
    0
    (quotient (+ (* function-definition-count 2) 2) 3)))
;;; Coverage denominator: constants are excluded so only arity-bearing helpers need expression evidence.
;; : (-> SourceFile (List Definition) )
(def (typed-combinator-style-function-definitions file)
  (filter (lambda (defn)
            (and (> (definition-arity defn) 0)
                 (not (poo-declarative-definition? defn))))
          (source-file-definitions file)))

;;; Declarative POO boundary:
;;; - POO type and method declarations are structural forms, not helper bodies.
;;; - Excluding them keeps coverage focused on arity-bearing behavior.
;; : (-> Definition Boolean )
(def (poo-declarative-definition? defn)
  (member (definition-kind defn) +poo-declarative-definition-kinds+))
;;; Coverage numerator: parser evidence is attributed by caller before compacting duplicate facts.
;; : (-> (List Evidence) (List String) )
(def (typed-combinator-style-evidence-callers implementation-evidence)
  (unique
   (filter (lambda (value)
             (and (string? value)
                  (not (string-empty? value))))
           (map (lambda (evidence) (hash-get evidence 'caller))
                implementation-evidence))))
;;; Coverage report: expose covered helpers so agents can see which functions already match the style.
;; : (-> SourceFile (List String) (List String) )
(def (typed-combinator-style-covered-definition-names file implementation-evidence-callers)
  (filter (cut member <> implementation-evidence-callers)
          (map definition-name
               (typed-combinator-style-function-definitions file))))
;;; Repair target list: uncovered helpers tell the agent where to add expression-level evidence first.
;; : (-> SourceFile (List String) (List String) )
(def (typed-combinator-style-uncovered-definition-names file implementation-evidence-callers)
  (filter (lambda (name) (not (member name implementation-evidence-callers)))
          (map definition-name
               (typed-combinator-style-function-definitions file))))
;;; Evidence boundary: implementation coverage merges higher-order facts and
;;; call-shape facts, leaving threshold decisions to the policy details layer.
;; : (-> SourceFile (List Evidence) )
(def (typed-combinator-style-implementation-evidence file)
  (append
   (map higher-order-style-evidence
        (filter typed-combinator-style-higher-order-fact?
                (source-file-higher-order-forms file)))
   (map call-style-evidence
        (filter typed-combinator-style-call-fact?
                (source-file-calls file)))))

;;; Boundary:
;;; - typed-combinator-style-higher-order-fact? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> HigherOrderFact Boolean )
(def (typed-combinator-style-higher-order-fact? fact)
  (ormap (cut equal? (higher-order-fact-role fact) <>)
         +typed-combinator-style-higher-order-roles+))
;;; Boundary:
;;; - typed-combinator-style-call-fact? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> CallFact Boolean )
(def (typed-combinator-style-call-fact? fact)
  (ormap (cut equal? (call-fact-callee fact) <>)
         +typed-combinator-style-call-heads+))

;; : (-> HigherOrderFact Evidence )
(def (higher-order-style-evidence fact)
  (hash (kind "higher-order")
        (name (higher-order-fact-name fact))
        (role (higher-order-fact-role fact))
        (caller (or (higher-order-fact-caller fact) ""))
        (selector (higher-order-fact-selector fact))))
;; : (-> CallFact Evidence )
(def (call-style-evidence fact)
  (hash (kind "call")
        (name (call-fact-callee fact))
        (caller (or (call-fact-caller fact) ""))
        (selector (call-fact-selector fact))))
