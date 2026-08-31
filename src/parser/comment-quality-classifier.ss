;;; -*- Gerbil -*-
;;; Comment quality classification and source-line helpers.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/model
        (only-in :std/srfi/13 string-contains string-downcase string-empty? string-prefix?)
        (only-in :std/sugar cut filter find ormap))

(export facts-matching-field
        definition-comment-required?
        comment-quality-summary
        definition-name-in-macros?
        definition-name-in-poo-forms?
        definition-name-in-higher-order-forms?
        definition-name-in-control-flow-forms?
        comment-line?
        engineering-comment-line?
        mode-comment-line?
        comment-body
        trim-ascii-space
        definition-line-span
        line-at*
        line-at-vector*
        blank-string?)

;;; Fact-field matching is the shared join primitive for parser witness lists.
;;; Keep the field accessor explicit so macro, POO, higher-order, and control-flow
;;; joins stay domain-named without duplicating the predicate body.
;; : (-> (-> Fact Value) Value (List Fact) (List Fact))
(def (facts-matching-field accessor expected facts)
  (filter (cut fact-field-equal? accessor expected <>)
          facts))

;; : (-> (-> Fact Value) Value (List Fact) Boolean)
;;; Boolean witness checks share the same accessor contract as list joins so
;;; context classification cannot drift from comment evidence selection.
(def (any-fact-matching-field? accessor expected facts)
  (ormap (cut fact-field-equal? accessor expected <>)
         facts))

;; : (-> (-> Fact Value) Value Fact Boolean)
;;; Keep equality in one predicate so future nil/alias normalization has one
;;; parser-owned boundary instead of four duplicated fact-specific lambdas.
(def (fact-field-equal? accessor expected fact)
  (equal? (accessor fact) expected))

