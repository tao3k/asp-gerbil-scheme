;;; -*- Gerbil -*-
;;; Parser-owned engineering comment quality facts.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/comment-quality-classifier
        :asp-gerbil-scheme/src/parser/model
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/1 drop-while iota take take-while)
        (only-in :std/srfi/13 string-contains string-downcase string-empty? string-prefix?)
        (only-in :std/sugar cut filter find hash ormap))

(export comment-quality-facts-from-source
        comment-quality-facts-from-lines)

(def +comment-quality-focus/module+
  "module responsibility, public boundary, package/import/export assumptions, and parser/policy ownership")
(def +comment-quality-focus/macro+
  "macro expansion boundary, hygiene assumptions, runtime-source witness, and safe edit constraints")
(def +comment-quality-focus/poo+
  "object/protocol/generic invariant, method specializers, and runtime witness boundary")
(def +comment-quality-focus/higher-order+
  "expression-level data flow, combinator choice, arity shape, and why the transform is safe")
(def +comment-quality-focus/control-flow+
  "state/control driver, branch invariants, loop or continuation reason, and exit conditions")
(def +comment-quality-focus/long-definition+
  "large-owner responsibility, branch/risk boundary, and intended optimization or decomposition pressure")
(def +comment-quality-focus/definition+
  "definition purpose, stable invariant, and non-obvious edit boundary")

(def +comment-quality-questions/module+
  ["What responsibility does this module own for the harness?"
   "Which package/import/export or runtime boundary must future edits preserve?"
   "Which parser-owned facts or policy outputs should an agent trust from this owner?"])
(def +comment-quality-questions/macro+
  ["What expansion or hygiene boundary does this macro enforce?"
   "Which runtime-source witness should be checked before editing the transformer?"
   "What generated shape or phase assumption would break downstream policy?"])
(def +comment-quality-questions/poo+
  ["What object, generic, method, or protocol contract is being implemented?"
   "Which receiver, specializer, slot, or protocol evidence constrains the edit?"
   "What runtime witness proves this is not a loose alist/hash object encoding?"])
(def +comment-quality-questions/higher-order+
  ["What data-flow transform does this expression-level combinator encode?"
   "Which arity/formal evidence makes map/filter/fold/cut/compose appropriate?"
   "What invariant would be hidden if this became a hand-written loop?"])
(def +comment-quality-questions/control-flow+
  ["What state, IO, generator, branch, or continuation driver requires explicit control flow?"
   "Which binding and body-shape facts bound the loop or match nesting?"
   "What exit or fallback condition should repairs preserve?"])
(def +comment-quality-questions/long-definition+
  ["What large-owner responsibility keeps this definition cohesive?"
   "Which branch, risk, or optimization boundary should repairs preserve?"
   "Which parser facts should guide a later split or simplification?"])
(def +comment-quality-questions/definition+
  ["What stable responsibility does this definition own?"
   "Which invariant or boundary is not obvious from the code mechanics?"
   "What parser fact should an agent use before rewriting this owner?"])

;;; Boundary:
;;; - comment-quality-facts-from-source composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; comment-quality-facts-from-source
;;   : (-> FullPath Relpath (List Definition) (List MacroFact) (List PooFormFact) (List HigherOrderFact) (List ControlFlowFact) (List CommentQualityFact) )
;;   | doc m%
;;       `comment-quality-facts-from-source fullpath relpath definitions macros poo-forms higher-order-forms control-flow-forms`
;;       emits one module-level comment fact plus definition-level facts keyed by
;;       parser-owned macro, POO, higher-order, and control-flow evidence.
;;
;;       # Examples
;;       ```scheme
;;       (map comment-quality-fact-target-kind
;;            (comment-quality-facts-from-source fullpath relpath [] [] [] [] []))
;;       ;; => ("module")
;;       ```
;;     %
(def (comment-quality-facts-from-source fullpath relpath definitions macros poo-forms higher-order-forms control-flow-forms)
  (let (lines (read-file-lines fullpath))
    (comment-quality-facts-from-lines
     lines relpath definitions macros poo-forms higher-order-forms control-flow-forms)))

