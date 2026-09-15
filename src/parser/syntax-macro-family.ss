;;; -*- Gerbil -*-
;;; Parser-owned macro-family grouping and uniformity evidence.

(import :asp-gerbil-scheme/src/parser/model
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-index-right)
        (only-in :std/sugar filter-map foldl)
        :gerbil/gambit)

(export +macro-family-min-count+
        macro-family-facts-from-macros
        macro-family-groups
        macro-family-group-cons
        macro-family-fact-from-group
        macro-family-quality-facets
        macro-family-prefix
        macro-family-last-hyphen-index
        macro-family-last
        macro-family-uniform-value
        macro-family-all?
        macro-family-thin-wrapper?
        macro-family-uniform?)

;; ConfigConstant
(def +macro-family-min-count+ 4)

;;; Macro-family evidence is derived from parser macro facts, not source text.
;;; Repeated same-prefix wrappers should collapse into one hygienic family or a
;;; table-driven syntax helper.
;; : (-> Relpath (List MacroFact) (List MacroFamilyFact))
(def (macro-family-facts-from-macros relpath macros)
  (filter-map (lambda (group)
                (macro-family-fact-from-group relpath group))
              (macro-family-groups macros)))

;; : (-> (List MacroFact) (List MacroFamilyGroup))
(def (macro-family-groups macros)
  (reverse
   (map (lambda (group)
          (cons (car group) (reverse (cdr group))))
        (foldl (lambda (macro groups)
                 (let (prefix (macro-family-prefix (macro-fact-name macro)))
                   (if prefix
                     (macro-family-group-cons prefix macro groups)
                     groups)))
               '()
               macros))))

;; : (-> String MacroFact (List MacroFamilyGroup) (List MacroFamilyGroup))
(def (macro-family-group-cons prefix macro groups)
  (cond
   ((null? groups) (list (cons prefix (list macro))))
   ((equal? prefix (caar groups))
    (cons (cons prefix (cons macro (cdar groups))) (cdr groups)))
   (else
    (cons (car groups)
          (macro-family-group-cons prefix macro (cdr groups))))))

;; : (-> Relpath MacroFamilyGroup (Maybe MacroFamilyFact))
(def (macro-family-fact-from-group relpath group)
  (let* ((prefix (car group))
         (macros (cdr group))
         (macro-count (length macros)))
    (if (< macro-count +macro-family-min-count+)
      #f
      (let* ((first-macro (car macros))
             (last-macro (macro-family-last macros))
             (kind (macro-family-uniform-value macros macro-fact-kind
                                               "mixed-macro-family"))
             (transformer
              (macro-family-uniform-value macros macro-fact-transformer
                                          "mixed-transformer"))
             (thin-wrapper? (macro-family-thin-wrapper? macros))
             (role (if thin-wrapper?
                     "repeated-thin-macro-family"
                     "macro-family"))
             (facets (macro-family-quality-facets macros transformer
                                                  thin-wrapper?)))
        (make-macro-family-fact
         (string-append prefix "-family")
         kind relpath
         (macro-fact-start first-macro)
         (macro-fact-end last-macro)
         role prefix (map macro-fact-name macros) macro-count transformer facets
         ["collapse same-prefix macro wrappers into one syntax-rules helper or macro family table"
          "keep macro surface thin and move runtime behavior into ordinary helpers"
          "document the macro family expansion contract with one example per shape"])))))

;; : (-> (List MacroFact) String Boolean (List QualityFacet))
(def (macro-family-quality-facets macros transformer thin-wrapper?)
  (unique
   (filter identity
           ["macro-family-boundary"
            (and thin-wrapper? "repeated-thin-macro-wrapper")
            (and (equal? transformer "syntax-rules")
                 "declarative-macro-family")
            (and (macro-family-all? macro-fact-hygienic macros)
                 "hygienic-macro-family")
            (and (equal? transformer "syntax-rules")
                 "syntax-rules-macro-family")
            (and thin-wrapper? "thin-macro-family")])))

;; : (-> String (Maybe String))
(def (macro-family-prefix name)
  (let (index (macro-family-last-hyphen-index name))
    (and index (> index 0) (substring name 0 index))))

;; : (-> String (Maybe Integer))
(def (macro-family-last-hyphen-index name)
  (let (index (string-index-right name #\-))
    (and index (> index 0) (< index (- (string-length name) 1)) index)))

;; : (forall (a) (-> (List a) a))
;; : (-> (NonEmptyList MacroFact) MacroFact)
(def (macro-family-last items)
  (if (null? (cdr items))
    (car items)
    (macro-family-last (cdr items))))

;; : (forall (a b) (-> (List a) (-> a b) b b))
;; : (-> List Procedure Value Value)
(def (macro-family-uniform-value items accessor mixed)
  (let (values (unique (filter identity (map accessor items))))
    (if (= (length values) 1) (car values) mixed)))

;; : (forall (a) (-> (-> a Boolean) (List a) Boolean))
;; : (-> Procedure List Boolean)
(def (macro-family-all? pred items)
  (cond
   ((null? items) #t)
   ((pred (car items)) (macro-family-all? pred (cdr items)))
   (else #f)))

;; : (-> (List MacroFact) Boolean)
(def (macro-family-thin-wrapper? macros)
  (and (macro-family-uniform? macros macro-fact-kind)
       (macro-family-uniform? macros macro-fact-transformer)
       (macro-family-all?
        (lambda (macro) (<= (macro-fact-pattern-count macro) 2))
        macros)))

;; : (forall (a b) (-> (List a) (-> a b) Boolean))
;; : (-> List Procedure Boolean)
(def (macro-family-uniform? items accessor)
  (= (length (unique (filter identity (map accessor items)))) 1))
