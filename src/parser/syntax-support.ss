;;; -*- Gerbil -*-
;;; Shared syntax constants, body projection, macro-family, and top-form helpers.

(import :gerbil/expander
        :asp-gerbil-scheme/src/parser/formals
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/support
        :asp-gerbil-scheme/src/parser/syntax-ast
        (only-in :std/misc/list unique)
        (only-in :std/srfi/1 drop)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :std/sugar filter-map find))

(export +definition-heads+
        +macro-definition-heads+
        +non-call-heads+
        +declarative-top-level-heads+
        form-caller-name
        form-body-datums
        let-head?
        let-body-datums
        let-binding-datums
        let-binding-stxes
        single-let-binding-datum?
        let-body-stxes
        stx-form-body-items
        lambda-body-stxes
        case-lambda-body-stxes
        match-body-stxes
        clause-body-stxes
        let-body-local-types
        binding-types
        sequential-binding-type-env
        binding-type
        argument-type-name
        literal-type-name
        binding-name-datums
        binding-value-datum
        macro-transformer-kind
        macro-phase
        macro-pattern-count
        syntax-rules-datum
        definition-lowering-macro?
        macro-hygienic?
        macro-quality-facets
        datum-has-head?
        top-form-from
        top-form-head-name
        declarative-top-form?
        top-form-datum-head
        form-kind
        declarative-top-level-head?
        module-refs
        export-symbols
        string-datums)

;; ConfigConstant
(def +definition-heads+
  '(def def* define define-values define-syntax
    defstruct defclass .defclass defsyntax defsyntax-for-match defrules defrule
    defsyntax-parameter defsyntax-parameter*
    defsyntax-for-import defsyntax-for-export defsyntax-for-import-export
    defn def-stx defsyntax-stx defsyntax-stx/form
    defalias define-type defmethod .defmethod defgeneric .defgeneric defprotocol .defprotocol
    defcompile-method))
;; ConfigConstant
(def +macro-definition-heads+
  '(define-syntax defsyntax defsyntax-for-match defrules defrule
    defsyntax-parameter defsyntax-parameter*
    defsyntax-for-import defsyntax-for-export defsyntax-for-import-export
    defsyntax-stx defsyntax-stx/form))
;; ConfigConstant
(def +non-call-heads+
  '(quote quasiquote syntax quote-syntax
    package package: prelude: namespace: import export include
    if begin begin0 lambda case-lambda
    let let* letrec let-values let*-values
    cond case and or when unless match
    syntax-case syntax-rules identifier-rules))
;; FFI forms declare native ABI surfaces at module load/compile time.
;; Their nested call facts are declarations, not executable effects.
(def +declarative-top-level-heads+
  '("declare" "c-declare" "c-define-type" "define-c-lambda"
    "begin-ffi" "begin-foreign" "c-define" "namespace"
    "declare-gxtest-memory-exception"))

;; : (-> Datum FormCallerName )
(def (form-caller-name datum)
  (and (pair? datum)
       (let (names (definition-name-datums datum))
         (and (pair? names)
              (null? (cdr names))
              (datum->string (car names))))))
;; : (-> Datum Integer )
(def (form-body-datums datum)
  (let ((head (and (pair? datum) (car datum))))
    (cond
     ((member head +definition-heads+) (safe-cddr datum))
     (else [datum]))))
