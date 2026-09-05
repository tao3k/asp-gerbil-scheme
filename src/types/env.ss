;;; -*- Gerbil -*-
;;; Type environment facts derived from parser-owned definitions.

(import :asp-gerbil-scheme/src/parser/model
        (only-in :asp-gerbil-scheme/src/parser/selectors
                 definition-selector
                 project-definitions
                 project-typed-contract-facts)
        (only-in :std/srfi/1 append-map)
        (only-in :std/sugar cut filter-map foldl foldr)
        :asp-gerbil-scheme/src/types/model
        :asp-gerbil-scheme/src/types/signatures)

(export make-type-binding
        type-binding-name
        type-binding-kind
        type-binding-type
        type-binding-formals
        type-binding-arity
        type-binding-path
        type-binding-selector
        make-type-param-binding
        type-param-binding-function-name
        type-param-binding-name
        type-param-binding-type
        type-param-binding-path
        type-param-binding-selector
        build-type-env
        build-type-env/signatures
        build-param-type-env
        build-param-type-env/signatures
        duplicate-type-bindings)
;; TypeBindingStruct
(defstruct type-binding (name kind type formals arity path selector))
;; TypeParamBindingStruct
(defstruct type-param-binding (function-name name type path selector))
;; : (-> ProjectIndex TypeSpec )
(def (build-type-env index)
  (build-type-env/signatures index '()))
;;; Boundary:
;;; - External signatures keep priority, then parser-owned typed contracts fill gaps.
;;; - Type facts therefore work in ordinary projects without a separate signature file.
;; : (-> ProjectIndex NativeSignatures TypeSpec )
(def (build-type-env/signatures index signatures)
  (let (native-signatures (project-native-signatures index signatures))
    (map (cut definition->type-binding <> native-signatures)
         (project-definitions index))))
;; : (-> ProjectIndex TypeSpec )
(def (build-param-type-env index)
  (build-param-type-env/signatures index '()))
;;; Boundary:
;;; - Parameter bindings use the same merged signature surface as function types.
;;; - This keeps checker argument facts aligned with source-local `;; :` contracts.
;; : (-> ProjectIndex NativeSignatures TypeSpec )
(def (build-param-type-env/signatures index signatures)
  (let (native-signatures (project-native-signatures index signatures))
    (append-map (cut definition->param-type-bindings
                     <> native-signatures)
                (project-definitions index))))

;;; Boundary:
;;; - Project typed contracts are parser-owned signatures.
;;; - Caller-provided signatures are prepended so tests/tools can override fixtures explicitly.
;; : (-> ProjectIndex NativeSignatures NativeSignatures )
(def (project-native-signatures index signatures)
  (append signatures (typed-contract-signatures index)))

;;; Boundary:
;;; - typed-contract-signatures projects valid contract facts into TypeSpec entries.
;;; - Invalid comments remain policy evidence and do not feed checker assumptions.
;; : (-> ProjectIndex NativeSignatures )
(def (typed-contract-signatures index)
  (filter-map typed-contract-fact->signature
              (project-typed-contract-facts index)))

;; : (-> TypedContractFact (Maybe TypeSignature) )
(def (typed-contract-fact->signature fact)
  (and (typed-contract-fact-signature-usable? fact)
       (cons (typed-contract-fact-definition-name fact)
             (parse-type-contract (typed-contract-fact-contract fact)))))

;; : (-> TypedContractFact Boolean )
(def (typed-contract-fact-signature-usable? fact)
  (and (typed-contract-fact-definition-name fact)
       (typed-contract-fact-contract fact)
       (not (equal? (typed-contract-fact-quality fact) "invalid"))))
;; : (-> Definition NativeSignatures TypeSpec )
(def (definition->type-binding defn signatures)
  (make-type-binding (definition-name defn)
                     (definition-kind defn)
                     (or (signature-type-for (definition-name defn) signatures)
                         (make-type-unknown))
                     (definition-formals defn)
                     (definition-arity defn)
                     (definition-path defn)
                     (definition-selector defn)))
;; : (-> Definition NativeSignatures (List BindingFact) )
(def (definition->param-type-bindings defn signatures)
  (let (signature-type (signature-type-for (definition-name defn) signatures))
    (if signature-type
      (signature-formal-bindings defn signature-type)
      '())))
;; : (-> Definition SignatureType (List BindingFact) )
(def (signature-formal-bindings defn signature-type)
  (let (formals (definition-formals defn))
    (case (type-kind signature-type)
      ((function)
       (let (params (type-params signature-type))
         (if (= (length formals) (length params))
           (param-bindings defn formals params)
           '())))
      ((function-variadic)
       (if (>= (length formals) (type-function-variadic-min-arity signature-type))
         (param-bindings defn
                         formals
                         (repeat-type (type-function-variadic-param signature-type)
                                      (length formals)))
         '()))
      (else '()))))
;;; Invariant:
;;; - param-bindings aligns formals and parameter types without allocating an
;;;   intermediate pair list.
;;; - Filtering remains tied to the aligned slot so unknown/any parameters do
;;;   not shift later bindings.
;; : (-> Definition Formals ParamTypes (List BindingFact) )
(def (param-bindings defn formals param-types)
  (filter-map
   (lambda (name type)
     (and (useful-param-type? type)
          (make-type-param-binding (definition-name defn)
                                   name
                                   type
                                   (definition-path defn)
                                   (definition-selector defn))))
   formals
   param-types))
;; : (-> Type Boolean )
(def (useful-param-type? type)
  (not (member (type-kind type) '(unknown any))))
;;; Invariant:
;;; - repeat-type owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; : (-> Type Integer TypeSpec )
(def (repeat-type type count)
  (make-list count type))
;;; Boundary:
;;; - duplicate-type-bindings is a keyed fold over path/name/kind triples.
;;; - State keeps seen bindings and duplicate pairs separate for repair output.
;; : (-> (List Definition) (List BindingFact) )
(def (duplicate-type-bindings bindings)
  (let (state
        (foldl duplicate-type-binding-step
               (cons '() '())
               bindings))
    (reverse (cdr state))))

;;; Reducer step:
;;; - POO methods are intentionally skipped before keying.
;;; - Non-method bindings flow through one association update boundary.
;; : (-> TypeBinding DuplicateState DuplicateState )
(def (duplicate-type-binding-step binding state)
  (if (poo-method-type-binding? binding)
    state
    (record-type-binding-duplicate binding state)))

;;; Duplicate state is `(seen . dupes)` where seen maps stable binding keys to
;;; the first binding fact and dupes keeps the later/earlier pair for repair.
;; : (-> TypeBinding DuplicateState DuplicateState )
(def (record-type-binding-duplicate binding state)
  (let* ((seen (car state))
         (dupes (cdr state))
         (prior (assoc (type-binding-key binding) seen)))
    (if prior
      (cons seen (cons [binding (cdr prior)] dupes))
      (cons (cons (cons (type-binding-key binding) binding) seen) dupes))))

;;; Binding keys deliberately include owner path and definition kind so
;;; overloaded method-like facts do not collapse unrelated source evidence.
;; : (-> TypeBinding DuplicateKey )
(def (type-binding-key binding)
  (list (type-binding-path binding)
        (type-binding-name binding)
        (type-binding-kind binding)))

;;; Boundary:
;;; - POO methods are overload/specializer entries under one generic, not duplicate definitions.
;;; - Keep duplicate type checks focused on owners where a same-name binding really shadows evidence.
;; : (-> TypeBinding Boolean )
(def (poo-method-type-binding? binding)
  (member (type-binding-kind binding) '("defmethod" ".defmethod")))
