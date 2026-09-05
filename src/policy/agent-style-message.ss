;;; -*- Gerbil -*-
;;; Typed-combinator policy messages and contract summary helpers.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/facade
        (only-in :std/sugar foldl))

(export typed-combinator-style-message
        typed-combinator-style-missing-count
        typed-combinator-style-missing-contract-triggered?
        file-typed-combinator-style-summary
        file-typed-combinator-style-count)

;; : Nat
(def +typed-combinator-style-missing-contract-small-owner-limit+ 4)

;;; Boundary:
;;; - typed-combinator-style-message coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> Boolean String String )
(def (typed-combinator-style-message-fragment condition text)
  (if condition text ""))

;; : (-> InvalidContractCount String )
(def (typed-combinator-style-invalid-comment-fragment invalid-typed-comment-count)
  (typed-combinator-style-message-fragment
   (> invalid-typed-comment-count 0)
   (string-append " and "
                  (number->string invalid-typed-comment-count)
                  " low-information typed comments")))

;; : (-> Nat Nat Nat String )
(def (typed-combinator-style-coverage-fragment covered-definition-count function-definition-count minimum-covered-definition-count)
  (string-append
   "; parser-owned expression-level implementation evidence covers "
   (number->string covered-definition-count)
   "/"
   (number->string function-definition-count)
   " arity-bearing definitions, below minimum "
   (number->string minimum-covered-definition-count)))

;; : (-> Boolean Nat String )
(def (typed-combinator-style-doc-fragment typed-doc-missing? typed-doc-missing-count)
  (typed-combinator-style-message-fragment
   typed-doc-missing?
   (string-append
    "; "
    (number->string typed-doc-missing-count)
    " public/policy-sensitive helpers need full typed doc blocks with | doc m%, # Examples, and result comments")))

;; : (-> DefinitionCount ValidContractCount InvalidContractCount Boolean Boolean Boolean Boolean Nat Nat Nat Nat Message )
(def (typed-combinator-style-forall-fragment typed-forall-missing? typed-forall-missing-count)
  (typed-combinator-style-message-fragment
   typed-forall-missing?
    (string-append
     "; "
     (number->string typed-forall-missing-count)
     " generic functional helpers need both layered typed comment forms; missing either the human-readable polymorphic generic line like ;; : (forall (k v) (-> [(Pair k v)] [(Pair k v)] [(Pair k v)])) or the readable/domain summary line like ;; : (-> List Alist Alist) triggers this warning; keep both because the forall line explains type-variable relationships and every signature line is parser-validated")))

(def (typed-combinator-style-message definition-count typed-comment-count invalid-typed-comment-count missing-implementation-evidence? implementation-coverage-insufficient? typed-doc-missing? typed-forall-missing? quality-repair-triggered? typed-doc-missing-count typed-forall-missing-count covered-definition-count function-definition-count minimum-covered-definition-count)
  (string-append
   "Scheme source owner has "
   (number->string definition-count)
   " definitions but only "
   (number->string typed-comment-count)
   " adjacent typed-combinator-style algebraic contracts"
   (typed-combinator-style-invalid-comment-fragment invalid-typed-comment-count)
   (typed-combinator-style-message-fragment
    missing-implementation-evidence?
    "; typed contracts are present but no parser-owned expression-level implementation evidence was found")
   (typed-combinator-style-message-fragment
    implementation-coverage-insufficient?
    (typed-combinator-style-coverage-fragment
     covered-definition-count
     function-definition-count
     minimum-covered-definition-count))
   (typed-combinator-style-doc-fragment
    typed-doc-missing?
    typed-doc-missing-count)
   (typed-combinator-style-forall-fragment
    typed-forall-missing?
    typed-forall-missing-count)
   (typed-combinator-style-message-fragment
    quality-repair-triggered?
    "; parser-owned quality facets require repair toward compact expression-level composition")
   "; typed-combinator-style has three criteria: adjacent Scheme-native typed block with both polymorphic generic signatures such as ;; : (forall (k v) (-> [(Pair k v)] [(Pair k v)] [(Pair k v)])) and readable/domain signatures such as ;; : (-> (Maybe Type) (Maybe Type) Boolean), compact expression-level composition, and optimization-boundary comments for specialized branches"))

;;; Missing contract count:
;;; - Clamp at zero so extra parser facts never produce negative diagnostics.
;;; - The caller still reports invalid typed comments separately.
;; : (-> Integer Integer Integer )
(def (typed-combinator-style-missing-count definition-count typed-comment-count)
  (if (> definition-count typed-comment-count)
    (- definition-count typed-comment-count)
    0))

;;; Missing-contract trigger:
;;; - Small/new owners should learn the typed-combinator surface immediately.
;;; - Large owners are repaired through concrete doc, evidence, and parser
;;;   quality signals instead of mechanical full-file comment churn.
;; : (-> Nat Nat Boolean )
(def (typed-combinator-style-missing-contract-triggered? function-definition-count missing-count)
  (and (> missing-count 0)
       (<= function-definition-count
           +typed-combinator-style-missing-contract-small-owner-limit+)))

;; : (-> ProjectIndex SourceFile ContractSummary )
(def (file-typed-combinator-style-summary index file)
  (typed-contract-fact-summary (source-file-typed-contract-facts file)))

;; : (-> ProjectIndex SourceFile Integer )
(def (file-typed-combinator-style-count index file)
  (cadr (file-typed-combinator-style-summary index file)))

;;; Boundary:
;;; - typed-contract-fact-summary composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypedContractFact) ContractSummary )
(def (typed-contract-fact-summary facts)
  (foldl (lambda (fact summary)
           (if (equal? (typed-contract-fact-quality fact) "invalid")
             (list (+ (car summary) 1)
                   (cadr summary)
                   (+ (caddr summary) 1))
             (list (+ (car summary) 1)
                   (+ (cadr summary) 1)
                   (caddr summary))))
         (list 0 0 0)
         facts))