;; : (-> Head Boolean )
(def (let-head? head)
  (member head '(let let* letrec let-values let*-values)))
;; : (-> Expr Integer )
(def (let-body-datums expr)
  (let ((head (car expr))
        (second (safe-cadr expr)))
    (cond
     ((and (eq? head 'let) (symbol? second))
      (safe-cdddr expr))
     (else (safe-cddr expr)))))
;; : (-> Expr Integer )
(def (let-binding-datums expr)
  (let ((head (car expr))
        (second (safe-cadr expr)))
    (cond
     ((and (eq? head 'let) (symbol? second))
      (safe-caddr expr))
     ((and (eq? head 'let) (single-let-binding-datum? second))
      [second])
     (else second))))
;; : (-> ExprStx Head LetBindingStxes )
(def (let-binding-stxes expr-stx head)
  (let (items (stx-list-items expr-stx))
    (cond
     ((and (eq? head 'let)
           (pair? (cdr items))
           (symbol? (syntax->datum (cadr items))))
      (stx-list-items (list-safe-caddr items)))
     ((and (eq? head 'let)
           (pair? (cdr items))
           (single-let-binding-datum? (syntax->datum (cadr items))))
      [(cadr items)])
     (else
      (stx-list-items (list-safe-cadr items))))))
;; : (-> Datum Boolean )
(def (single-let-binding-datum? datum)
  (and (pair? datum)
       (symbol? (car datum))
       (pair? (cdr datum))))
;; : (-> ExprStx Head LetBodyStxes )
(def (let-body-stxes expr-stx head)
  (let (items (stx-list-items expr-stx))
    (cond
     ((and (eq? head 'let)
           (pair? (cdr items))
           (symbol? (syntax->datum (cadr items))))
      (if (>= (length items) 3)
        (drop items 3)
        '()))
     (else
      (if (>= (length items) 2)
        (drop items 2)
        '())))))
;; : (-> Form Datum Integer )
(def (stx-form-body-items form datum)
  (let (items (stx-list-items form))
    (if (and (pair? datum) (member (car datum) +definition-heads+))
      (if (>= (length items) 2)
        (drop items 2)
        '())
      [form])))
;; : (-> ExprStx LambdaBodyStxes )
(def (lambda-body-stxes expr-stx)
  (let (items (stx-list-items expr-stx))
    (if (>= (length items) 2)
      (drop items 2)
      '())))
;;; Boundary:
;;; - case-lambda-body-stxes composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ExprStx CaseLambdaBodyStxes )
(def (case-lambda-body-stxes expr-stx)
  (apply append
         (map clause-body-stxes
              (cdr (stx-list-items expr-stx)))))
;;; Boundary:
;;; - match-body-stxes composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ExprStx MatchBodyStxes )
(def (match-body-stxes expr-stx)
  (let (items (stx-list-items expr-stx))
    (append (if (pair? (cdr items)) [(cadr items)] '())
            (apply append
                   (map clause-body-stxes
                        (if (>= (length items) 2)
                          (drop items 2)
                          '()))))))
;; : (-> ClauseStx ClauseBodyStxes )
(def (clause-body-stxes clause-stx)
  (let (items (stx-list-items clause-stx))
    (if (>= (length items) 1)
      (drop items 1)
      '())))
;; let-body-local-types
;;   : (-> Head (List Binding) LocalTypes LocalTypes)
;;   | doc m%
;;       `let-body-local-types head bindings local-types` extends the local type
;;       environment for let bodies, preserving sequential semantics for `let*`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (let-body-local-types 'let* bindings local-types)
;;       ;; => local type environment
;;       ```
;;     %
(def (let-body-local-types head bindings local-types)
  (cond
   ((not (pair? bindings)) local-types)
   ((member head '(let* let*-values))
    (sequential-binding-type-env bindings local-types))
   (else
    (append (binding-types bindings local-types) local-types))))
;; binding-types
;;   : (-> (List Binding) LocalTypes (List TypeBinding))
;;   | doc m%
;;       `binding-types bindings local-types` extracts type bindings from let
;;       binding datums without applying sequential environment updates.
;;
;;       # Examples
;;
;;       ```scheme
;;       (binding-types bindings local-types)
;;       ;; => type bindings
;;       ```
;;     %
(def (binding-types bindings local-types)
  (filter-map (cut binding-type <> local-types)
              (datum-list-items bindings)))
;; sequential-binding-type-env
;;   : (-> (List Binding) LocalTypes LocalTypes)
;;   | doc m%
;;       `sequential-binding-type-env bindings local-types` extends the local
;;       type environment one binding at a time for `let*`-style semantics.
;;
;;       # Examples
;;
;;       ```scheme
;;       (sequential-binding-type-env bindings local-types)
;;       ;; => local type environment
;;       ```
;;     %
(def (sequential-binding-type-env bindings local-types)
  (foldl (lambda (binding env)
           (let (type-binding (binding-type binding env))
             (if type-binding (cons type-binding env) env)))
         local-types
         (datum-list-items bindings)))
;; : (-> Binding LocalTypes TypeSpec )
(def (binding-type binding local-types)
  (and (pair? binding)
       (symbol? (car binding))
       (pair? (cdr binding))
       (let (type-name (argument-type-name (cadr binding) local-types))
         (and type-name (cons (datum->string (car binding)) type-name)))))

;; : (-> Datum LocalTypes TypeSpec )
(def (argument-type-name datum local-types)
  (or (literal-type-name datum)
      (and (symbol? datum)
           (let (found (assoc (datum->string datum) local-types))
             (and found (cdr found))))))

;; : (-> Datum TypeSpec )
(def (literal-type-name datum)
  (cond
   ((number? datum) "number")
   ((string? datum) "string")
   ((boolean? datum) "bool")
   ((char? datum) "char")
   (else #f)))

;; binding-name-datums
;;   : (-> Binding (List Symbol))
;;   | doc m%
;;       `binding-name-datums binding` returns every symbol introduced by a
;;       binding pattern.
;;
;;       # Examples
;;
;;       ```scheme
;;       (binding-name-datums '(x 1))
;;       ;; => (x)
;;       ```
;;     %
(def (binding-name-datums binding)
  (cond
   ((and (pair? binding) (symbol? (car binding))) [(car binding)])
   ((and (pair? binding) (pair? (car binding)))
    (filter symbol? (flatten (car binding))))
   (else '())))
;; : (-> Binding BindingValueDatum )
(def (binding-value-datum binding)
  (and (pair? binding) (pair? (cdr binding)) (cadr binding)))

;; : (-> Datum (List Symbol) Boolean)
(def (datum-has-head? datum heads)
  (cond
   ((pair? datum)
    (or (and (symbol? (car datum)) (member (car datum) heads))
        (datum-list-has-head? datum heads)))
   ((vector? datum)
    (datum-list-has-head? (vector->list datum) heads))
   (else #f)))

;; : (-> (List Datum) (List Symbol) Boolean)
(def (datum-list-has-head? datums heads)
  (and (pair? datums)
       (or (datum-has-head? (car datums) heads)
           (datum-list-has-head? (cdr datums) heads))))

;; : (-> Datum String )
(def (macro-transformer-kind datum)
  (cond
   ((tree-contains-symbol? datum 'syntax-rules) "syntax-rules")
   ((tree-contains-symbol? datum 'identifier-rules) "identifier-rules")
   ((tree-contains-symbol? datum 'syntax-case) "syntax-case")
   ((tree-contains-symbol? datum 'datum->syntax) "datum->syntax")
   ((tree-contains-symbol? datum 'lambda) "lambda-transformer")
   (else "macro-transformer")))
;; : (-> Head String )
(def (macro-phase head)
  (cond
   ((eq? head 'defsyntax-for-match) "match")
   ((eq? head 'defsyntax-for-import) "import")
   ((eq? head 'defsyntax-for-export) "export")
   ((eq? head 'defsyntax-for-import-export) "import-export")
   (else "syntax")))
;; : (-> Datum Integer )
(def (macro-pattern-count datum)
  (let (head (and (pair? datum) (car datum)))
    (cond
     ((eq? head 'defrule) 1)
     ((eq? head 'defrules) (max 0 (length (safe-cdddr datum))))
     ((tree-contains-symbol? datum 'syntax-rules)
      (max 0 (length (safe-cddr (syntax-rules-datum datum)))))
     (else 0))))
;; syntax-rules-datum
;;   : (-> Datum Datum)
;;   | doc m%
;;       `syntax-rules-datum datum` finds the first nested `syntax-rules` form,
;;       or returns the empty list when none is present.
;;
;;       # Examples
;;
;;       ```scheme
;;       (syntax-rules-datum '(defrules f () ((_ x) x)))
;;       ;; => ()
;;       ```
;;     %
(def (syntax-rules-datum datum)
  (or (find (lambda (item)
              (and (pair? item) (eq? (car item) 'syntax-rules)))
            (flatten-with-pairs datum))
      '()))

;;; A definition-lowering macro is safe at module top level only when every
;;; declarative branch expands directly to a native definition form.  This is
;;; deliberately stricter than accepting `begin` or recursively searching a
;;; template: mixed definition/effect templates must remain visible to R005.
;; : (-> Head Datum Boolean)
(def (definition-lowering-macro? head datum)
  (let (clauses
        (cond
         ((eq? head 'defrule) (safe-cddr datum))
         ((eq? head 'defrules) (safe-cdddr datum))
         ((tree-contains-symbol? datum 'syntax-rules)
          (safe-cddr (syntax-rules-datum datum)))
         (else '())))
    (and (pair? clauses)
         (andmap definition-lowering-clause? clauses))))

;; : (-> Datum Boolean)
(def (definition-lowering-clause? clause)
  (and (pair? clause)
       (pair? (cdr clause))
       (let (template (cadr clause))
         (and (pair? template)
              (symbol? (car template))
              (member (car template) +definition-heads+)))))
;; : (-> Datum Boolean )
(def (macro-hygienic? datum)
  (let (head (and (pair? datum) (car datum)))
    (if (or (member head '(defrule defrules))
            (tree-contains-symbol? datum 'syntax-rules)
            (tree-contains-symbol? datum 'identifier-rules)
            (tree-contains-symbol? datum 'syntax-case)
            (tree-contains-symbol? datum 'quote-syntax)
            (tree-contains-symbol? datum 'datum->syntax)
            (tree-contains-symbol? datum 'syntax))
      #t
      #f)))

;;; Macro quality facets expose Gerbil-specific macro engineering evidence to policy/search without relying on prose heuristics.
;; : (-> Head Datum (List QualityFacet) )
(def (macro-quality-facets head datum)
  (unique
   (filter identity
           [(and (macro-hygienic? datum) "hygienic-macro")
            (and (member head '(defrule defrules)) "macro-sugar")
            (and (or (member head '(defrule defrules))
                     (tree-contains-symbol? datum 'syntax-rules)
                     (tree-contains-symbol? datum 'identifier-rules))
                 "declarative-macro-pattern")
            (and (tree-contains-symbol? datum 'syntax-rules)
                 "syntax-rules-pattern")
            (and (definition-lowering-macro? head datum)
                 "definition-lowering-macro")
            (and (tree-contains-symbol? datum 'identifier-rules)
                 "identifier-rules-pattern")
            (and (tree-contains-symbol? datum 'syntax-case)
                 "syntax-case-transformer")
            (and (or (tree-contains-symbol? datum 'syntax-case)
                     (tree-contains-symbol? datum 'with-syntax)
                     (tree-contains-symbol? datum 'datum->syntax))
                 "procedural-macro-transformer")
            (and (member head '(defsyntax-parameter defsyntax-parameter*))
                 "syntax-parameter-definition")
            (and (tree-contains-symbol? datum 'syntax-parameterize)
                 "syntax-parameterized-context")
            (and (or (tree-contains-symbol? datum 'syntax-local-value)
                     (tree-contains-symbol? datum 'syntax-local-rewrap))
                 "syntax-local-context-lookup")
            (and (tree-contains-symbol? datum 'syntax-local-value)
                 "syntax-local-registry-lookup")
            (and (or (tree-contains-symbol? datum 'make-hash-table)
                     (tree-contains-symbol? datum 'hash-put!)
                     (tree-contains-symbol? datum 'hash-get))
                 "manual-syntax-registry-table")
            (and (tree-contains-symbol? datum 'syntax->datum)
                 "syntax-datum-registry-key")
            (and (tree-contains-symbol? datum 'let-syntax)
                 "phase-local-syntax-binding")
            (and (tree-contains-symbol? datum 'set!)
                 "global-macro-state-mutation")
            (and (or (tree-contains-symbol? datum 'identifier?)
                     (tree-contains-symbol? datum 'identifier-list?)
                     (tree-contains-symbol? datum 'stx-identifier?)
                     (tree-contains-symbol? datum 'stx-andmap))
                 "syntax-object-validation")
            (and (or (tree-contains-symbol? datum 'with-syntax)
                     (tree-contains-symbol? datum 'datum->syntax)
                     (tree-contains-symbol? datum 'stx-identifier))
                 "identifier-reconstruction")
            (and (tree-contains-symbol? datum 'with-syntax)
                 "with-syntax-reconstruction")
            (and (tree-contains-symbol? datum 'raise-syntax-error)
                 "source-aware-syntax-error")
            (and (member head '(defsyntax-for-match
                                defsyntax-for-import
                                defsyntax-for-export
                                defsyntax-for-import-export))
                 "phase-specific-macro")
            (and (member head '(defsyntax-for-match
                                defsyntax-for-import
                                defsyntax-for-export
                                defsyntax-for-import-export))
                 "phase-extension-hook")
            (and (tree-contains-symbol? datum 'datum->syntax)
                 "datum->syntax-witness")
            (and (or (tree-contains-symbol? datum 'syntax)
                     (tree-contains-symbol? datum 'quote-syntax))
                 "syntax-template-witness")
            (and (tree-contains-symbol? datum 'lambda)
                 "lambda-transformer")
            (and (tree-contains-symbol? datum 'def)
                 "generated-runtime-helper")
            (and (tree-contains-symbol? datum 'apply)
                 "macro-template-dynamic-apply")
            (and (or (tree-contains-symbol? datum 'let)
                     (tree-contains-symbol? datum 'let*)
                     (tree-contains-symbol? datum 'letrec))
                 "macro-template-runtime-binding")])))

;; : (-> Relpath Form Datum TopFormFrom )
(def (top-form-from relpath form datum)
  (let* ((head (top-form-datum-head datum))
         (loc (stx-source form)))
    (make-top-form (form-kind head) (top-form-head-name head) relpath
                   (source-start-line loc) (source-end-line loc)
                   (syntax-ast-from-form relpath form
                                         (form-caller-name datum)))))
;; : (-> Head String )
(def (top-form-head-name head)
  (if head
    (datum->string head)
    "form"))
;; : (-> TopForm Boolean )
(def (declarative-top-form? form)
  (equal? (top-form-kind form) "declarative"))
;; : (-> Datum Head )
(def (top-form-datum-head datum)
  (cond
   ((pair? datum) (car datum))
   ((symbol? datum) datum)
   (else #f)))
;; : (-> Head String )
(def (form-kind head)
  (cond
   ((eq? head 'package:) "package")
   ((eq? head 'prelude:) "prelude")
   ((eq? head 'namespace:) "namespace")
   ((eq? head 'import) "import")
   ((eq? head 'export) "export")
   ((eq? head 'include) "include")
   ((declarative-top-level-head? head) "declarative")
   ((member head +definition-heads+) "definition")
   (else "form")))
;; : (-> Head Boolean )
(def (declarative-top-level-head? head)
  (and head (member (datum->string head) +declarative-top-level-heads+)))
;; module-refs
;;   : (-> Datum (List String))
;;   | doc m%
;;       `module-refs datum` returns string and colon-prefixed symbol module
;;       references found in a datum tree.
;;
;;       # Examples
;;
;;       ```scheme
;;       (module-refs '(import :std/sugar "support.ss"))
;;       ;; => (":std/sugar" "support.ss")
;;       ```
;;     %
(def (module-refs datum)
  (unique
   (filter-map
    (lambda (item)
      (cond
       ((string? item) item)
       ((and (symbol? item) (string-prefix? ":" (symbol->string item)))
        (symbol->string item))
       (else #f)))
    (flatten datum))))
;; export-symbols
;;   : (-> Datum (List String))
;;   | doc m%
;;       `export-symbols datum` returns exported symbol names while skipping
;;       import/export adapter markers and module refs.
;;
;;       # Examples
;;
;;       ```scheme
;;       (export-symbols '(export foo (rename: bar baz)))
;;       ;; => ("foo" "bar" "baz")
;;       ```
;;     %
(def (export-symbols datum)
  (unique
   (filter-map
    (lambda (item)
      (and (symbol? item)
           (let (s (symbol->string item))
             (and (not (member s '("export" "import:" "except-out" "rename:" "phi:" "only-in")))
                  (not (string-prefix? ":" s))
                  s))))
    (flatten datum))))
;; string-datums
;;   : (-> Datum (List String))
;;   | doc m%
;;       `string-datums datum` returns every string datum found in a flattened
;;       datum tree.
;;
;;       # Examples
;;
;;       ```scheme
;;       (string-datums '(include "a.ss" "b.ss"))
;;       ;; => ("a.ss" "b.ss")
;;       ```
;;     %
(def (string-datums datum)
  (filter string? (flatten datum)))
