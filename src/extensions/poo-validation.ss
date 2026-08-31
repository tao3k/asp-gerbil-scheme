;;; -*- Gerbil -*-
;;; Formal structural validation for Gerbil POO extension pattern evidence.
;;; Boundary:
;;; - :asp-gerbil-scheme/src/extensions/poo-patterns owns static POO pattern slots.
;;; - This module owns validation packets and diagnostics derived from them.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/extensions/poo-patterns
        (only-in :std/srfi/1 append-map)
        (only-in :std/srfi/13 string-contains string-prefix?)
        (only-in :std/sugar filter hash ormap))

;;; Selector URI prefixes are protocol vocabulary, not free-form string checks.
;;; Keeping the whitelist as data lets new extension namespaces land without
;;; growing the URI predicate.
;; (List SelectorUriPrefix)
(def +poo-pattern-selector-uri-prefixes+
  '("gerbil-poo://"
    "gerbil-poo-test://"
    "gerbil-poo-witness://"
    "gerbil-runtime://"
    "gerbil-runtime-test://"
    "gerbil-utils://"))

(export poo-pattern-structural-validation)

;;; Formal structural validation for POO pattern evidence:
;;; - Generic checks verify packet shape, selector URI grammar, and sourceRef.
;;; - Type-validation adds sealed-class and validator-specific witness checks.
;; poo-pattern-structural-validation
;;   : (-> PatternKind SourceRef Json)
;;   | doc m%
;;       `poo-pattern-structural-validation kind source-ref` returns a machine
;;       readable validation packet for POO extension pattern evidence.
;;
;;       # Examples
;;       ```scheme
;;       (hash-get (poo-pattern-structural-validation 'type-validation source-ref)
;;                 'valid)
;;       ;; => #t
;;       ```
;;     %
(def (poo-pattern-structural-validation kind source-ref)
  (let (diagnostics (poo-pattern-structural-diagnostics kind source-ref))
    (hash (kind "poo-pattern-structural-validation")
          (schema "poo-pattern-evidence/v1")
          (patternKind (symbol->string kind))
          (valid (not (pair? diagnostics)))
          (diagnostics diagnostics)
          (checkedSignals
           ["required-slots"
            "selector-uri-grammar"
            "source-ref-shape"
            "failure-case-coverage"
            "quality-signal-coverage"]))))

;;; Diagnostic composition is intentionally signal-based.
;;; Policy can consume the aggregate without binding itself to one brittle rule.
;; : (-> PatternKind SourceRef (List Diagnostic) )
(def (poo-pattern-structural-diagnostics kind source-ref)
  (append
   (poo-pattern-required-slot-diagnostics kind)
   (poo-pattern-selector-diagnostics (poo-pattern-selectors kind))
   (poo-pattern-source-ref-diagnostics source-ref)
   (poo-pattern-specialized-diagnostics kind)))

