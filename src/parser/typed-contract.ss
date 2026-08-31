;;; -*- Gerbil -*-
;;; Parser-owned typed-combinator contract facts.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/typed-comment-metadata
        :asp-gerbil-scheme/src/parser/typed-contract-diagnostics
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

;;; Stable de-duplication keeps quality facets compact while preserving first evidence.
;;; Do not sort here.
;;; Source-order facets make repair payloads easier to trace.

;; : (-> (Vector SourceLine) TypedContractEntryIndex)
;; : (-> (List Definition) HashTable)
(def (definition-start-set definitions)
  (let (table (make-hash-table))
    (for-each
     (lambda (definition)
       (hash-put! table (definition-start definition) #t))
     definitions)
    table))

;; : (-> (Maybe HashTable) LineNumber Boolean)
(def (definition-start-line? definition-starts line)
  (or (not definition-starts)
      (hash-key? definition-starts line)))

;; : (-> (Vector SourceLine) (List Definition) TypedContractEntryIndex)
(def (typed-contract-entry-index/definitions line-vector definitions)
  (typed-contract-entry-index/selective
   line-vector
   (definition-start-set definitions)))

;; : (-> (Vector SourceLine) TypedContractEntryIndex)
(def (typed-contract-entry-index line-vector)
  (typed-contract-entry-index/selective line-vector #f))

;; : (-> (Vector SourceLine) (Maybe HashTable) TypedContractEntryIndex)
(def (typed-contract-entry-index/selective line-vector definition-starts)
  (let ((table (make-hash-table))
        (signature-analysis-cache (make-hash-table))
        (count 0)
        (line-count (vector-length line-vector))
        (current 1))
    (def (put-entry! line entry)
      (when entry
        (hash-put! table line entry)
        (set! count (+ count 1))))
    (while (<= current line-count)
      (if (typed-comment-line?
           (line-vector-at* line-vector (fx1- current)))
        (let ((block '())
              (block-line current))
          (while (and (<= block-line line-count)
                      (typed-comment-line?
                       (line-vector-at* line-vector (fx1- block-line))))
            (set! block
              (cons [block-line
                     (typed-comment-text
                      (line-vector-at* line-vector (fx1- block-line)))]
                    block))
            (set! block-line (+ block-line 1)))
          (when (definition-start-line? definition-starts block-line)
            (put-entry!
             block-line
             (typed-comment-block-signature-entry/cache
              (reverse block)
              signature-analysis-cache)))
          (set! current block-line))
        (set! current (+ current 1))))
    (vector table count)))

;; : (-> TypedContractEntryIndex HashTable)
(def (typed-contract-entry-index-table entry-index)
  (vector-ref entry-index 0))

;; : (-> TypedContractEntryIndex Integer)
(def (typed-contract-entry-index-count entry-index)
  (vector-ref entry-index 1))

;; : (-> TypedContractEntryIndex Definition (Maybe TypedContractEntry))
(def (typed-contract-entry-for-definition entry-index definition)
  (let ((table (typed-contract-entry-index-table entry-index))
        (key (definition-start definition)))
    (and (hash-key? table key)
         (hash-get table key))))

;; : (-> (List SourceLine) Definition (Maybe TypedContractEntry))
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata)
(def (typed-contract-entry-near-definition lines definition)
  (typed-contract-block-entry lines definition))

;;; Indexed boundary:
;;; - The parser hot path already owns a source-line vector. Keep typed-contract
;;;   lookup O(1) per line instead of falling back to repeated list-ref scans.
;; : (-> (Vector SourceLine) Definition (Maybe TypedContractEntry))
(def (typed-contract-entry-near-definition/indexed line-vector definition)
  (typed-contract-block-entry/indexed line-vector definition))

;; : (-> (Vector SourceLine) Definition (Maybe TypedContractEntry))
(def (typed-contract-block-entry/indexed line-vector definition)
  (let (block
        (typed-comment-block-before/indexed
         line-vector
         (fx1- (definition-start definition))))
    (typed-comment-block-signature-entry block)))

;; : (-> (Vector SourceLine) LineNumber (List TypedCommentLine))
(def (typed-comment-block-before/indexed line-vector line-number)
  (let ((current line-number)
        (entries '()))
    (while (and (> current 0)
                (typed-comment-line?
                 (line-vector-at* line-vector (fx1- current))))
      (set! entries
        (cons [current
               (typed-comment-text
                (line-vector-at* line-vector (fx1- current)))]
              entries))
      (set! current (fx1- current)))
    entries))

;; : (-> TypedContractEntry (List QualityFacet))
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet))
(def (typed-contract-entry-facets entry)
  (let (tail (cddddr entry))
    (if (pair? tail)
      (car tail)
      [])))

;; : (-> TypedContractEntry TypedCommentMetadata)
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata)
(def (typed-contract-entry-typed-comment entry)
  (let (tail (cddddr entry))
    (if (and (pair? tail) (pair? (cdr tail)))
      (cadr tail)
      (typed-comment-empty-metadata "scheme-native-block" (caddr entry)))))

;; : (-> TypedContractEntry (Tuple TypeExpr (List TypeExpr)))
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata ContractProjection)
(def (typed-contract-entry-projection entry)
  (let (tail (cddddr entry))
    (if (and (pair? tail) (pair? (cdr tail)) (pair? (cddr tail)))
      (caddr tail)
      (typed-contract-projection (caddr entry)))))

;; : (-> (List SourceLine) Definition (Maybe TypedContractEntry))
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata)
(def (typed-contract-block-entry lines definition)
  (let (block
        (typed-comment-block-before lines
                                    (fx1- (definition-start definition))))
    (typed-comment-block-signature-entry block)))

;;; Invariant:
;;; - typed-comment-block-before returns source-order entries.
;;; - The block is contiguous and immediately above the definition.
;; : (-> (List SourceLine) LineNumber (List TypedCommentLine))
;; | type TypedCommentLine = (Tuple LineNumber TypedCommentText)
(def (typed-comment-block-before lines line-number)
  (let ((current line-number)
        (entries '()))
    (while (and (> current 0)
                (typed-comment-line? (line-at* lines (fx1- current))))
      (set! entries
        (cons [current
               (typed-comment-text (line-at* lines (fx1- current)))]
              entries))
      (set! current (fx1- current)))
    entries))

;; : (-> SourceLine Boolean)
(def (typed-comment-line? line)
  (and (string? line)
       (let (trimmed (string-trim line))
         (and (string-prefix? ";;" trimmed)
              (not (string-prefix? ";;; -*-" trimmed))))))

;; : (-> SourceLine TypedCommentText)
(def (typed-comment-text line)
  (string-trim (string-trim (string-trim line) #\;)))

;; : (-> (List TypedCommentLine) (Maybe TypedContractEntry))
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata)
(def (typed-comment-block-signature-entry block)
  (typed-comment-block-signature-entry/cache block #f))

;; : (-> (List TypedCommentLine) (Maybe HashTable) (Maybe TypedContractEntry))
(def (typed-comment-last entries)
  (if (null? (cdr entries))
    (car entries)
    (typed-comment-last (cdr entries))))

(def (typed-comment-signature-starts block)
  (filter typed-comment-signature-start? block))

(def (typed-comment-signature-entry-text entry)
  (typed-comment-strip-signature-marker
   (string-trim (cadr entry))))

(def (typed-comment-forall-signature-entry? entry)
  (string-prefix? "(forall"
                  (typed-comment-signature-entry-text entry)))

(def (typed-comment-layered-signature-facets signature-starts signature-start)
  (let ((layered? (and (pair? signature-starts)
                       (pair? (cdr signature-starts))))
        (precision?
         (find (lambda (entry)
                 (and (< (car entry) (car signature-start))
                      (typed-comment-forall-signature-entry? entry)))
               signature-starts)))
    (append (if layered?
              ['typed-contract-layered-signature
               'typed-contract-summary-signature]
              [])
            (if precision?
              ['typed-contract-precision-signature]
              []))))

(def (typed-comment-block-signature-entry/cache block signature-analysis-cache)
  (let* ((signature-starts (typed-comment-signature-starts block))
         (signature-start (and (pair? signature-starts)
                               (typed-comment-last signature-starts))))
    (and signature-start
         (typed-comment-signature-entry/cache
          block
          signature-start
          signature-analysis-cache))))

;; : (-> TypedCommentLine Boolean)
(def (typed-comment-signature-start? entry)
  (string-prefix? ":" (string-trim (cadr entry))))

;; : (-> (List TypedCommentLine) TypedCommentLine TypedContractEntry)
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata)
(def (typed-comment-signature-entry block signature-start)
  (typed-comment-signature-entry/cache block signature-start #f))

;; : (-> HashTable SignatureContract SignatureAnalysis)
(def (scheme-type-signature-analysis/cached cache signature)
  (if cache
    (if (hash-key? cache signature)
      (hash-get cache signature)
      (let (analysis (scheme-type-signature-analysis signature))
        (hash-put! cache signature analysis)
        analysis))
    (scheme-type-signature-analysis signature)))

;; : (-> (List TypedCommentLine) TypedCommentLine (Maybe HashTable) TypedContractEntry)
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata)
(def (typed-comment-signature-entry/cache block signature-start signature-analysis-cache)
  (let* ((signature-entries
          (cons signature-start
                (take-while (lambda (entry)
                              (not (typed-comment-section-start? entry)))
                            (cdr (member signature-start block)))))
         (entries (member signature-start block))
         (section-entries (drop entries (length signature-entries)))
         (parts
          (filter-map
           (lambda (entry)
             (let* ((text (string-trim (cadr entry)))
                    (part (if (typed-comment-signature-start? entry)
                            (typed-comment-strip-signature-marker text)
                            text)))
               (and (not (string-empty? part)) part)))
           signature-entries))
         (signature (string-join parts " "))
         (sections (typed-comment-section-groups section-entries))
         (signature-analysis
          (scheme-type-signature-analysis/cached
           signature-analysis-cache
           signature))
         (signature-type (car signature-analysis))
         (signature-projection
          (or (cadr signature-analysis)
              [signature []]))
         (layered-facets
          (typed-comment-layered-signature-facets
           (typed-comment-signature-starts block)
           signature-start)))
    [(typed-comment-signature-comment-start block signature-start)
     (typed-comment-block-end-line entries)
     signature
     "scheme-native-block"
     (unique
      (append layered-facets
              (typed-comment-section-facets/groups sections)))
     (typed-comment-metadata/groups/signature-type
      block
      signature-start
      signature
      sections
      signature-type)
     signature-projection]))

;; : (-> (List TypedCommentLine) LineNumber)
(def (typed-comment-block-end-line entries)
  (car (last entries)))
