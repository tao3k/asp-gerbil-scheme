;;; -*- Gerbil -*-
;;; Agent-facing self-audit for repeated inline alist lookup.
;;; Repeated assq/cdr lookups are a common generated-code smell when keyword
;;; parameters, a record, profile accessor, or source-backed fact would make the
;;; shape explicit.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/sugar filter hash)
        :asp-gerbil-scheme/src/types/findings)

(export alist-access-findings
        alist-access-finding)

;; Integer
(def +alist-access-min-inline-lookups+ 2)

;;; Project traversal boundary:
;;; - Parser call facts own the syntax evidence.
;;; - The policy only groups repeated inline lookup shape per source owner.
;; : (-> ProjectIndex (List TypeFinding) )
(def (alist-access-findings index)
  (filter-map alist-access-finding
              (project-index-files index)))

;;; Threshold boundary:
;;; - One inline lookup can be a local bridge.
;;; - Repetition means the owner needs keyword/default parameters, a record,
;;;   profile accessor, or helper.
;; : (-> SourceFile MaybeTypeFinding )
(def (alist-access-finding file)
  (let (lookups (alist-inline-access-facts file))
    (and (>= (alist-inline-access-count lookups)
             +alist-access-min-inline-lookups+)
         (make-type-finding
          (policy-rule-id +agent-alist-access-rule+)
          (policy-rule-severity +agent-alist-access-rule+)
          (source-file-path file)
          "repeated inline assq/cdr alist lookups hide a data model; use Gerbil #!key/#!optional parameters, a record/defstruct, source-backed profile accessors, or one named lookup helper"
          (field-access-pattern-fact-selector (car lookups))
          (alist-access-details lookups)))))

;;; Lookup collection:
;;; - Parser-owned field access facts carry native AST evidence.
;;; - Policy does not inspect rendered call arguments or source strings.
;; : (-> SourceFile (List FieldAccessPatternFact) )
(def (alist-inline-access-facts file)
  (filter inline-alist-access-fact?
          (source-file-field-access-pattern-facts file)))

;;; Fact predicate:
;;; - The parser role is emitted only for native `(cdr (assq ...))` shapes.
;;; - The facet keeps this policy aligned with function-quality/search reports.
;; : (-> FieldAccessPatternFact Boolean )
(def (inline-alist-access-fact? fact)
  (and (equal? (field-access-pattern-fact-role fact)
               "inline-alist-lookup")
       (member "inline-alist-lookup-drift"
               (field-access-pattern-fact-quality-facets fact))))

;;; Access count sums parser-owned grouped facts so repeated lookups across
;;; several alist keys still trigger one owner-level repair.
;; : (-> (List FieldAccessPatternFact) Integer )
(def (alist-inline-access-count lookups)
  (apply + (map field-access-pattern-fact-access-count lookups)))

;;; Details boundary:
;;; - Finding details stay JSON-shaped at the report edge.
;;; - Selectors expose the repeated call sites for direct repair.
;; : (-> (List CallFact) PolicyDetails )
(def (alist-access-details lookups)
  (hash (kind "repeated-inline-alist-lookup")
        (lookupCount (alist-inline-access-count lookups))
        (selectors (map field-access-pattern-fact-selector lookups))
        (fieldKeys (map field-access-pattern-fact-field-key lookups))
        (callers (apply append
                        (map field-access-pattern-fact-callers lookups)))
        (callees ["assq" "cdr"])
        (repair "replace repeated inline (cdr (assq ...)) with Gerbil #!key/#!optional parameters for function option APIs, a record/defstruct, typed profile accessor, or one named alist lookup helper")
        (repairStrategies ["gerbil-keyword-optional-parameters"
                           "record-or-defstruct"
                           "typed-profile-accessor"
                           "named-alist-lookup-helper"])
        (learnedStyleSources ["gerbil://gambit/gsc/tests/69-params/optional.scm"
                              "gerbil://gambit/gsc/tests/69-params/optionalkeyrest.scm"
                              "gerbil://std/markup/sxml/oleg/define-opt.scm"])))