;;; Boundary:
;;; - parse-source-file already owns source line IO; this helper keeps comment
;;;   quality extraction reusable without a second read-file-lines pass.
;; : (-> (List SourceLine) Relpath (List Definition) (List MacroFact) (List PooFormFact) (List HigherOrderFact) (List ControlFlowFact) (List CommentQualityFact) )
(def (comment-quality-facts-from-lines lines relpath definitions macros poo-forms higher-order-forms control-flow-forms)
  (let* ((module-fact (module-comment-quality-fact relpath lines))
         (line-vector (list->vector lines))
         (comment-index (leading-comment-lines-index line-vector))
         (macro-index (index-facts-by-field macro-fact-name macros))
         (poo-index (index-facts-by-field poo-form-fact-name poo-forms))
         (higher-order-index
          (index-facts-by-field higher-order-fact-caller higher-order-forms))
         (control-flow-index
          (index-facts-by-field control-flow-fact-caller control-flow-forms)))
    (cons module-fact
          (map (cut definition-comment-quality-fact/comment-indexed
                    relpath comment-index <>
                    macro-index poo-index
                    higher-order-index control-flow-index)
               definitions))))

;; : (-> Relpath (List SourceLine) CommentQualityFact )
(def (module-comment-quality-fact relpath lines)
  (let* ((comments (module-leading-comments lines))
         (summary (comment-quality-summary comments #t "module")))
    (make-comment-quality-fact
     "module" relpath relpath 1 1
     1 (max 1 (length comments))
     comments
     (vector-ref summary 0)
     (vector-ref summary 1)
     (vector-ref summary 2)
     #t
     "module"
     (module-comment-quality-evidence relpath lines comments))))

;;; Boundary:
;;; - definition-comment-quality-fact coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> Relpath (List SourceLine) Definition (List MacroFact) (List PooFormFact) (List HigherOrderFact) (List ControlFlowFact) CommentQualityFact )
(def (definition-comment-quality-fact relpath lines definition macros poo-forms higher-order-forms control-flow-forms)
  (definition-comment-quality-fact/indexed
   relpath
   (list->vector lines)
   definition
   (index-facts-by-field macro-fact-name macros)
   (index-facts-by-field poo-form-fact-name poo-forms)
   (index-facts-by-field higher-order-fact-caller higher-order-forms)
   (index-facts-by-field control-flow-fact-caller control-flow-forms)))

;; : (-> Relpath (Vector SourceLine) Definition HashTable HashTable HashTable HashTable CommentQualityFact )
(def (definition-comment-quality-fact/indexed relpath line-vector definition macro-index poo-index higher-order-index control-flow-index)
  (definition-comment-quality-fact/from-comments
   relpath
   definition
   (leading-comment-lines/indexed line-vector (definition-start definition))
   macro-index
   poo-index
   higher-order-index
   control-flow-index))

;; : (-> Relpath HashTable Definition HashTable HashTable HashTable HashTable CommentQualityFact )
(def (definition-comment-quality-fact/comment-indexed relpath comment-index definition macro-index poo-index higher-order-index control-flow-index)
  (definition-comment-quality-fact/from-comments
   relpath
   definition
   (indexed-comment-lines comment-index (definition-start definition))
   macro-index
   poo-index
   higher-order-index
   control-flow-index))

;; : (-> Relpath Definition (List CommentLine) HashTable HashTable HashTable HashTable CommentQualityFact )
(def (definition-comment-quality-fact/from-comments relpath definition comments macro-index poo-index higher-order-index control-flow-index)
  (let* ((context
          (definition-comment-context/indexed
           definition macro-index poo-index
           higher-order-index control-flow-index))
         (required (definition-comment-required? definition context))
         (summary (comment-quality-summary comments required context))
         (comment-start (if (null? comments)
                          (definition-start definition)
                          (- (definition-start definition)
                             (length comments))))
         (evidence (definition-comment-quality-evidence/indexed
                     definition context macro-index poo-index
                     higher-order-index control-flow-index comments)))
    (make-comment-quality-fact
     "definition"
     (definition-name definition)
     relpath
     (definition-start definition)
     (definition-end definition)
     comment-start
     (if (null? comments)
       (definition-start definition)
       (fx1- (definition-start definition)))
     comments
     (vector-ref summary 0)
     (vector-ref summary 1)
     (vector-ref summary 2)
     required
     context
     evidence)))

;; : (-> Relpath (List SourceLine) (List CommentLine) Json )
(def (module-comment-quality-evidence relpath lines comments)
  (hash (factSource "native-parser")
        (targetKind "module")
        (path relpath)
        (lineCount (length lines))
        (existingCommentLines comments)
        (existingCommentLineCount (length comments))
        (matchedFacts [])
        (commentFocus (comment-quality-context-focus "module"))
        (commentQuestions (comment-quality-context-questions "module"))
        (agentRepairMode "generate as many adjacent engineering comment lines as needed from parser evidence; completeness and confidence matter more than line count")))

;; : (-> Definition String (List MacroFact) (List PooFormFact) (List HigherOrderFact) (List ControlFlowFact) (List CommentLine) Json )
(def (definition-comment-quality-evidence definition context macros poo-forms higher-order-forms control-flow-forms comments)
  (let (matched-facts
        (definition-comment-matched-facts
          definition macros poo-forms higher-order-forms control-flow-forms))
    (hash (factSource "native-parser")
          (targetKind "definition")
          (definition (definition-name definition))
          (definitionKind (definition-kind definition))
          (definitionFormals (definition-formals definition))
          (definitionArity (definition-arity definition))
          (lineSpan (definition-line-span definition))
          (selector (definition-source-selector definition))
          (context context)
          (existingCommentLines comments)
          (existingCommentLineCount (length comments))
          (matchedFactCount (length matched-facts))
          (matchedFacts matched-facts)
          (commentFocus (comment-quality-context-focus context))
          (commentQuestions (comment-quality-context-questions context))
          (agentRepairMode "write as many adjacent comment lines as needed from these parser witnesses; preserve typed-contract comments as shape evidence, not rationale"))))

;; : (-> Definition String HashTable HashTable HashTable HashTable (List CommentLine) Json )
(def (definition-comment-quality-evidence/indexed definition context macro-index poo-index higher-order-index control-flow-index comments)
  (let (matched-facts
        (definition-comment-matched-facts/indexed
          definition macro-index poo-index higher-order-index control-flow-index))
    (hash (factSource "native-parser")
          (targetKind "definition")
          (definition (definition-name definition))
          (definitionKind (definition-kind definition))
          (definitionFormals (definition-formals definition))
          (definitionArity (definition-arity definition))
          (lineSpan (definition-line-span definition))
          (selector (definition-source-selector definition))
          (context context)
          (existingCommentLines comments)
          (existingCommentLineCount (length comments))
          (matchedFactCount (length matched-facts))
          (matchedFacts matched-facts)
          (commentFocus (comment-quality-context-focus context))
          (commentQuestions (comment-quality-context-questions context))
          (agentRepairMode "write as many adjacent comment lines as needed from these parser witnesses; preserve typed-contract comments as shape evidence, not rationale"))))

;;; Parser witness join: preserve owner/caller keyed joins so R015 can expose concrete macro, POO, higher-order, and control-flow evidence without source scanning.
;; : (-> Definition (List MacroFact) (List PooFormFact) (List HigherOrderFact) (List ControlFlowFact) (List Json) )
(def (definition-comment-matched-facts definition macros poo-forms higher-order-forms control-flow-forms)
  (let (name (definition-name definition))
     (append
      (let (facts (matching-macro-facts name macros))
        (map macro-comment-evidence
             (take facts (min 4 (length facts)))))
      (let (facts (matching-poo-facts name poo-forms))
        (map poo-comment-evidence
             (take facts (min 4 (length facts)))))
      (let (facts (matching-higher-order-facts name higher-order-forms))
        (map higher-order-comment-evidence
             (take facts (min 6 (length facts)))))
      (let (facts (matching-control-flow-facts name control-flow-forms))
        (map control-flow-comment-evidence
             (take facts (min 4 (length facts))))))))

;; : (-> Definition HashTable HashTable HashTable HashTable (List Json) )
(def (definition-comment-matched-facts/indexed definition macro-index poo-index higher-order-index control-flow-index)
  (let (name (definition-name definition))
    (append
     (let (facts (indexed-facts macro-index name))
       (map macro-comment-evidence
            (take facts (min 4 (length facts)))))
     (let (facts (indexed-facts poo-index name))
       (map poo-comment-evidence
            (take facts (min 4 (length facts)))))
     (let (facts (indexed-facts higher-order-index name))
       (map higher-order-comment-evidence
            (take facts (min 6 (length facts)))))
     (let (facts (indexed-facts control-flow-index name))
       (map control-flow-comment-evidence
            (take facts (min 4 (length facts))))))))

;; : (-> Procedure (List Fact) HashTable)
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

;; : (-> HashTable Value (List Fact))
(def (indexed-facts table key)
  (if (and key (hash-key? table key))
    (hash-get table key)
    '()))

;;; Parser-owned macro evidence is joined by definition name.
;;; Do not widen this into comment text or selector substring matching.
;; : (-> String (List MacroFact) (List MacroFact) )
(def (matching-macro-facts name facts)
  (facts-matching-field macro-fact-name name facts))

;;; POO evidence is joined by object/generic/protocol form name so comment repair can cite the declared language feature boundary.
;; : (-> String (List PooFormFact) (List PooFormFact) )
(def (matching-poo-facts name facts)
  (facts-matching-field poo-form-fact-name name facts))

;;; Higher-order evidence is joined by caller, which preserves the expression-level combinator witness for comment generation.
;; : (-> String (List HigherOrderFact) (List HigherOrderFact) )
(def (matching-higher-order-facts name facts)
  (facts-matching-field higher-order-fact-caller name facts))

;;; Control-flow evidence is joined by caller so loop, match, continuation, and resource-driver comments stay tied to parsed facts.
;; : (-> String (List ControlFlowFact) (List ControlFlowFact) )
(def (matching-control-flow-facts name facts)
  (facts-matching-field control-flow-fact-caller name facts))

;; : (-> MacroFact Json )
(def (macro-comment-evidence fact)
  (hash (factKind "macro")
        (name (macro-fact-name fact))
        (formKind (macro-fact-kind fact))
        (transformer (macro-fact-transformer fact))
        (phase (macro-fact-phase fact))
        (patternCount (macro-fact-pattern-count fact))
        (hygienicSyntax (macro-fact-hygienic fact))
        (qualityFacets (macro-fact-quality-facets fact))
        (selector (fact-source-selector (macro-fact-path fact)
                                        (macro-fact-start fact)
                                        (macro-fact-end fact)))))

;; : (-> PooFormFact Json )
(def (poo-comment-evidence fact)
  (hash (factKind "poo")
        (name (poo-form-fact-name fact))
        (formKind (poo-form-fact-kind fact))
        (role (poo-form-fact-role fact))
        (generic (or (poo-form-fact-generic fact) ""))
        (receiver (or (poo-form-fact-receiver fact) ""))
        (receiverType (or (poo-form-fact-receiver-type fact) ""))
        (supers (poo-form-fact-supers fact))
        (slots (poo-form-fact-slots fact))
        (specializers (poo-form-fact-specializers fact))
        (specializerTypes (poo-form-fact-specializer-types fact))
        (selector (fact-source-selector (poo-form-fact-path fact)
                                        (poo-form-fact-start fact)
                                        (poo-form-fact-end fact)))))

;; : (-> HigherOrderFact Json )
(def (higher-order-comment-evidence fact)
  (hash (factKind "higher-order")
        (name (higher-order-fact-name fact))
        (formKind (higher-order-fact-kind fact))
        (role (higher-order-fact-role fact))
        (operandCount (higher-order-fact-operand-count fact))
        (arities (higher-order-fact-arities fact))
        (formals (higher-order-fact-formals fact))
        (caller (or (higher-order-fact-caller fact) ""))
        (selector (fact-source-selector (higher-order-fact-path fact)
                                        (higher-order-fact-start fact)
                                        (higher-order-fact-end fact)))))

;; : (-> ControlFlowFact Json )
(def (control-flow-comment-evidence fact)
  (hash (factKind "control-flow")
        (name (control-flow-fact-name fact))
        (formKind (control-flow-fact-kind fact))
        (role (control-flow-fact-role fact))
        (caller (or (control-flow-fact-caller fact) ""))
        (bindingCount (control-flow-fact-binding-count fact))
        (bodyFormCount (control-flow-fact-body-form-count fact))
        (selector (fact-source-selector (control-flow-fact-path fact)
                                        (control-flow-fact-start fact)
                                        (control-flow-fact-end fact)))))

;; : (-> String String )
(def (comment-quality-context-focus context)
  (cond
   ((equal? context "module")
    +comment-quality-focus/module+)
   ((equal? context "macro")
    +comment-quality-focus/macro+)
   ((equal? context "poo")
    +comment-quality-focus/poo+)
   ((equal? context "higher-order")
    +comment-quality-focus/higher-order+)
   ((equal? context "control-flow")
    +comment-quality-focus/control-flow+)
   ((equal? context "long-definition")
    +comment-quality-focus/long-definition+)
   (else
    +comment-quality-focus/definition+)))

;; comment-quality-context-questions
;;   : (-> String (List String))
;;   | doc m%
;;       `comment-quality-context-questions context` returns the parser-evidence
;;       questions an agent must cover before writing comment rationale for a
;;       context.
;;
;;       # Examples
;;
;;       ```scheme
;;       (comment-quality-context-questions "macro")
;;       ;; => macro evidence questions
;;       ```
;;     %
(def (comment-quality-context-questions context)
  (cond
   ((equal? context "module")
    +comment-quality-questions/module+)
   ((equal? context "macro")
    +comment-quality-questions/macro+)
   ((equal? context "poo")
    +comment-quality-questions/poo+)
   ((equal? context "higher-order")
    +comment-quality-questions/higher-order+)
   ((equal? context "control-flow")
    +comment-quality-questions/control-flow+)
   ((equal? context "long-definition")
    +comment-quality-questions/long-definition+)
   (else
    +comment-quality-questions/definition+)))

;; : (-> Definition Selector )
(def (definition-source-selector definition)
  (fact-source-selector (definition-path definition)
                        (definition-start definition)
                        (definition-end definition)))

;; : (-> Path SourceLine SourceLine Selector )
(def (fact-source-selector path start end)
  (string-append path ":" (number->string start) "-" (number->string end)))

;; module-leading-comments
;;   : (-> (List SourceLine) (List CommentLine))
;;   | doc m%
;;       `module-leading-comments lines` returns the leading engineering
;;       comments for a module, skipping shebang and mode-comment headers.
;;
;;       # Examples
;;
;;       ```scheme
;;       (module-leading-comments '(";;; -*- Gerbil -*-" ";;; Purpose." ""))
;;       ;; => ("Purpose.")
;;       ```
;;     %
(def (module-leading-comments lines)
  (map (lambda (entry) (comment-body (cdr entry)))
       (take-while
        (lambda (entry) (engineering-comment-line? (cdr entry)))
        (drop-while
         (lambda (entry)
           (let ((line-number (car entry))
                 (line (cdr entry)))
             (or (script-header-line? line line-number)
                 (blank-string? line))))
         (map cons (iota (length lines) 1) lines)))))

;;; Boundary:
;;; - Script shebangs and Gerbil mode comments are transport headers.
;;; - They must not hide the module-level engineering comment immediately below.
;; : (-> SourceLine SourceLineNumber Boolean)
(def (script-header-line? line line-number)
  (or (mode-comment-line? line)
      (and (= line-number 1)
           (string? line)
           (string-prefix? "#!" line))))

;; leading-comment-lines
;;   : (-> (List SourceLine) SourceLineNumber (List CommentLine))
;;   | doc m%
;;       `leading-comment-lines lines start-line` walks upward from a definition
;;       start line and returns adjacent leading comment lines in source order.
;;
;;       # Examples
;;
;;       ```scheme
;;       (leading-comment-lines '(";; helper" "(def helper 1)") 2)
;;       ;; => ("helper")
;;       ```
;;     %
(def (leading-comment-lines lines start-line)
  (map comment-body
       (take-while
        comment-line?
        (map (lambda (line-number)
               (line-at* lines (fx1- line-number)))
             (reverse (iota (max 0 (fx1- start-line)) 1))))))

;; leading-comment-lines/indexed
;;   : (-> (Vector SourceLine) SourceLineNumber (List CommentLine))
;;   | doc m%
;;       `leading-comment-lines/indexed` returns the contiguous comment block
;;       immediately above `start-line`, preserving source order while using the
;;       indexed source-line vector.
;;
;;       # Examples
;;
;;       ```scheme
;;       (leading-comment-lines/indexed '#(";; helper" "(def helper 1)") 2)
;;       ;; => ("helper")
;;       ```
;;     %
(def (leading-comment-lines/indexed line-vector start-line)
  (reverse
   (map comment-body
        (take-while
         comment-line?
         (map (lambda (line-number)
                (line-at-vector* line-vector (fx1- line-number)))
              (reverse (iota (max 0 (fx1- start-line)) 1)))))))

;;; Source-line comment index:
;;; - Build contiguous leading comment blocks once per file.
;;; - Definition-level quality facts then use an O(1) start-line lookup instead
;;;   of rebuilding `iota/reverse/map/take-while` for every definition.
;; : (-> (Vector SourceLine) HashTable)
(def (leading-comment-lines-index line-vector)
  (let ((table (make-hash-table))
        (line-count (vector-length line-vector))
        (block-rev '()))
    (def (flush! next-line)
      (when (pair? block-rev)
        (hash-put! table next-line (reverse block-rev))
        (set! block-rev '())))
    (let loop ((line-number 1))
      (if (> line-number line-count)
        (begin
          (flush! (fx1+ line-count))
          table)
        (let (line (line-at-vector* line-vector (fx1- line-number)))
          (if (comment-line? line)
            (begin
              (set! block-rev (cons (comment-body line) block-rev))
              (loop (fx1+ line-number)))
            (begin
              (flush! line-number)
              (loop (fx1+ line-number)))))))))

;; : (-> HashTable SourceLineNumber (List CommentLine))
(def (indexed-comment-lines comment-index start-line)
  (if (hash-key? comment-index start-line)
    (hash-get comment-index start-line)
    '()))

;; : (-> Definition (List MacroFact) (List PooFormFact) (List HigherOrderFact) (List ControlFlowFact) String )
(def (definition-comment-context definition macros poo-forms higher-order-forms control-flow-forms)
  (let ((name (definition-name definition))
        (kind (definition-kind definition)))
    (cond
     ((definition-name-in-macros? name macros) "macro")
     ((or (member kind '("defclass" "defgeneric" "defmethod" "defprotocol"))
          (definition-name-in-poo-forms? name poo-forms))
      "poo")
     ((>= (definition-line-span definition) 60) "long-definition")
     ((definition-name-in-higher-order-forms? name higher-order-forms)
      "higher-order")
     ((definition-name-in-control-flow-forms? name control-flow-forms)
      "control-flow")
     (else "definition"))))
;; : (-> Definition HashTable HashTable HashTable HashTable String )
(def (definition-comment-context/indexed definition macro-index poo-index higher-order-index control-flow-index)
  (let ((name (definition-name definition))
        (kind (definition-kind definition)))
    (cond
     ((not (null? (indexed-facts macro-index name))) "macro")
     ((or (member kind '("defclass" "defgeneric" "defmethod" "defprotocol"))
          (not (null? (indexed-facts poo-index name))))
      "poo")
     ((>= (definition-line-span definition) 60) "long-definition")
     ((not (null? (indexed-facts higher-order-index name)))
      "higher-order")
     ((not (null? (indexed-facts control-flow-index name)))
      "control-flow")
     (else "definition"))))
