;;; -*- Gerbil -*-
;;; Agent-facing self-audit for policy source scope hardcoding.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/srfi/1 find)
        (only-in :std/srfi/13 string-contains string-prefix?)
        (only-in :std/sugar cut filter filter-map hash ormap)
        :asp-gerbil-scheme/src/types/findings)

(export policy-source-scope-findings
        policy-source-scope-finding)

;;; Literal markers describe misplaced source-class knowledge.
;;; Keep the list narrow so parser/source-class remains the real owner.
;; (List PathLiteral)
(def +policy-source-scope-literal-markers+
  '("t/scenarios/"
    "/scenarios/"
    "t/fixtures/"
    "/fixtures/"
    "t/snapshots/"
    "/snapshots/"))

;;; Project traversal boundary:
;;; - Policy owners are selected before call facts are inspected.
;;; - Parser call facts expose string literals used by policy code.
;;; - Parser source-class definitions own fixture and scenario vocabulary.
;;; - This rule reports only misplaced vocabulary in policy owners.
;; : (-> ProjectIndex (List TypeFinding) )
(def (policy-source-scope-findings index)
  (filter-map policy-source-scope-file-finding
              (filter policy-source-file?
                      (project-index-files index))))

;;; File-level predicate search:
;;; - find stops at the first offending parser call.
;;; - Nested call facts can repeat the same literal through parent forms.
;;; - One finding per policy owner is enough to direct the repair.
;; : (-> SourceFile MaybeTypeFinding )
(def (policy-source-scope-file-finding file)
  (let (call (find policy-source-scope-call-marker
                   (source-file-calls file)))
    (and call
         (policy-source-scope-finding
          file
          call
          (policy-source-scope-call-marker call)))))

;;; Finding boundary:
;;; - The selector remains the parser call fact that exposed the literal.
;;; - The message directs repair to parser/source-class, not local suppression.
;; : (-> SourceFile CallFact PathLiteral TypeFinding )
(def (policy-source-scope-finding file call marker)
  (make-type-finding
   (policy-rule-id +agent-policy-source-scope-rule+)
   (policy-rule-severity +agent-policy-source-scope-rule+)
   (source-file-path file)
   "policy source scope is hardcoding fixture/scenario/snapshot paths; move classification to parser source-path-class and consume source classes in policy"
   (call-fact-selector call)
   (policy-source-scope-details call marker)))

;;; Details boundary:
;;; - Finding details cross the provider JSON boundary, so this is plain data.
;;; - parserOwner points agents at the source-class owner before editing policy.
;; : (-> CallFact PathLiteral PolicyDetails )
(def (policy-source-scope-details call marker)
  (hash (kind "policy-source-scope")
        (callee (call-fact-callee call))
        (literal marker)
        (parserOwner "src/parser/source-class.ss")
        (repair "add or reuse a source-path-class case, then branch on the parser-owned class")))

;;; Scope boundary: this self-audit targets policy owners only.
;;; Parser/source-class is allowed to contain path literals by design.
;; : (-> SourceFile Boolean )
(def (policy-source-file? file)
  (let (path (source-file-path file))
    (and path
         (string-prefix? "src/policy/" path))))

;;; Marker lookup composes marker predicates across parser-owned call arguments.
;;; The returned literal becomes the evidence value in the TypeFinding details.
;; : (-> CallFact MaybePathLiteral )
(def (policy-source-scope-call-marker call)
  (let (arguments (call-fact-arguments call))
    (ormap (lambda (marker)
             (and (ormap (cut policy-source-scope-argument-contains? <> marker)
                         arguments)
                  marker))
           +policy-source-scope-literal-markers+)))

;;; Argument predicate boundary:
;;; - Parser call arguments are already compact strings at this layer.
;;; - Literal containment is bounded by the marker vocabulary above.
;; : (-> CallArgument PathLiteral Boolean )
(def (policy-source-scope-argument-contains? argument marker)
  (and (string? argument)
       (string-contains argument marker)))
