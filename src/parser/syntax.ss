;;; -*- Gerbil -*-
;;; Native Gerbil syntax fact extraction.

(import :gerbil/expander
        :asp-gerbil-scheme/src/parser/syntax-calls
        :asp-gerbil-scheme/src/parser/syntax-support
        :asp-gerbil-scheme/src/parser/formals
        :asp-gerbil-scheme/src/parser/imports
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/support
        (only-in :std/misc/list unique)
        (only-in :std/srfi/1 drop)
        (only-in :std/srfi/13 string-index-right string-prefix?))

(export +definition-heads+
        +declarative-top-level-heads+
        calls-from-form
        module-import-facts-from-form
        macro-facts-from-form
        macro-family-facts-from-macros
        binding-facts-from-form
        +macro-definition-heads+
        form-caller-name
        stx-form-body-items
        let-head?
        let-binding-stxes
        let-body-stxes
        lambda-body-stxes
        case-lambda-body-stxes
        match-body-stxes
        datum-has-head?
        top-form-from
        declarative-top-form?
        module-refs
        export-symbols
        string-datums)
;; macro-facts-from-form
;;   : (-> Relpath Form Datum (List MacroFact))
;;   | doc m%
;;       `macro-facts-from-form relpath form datum` extracts macro definition
;;       facts from macro forms and annotates them with source and quality
;;       evidence.
;;
;;       # Examples
;;
;;       ```scheme
;;       (macro-facts-from-form "src/core.ss" form datum)
;;       ;; => macro facts
;;       ```
;;     %
(def (macro-facts-from-form relpath form datum)
  (let ((head (and (pair? datum) (car datum))))
    (if (member head +macro-definition-heads+)
      (map (lambda (name)
             (let (loc (stx-source form))
               (make-macro-fact (datum->string name)
                                (symbol->string head)
                                relpath
                                (source-start-line loc)
                                (source-end-line loc)
                                (macro-transformer-kind datum)
                                (macro-phase head)
                                (macro-pattern-count datum)
                                (macro-hygienic? datum)
                                (macro-quality-facets head datum))))
           (definition-name-datums datum))
      '())))
;; : (-> Relpath Form Datum BindingFactsFromForm )
(def (binding-facts-from-form relpath form datum)
  (let (head (and (pair? datum) (car datum)))
    (if (member head +macro-definition-heads+)
      (formal-binding-facts-from-form relpath form datum "macro-formal")
      (append (top-level-value-binding-facts-from-form relpath form datum)
              (formal-binding-facts-from-form relpath form datum "formal")
              (binding-facts-from-stx relpath form (form-caller-name datum) '())))))

;;; Top-level value definitions expose literal/identifier shape to policy
;;; without making policy parse source text or concrete version strings.
;; : (-> Relpath Form Datum BindingFactsFromForm )
(def (top-level-value-binding-facts-from-form relpath form datum)
  (let (head (and (pair? datum) (car datum)))
    (if (top-level-value-definition-datum? datum)
      (let* ((loc (stx-source form))
             (name (cadr datum))
             (value (caddr datum)))
        [(make-binding-fact (datum->string name)
                            (symbol->string head)
                            relpath
                            (source-start-line loc)
                            (source-end-line loc)
                            "top-level"
                            (argument-type-name value '()))])
      '())))

;; : (-> Datum Boolean )
(def (top-level-value-definition-datum? datum)
  (and (pair? datum)
       (member (car datum) '(def define))
       (pair? (cdr datum))
       (symbol? (cadr datum))
       (pair? (cddr datum))
       (null? (cdddr datum))))
;; formal-binding-facts-from-form
;;   : (-> Relpath Form Datum String (List BindingFact))
;;   | doc m%
;;       `formal-binding-facts-from-form relpath form datum kind` extracts
;;       binding facts for function or macro formals.
;;
;;       # Examples
;;
;;       ```scheme
;;       (formal-binding-facts-from-form "src/core.ss" form datum "formal")
;;       ;; => binding facts
;;       ```
;;     %
(def (formal-binding-facts-from-form relpath form datum kind)
  (let (names (definition-name-datums datum))
    (if (pair? names)
      (let ((name (car names))
            (loc (stx-source form)))
        (map (lambda (formal)
               (make-binding-fact (datum->string formal)
                                  kind
                                  relpath
                                  (source-start-line loc)
                                  (source-end-line loc)
                                  (datum->string name)
                                  #f))
             (definition-formal-datums datum name)))
      '())))
;;; Boundary:
;;; - binding-facts-from-stx coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> Relpath ExprStx String LocalTypes BindingFactsFromStx )
(def (binding-facts-from-stx relpath expr-stx caller local-types)
  (if (not (stx-pair? expr-stx))
    '()
    (let* ((items (stx-list-items expr-stx))
           (head-stx (and (pair? items) (car items)))
           (head (and head-stx (syntax->datum head-stx)))
           (datum (syntax->datum expr-stx)))
      (cond
       ((not (symbol? head))
        (binding-facts-from-stxes relpath items caller local-types))
       ((member head '(quote quasiquote syntax quote-syntax))
        '())
       ((metadata-head? head)
        '())
       ((eq? head '.def)
        '())
       ((member head +definition-heads+)
        (cond
         ((member head +macro-definition-heads+) '())
         ((member head '(define-type defclass .defclass defgeneric .defgeneric)) '())
         (else
          (binding-facts-from-stxes relpath
                                    (stx-form-body-items expr-stx datum)
                                    (or (form-caller-name datum) caller)
                                    local-types))))
       ((let-head? head)
        (let* ((bindings (let-binding-datums datum))
               (binding-stxes (let-binding-stxes expr-stx head))
               (body-local-types (let-body-local-types head bindings local-types)))
          (append
           (let-binding-facts relpath head binding-stxes caller local-types)
           (binding-facts-from-stxes relpath
                                     (let-body-stxes expr-stx head)
                                     caller
                                     body-local-types))))
       ((eq? head 'lambda)
        (binding-facts-from-stxes relpath (lambda-body-stxes expr-stx) caller local-types))
       ((eq? head 'case-lambda)
        (binding-facts-from-stxes relpath (case-lambda-body-stxes expr-stx) caller local-types))
       ((eq? head 'match)
        (binding-facts-from-stxes relpath (match-body-stxes expr-stx) caller local-types))
       ((member head '(syntax-case syntax-rules identifier-rules))
        '())
       (else
        (binding-facts-from-stxes relpath (cdr items) caller local-types))))))
;; binding-facts-from-stxes
;;   : (-> Relpath (List ExprStx) String LocalTypes (List BindingFact))
;;   | doc m%
;;       `binding-facts-from-stxes relpath exprs caller local-types` appends
;;       binding facts collected from each expression syntax object.
;;
;;       # Examples
;;
;;       ```scheme
;;       (binding-facts-from-stxes "src/core.ss" exprs "handler" local-types)
;;       ;; => binding facts
;;       ```
;;     %
(def (binding-facts-from-stxes relpath exprs caller local-types)
  (apply append
         (map (cut binding-facts-from-stx relpath <> caller local-types)
              exprs)))
;; let-binding-facts
;;   : (-> Relpath Head (List BindingStx) String LocalTypes (List BindingFact))
;;   | doc m%
;;       `let-binding-facts relpath head binding-stxes caller local-types`
;;       walks let bindings in source order and threads sequential type
;;       bindings for `let*` forms.
;;
;;       # Examples
;;
;;       ```scheme
;;       (let-binding-facts "src/core.ss" 'let* binding-stxes "handler" local-types)
;;       ;; => binding facts
;;       ```
;;     %
(def (let-binding-facts relpath head binding-stxes caller local-types)
  (let ((rest binding-stxes)
        (env local-types)
        (out '()))
    (while (pair? rest)
      (let* ((binding (car rest))
             (datum (syntax->datum binding))
             (type-binding (binding-type datum env))
             (next-env (if (and (member head '(let* let*-values)) type-binding)
                         (cons type-binding env)
                         env)))
        (set! out
          (append out
                  (binding-facts-from-binding relpath head binding caller env)))
        (set! env next-env)
        (set! rest (cdr rest))))
    out))
;; binding-facts-from-binding
;;   : (-> Relpath Head BindingStx String LocalTypes (List BindingFact))
;;   | doc m%
;;       `binding-facts-from-binding relpath head binding caller local-types`
;;       extracts binding facts for each name introduced by one binding form.
;;
;;       # Examples
;;
;;       ```scheme
;;       (binding-facts-from-binding "src/core.ss" 'let binding "handler" local-types)
;;       ;; => binding facts
;;       ```
;;     %
(def (binding-facts-from-binding relpath head binding caller local-types)
  (let* ((datum (syntax->datum binding))
         (names (binding-name-datums datum))
         (value (binding-value-datum datum))
         (loc (stx-source binding)))
    (map (lambda (name)
           (make-binding-fact (datum->string name)
                              (symbol->string head)
                              relpath
                              (source-start-line loc)
                              (source-end-line loc)
                              (or caller "-")
                              (argument-type-name value local-types)))
         names)))
