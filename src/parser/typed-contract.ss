;;; -*- Gerbil -*-
;;; Parser-owned typed-combinator contract facts.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/typed-comment-metadata
        :asp-gerbil-scheme/src/parser/typed-contract-diagnostics
        :asp-gerbil-scheme/src/parser/typed-contract-comment-index
        :asp-gerbil-scheme/src/parser/typed-contract-scheme
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/13
                 string-join
                 string-empty?
                 string-every
                 string-prefix?
                 string-trim
                 string-trim-both)
        (only-in :std/srfi/1 last take take-while)
        (only-in :std/misc/list length<=n? unique)
        (only-in :std/sugar cut filter filter-map find foldl hash ormap while with-catch)
        )

(export typed-contract-facts-from-definitions
        typed-contract-facts-from-lines)

;;; Boundary:
;;; - typed-contract-facts-from-definitions composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; typed-contract-facts-from-definitions
;;   : (-> FullPath Relpath (List Definition) (List CallFact) (List HigherOrderFact) (List ControlFlowFact) (List TypedContractFact) )
;;   | doc m%
;;       `typed-contract-facts-from-definitions fullpath relpath definitions calls higher-order-forms control-flow-forms`
;;       attaches adjacent typed comment facts to parsed definitions while preserving parser-owned implementation evidence.
;;
;;       # Examples
;;       ```scheme
;;       (typed-contract-facts-from-definitions fullpath relpath [] [] [] [])
;;       ;; => ()
;;       ```
;;     %
(def (typed-contract-facts-from-definitions fullpath relpath definitions calls higher-order-forms control-flow-forms)
  (with-catch
   (lambda (_) '())
   (lambda ()
     (let (lines (read-file-lines fullpath))
       (typed-contract-facts-from-lines
        lines relpath definitions calls higher-order-forms control-flow-forms)))))

;;; Boundary:
;;; - parse-source-file already owns source line IO; this helper keeps typed
;;;   contract extraction reusable without re-reading the file on hot paths.
;; : (-> (List SourceLine) Relpath (List Definition) (List CallFact) (List HigherOrderFact) (List ControlFlowFact) (List TypedContractFact) )
(def (typed-contract-facts-from-lines lines relpath definitions calls higher-order-forms control-flow-forms)
  (let* ((line-vector (list->vector lines))
         (entry-index
          (typed-contract-entry-index/definitions line-vector definitions)))
    (if (= (typed-contract-entry-index-count entry-index) 0)
      '()
      (let ((call-index (index-facts-by-field call-fact-caller calls))
            (higher-order-index
             (index-facts-by-field higher-order-fact-caller higher-order-forms))
            (control-flow-index
             (index-facts-by-field control-flow-fact-caller control-flow-forms)))
        (filter-map (cut typed-contract-fact-from-definition/entry-indexed
                         relpath entry-index <>
                         call-index higher-order-index control-flow-index)
                    definitions)))))

;;; Compatibility wrapper for callers that still pass list-shaped source lines.
;; : (-> Relpath (List SourceLine) Definition (List CallFact) (List HigherOrderFact) (List ControlFlowFact) (Maybe TypedContractFact) )
(def (typed-contract-fact-from-definition relpath lines definition calls higher-order-forms control-flow-forms)
  (typed-contract-fact-from-definition/indexed
   relpath
   (list->vector lines)
   definition
   (index-facts-by-field call-fact-caller calls)
   (index-facts-by-field higher-order-fact-caller higher-order-forms)
   (index-facts-by-field control-flow-fact-caller control-flow-forms)))

;;; Boundary:
;;; - typed-contract-fact-from-definition/indexed owns the hot path.
;;; - Source lines and parser witnesses are indexed once per file by the caller.
;; : (-> Relpath (Vector SourceLine) Definition HashTable HashTable HashTable (Maybe TypedContractFact) )
(def (typed-contract-fact-from-definition/indexed relpath line-vector definition call-index higher-order-index control-flow-index)
  (typed-contract-fact-from-entry
   relpath
   definition
   (typed-contract-entry-near-definition/indexed line-vector definition)
   call-index
   higher-order-index
   control-flow-index))

;; : (-> Relpath TypedContractEntryIndex Definition HashTable HashTable HashTable (Maybe TypedContractFact) )
(def (typed-contract-fact-from-definition/entry-indexed relpath entry-index definition call-index higher-order-index control-flow-index)
  (typed-contract-fact-from-entry
   relpath
   definition
   (typed-contract-entry-for-definition entry-index definition)
   call-index
   higher-order-index
   control-flow-index))

;;; Boundary:
;;; - This is the single projection boundary from typed-comment entries to
;;;   `TypedContractFact` records.
;;; - Keep arity alignment, parser-quality reasons, matched implementation
;;;   facts, and repair evidence assembled together so later policy splits can
;;;   move whole evidence lanes without changing fact semantics.
;; : (-> Relpath Definition (Maybe TypedContractEntry) HashTable HashTable HashTable (Maybe TypedContractFact) )
(def (typed-contract-fact-from-entry relpath definition entry call-index higher-order-index control-flow-index)
  (and entry
       (let* ((comment-start (car entry))
              (comment-end (cadr entry))
              (contract (caddr entry))
              (block-style (cadddr entry))
              (block-facets (typed-contract-entry-facets entry))
              (typed-comment (typed-contract-entry-typed-comment entry))
              (tokens (typed-contract-tokens contract))
              (arrow-count (typed-contract-arrow-count contract))
              (group-count (typed-contract-group-count contract))
              (contract-projection (typed-contract-entry-projection entry))
              (contract-output (car contract-projection))
              (contract-inputs (cadr contract-projection))
              (contract-input-count (length contract-inputs))
              (arity-alignment
               (typed-contract-arity-alignment definition
                                               arrow-count
                                               contract-input-count))
              (reasons (typed-contract-invalid-reasons
                        definition contract contract-output contract-inputs
                        typed-comment tokens arrow-count group-count))
              (quality (typed-contract-quality reasons arrow-count group-count))
              (matched-calls
               (indexed-facts call-index (definition-name definition)))
              (matched-higher-order
               (indexed-facts higher-order-index (definition-name definition)))
              (matched-control-flow
               (indexed-facts control-flow-index (definition-name definition)))
              (quality-facets
               (typed-contract-quality-facets
                definition quality arity-alignment reasons
                matched-calls matched-higher-order matched-control-flow
                block-style block-facets))
              (repair-evidence
               (typed-contract-repair-evidence
                relpath definition contract quality quality-facets
                matched-calls matched-higher-order matched-control-flow)))
           (make-typed-contract-fact
            (definition-name definition)
            (definition-kind definition)
            (definition-formals definition)
            (definition-arity definition)
            relpath
            (definition-start definition)
            (definition-end definition)
            comment-start
            comment-end
            contract
            contract-output
            contract-inputs
            contract-input-count
            arity-alignment
            tokens
            arrow-count
            group-count
            quality
            reasons
            quality-facets
            repair-evidence
            typed-comment))))

;; : (-> (-> Fact Key) (List Fact) HashTable)
(def (index-facts-by-field accessor facts)
  (let (table (make-hash-table))
    (for-each
     (lambda (fact)
       (let (key (accessor fact))
         (when key
           (let (existing
                 (if (hash-key? table key)
                   (hash-get table key)
                   '()))
             (hash-put! table key (cons fact existing))))))
     facts)
    table))

;; : (-> HashTable Key (List Fact))
(def (indexed-facts table key)
  (if (and key (hash-key? table key))
    (hash-get table key)
    '()))

;;; Boundary:
;;; - typed-contract-fact-from-definition coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> Relpath (List SourceLine) Definition (List CallFact) (List HigherOrderFact) (List ControlFlowFact) (Maybe TypedContractFact) )
(def (typed-contract-fact-from-definition/list-scan relpath lines definition calls higher-order-forms control-flow-forms)
  (let (entry (typed-contract-entry-near-definition lines definition))
    (and entry
         (let* ((comment-start (car entry))
                (comment-end (cadr entry))
                (contract (caddr entry))
                (block-style (cadddr entry))
                (block-facets (typed-contract-entry-facets entry))
                (typed-comment (typed-contract-entry-typed-comment entry))
                (tokens (typed-contract-tokens contract))
                (arrow-count (typed-contract-arrow-count contract))
                (group-count (typed-contract-group-count contract))
                (contract-projection (typed-contract-entry-projection entry))
                (contract-output (car contract-projection))
                (contract-inputs (cadr contract-projection))
                (contract-input-count (length contract-inputs))
                (arity-alignment
                 (typed-contract-arity-alignment definition
                                                 arrow-count
                                                 contract-input-count))
                (reasons (typed-contract-invalid-reasons
                          definition contract contract-output contract-inputs
                          typed-comment tokens arrow-count group-count))
                (quality (typed-contract-quality reasons arrow-count group-count))
                (matched-calls
                 (definition-calls definition calls))
                (matched-higher-order
                 (definition-higher-order-forms definition higher-order-forms))
                (matched-control-flow
                 (definition-control-flow-forms definition control-flow-forms))
                (quality-facets
                (typed-contract-quality-facets
                 definition quality arity-alignment reasons
                 matched-calls matched-higher-order matched-control-flow
                  block-style block-facets))
                (repair-evidence
                 (typed-contract-repair-evidence
                  relpath definition contract quality quality-facets
                  matched-calls matched-higher-order matched-control-flow)))
           (make-typed-contract-fact
            (definition-name definition)
            (definition-kind definition)
            (definition-formals definition)
            (definition-arity definition)
            relpath
            (definition-start definition)
            (definition-end definition)
            comment-start
            comment-end
            contract
            contract-output
            contract-inputs
            contract-input-count
            arity-alignment
            tokens
            arrow-count
            group-count
            quality
            reasons
            quality-facets
            repair-evidence
            typed-comment)))))

;;; Quality facets are parser-owned evidence for later policy decisions.
;;; Keep style signals separate from hard findings so guidance stays flexible.
;; : (-> Definition SignatureQuality ArityAlignment (List SignatureReason) (List CallFact) (List HigherOrderFact) (List ControlFlowFact) BlockStyle (List QualityFacet) (List QualityFacet) )
(def (typed-contract-quality-facets definition quality arity-alignment reasons calls higher-order-forms control-flow-forms block-style block-facets)
  (unique
   (filter identity
           (append
            [(if (pair? reasons) "contract-invalid" "contract-valid")
             block-style
             quality
             arity-alignment
             (and (> (definition-arity definition) 0) "arity-bearing-definition")
             (and (pair? calls) "call-backed")
             (and (pair? higher-order-forms) "higher-order-used")
             (and (pair? higher-order-forms) "combinator-backed")
             (and (manual-loop-drift? control-flow-forms) "manual-loop-drift")
             (and (combinator-candidate? definition reasons calls higher-order-forms control-flow-forms)
                  "combinator-candidate")
             (and (over-abstracted-contract-risk? quality calls higher-order-forms)
                  "over-abstracted-contract-risk")]
            block-facets
            (map control-flow-facet control-flow-forms)))))

;; : (-> Definition (List SignatureReason) (List CallFact) (List HigherOrderFact) (List ControlFlowFact) Boolean )
(def (combinator-candidate? definition reasons calls higher-order-forms control-flow-forms)
  (and (not (pair? reasons))
       (> (definition-arity definition) 0)
       (or (manual-loop-drift? control-flow-forms)
           (and (pair? calls) (not (pair? higher-order-forms))))))

;; : (-> SignatureQuality (List CallFact) (List HigherOrderFact) Boolean )
(def (over-abstracted-contract-risk? quality calls higher-order-forms)
  (and (member quality ["higher-order-transform" "grouped-transform"])
       (not (pair? calls))
       (not (pair? higher-order-forms))))

;;; Manual-loop drift is a style signal, not a forced rewrite by itself.
;;; Runtime/control boundaries suppress the signal when loops encode structure.
;; : (-> (List ControlFlowFact) Boolean )
(def (manual-loop-drift? control-flow-forms)
  (and (control-flow-role-present? control-flow-forms "manual-loop")
       (not (ormap (cut control-flow-role-present? control-flow-forms <>)
                   ["resource-scope" "continuation-control"
                    "protected-control" "builder-control"]))))

;;; Role lookup keeps control-flow facet detection declarative.
;;; Callers can compose role predicates without inlining loop tests.
;; : (-> (List ControlFlowFact) String Boolean )
(def (control-flow-role-present? control-flow-forms role)
  (ormap (lambda (fact) (equal? (control-flow-fact-role fact) role))
         control-flow-forms))

;; : (-> ControlFlowFact QualityFacet )
(def (control-flow-facet fact)
  (string-append "control-flow:" (control-flow-fact-role fact)))

;;; Repair evidence packages parser witnesses for guide output.
;;; Keep allowed moves flexible while preserving runtime and macro boundaries.
;; : (-> Relpath Definition SignatureContract SignatureQuality (List QualityFacet) (List CallFact) (List HigherOrderFact) (List ControlFlowFact) RepairEvidence )
(def (typed-contract-repair-evidence relpath definition contract quality quality-facets calls higher-order-forms control-flow-forms)
  (hash (factSource "native-parser")
        (trigger "typed-combinator-style")
        (definition (definition-name definition))
        (definitionKind (definition-kind definition))
        (definitionFormals (definition-formals definition))
        (definitionArity (definition-arity definition))
        (path relpath)
        (lineSpan [(definition-start definition) (definition-end definition)])
        (selector (definition-source-selector definition))
        (contract contract)
        (quality quality)
        (qualityFacets quality-facets)
        (matchedCalls (map call-repair-evidence
                           (if (length<=n? calls 5) calls (take calls 5))))
        (matchedHigherOrder (map higher-order-repair-evidence
                                 (if (length<=n? higher-order-forms 5)
                                   higher-order-forms
                                   (take higher-order-forms 5))))
        (matchedControlFlow (map control-flow-repair-evidence
                                 (if (length<=n? control-flow-forms 5)
                                   control-flow-forms
                                   (take control-flow-forms 5))))
        (allowedMoves (typed-contract-allowed-moves quality-facets))
        (forbiddenMoves ["change-public-export-without-policy-evidence"
                         "rewrite-io-or-runtime-boundary-without-witness"
                         "replace-macro-transformer-without-runtime-source-witness"])
        (witnessNeeded (typed-contract-witness-needed quality-facets))
        (agentRepairMode "use parserEvidence to choose the smallest helper/combinator rewrite; keep names and exact composition flexible when tests and selectors preserve behavior")))

;; : (-> (List QualityFacet) (List RepairMove) )
(def (typed-contract-allowed-moves quality-facets)
  (unique
   (append ["add-or-expand-adjacent-typed-contract-block"]
           (if (member "combinator-candidate" quality-facets)
             ["extract-predicate-mapper-or-reducer-helper"
              "compose-with-map-filter-fold-cut-curry-or-compose"]
             [])
           (if (member "manual-loop-drift" quality-facets)
             ["replace-manual-loop-with-higher-order-combinator-when-no-state-witness"]
             []))))

;; : (-> (List QualityFacet) (List WitnessName) )
(def (typed-contract-witness-needed quality-facets)
  (unique
   (append
    (if (member "manual-loop-drift" quality-facets)
      ["state-or-early-exit-witness-if-named-let-remains"]
      [])
    (if (member "over-abstracted-contract-risk" quality-facets)
      ["callsite-or-higher-order-implementation-evidence"]
      [])
    ["parser-snapshot-or-policy-check"])))

;;; Definition-scoped call evidence stays attached to the owning helper.
;;; Matching by caller name avoids comment-text or selector substring heuristics.
;; : (-> Definition (List CallFact) (List CallFact) )
(def (definition-calls definition calls)
  (filter (lambda (fact)
            (equal? (or (call-fact-caller fact) "")
                    (definition-name definition)))
          calls))

;;; Definition-scoped higher-order evidence exposes the combinator witness.
;;; Matching by caller name keeps map/filter/fold advice parser-owned.
;; : (-> Definition (List HigherOrderFact) (List HigherOrderFact) )
(def (definition-higher-order-forms definition facts)
  (filter (lambda (fact)
            (equal? (or (higher-order-fact-caller fact) "")
                    (definition-name definition)))
          facts))

;;; Definition-scoped control-flow evidence separates real structure from style advice.
;;; Matching by caller name keeps loop-risk detection local to the helper.
;; : (-> Definition (List ControlFlowFact) (List ControlFlowFact) )
(def (definition-control-flow-forms definition facts)
  (filter (lambda (fact)
            (equal? (or (control-flow-fact-caller fact) "")
                    (definition-name definition)))
          facts))

;; : (-> CallFact Json )
(def (call-repair-evidence fact)
  (hash (kind "call")
        (name (call-fact-callee fact))
        (arity (call-fact-arity fact))
        (selector (call-fact-source-selector fact))))

;; : (-> HigherOrderFact Json )
(def (higher-order-repair-evidence fact)
  (hash (kind "higher-order")
        (name (higher-order-fact-name fact))
        (role (higher-order-fact-role fact))
        (operandCount (higher-order-fact-operand-count fact))
        (selector (higher-order-source-selector fact))))

;; : (-> ControlFlowFact Json )
(def (control-flow-repair-evidence fact)
  (hash (kind "control-flow")
        (name (control-flow-fact-name fact))
        (role (control-flow-fact-role fact))
        (bindingCount (control-flow-fact-binding-count fact))
        (bodyFormCount (control-flow-fact-body-form-count fact))
        (selector (control-flow-source-selector fact))))

;; : (-> Definition Selector )
(def (definition-source-selector definition)
  (string-append (definition-path definition) ":"
                 (number->string (definition-start definition))
                 "-"
                 (number->string (definition-end definition))))

;; : (-> CallFact Selector )
(def (call-fact-source-selector fact)
  (string-append (call-fact-path fact) ":"
                 (number->string (call-fact-start fact))
                 "-"
                 (number->string (call-fact-end fact))))

;; : (-> HigherOrderFact Selector )
(def (higher-order-source-selector fact)
  (string-append (higher-order-fact-path fact) ":"
                 (number->string (higher-order-fact-start fact))
                 "-"
                 (number->string (higher-order-fact-end fact))))

;; : (-> ControlFlowFact Selector )
(def (control-flow-source-selector fact)
  (string-append (control-flow-fact-path fact) ":"
                 (number->string (control-flow-fact-start fact))
                 "-"
                 (number->string (control-flow-fact-end fact))))