;;; Invariant:
;;; - Required slot checks turn each declarative registry slot into zero or one diagnostic.
;;; - `append-map` keeps the packet-level diagnostic stream flat for downstream policy.
;; : (-> PatternKind (List Diagnostic) )
(def (poo-pattern-required-slot-diagnostics kind)
  (append-map (lambda (entry)
                (poo-pattern-required-slot-diagnostic kind (car entry) (cdr entry)))
              [(cons 'id (poo-pattern-id kind))
               (cons 'sourceOwners (poo-pattern-source-owners kind))
               (cons 'selectors (poo-pattern-selectors kind))
               (cons 'minimalForms (poo-pattern-minimal-forms kind))
               (cons 'failureCases (poo-pattern-failure-cases kind))
               (cons 'qualitySignals (poo-pattern-quality-signals kind))
               (cons 'witness (poo-pattern-witness kind))
               (cons 'next (poo-pattern-next kind))]))

;; : (-> PatternKind Slot Value (List Diagnostic) )
(def (poo-pattern-required-slot-diagnostic kind slot value)
  (if (poo-pattern-required-value? value)
    []
    [(string-append "pattern:" (symbol->string kind)
                    ":missing-slot:" (symbol->string slot))]))

;; : (-> RequiredSlotValue Boolean )
(def (poo-pattern-required-value? value)
  (cond
   ((not value) #f)
   ((and (list? value) (null? value)) #f)
   ((and (string? value) (equal? value "")) #f)
   (else #t)))

;;; Selector validation treats gerbil-poo URI strings as structured evidence.
;;; This keeps extension packets from smuggling unparseable source anchors.
;; : (-> (List Selector) (List Diagnostic) )
(def (poo-pattern-selector-diagnostics selectors)
  (append-map poo-pattern-selector-diagnostic selectors))

;; : (-> Selector (List Diagnostic) )
(def (poo-pattern-selector-diagnostic selector)
  (append
   (if (hash-get selector 'role) [] ["selector:missing-role"])
   (if (hash-get selector 'symbol) [] ["selector:missing-symbol"])
   (let (uri (hash-get selector 'selector))
     (cond
      ((not uri) ["selector:missing-selector-uri"])
      ((not (poo-pattern-selector-uri? uri))
       [(string-append "selector:invalid-uri:" uri)])
      (else [])))))

;; : (-> SelectorUri Boolean )
(def (poo-pattern-selector-uri? uri)
  (and (string? uri)
       (poo-pattern-selector-uri-prefix? uri)
       (string-contains uri "#")))

;;; URI prefix validation is a bounded whitelist match; the caller still owns
;;; the fragment check so malformed anchors remain visible in diagnostics.
;; : (-> SelectorUri Boolean )
(def (poo-pattern-selector-uri-prefix? uri)
  (ormap (lambda (prefix)
           (string-prefix? prefix uri))
         +poo-pattern-selector-uri-prefixes+))

;;; SourceRef validation keeps package-manager evidence distinct from repository fallback.
;;; POO evidence must expose both local probe and repository fallback metadata.
;; : (-> SourceRef (List Diagnostic) )
(def (poo-pattern-source-ref-diagnostics source-ref)
  (append-map (lambda (slot)
                (if (hash-get source-ref slot)
                  []
                  [(string-append "sourceRef:missing:" (symbol->string slot))]))
              '(kind manager dependency repository localSource
                     repositorySource indexHint pathPolicy selectorScheme)))

;; : (-> PatternKind (List Diagnostic) )
(def (poo-pattern-specialized-diagnostics kind)
  (if (eq? kind 'type-validation)
    (poo-type-validation-pattern-diagnostics kind)
    []))

;;; Boundary:
;;; - Type-validation is the first POO pattern with specialized structural obligations.
;;; - Each mapped list checks a separate witness axis: selectors, minimal forms, failures, then quality.
;; : (-> PatternKind (List Diagnostic) )
(def (poo-type-validation-pattern-diagnostics kind)
  (append
   (poo-pattern-required-roles-diagnostics
    "selector-role"
    (map (lambda (selector) (hash-get selector 'role))
         (poo-pattern-selectors kind))
    ["class-descriptor"
     "function-validator"
     "generic-slot-validator"
     "real-project-validation-test"])
   (poo-pattern-required-roles-diagnostics
    "minimal-form-role"
    (map (lambda (form) (hash-get form 'role))
         (poo-pattern-minimal-forms kind))
    ["sealed-class-definition"
     "generic-slot-validator"
     "validation-regression-test"])
   (poo-pattern-required-roles-diagnostics
    "failure-case-id"
    (map (lambda (failure) (hash-get failure 'id))
         (poo-pattern-failure-cases kind))
    ["missing-required-typed-slot"
     "sealed-extra-slot-assumption"
     "unchecked-function-arity"])
   (poo-pattern-required-roles-diagnostics
    "quality-signal"
    (poo-pattern-quality-signals kind)
    ["sealed-type-witness"
     "validation-negative-witness"])))

;;; Invariant:
;;; - Role diagnostics are a set difference over expected witness labels.
;;; - `filter` selects missing evidence and `map` preserves a stable diagnostic prefix.
;; : (-> String (List String) (List String) (List Diagnostic) )
(def (poo-pattern-required-roles-diagnostics prefix actual expected)
  (map (lambda (missing)
         (string-append "type-validation:" prefix ":missing:" missing))
       (filter (lambda (required) (not (member required actual)))
               expected)))
