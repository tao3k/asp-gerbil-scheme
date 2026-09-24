;;; -*- Gerbil -*-
;;; Lightweight POO source-ref structural validation.

(import :gerbil/runtime/gambit)

(export poo-object-source-ref-structural-validation)

(def +poo-object-source-ref-slots+
  '(kind manager dependency repository localSource repositorySource
         indexHint pathPolicy selectorScheme))

;; : (-> (List (List Dyn)) (List Dyn))
(def (append-lists lists)
  (if (null? lists)
    []
    (apply append lists)))

;; : (-> Alist HashTable)
(def (alist->hash entries)
  (let (table (make-hash-table))
    (for-each (lambda (entry)
                (hash-put! table (car entry) (cdr entry)))
              entries)
    table))

;; : (-> SourceRef Slot (List Diagnostic))
(def (poo-object-source-ref-slot-diagnostic source-ref slot)
  (if (hash-get source-ref slot)
    []
    [(string-append "sourceRef:missing:" (symbol->string slot))]))

;; : (-> SourceRef Json)
;;; Boundary: object-contract runtime validation needs only source-ref shape
;;; evidence. This module stays free of TypeSpec imports so default smoke tests
;;; can validate POO source-ref contracts without loading the full type system.
(def (poo-object-source-ref-structural-validation source-ref)
  (let (diagnostics
        (append-lists
         (map (lambda (slot)
                (poo-object-source-ref-slot-diagnostic source-ref slot))
              +poo-object-source-ref-slots+)))
    (alist->hash
     `((kind . "poo-pattern-structural-validation")
       (schema . "poo-pattern-evidence/v1")
       (patternKind . "type-validation")
       (valid . ,(not (pair? diagnostics)))
       (diagnostics . ,diagnostics)
       (checkedSignals . ["source-ref-shape"])))))
