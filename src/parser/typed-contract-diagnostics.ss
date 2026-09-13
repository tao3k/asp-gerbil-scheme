;;; -*- Gerbil -*-
;;; Typed contract signature diagnostics and token projection helpers.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/typed-comment-metadata
        :asp-gerbil-scheme/src/parser/typed-contract-scheme
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13
                 string-contains
                 string-empty?
                 string-every
                 string-prefix?
                 string-trim)
        (only-in :std/sugar cut filter-map find ormap while))

(export typed-contract-invalid-reasons
        typed-contract-quality
        typed-contract-arity-alignment
        typed-contract-tokens
        typed-contract-projection
        typed-contract-output
        typed-contract-inputs
        line-at*
        line-vector-at*)

;;; Known domain tokens are split by role so signature validation can explain
;;; whether a name is a container or scalar without growing token predicates.
;; (List SignatureToken)
(def +typed-contract-container-tokens+ '("List" "Maybe" "NonEmptyList" "Vector" "Hash"))
;; (List SignatureToken)
(def +typed-contract-scalar-tokens+ '("Boolean" "String" "Integer" "Number" "Unit" "Character"))

;; : (-> Boolean SignatureReason (List SignatureReason) )
(def (signature-reason-when condition reason)
  (if condition [reason] []))


;; : (-> Definition SignatureContract (List SignatureToken) Integer Integer (List SignatureReason) )
;;; Structural TypeSpec diagnostics are folded into the same invalid-reason
;;; channel as token evidence. Policy can then reject pseudo typed comments
;;; without reparsing source text or hard-coding suspicious type names.
;; : (-> Definition SignatureContract TypeExpr (List TypeExpr) TypedCommentMetadata (List SignatureToken) Integer Integer (List SignatureReason) )
(def (typed-contract-invalid-reasons definition contract contract-output contract-inputs typed-comment tokens arrow-count group-count)
  (unique
   (append
    (signature-reason-when
     (string-contains contract ";")
     "inline-comment")
    (signature-reason-when
     (and (= arrow-count 0)
          (typed-contract-transform-definition? definition))
     "missing-transform-arrow")
    (signature-reason-when
     (typed-contract-unknown-token? tokens)
     "unknown-or-any-token")
    (signature-reason-when
     (typed-contract-placeholder-token-invalid? tokens arrow-count group-count)
     "placeholder-type-variable-token")
    (signature-reason-when
     (typed-contract-simple-placeholder? tokens arrow-count group-count)
     "placeholder-contract-without-domain-or-higher-order-shape")
    (typed-contract-structural-invalid-reasons contract-output
                                               contract-inputs
                                               typed-comment
                                               arrow-count))))

;;; Full-form `;; :` blocks carry parser-owned TypeSpec diagnostics in
;;; typed-comment metadata; declaration contracts are validated through their
;;; projected input/output expressions.
;; : (-> TypeExpr (List TypeExpr) TypedCommentMetadata Integer (List SignatureReason) )
(def (typed-contract-structural-invalid-reasons contract-output contract-inputs typed-comment arrow-count)
  (append
   (if (and (> arrow-count 0)
            (typed-comment-signature-type typed-comment))
     (typed-comment-structural-invalid-reasons typed-comment)
     (typed-contract-expression-invalid-reasons contract-output contract-inputs))
   (typed-comment-local-type-invalid-reasons typed-comment)))

;; : (-> TypedCommentMetadata MaybeJson )
(def (typed-comment-signature-type typed-comment)
  (and typed-comment
       (hash-get typed-comment 'signatureType)))

;; : (-> TypedCommentMetadata (List Json) )
(def (typed-comment-signature-types typed-comment)
  (if typed-comment
    (let (signature-types (hash-get typed-comment 'signatureTypes))
      (if (pair? signature-types)
        signature-types
        (let (signature-type (typed-comment-signature-type typed-comment))
          (if signature-type [signature-type] []))))
    []))

;;; Boundary:
;;; - Doc metadata syntax owns the =m%= fence marker.
;;; - A value such as =100%= is a malformed marker, not a documentation score.
;; : (-> TypedCommentMetadata (List SignatureReason) )
(def (typed-comment-structural-invalid-reasons typed-comment)
  (append
   (typed-comment-signature-types-invalid-reasons typed-comment)
   (typed-comment-runtime-contract-invalid-reasons typed-comment)
   (filter-map
    (lambda (doc)
      (let (marker (hash-get doc 'marker))
        (and marker
             (not (equal? marker ""))
             (not (equal? marker "m%"))
             (string-append "doc-marker-invalid:" marker))))
    (if typed-comment
      (or (hash-get typed-comment 'docs) [])
       []))))

;; : (-> TypedCommentMetadata (List SignatureReason) )
(def (typed-comment-signature-types-invalid-reasons typed-comment)
  (typed-comment-signature-types-invalid-reasons*
   (typed-comment-signature-types typed-comment)
   0))

;; : (-> (List Json) Integer (List SignatureReason) )
(def (typed-comment-signature-types-invalid-reasons* signature-types index)
  (if (null? signature-types)
    []
    (append
     (typed-contract-json-invalid-reasons
      (string-append "type-signature[" (number->string index) "]")
      (car signature-types))
     (typed-comment-signature-types-invalid-reasons*
      (cdr signature-types)
      (fx1+ index)))))

;; : (-> TypedCommentMetadata (List SignatureReason) )
(def (typed-comment-runtime-contract-invalid-reasons typed-comment)
  (typed-comment-runtime-contract-invalid-reasons*
   (if typed-comment
     (or (hash-get typed-comment 'runtimeContractsDetailed) [])
     [])
   0))

;; : (-> (List Json) Integer (List SignatureReason) )
(def (typed-comment-runtime-contract-invalid-reasons* contracts index)
  (if (null? contracts)
    []
    (append
     (typed-contract-json-invalid-reasons
      (string-append "runtime-contract[" (number->string index) "]")
      (car contracts))
     (typed-comment-runtime-contract-invalid-reasons*
      (cdr contracts)
      (fx1+ index)))))

;;; Local type aliases are already section-parsed by typed-comment metadata.
;;; Mapping each section independently preserves the alias name in the repair
;;; reason prefix instead of collapsing all alias diagnostics into one bucket.
;; : (-> TypedCommentMetadata (List SignatureReason) )
(def (typed-comment-local-type-invalid-reasons typed-comment)
  (apply append
         (map typed-comment-local-type-invalid-reasons*
              (if typed-comment
                (or (hash-get typed-comment 'localTypes) [])
                []))))

;; : (-> Json (List SignatureReason) )
(def (typed-comment-local-type-invalid-reasons* local-type)
  (typed-contract-json-invalid-reasons
   (string-append "local-type:" (or (hash-get local-type 'name) "<anonymous>"))
   (hash-get local-type 'expressionType)))

;;; Projected contracts have separate output and input expressions. The indexed
;;; map keeps input-position diagnostics stable so agents can fix malformed type
;;; expressions without guessing which parameter failed.
;; : (-> TypeExpr (List TypeExpr) (List SignatureReason) )
(def (typed-contract-expression-invalid-reasons contract-output contract-inputs)
  (append
   (typed-contract-type-expression-invalid-reasons "type-output" contract-output)
   (apply append
          (map (lambda (entry)
                 (typed-contract-type-expression-invalid-reasons
                  (string-append "type-input[" (number->string (car entry)) "]")
                  (cdr entry)))
               (typed-contract-indexed-inputs contract-inputs 0)))))

;; : (-> TypeExprIndex (List TypeExpr) (List (Pair Integer TypeExpr)) )
(def (typed-contract-indexed-inputs inputs index)
  (if (null? inputs)
    []
    (cons (cons index (car inputs))
          (typed-contract-indexed-inputs (cdr inputs) (fx1+ index)))))

;; : (-> SignatureReasonPrefix TypeExpr (List SignatureReason) )
(def (typed-contract-type-expression-invalid-reasons prefix expression)
  (typed-contract-json-invalid-reasons
   prefix
   (scheme-type-expression-text-json expression)))

;;; This is the final diagnostic-to-policy bridge.
;;; It prefixes parser-owned TypeSpec diagnostics with their comment location
;;; class, so policy can group repairs without re-inspecting comment text.
;; : (-> SignatureReasonPrefix Json (List SignatureReason) )
(def (typed-contract-json-invalid-reasons prefix json)
  (map (cut string-append prefix ":" <>)
       (typed-contract-json-diagnostics json)))

;; : (-> Json (List Diagnostic) )
(def (typed-contract-json-diagnostics json)
  (unique
   (append
    (if json (or (hash-get json 'diagnostics) []) [])
    (typed-contract-type-spec-json-diagnostics
     (and json (hash-get json 'typeSpec))))))

;; : (-> MaybeJson (List Diagnostic) )
(def (typed-contract-type-spec-json-diagnostics type-spec-json)
  (if type-spec-json
    (or (hash-get type-spec-json 'diagnostics) [])
    []))

;; : (-> (List SignatureReason) Integer Integer SignatureQuality )
(def (typed-contract-quality reasons arrow-count group-count)
  (cond
   ((pair? reasons) "invalid")
   ((= arrow-count 0) "declaration-contract")
   ((> arrow-count 1) "higher-order-transform")
   ((> group-count 0) "grouped-transform")
   (else "domain-transform")))

;; : (-> Definition Integer Integer ArityAlignment )
(def (typed-contract-arity-alignment definition arrow-count contract-input-count)
  (cond
   ((= arrow-count 0) "declaration")
   ((equal? (definition-kind definition) "defrules") "macro-syntax")
   ((= (definition-arity definition) contract-input-count) "aligned")
   (else "input-count-mismatch")))

;; : (-> Definition Boolean )
(def (typed-contract-transform-definition? definition)
  (> (definition-arity definition) 0))

;;; Boundary:
;;; - typed-contract-simple-placeholder? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List SignatureToken) Integer Integer Boolean )
(def (typed-contract-simple-placeholder? tokens arrow-count group-count)
  (and (= arrow-count 1)
       (find typed-contract-generic-token? tokens)
       (not (find typed-contract-domain-token? tokens))))

;;; Boundary:
;;; - typed-contract-unknown-token? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List SignatureToken) Boolean )
(def (typed-contract-unknown-token? tokens)
  (if (find (lambda (token)
              (member token ["Any" "Unknown"]))
            tokens)
    #t
    #f))

;; : (-> SignatureToken Boolean )
(def (typed-contract-domain-token? token)
  (and (not (typed-contract-generic-token? token))
       (not (typed-contract-known-domain-token? token))))

;;; Known-domain lookup is table driven so adding a built-in type does not make
;;; unknown-token classification harder to audit.
;; : (-> SignatureToken Boolean )
(def (typed-contract-known-domain-token? token)
  (ormap (lambda (tokens)
           (member token tokens))
         [+typed-contract-container-tokens+
          +typed-contract-scalar-tokens+]))

;; : (-> SignatureToken Boolean )
(def (typed-contract-generic-token? token)
  (or (typed-contract-type-variable-token? token)
      (member token ["Fact" "Value" "TypeSpec" "Side" "Groups" "Key"])))

;;; Boundary:
;;; - Placeholder symbols are low-information type variables from old comments.
;;; - Keep this as token evidence so policy can repair docs without text scans.
;; : (-> (List SignatureToken) Boolean )
(def (typed-contract-placeholder-token? tokens)
  (if (find (lambda (token)
              (member token ["XX" "YY" "ZZ"]))
            tokens)
    #t
    #f))

;;; Placeholder-looking variables can be real higher-order contract variables.
;;; Keep the warning for low-information single-arrow comments, but do not mark
;;; nested higher-order contracts invalid.
;; : (-> (List SignatureToken) Integer Integer Boolean )
(def (typed-contract-placeholder-token-invalid? tokens arrow-count group-count)
  (and (typed-contract-placeholder-token? tokens)
       (= arrow-count 1)
       (= group-count 0)))

;;; Token-classification boundary:
;;; - Short uppercase tokens are treated as polymorphic variables, not domains.
;;; - Keeping this narrow prevents helper names from becoming fake types.
;; : (-> SignatureToken Boolean )
(def (typed-contract-type-variable-token? token)
  (and (<= (string-length token) 2)
       (not (string-empty? token))
       (string-every (lambda (ch)
                       (or (char-upper-case? ch)
                           (char-numeric? ch)))
                     token)))

;;; Invariant:
;;; - typed-contract-tokens owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; : (-> SignatureContract (List SignatureToken) )
(def (typed-contract-tokens contract)
  (let ((length (string-length contract))
        (index 0)
        (start #f)
        (tokens '()))
    (while (< index length)
      (if (typed-contract-token-char? (string-ref contract index))
        (if (not start)
          (set! start index))
        (if start
          (begin
            (set! tokens (cons (substring contract start index) tokens))
            (set! start #f))))
      (set! index (fx1+ index)))
    (reverse
     (if start
       (cons (substring contract start index) tokens)
       tokens))))

;; : (-> SignatureContract TypeExpr )
(def (typed-contract-output contract)
  (car (typed-contract-projection contract)))

;; : (-> SignatureContract (List TypeExpr) )
(def (typed-contract-inputs contract)
  (cadr (typed-contract-projection contract)))

;; : (-> SignatureContract (Tuple TypeExpr (List TypeExpr)))
(def (typed-contract-projection contract)
  (or (scheme-contract-projection contract)
      [contract []]))

;;; Boundary:
;;; - line-at* is zero-based and total over malformed indices.
;;; - Guard before list-ref so typed contract facts never raise on drifted spans.
;; : (-> (List SourceLine) LineNumber (Maybe SourceLine) )
(def (line-at* lines index)
  (and (>= index 0)
       (< index (length lines))
       (list-ref lines index)))

;; : (-> (Vector SourceLine) LineNumber (Maybe SourceLine) )
(def (line-vector-at* line-vector index)
  (and (>= index 0)
       (< index (vector-length line-vector))
       (vector-ref line-vector index)))

;; : (-> String Boolean )
(def (blank-string? value)
  (or (not (string? value))
      (string-empty? (string-trim value))))
