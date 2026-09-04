;;; -*- Gerbil -*-
;;; Indexed adjacent typed-comment ownership and projection.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/typed-comment-metadata
        :asp-gerbil-scheme/src/parser/typed-contract-diagnostics
        :asp-gerbil-scheme/src/parser/typed-contract-scheme
        (only-in :std/srfi/13 string-join string-empty? string-prefix?)
        (only-in :std/srfi/1 last take-while)
        (only-in :std/misc/list unique)
        (only-in :std/sugar filter filter-map find while))

(export typed-contract-entry-index/definitions
        typed-contract-entry-index-count
        typed-contract-entry-for-definition
        typed-contract-entry-near-definition
        typed-contract-entry-near-definition/indexed
        typed-contract-entry-facets
        typed-contract-entry-typed-comment
        typed-contract-entry-projection)

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
       (let* ((length (string-length line))
              (start
               (let loop ((index 0))
                 (if (and (< index length)
                          (char-whitespace? (string-ref line index)))
                   (loop (fx1+ index))
                   index)))
              (trimmed-left (substring line start length)))
         (and (string-prefix? ";;" trimmed-left)
              (not (string-prefix? ";;; -*-" trimmed-left))))))

;; : (-> SourceLine TypedCommentText)
(def (typed-comment-text line)
  (let* ((length (string-length line))
         (content-start
          (let loop ((index 0))
            (if (and (< index length)
                     (or (char-whitespace? (string-ref line index))
                         (char=? (string-ref line index) #\;)))
              (loop (fx1+ index))
              index)))
         (content-end
          (let loop ((index length))
            (if (and (> index content-start)
                     (char-whitespace? (string-ref line (fx1- index))))
              (loop (fx1- index))
              index))))
    (substring line content-start content-end)))

;; : (-> String String)
(def (typed-comment-trim value)
  (let* ((length (string-length value))
         (start
          (let loop ((index 0))
            (if (and (< index length)
                     (char-whitespace? (string-ref value index)))
              (loop (fx1+ index))
              index)))
         (end
          (let loop ((index length))
            (if (and (> index start)
                     (char-whitespace? (string-ref value (fx1- index))))
              (loop (fx1- index))
              index))))
    (substring value start end)))

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
   (typed-comment-trim (cadr entry))))

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
  (string-prefix? ":" (typed-comment-trim (cadr entry))))

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
             (let* ((text (typed-comment-trim (cadr entry)))
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