;; : (-> Definition String Boolean )
(def (definition-comment-required? definition context)
  (or (member (definition-kind definition)
              '("defrule" "defsyntax" "defclass" "defgeneric" "defmethod" "defprotocol"))
      (member context
              '("macro" "poo" "long-definition"))))

;; : (-> (List CommentLine) Boolean String CommentSummary )
(def (comment-quality-summary comments required context)
  (let* ((kind (comment-kind comments))
         (quality (comment-quality kind required))
         (reasons (comment-quality-reasons kind quality required context)))
    (vector kind quality reasons)))

;;; Boundary:
;;; - comment-kind composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List CommentLine) String )
(def (comment-kind comments)
  (cond
   ((null? comments) "missing")
   ((compressed-engineering-comments? comments) "compressed-engineering")
   ((ormap engineering-boundary-comment? comments) "boundary")
   ((ormap engineering-invariant-comment? comments) "invariant")
   ((ormap engineering-optimization-comment? comments) "optimization")
   ((ormap engineering-risk-comment? comments) "risk")
   ((ormap engineering-intent-comment? comments) "intent")
   ((ormap typed-contract-comment? comments) "contract-only")
   (else "weak")))

;; : (-> String Boolean String )
(def (comment-quality kind required)
  (cond
   ((equal? kind "missing") "absent")
   ((equal? kind "contract-only") "weak")
   ((equal? kind "compressed-engineering") "weak")
   ((equal? kind "weak") "weak")
   ((member kind '("boundary" "invariant" "optimization" "risk"))
    "engineering-grade")
   ((equal? kind "intent") "useful")
   (else "useful")))

;; : (-> String String Boolean String (List Reason) )
(def (comment-quality-reasons kind quality required context)
  (cond
   ((equal? quality "absent")
    ["missing-engineering-comment"])
   ((equal? kind "contract-only")
    ["contract-only-is-not-engineering-comment"])
   ((equal? kind "compressed-engineering")
    ["compressed-engineering-comment-needs-adjacent-lines"])
   ((and required (equal? quality "useful"))
    [(string-append "missing-" context "-boundary-comment")])
   ((equal? quality "weak")
    ["weak-engineering-comment"])
   (else [])))

;;; Boundary:
;;; - Typed contract detection owns algebraic shape only.
;;; - Engineering-rationale classification stays separate from type signatures.
;;; Invariant:
;;; - A contract comment cannot satisfy key-owner rationale by itself.
;; : (-> CommentLine Boolean )
(def (typed-contract-comment? comment)
  (or (string-contains comment "<-")
      (string-prefix? ":" (trim-ascii-space comment))
      (typed-doc-result-comment? comment)))

;;; Boundary:
;;; - Full-form typed docs may embed Scheme comments inside fenced examples.
;;; - Result markers such as `;; => value` are typed-doc evidence, not rationale.
;; : (-> CommentLine Boolean)
(def (typed-doc-result-comment? comment)
  (let (trimmed (trim-ascii-space comment))
    (or (string-prefix? ";; =>" trimmed)
        (string-prefix? "=>" trimmed))))

;;; Boundary:
;;; - Compressed engineering comments hide separate rationale clauses in one line.
;;; - Keep separate rationale clauses on adjacent lines when splitting improves evidence confidence.
;; : (-> (List CommentLine) Boolean )
(def (compressed-engineering-comments? comments)
  (and (single-engineering-comment-body? comments)
       (ormap compressed-engineering-comment? comments)))

;;; Boundary:
;;; - Compression only applies when one prose line carries all rationale.
;;; - Structured multi-line Boundary or Invariant comments remain engineering-grade.
;; : (-> (List CommentLine) Boolean )
(def (single-engineering-comment-body? comments)
  (= (length (filter engineering-comment-body? comments)) 1))

;;; Boundary:
;;; - A semicolon inside the comment body usually means two rationale clauses were squeezed together.
;;; - Agents should split those clauses rather than forcing every rationale into one line.
;; : (-> CommentLine Boolean )
(def (compressed-engineering-comment? comment)
  (and (engineering-comment-body? comment)
       (comment-rationale-semicolon? comment)))

;; comment-rationale-semicolon?
;;   : (-> CommentLine Boolean)
;;   | rationale A single engineering comment line with prose semicolons is
;;       usually compressed rationale, but repeated Scheme comment markers are
;;       not compression.
;;   | doc m%
;;       `comment-rationale-semicolon?` detects a semicolon that separates prose
;;       clauses inside one engineering comment body.
;;
;;       # Examples
;;
;;       ```scheme
;;       (comment-rationale-semicolon? "Boundary: parse first; emit later")
;;       ;; => #t
;;       ```
;;     %
(def (comment-rationale-semicolon? comment)
  (let (length (string-length comment))
    (let loop ((index 0))
      (and (< index length)
           (if (char=? (string-ref comment index) #\;)
             (or (not (comment-semicolon-neighbor?
                       comment
                       length
                       index))
                 (loop (fx1+ index)))
             (loop (fx1+ index)))))))

;; : (-> CommentLine Integer Integer Boolean)
(def (comment-semicolon-neighbor? comment length index)
  (or (and (> index 0)
           (char=? (string-ref comment (fx1- index)) #\;))
      (and (< (fx1+ index) length)
           (char=? (string-ref comment (fx1+ index)) #\;))))

;; : (-> CommentLine Boolean )
(def (engineering-intent-comment? comment)
  (and (engineering-comment-body? comment)
       (or (comment-contains-any? comment '("intent" "purpose" "why" "because" "agent" "parser" "semantic" "source"))
           (>= (string-length (trim-ascii-space comment)) 36))))

;; : (-> CommentLine Boolean )
(def (engineering-boundary-comment? comment)
  (comment-contains-any? comment '("boundary" "facade" "runtime" "provider" "parser-owned" "source-class" "scope" "contract-visible")))

;; : (-> CommentLine Boolean )
(def (engineering-invariant-comment? comment)
  (comment-contains-any? comment '("invariant" "preserve" "must" "never" "stable" "deterministic")))

;; : (-> CommentLine Boolean )
(def (engineering-optimization-comment? comment)
  (comment-contains-any? comment '("optimization" "fast path" "common case" "specialized" "avoid allocation" "performance")))

;; : (-> CommentLine Boolean )
(def (engineering-risk-comment? comment)
  (comment-contains-any? comment '("risk" "unsafe" "fallback" "avoid" "denied" "drift" "ambiguous")))

;; : (-> CommentLine Boolean )
(def (engineering-comment-body? comment)
  (and (string? comment)
       (not (blank-string? comment))
       (not (typed-contract-comment? comment))))

;;; Boundary:
;;; - comment-contains-any? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> String (List String) Boolean )
(def (comment-contains-any? comment needles)
  (and (string? comment)
       (let (downcased (string-downcase comment))
         (ormap (lambda (needle)
                  (string-contains downcased needle))
                needles))))

;;; Boundary:
;;; - definition-name-in-macros? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> String (List MacroFact) Boolean )
(def (definition-name-in-macros? name macros)
  (any-fact-matching-field? macro-fact-name name macros))

;;; Boundary:
;;; - definition-name-in-poo-forms? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> String (List PooFormFact) Boolean )
(def (definition-name-in-poo-forms? name poo-forms)
  (any-fact-matching-field? poo-form-fact-name name poo-forms))

;;; Boundary:
;;; - definition-name-in-higher-order-forms? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> String (List HigherOrderFact) Boolean )
(def (definition-name-in-higher-order-forms? name higher-order-forms)
  (any-fact-matching-field? higher-order-fact-caller name higher-order-forms))

;;; Boundary:
;;; - definition-name-in-control-flow-forms? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> String (List ControlFlowFact) Boolean )
(def (definition-name-in-control-flow-forms? name control-flow-forms)
  (any-fact-matching-field? control-flow-fact-caller name control-flow-forms))

;; : (-> SourceLine Boolean )
(def (comment-line? line)
  (and (string? line)
       (let (trimmed (trim-ascii-space line))
         (and (string-prefix? ";;" trimmed)
              (not (mode-comment-line? trimmed))))))

;; : (-> SourceLine Boolean )
(def (engineering-comment-line? line)
  (and (string? line)
       (let (trimmed (trim-ascii-space line))
         (and (string-prefix? ";;;" trimmed)
              (not (mode-comment-line? trimmed))))))

;; : (-> SourceLine Boolean )
(def (mode-comment-line? line)
  (and (string? line)
       (string-prefix? ";;; -*-" (trim-ascii-space line))))

;; : (-> SourceLine CommentLine )
(def (comment-body line)
  (trim-ascii-space (drop-leading-semicolons (trim-ascii-space line))))

;;; Gerbil-utils contains high-codepoint prose in comments; SRFI-13 trim can throw on those bytes in this runtime path.
;;; Keep parser-owned comment facts robust by trimming only ASCII whitespace around the line.
;; : (-> String String )
(def (trim-ascii-space text)
  (if (string? text)
    (let* ((length (string-length text))
           (start (first-non-ascii-space text length))
           (end (last-non-ascii-space text start length)))
      (substring text start end))
    ""))

;; first-non-ascii-space
;;   : (-> SourceLine SourceLength Integer )
;;   | rationale Keep SRFI-13 character-set conversion out of the comment trim
;;       path while preserving high-codepoint prose.
;;   | doc m%
;;       `first-non-ascii-space` returns the left trim boundary for ASCII
;;       whitespace only.
;;
;;       # Examples
;;
;;       ```scheme
;;       (first-non-ascii-space "  body" 6)
;;       ;; => 2
;;       ```
;;     %
(def (first-non-ascii-space text length)
  (let loop ((index 0))
    (cond
     ((>= index length) length)
     ((ascii-space? (string-ref text index))
      (loop (fx1+ index)))
     (else index))))

;; last-non-ascii-space
;;   : (-> SourceLine TrimStart SourceLength Integer )
;;   | rationale The caller-provided left boundary prevents the right scan from
;;       crossing already-trimmed content.
;;   | doc m%
;;       `last-non-ascii-space` returns the exclusive right trim boundary for
;;       ASCII whitespace only.
;;
;;       # Examples
;;
;;       ```scheme
;;       (last-non-ascii-space "body  " 0 6)
;;       ;; => 4
;;       ```
;;     %
(def (last-non-ascii-space text start length)
  (let loop ((index (fx1- length)))
    (cond
     ((< index start) start)
     ((ascii-space? (string-ref text index))
      (loop (fx1- index)))
     (else (fx1+ index)))))

;; : (-> Character Boolean )
(def (ascii-space? ch)
  (or (char=? ch #\space)
      (char=? ch #\tab)
      (char=? ch #\newline)
      (char=? ch #\return)))

;; drop-leading-semicolons
;;   : (-> SourceLine SourceLine )
;;   | rationale Comment marker removal should not trim or normalize the body;
;;       later trimming owns whitespace policy.
;;   | doc m%
;;       `drop-leading-semicolons` removes the leading Scheme comment marker run
;;       and returns the remaining body unchanged.
;;
;;       # Examples
;;
;;       ```scheme
;;       (drop-leading-semicolons ";;; Boundary")
;;       ;; => " Boundary"
;;       ```
;;     %
(def (drop-leading-semicolons text)
  (let (length (string-length text))
    (let loop ((index 0))
      (if (and (< index length)
               (char=? (string-ref text index) #\;))
        (loop (fx1+ index))
        (substring text index length)))))

;; : (-> Definition Integer )
(def (definition-line-span definition)
  (fx1+ (- (definition-end definition)
           (definition-start definition))))

;;; Boundary:
;;; - line-at* is zero-based and total over malformed indices.
;;; - Guard before list-ref so parser facts never raise on drifted line spans.
;; : (-> (List SourceLine) Integer SourceLine )
(def (line-at* lines index)
  (and (>= index 0)
       (< index (length lines))
       (list-ref lines index)))

;; : (-> (Vector SourceLine) Integer SourceLine )
(def (line-at-vector* line-vector index)
  (and (>= index 0)
       (< index (vector-length line-vector))
       (vector-ref line-vector index)))

;; : (-> String Boolean )
(def (blank-string? value)
  (or (not (string? value))
      (string-empty? (trim-ascii-space value))))
