;;; -*- Gerbil -*-
;;; Parser-owned quality-shape facts derived from native call and control-flow facts.
;;; Boundary: this module emits evidence packets only. Policy thresholds,
;;; repair wording, and agent-facing severity stay outside the parser layer.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/quality-shape-loop-driver
        (only-in :asp-gerbil-scheme/src/parser/support datum-list-items)
        (only-in :asp-gerbil-scheme/src/parser/syntax form-caller-name)
        (only-in :std/misc/list unique)
        (only-in :std/srfi/1 find)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :std/sugar cut filter filter-map foldl ormap))

(export predicate-family-facts-from-source
        field-access-pattern-facts-from-source
        projection-burst-facts-from-source
        boolean-condition-facts-from-source
        loop-driver-facts-from-source)

;; (List String)
(def +field-access-callees+ '("field-string" "field-list-string" "hash-get"))
;; (List String)
(def +projection-emitter-callees+ '("display" "displayln" "write" "fprintf" "printf"))
;; Integer
(def +projection-burst-native-min-access-count+ 3)
;; (List String)
(def +condition-callees+ '("member" "equal?" "not" ">" "<" ">=" "<=" "string=?" "string-contains" "string-prefix?" "string-suffix?"))
;; (List String)

;;; Predicate family facts identify repeated one-argument predicate helpers over the same subject.
;;; They give policy enough native evidence to request a helper/combinator rewrite without reading raw source.
;; : (-> Relpath Definitions Calls (List PredicateFamilyFact) )
(def (predicate-family-facts-from-source relpath definitions calls)
  (filter-map (cut predicate-family-fact-from-group relpath calls <>)
              (predicate-definition-groups definitions)))

;;; Grouping uses filter+fold so predicate-family evidence is stable and does
;;; not depend on policy-side scans. The grouped value keeps original
;;; definitions intact for later selector and repair payloads.
;; : (-> Definitions (List PredicateGroup) )
(def (predicate-definition-groups definitions)
  (foldl add-predicate-definition-group '()
         (filter predicate-definition? definitions)))

;;; The accumulator is intentionally association-list shaped: it is small,
;;; deterministic under reverse-at-materialization, and easy for agent repair
;;; payloads to display without introducing another model struct.
;; : (-> Definition PredicateGroups PredicateGroup )
(def (add-predicate-definition-group definition groups)
  (let* ((key (predicate-definition-subject definition))
         (prior (assoc key groups)))
    (if prior
      (cons (cons key (cons definition (cdr prior)))
            (remove-predicate-definition-group key groups))
      (cons (cons key [definition]) groups))))

;;; Removing before re-cons keeps the newest accumulated group unique while the
;;; outer fold stays expression-returning and avoids mutation.
;; : (-> Subject PredicateGroups PredicateGroups )
(def (remove-predicate-definition-group key groups)
  (filter (lambda (group) (not (equal? (car group) key))) groups))

;; : (-> Definition Boolean )
(def (predicate-definition? definition)
  (and (= (definition-arity definition) 1)
       (string-suffix? "?" (definition-name definition))
       (pair? (definition-formals definition))))

;;; Boolean condition facts are predicate-shaped but not family-shaped: multi-
;;; argument helpers such as path matching still need parser-owned evidence.
;; : (-> Definition Boolean )
(def (boolean-condition-definition? definition)
  (and (>= (definition-arity definition) 1)
       (string-suffix? "?" (definition-name definition))
       (pair? (definition-formals definition))))

;; : (-> Definition String )
(def (predicate-definition-subject definition)
  (car (definition-formals definition)))

;;; This is the family materializer, not the threshold policy.
;;; It requires enough native field evidence before producing a repair fact.
;;; Names and spans are preserved so agent repair can stay selector-bounded.
;; : (-> Relpath Calls PredicateGroup PredicateFamilyFact )
(def (predicate-family-fact-from-group relpath calls group)
  (let* ((subject (car group))
         (definitions (reverse (cdr group)))
         (names (map definition-name definitions))
         (family-calls (filter (cut call-owned-by? <> names) calls))
         (field-access-calls (filter field-access-call? family-calls))
         (condition-calls (filter condition-call? family-calls))
         (repeated-callees (repeated-call-callees family-calls))
         (field-keys (unique
                      (filter identity (map call-field-key field-access-calls)))))
    (and (>= (length definitions) 3)
         (>= (length field-access-calls) 3)
         (make-predicate-family-fact
          (string-append "predicate-family:" subject)
          "predicate-family"
          relpath
          (earliest-definition-start definitions)
          (latest-definition-end definitions)
          "repeated-predicate-family"
          subject
          names
          (length definitions)
          field-keys
          repeated-callees
          (length condition-calls)
          ["predicate-family-combinator-drift"
           "field-selector-helper-candidate"
           "gerbil-utils-combinator-style"]
          "extract field/role predicate helpers or a table-driven predicate combinator; preserve exported predicate names unless policy evidence permits"))))

;;; Field access facts expose repeated hash/field selectors independently from policy thresholds.
;; : (-> Relpath Calls Definitions Forms (List FieldAccessPatternFact) )
(def (field-access-pattern-facts-from-source relpath calls definitions form-datums)
  (append
   (filter-map (cut field-access-pattern-fact-from-group relpath <>)
               (field-access-groups calls))
   (if (and (calls-include-callee? calls "cdr")
            (calls-include-callee? calls "assq"))
     (inline-alist-access-facts-from-source relpath definitions form-datums)
     [])))

;;; Field accesses are grouped independently from predicate families so search,
;;; snapshot, and policy can each consume the same native fact without
;;; re-deriving thresholds.
;; : (-> Calls (List FieldAccessGroup) )
(def (field-access-groups calls)
  (foldl add-field-access-group '()
         (filter field-access-call? calls)))

;;; Unknown keys are retained as an explicit bucket; this keeps malformed or
;;; unsupported call shapes visible to policy instead of silently dropping
;;; parser evidence.
;; : (-> CallFact FieldAccessGroups FieldAccessGroups )
(def (add-field-access-group call groups)
  (let* ((key (or (call-field-key call) "<unknown>"))
         (prior (assoc key groups)))
    (if prior
      (cons (cons key (cons call (cdr prior)))
            (remove-field-access-group key groups))
      (cons (cons key [call]) groups))))

;;; The remove/re-cons pattern mirrors predicate grouping and preserves a
;;; compact, mutation-free accumulator shape.
;; : (-> FieldKey FieldAccessGroups FieldAccessGroups )
(def (remove-field-access-group key groups)
  (filter (lambda (group) (not (equal? (car group) key))) groups))

;;; This materializer turns a grouped call bucket into search-ready selector
;;; evidence.
;;; Callers and accessors stay in fields so policy can explain the helper
;;; candidate without source reads.
;; : (-> Relpath FieldAccessGroup FieldAccessPatternFact )
(def (field-access-pattern-fact-from-group relpath group)
  (let* ((field-key (car group))
         (calls (reverse (cdr group)))
         (callers (unique
                   (filter identity (map call-fact-caller calls)))))
    (and (>= (length calls) 3)
         (make-field-access-pattern-fact
          (string-append "field-access:" field-key)
          "field-access-pattern"
          relpath
          (earliest-call-start calls)
          (latest-call-end calls)
          "repeated-field-access"
          field-key
          callers
          (length calls)
          (unique (map call-fact-callee calls))
          ["field-selector-helper-candidate"
           "predicate-family-combinator-drift"]
         "centralize repeated field access behind a small selector helper before adding more predicate branches"))))

;;; Inline alist lookup facts catch generated `(cdr (assq ...))` access walls.
;;; Detection walks native datum trees and skips quoted data; policy consumes
;;; only the resulting FieldAccessPatternFact.
;; : (-> Relpath Definitions Forms (List FieldAccessPatternFact) )
(def (inline-alist-access-facts-from-source relpath definitions form-datums)
  (filter-map (cut inline-alist-access-fact-from-group relpath <>)
              (inline-alist-access-groups definitions form-datums)))

;;; Grouping by key keeps repeated anonymous data-model access visible even
;;; when it is spread across several helpers in one owner.
;; : (-> Definitions Forms (List InlineAlistGroup) )
(def (inline-alist-access-groups definitions form-datums)
  (foldl add-inline-alist-entry '()
         (apply append
                (map (cut inline-alist-access-entries-from-datum
                          definitions <>)
                     form-datums))))

;;; A definition-owned entry preserves the caller and selector span while the
;;; alist key stays a compact field-key token.
;; : (-> Definitions Datum (List InlineAlistEntry) )
(def (inline-alist-access-entries-from-datum definitions datum)
  (let* ((name (form-caller-name datum))
         (definition (and name (definition-by-name definitions name))))
    (if definition
      (map (lambda (key)
             (list key name definition))
           (inline-alist-keys-from-datum datum))
      [])))

;;; The AST walk ignores quoted/syntax data so literal examples do not become
;;; policy evidence.
;; : (-> Datum (List FieldKey) )
(def (inline-alist-keys-from-datum datum)
  (cond
   ((not (pair? datum)) [])
   ((quoted-datum? datum) [])
   (else
    (append (if (inline-alist-lookup-datum? datum)
              [(inline-alist-lookup-key datum)]
              [])
            (apply append
                   (map inline-alist-keys-from-datum
                        (datum-list-items datum)))))))

;; : (-> Datum Boolean )
(def (inline-alist-lookup-datum? datum)
  (and (pair? datum)
       (eq? (car datum) 'cdr)
       (let (argument (and (pair? (cdr datum)) (cadr datum)))
         (and (pair? argument)
              (eq? (car argument) 'assq)))))

;; : (-> Datum FieldKey )
(def (inline-alist-lookup-key datum)
  (let* ((argument (and (pair? (cdr datum)) (cadr datum)))
         (key (and (pair? (cdr argument)) (cadr argument))))
    (string-append "alist:"
                   (cond
                    ((and (pair? key)
                          (eq? (car key) 'quote)
                          (pair? (cdr key)))
                     (quality-shape-datum->string (cadr key)))
                    ((symbol? key) (symbol->string key))
                    ((string? key) key)
                    (else "<dynamic>")))))

;;; Quoted alist keys use the Scheme printer so compound literal keys remain
;;; distinct without inventing parser-local display syntax.
;; : (-> Datum String)
(def (quality-shape-datum->string datum)
  (call-with-output-string []
    (cut write datum <>)))

;; : (-> InlineAlistEntry InlineAlistGroups InlineAlistGroups )
(def (add-inline-alist-entry entry groups)
  (let* ((key (car entry))
         (prior (assoc key groups)))
    (if prior
      (cons (cons key (cons entry (cdr prior)))
            (remove-inline-alist-group key groups))
      (cons (cons key [entry]) groups))))

;;; Accumulator invariant:
;;; - Each inline alist field key has one bucket during fold grouping.
;;; - Removing before re-cons keeps updates functional and deterministic.
;; : (-> FieldKey InlineAlistGroups InlineAlistGroups )
(def (remove-inline-alist-group key groups)
  (filter (lambda (group) (not (equal? (car group) key))) groups))

;; : (-> InlineAlistEntry Definition )
(def (inline-alist-entry-definition entry)
  (caddr entry))

;; : (-> InlineAlistEntry CallerName )
(def (inline-alist-entry-caller entry)
  (cadr entry))

;;; Materialization emits even a single passive fact so search can expose the
;;; anonymous data-model shape. Policy owns the warning threshold.
;; : (-> Relpath InlineAlistGroup FieldAccessPatternFact )
(def (inline-alist-access-fact-from-group relpath group)
  (let* ((field-key (car group))
         (entries (reverse (cdr group)))
         (definitions (map inline-alist-entry-definition entries))
         (callers (unique (map inline-alist-entry-caller entries))))
    (and (pair? entries)
         (make-field-access-pattern-fact
          (string-append "inline-alist-access:" field-key)
          "field-access-pattern"
          relpath
          (earliest-definition-start definitions)
          (latest-definition-end definitions)
          "inline-alist-lookup"
          field-key
          callers
          (length entries)
          ["assq" "cdr"]
          ["inline-alist-lookup-drift"
           "anonymous-data-model"
           "field-selector-helper-candidate"]
          "replace repeated inline alist lookups with a record/defstruct, typed profile accessor, or one named lookup helper"))))

;;; Projection burst facts keep single-caller emit/projection walls visible.
;;; Policy later decides whether enough independent groups align for a warning.
;; : (-> Relpath Calls (List ProjectionBurstFact) )
(def (projection-burst-facts-from-source relpath calls)
  (filter-map (cut projection-burst-fact-from-group relpath <>)
              (projection-burst-groups calls)))

;;; Group by caller, not by field key: the smell is a function boundary that
;;; repeatedly projects fields while emitting lines, even when keys differ.
;; : (-> Calls (List ProjectionBurstGroup) )
(def (projection-burst-groups calls)
  (foldl add-projection-burst-call '()
         (filter projection-burst-call? calls)))

;;; Projection grouping keeps access and output calls in the same bucket so the
;;; later detector can require both, instead of treating hash access alone as bad.
;; : (-> CallFact ProjectionBurstGroups ProjectionBurstGroups )
(def (add-projection-burst-call call groups)
  (let* ((caller (or (call-fact-caller call) ""))
         (prior (assoc caller groups)))
    (if prior
      (cons (cons caller (cons call (cdr prior)))
            (remove-projection-burst-group caller groups))
      (cons (cons caller [call]) groups))))

;;; Group replacement mirrors other quality-shape reducers and keeps parser
;;; evidence mutation-free while preserving one bucket per caller.
;; : (-> Caller ProjectionBurstGroups ProjectionBurstGroups )
(def (remove-projection-burst-group caller groups)
  (filter (lambda (group) (not (equal? (car group) caller))) groups))

;; : (-> CallFact Boolean )
(def (projection-burst-call? call)
  (and (call-fact-caller call)
       (or (field-access-call? call)
           (projection-emitter-call? call))))

;; : (-> CallFact Boolean )
(def (projection-emitter-call? call)
  (member (call-fact-callee call) +projection-emitter-callees+))

;;; The fact is deliberately permissive: access, field spread, and emitter
;;; thresholds stay as named detection groups in policy.
;; : (-> Relpath ProjectionBurstGroup ProjectionBurstFact )
(def (projection-burst-fact-from-group relpath group)
  (let* ((caller (car group))
         (calls (reverse (cdr group)))
         (access-calls (filter field-access-call? calls))
         (emitter-calls (filter projection-emitter-call? calls))
         (field-keys (unique
                      (filter identity (map call-field-key access-calls)))))
    (and (>= (length access-calls)
             +projection-burst-native-min-access-count+)
         (pair? emitter-calls)
         (make-projection-burst-fact
          (string-append "projection-burst:" caller)
          "projection-burst"
          relpath
          (earliest-call-start calls)
          (latest-call-end calls)
          "emitter-projection-burst"
          caller
          field-keys
          (length access-calls)
          (length field-keys)
          (length emitter-calls)
          (unique (map call-fact-callee access-calls))
          (unique (map call-fact-callee emitter-calls))
          ["emitter-projection-burst"
           "field-selector-helper-candidate"
           "list-builder-output-shape"]
          "separate field projection, line formatting, and output traversal before adding more hash-get/display scaffolding"))))

;;; Boolean condition facts keep individual predicate helpers queryable for repair payloads.
;; : (-> Relpath Definitions Calls Forms (List BooleanConditionFact) )
(def (boolean-condition-facts-from-source relpath definitions calls form-datums)
  (append
   (filter-map (cut boolean-condition-fact-from-definition relpath calls <>)
               (filter boolean-condition-definition? definitions))
   (if (calls-include-callee? calls "not")
     (boolean-normalization-facts-from-source relpath definitions form-datums)
     [])))

;; : (-> Calls Callee Boolean)
(def (calls-include-callee? calls callee)
  (ormap (lambda (call)
           (equal? (call-fact-callee call) callee))
         calls))

;;; Boolean normalization facts catch generated scaffold such as nested negation.
;;; This is parser-owned evidence from native datum trees, not rendered source
;;; or call-argument strings. The policy decides whether it is actionable.
;; : (-> Relpath Definitions Forms (List BooleanConditionFact) )
(def (boolean-normalization-facts-from-source relpath definitions form-datums)
  (filter-map (cut boolean-normalization-fact-from-datum relpath definitions <>)
              form-datums))

;;; Evidence boundary: this AST walker isolates double-not scaffolds owned by
;;; one definition before policy decides whether to warn.
;; : (-> Relpath Definitions Datum BooleanConditionFact )
(def (boolean-normalization-fact-from-datum relpath definitions datum)
  (let* ((name (form-caller-name datum))
         (definition (and name (definition-by-name definitions name)))
         (normalization-count (nested-not-datum-count datum)))
    (and definition
         (> normalization-count 0)
         (make-boolean-condition-fact
          (string-append "boolean-normalization:" name)
          "boolean-condition"
          relpath
          (definition-start definition)
          (definition-end definition)
          "boolean-normalization-scaffold"
          name
          (definition-formals definition)
          ["not"]
          []
          normalization-count
          ["boolean-normalization-drift"
           "generated-scaffold-shape"
           "expression-level-composition"]
          "replace double negation with an explicit predicate/helper boundary or the underlying boolean expression"))))

;;; Definition lookup preserves parser order and returns the original fact
;;; object, so later evidence keeps the exact owner span instead of a copied
;;; one-element filter result.
;; : (-> Definitions DefinitionName (Maybe Definition) )
(def (definition-by-name definitions name)
  (find (lambda (definition)
          (equal? (definition-name definition) name))
        definitions))

;;; The detector is an AST predicate: only an actual `(not (not ...))` datum
;;; shape counts, and quoted/syntax data is skipped.
;; : (-> Datum Nat )
(def (nested-not-datum-count datum)
  (cond
   ((not (pair? datum)) 0)
   ((quoted-datum? datum) 0)
   (else
    (+ (if (nested-not-datum? datum) 1 0)
       (foldl (lambda (item count)
                (+ count (nested-not-datum-count item)))
              0
              (datum-list-items datum))))))

;; : (-> Datum Boolean )
(def (nested-not-datum? datum)
  (and (pair? datum)
       (eq? (car datum) 'not)
       (let (argument (and (pair? (cdr datum)) (cadr datum)))
         (and (pair? argument)
              (eq? (car argument) 'not)))))

;; : (-> Datum Boolean )
(def (quoted-datum? datum)
  (and (pair? datum)
       (member (car datum)
               '(quote quasiquote syntax quote-syntax))))

;;; Individual condition facts keep predicate-level evidence available even
;;; when a family warning owns the repair decision.
;;; The filter/map chain preserves callees and field keys as compact native
;;; context for the model.
;; : (-> Relpath Calls Definition BooleanConditionFact )
(def (boolean-condition-fact-from-definition relpath calls definition)
  (let* ((name (definition-name definition))
         (owned-calls (filter (cut call-owned-by? <> [name]) calls))
         (condition-calls (filter condition-call? owned-calls))
         (field-access-calls (filter field-access-call? owned-calls)))
    (and (>= (+ (length condition-calls) (length field-access-calls)) 2)
         (make-boolean-condition-fact
          name
          "boolean-condition"
          relpath
          (definition-start definition)
          (definition-end definition)
          "predicate-condition"
          name
          (definition-formals definition)
          (unique (map call-fact-callee condition-calls))
          (unique
           (filter identity (map call-field-key field-access-calls)))
          (+ (length condition-calls) (length field-access-calls))
          ["predicate-helper-candidate"]
          "keep this as a small expression-returning predicate or compose it through the predicate family helper"))))

;; : (-> CallFact (List String) Boolean )
(def (call-owned-by? call names)
  (member (or (call-fact-caller call) "") names))

;; : (-> CallFact Boolean )
(def (field-access-call? call)
  (member (call-fact-callee call) +field-access-callees+))

;; : (-> CallFact Boolean )
(def (condition-call? call)
  (member (call-fact-callee call) +condition-callees+))

;; : (-> CallFact FieldKey )
(def (call-field-key call)
  (let (args (call-fact-arguments call))
    (and (pair? args)
         (pair? (cdr args))
         (clean-field-key (cadr args)))))

;;; Field keys come from reader-token text, so this normalizes quoted symbols
;;; without pretending to evaluate arbitrary Scheme values.
;; : (-> FieldArgumentToken FieldKey )
(def (clean-field-key value)
  (let (text (if (string? value) value ""))
    (cond
     ((and (> (string-length text) 1) (string-prefix? "'" text))
      (substring text 1 (string-length text)))
     (else text))))

;;; The map/filter composition returns only repeated callees for the repair
;;; summary.
;;; Full call facts stay separate so this helper cannot hide selector evidence
;;; from policy.
;; : (-> Calls (List CalleeName) )
(def (repeated-call-callees calls)
  (map car
       (filter (lambda (entry) (>= (cdr entry) 2))
               (call-callee-counts calls))))

;;; Counting stays local to the parser fact producer so policy can stay about
;;; thresholds and repair strategy, not call aggregation mechanics.
;; : (-> Calls (List CountEntry) )
(def (call-callee-counts calls)
  (foldl add-call-callee-count '() calls))

;;; Each fold step replaces the old bucket and returns a fresh count list,
;;; matching the gerbil-utils preference for small expression-level reducers.
;; : (-> CallFact CountEntries CountEntries )
(def (add-call-callee-count call counts)
  (let* ((callee (call-fact-callee call))
         (prior (assoc callee counts)))
    (if prior
      (cons (cons callee (fx1+ (cdr prior)))
            (remove-call-callee-count callee counts))
      (cons (cons callee 1) counts))))

;;; This helper is the reducer's uniqueness gate.
;;; The filter shape exposes the accumulator invariant and keeps count updates
;;; mutation-free.
;; : (-> CalleeName CountEntries CountEntries )
(def (remove-call-callee-count callee counts)
  (filter (lambda (entry) (not (equal? (car entry) callee))) counts))

;; : (-> ControlFlowFact Boolean )
;;; Min/max folds keep location spans deterministic across parser runs without
;;; sorting the original definitions.
;; : (-> Definitions Integer )
(def (earliest-definition-start definitions)
  (foldl (lambda (definition start)
           (min start (definition-start definition)))
         (definition-start (car definitions))
         (cdr definitions)))

;;; The span end is paired with earliest-definition-start so a predicate family
;;; can be surfaced as one repair selector.
;; : (-> Definitions Integer )
(def (latest-definition-end definitions)
  (foldl (lambda (definition end)
           (max end (definition-end definition)))
         (definition-end (car definitions))
         (cdr definitions)))

;;; Call spans use the same fold shape as definition spans, which keeps fact
;;; projection stable for field-access pattern evidence.
;; : (-> Calls Integer )
(def (earliest-call-start calls)
  (foldl (lambda (call start)
           (min start (call-fact-start call)))
         (call-fact-start (car calls))
         (cdr calls)))

;;; The latest call endpoint completes the selector boundary for grouped call
;;; facts without reaching back into source text.
;; : (-> Calls Integer )
(def (latest-call-end calls)
  (foldl (lambda (call end)
           (max end (call-fact-end call)))
         (call-fact-end (car calls))
         (cdr calls)))
