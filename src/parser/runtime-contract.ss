;;; -*- Gerbil -*-
;;; Runtime contract projection for typed comment `| contract` sections.
;;; Boundary: static `;; :` signatures stay in typed-contract-scheme; this
;;; module owns runtime contract arrows and their TypeSpec validation bridge.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/parser/typed-contract-scheme
                 scheme-type-expression-text-json
                 split-top-level-type-exprs)
        (only-in :std/srfi/1 drop-right last)
        (only-in :std/srfi/13 string-join)
        (only-in :std/sugar cut hash))

(export scheme-runtime-contract-json)

;;; Runtime contracts stay separate from static types, but their arrow shape is
;;; still formally projected so invalid child contracts become parser evidence.
;; scheme-runtime-contract-json
;;   : (-> RuntimeContract Json)
;;   | doc m%
;;       `scheme-runtime-contract-json contract` accepts both Scheme prefix
;;       arrows and Nickel-style infix arrows.
;;
;;       # Examples
;;       ```scheme
;;       (hash-get (scheme-runtime-contract-json "Dyn -> NonEmpty -> Dyn") 'valid)
;;       ;; => #t
;;       ```
;;     %
(def (scheme-runtime-contract-json contract)
  (let* ((prefix-arrow (runtime-contract-prefix-arrow-datum contract))
         (items (runtime-contract-arrow-items contract prefix-arrow))
         (type-json (and items
                         (scheme-type-expression-text-json
                          (runtime-contract-arrow-type-text items))))
         (diagnostics
          (cond
           ((not items) ["runtime-contract-missing-arrow"])
           ((< (length items) 2) ["runtime-contract-arrow-too-short"])
           (else []))))
    (hash (syntax "scheme-runtime-contract")
          (raw contract)
          (notation (if prefix-arrow "scheme-prefix-arrow" "infix-arrow"))
          ;; Runtime predicates such as `procedure?` are valid contract atoms
          ;; even when static type-expression diagnostics would classify them
          ;; as unbound type variables. TypeSpec validation is the boundary.
          (valid (runtime-contract-valid? diagnostics type-json))
          (typeSpec (and type-json (hash-get type-json 'typeSpec)))
          (inputPredicates (runtime-contract-input-predicates items))
          (outputPredicate (runtime-contract-output-predicate items))
          (predicateCount (if items (length items) 0))
          (diagnostics diagnostics))))

;; : (-> (List Diagnostic) Json Boolean)
(def (runtime-contract-valid? diagnostics type-json)
  (and (not (pair? diagnostics))
       (runtime-contract-type-spec-valid? type-json)))

;; : (-> (Maybe (List TypeDatum)) Boolean)
(def (runtime-contract-arrow-ready? items)
  (and items (>= (length items) 2)))

;; : (-> (Maybe (List TypeDatum)) (List TypeExpr))
(def (runtime-contract-input-predicates items)
  (if (runtime-contract-arrow-ready? items)
    (map runtime-contract-datum->string (drop-right items 1))
    []))

;; : (-> (Maybe (List TypeDatum)) (Maybe TypeExpr))
(def (runtime-contract-output-predicate items)
  (and (runtime-contract-arrow-ready? items)
       (runtime-contract-datum->string (last items))))

;;; Validation bridge: runtime predicate names stay contract atoms while the
;;; normalized arrow container still uses TypeSpec child-shape validation.
;; : (-> Json Boolean)
(def (runtime-contract-type-spec-valid? type-json)
  (let (type-spec (and type-json (hash-get type-json 'typeSpec)))
    (and type-spec (hash-get type-spec 'valid))))

;; : (-> RuntimeContract (Maybe ArrowDatum) (Maybe (List TypeDatum)))
(def (runtime-contract-arrow-items contract prefix-arrow)
  (if prefix-arrow
    (cdr prefix-arrow)
    (runtime-contract-infix-arrow-items contract)))

;; : (-> RuntimeContract (Maybe ArrowDatum))
(def (runtime-contract-prefix-arrow-datum contract)
  (let (datum (runtime-contract-datum contract))
    (and datum
         (runtime-contract-arrow-datum datum))))

;; : (-> Datum (Maybe ArrowDatum))
(def (runtime-contract-arrow-datum datum)
  (cond
   ((and (pair? datum) (eq? (car datum) '->)) datum)
   (else #f)))

;;; Nickel-style `A -> B -> C` is normalized at top level only. Nested contract
;;; text remains inside its parenthesized token for later grammar extensions.
;; : (-> RuntimeContract (Maybe (List TypeDatum)))
(def (runtime-contract-infix-arrow-items contract)
  (let (parts (runtime-contract-infix-arrow-parts
               (split-top-level-type-exprs contract)))
    (and parts
         (>= (length parts) 2)
         (map runtime-contract-part-datum parts))))

;;; Token grouping keeps top-level arrows as separators without splitting
;;; nested parenthesized contract text reserved for later grammar expansion.
;; : (-> (List TypeExpr) (Maybe (List TypeExpr)))
(def (runtime-contract-infix-arrow-parts tokens)
  (runtime-contract-infix-arrow-parts* tokens [] []))

;; : (-> (List TypeExpr) (List TypeExpr) (List TypeExpr) (Maybe (List TypeExpr)))
(def (runtime-contract-infix-arrow-parts* tokens current parts)
  (cond
   ((null? tokens)
    (and (pair? current)
         (reverse
          (cons (string-join (reverse current) " ") parts))))
   ((equal? (car tokens) "->")
    (and (pair? current)
         (runtime-contract-infix-arrow-parts*
          (cdr tokens)
          []
          (cons (string-join (reverse current) " ") parts))))
   (else
    (runtime-contract-infix-arrow-parts*
     (cdr tokens)
     (cons (car tokens) current)
     parts))))

;; : (-> RuntimeContractParts TypeExpr)
(def (runtime-contract-arrow-type-text parts)
  (string-append "(-> "
                 (string-join (map runtime-contract-datum->string parts) " ")
                 ")"))

;; : (-> TypeExpr TypeDatum)
(def (runtime-contract-part-datum text)
  (or (runtime-contract-datum text) 'unknown))

;; : (-> RuntimeContract (Maybe Datum))
(def (runtime-contract-datum contract)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (call-with-input-string contract read))))

;;; Printer boundary: runtime contract evidence needs the exact datum spelling
;;; that the reader produced. `call-with-output-string` owns that transient port
;;; so callers receive a plain TypeExpr string.
;; : (-> TypeDatum TypeExpr)
(def (runtime-contract-datum->string datum)
  (call-with-output-string []
    (cut write datum <>)))
