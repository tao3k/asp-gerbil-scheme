;;; -*- Gerbil -*-
;;; Parser-owned import facts for Gerbil module forms.

(import :gerbil/expander
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/support
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-prefix?))

(export module-import-facts-from-form)

;;; Boundary:
;;; - module-import-facts-from-form composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Relpath Form ModuleImportFactsFromForm )
(def (module-import-facts-from-form relpath form)
  (filter-map (cut module-import-fact-from-stx relpath <>)
              (cdr (stx-list-items form))))

;; : (-> Relpath Item ModuleImportFactFromStx )
(def (module-import-fact-from-stx relpath item)
  (let* ((datum (syntax->datum item))
         (loc (stx-source item))
         (module (module-ref-from-import-datum datum)))
    (and module
         (make-module-import-fact module
                                  (import-phase datum)
                                  (import-modifier datum)
                                  (import-alias datum)
                                  (import-symbols datum)
                                  relpath
                                  (source-start-line loc)
                                  (source-end-line loc)))))

;;; Boundary:
;;; Import wrappers can nest the module reference behind only-in/rename-in forms.
;;; The find combinator keeps that search declarative and returns only a module
;;; ref datum accepted by module-ref-datum?, never an arbitrary operand.
;; : (-> Datum ModuleRefFromImportDatum )
(def (module-ref-from-import-datum datum)
  (cond
   ((module-ref-datum? datum) => values)
   ((pair? datum)
    (let (found (find module-ref-datum? (datum-list-items (cdr datum))))
      (and found (module-ref-datum? found))))
   (else #f)))

;; : (-> Datum (Maybe String) )
(def (module-ref-datum? datum)
  (cond
   ((string? datum) datum)
   ((and (symbol? datum) (module-ref-symbol? datum)) (symbol->string datum))
   (else #f)))

;; : (-> Symbol Boolean )
(def (module-ref-symbol? symbol)
  (let (module-ref (symbol->string symbol))
    (or (string-prefix? ":" module-ref)
        (string-prefix? "./" module-ref)
        (string-prefix? "../" module-ref))))

;; : (-> Datum ImportModifier )
(def (import-modifier datum)
  (if (pair? datum)
    (datum->string (car datum))
    "direct"))

;; : (-> Datum String )
(def (import-phase datum)
  (cond
   ((and (pair? datum) (eq? (car datum) 'for-syntax)) "syntax")
   ((and (pair? datum) (eq? (car datum) 'for-template)) "template")
   ((and (pair? datum) (eq? (car datum) 'phi:))
    (let (phase (safe-cadr datum))
      (if phase
        (string-append "phase:" (datum->string phase))
        "phase")))
   (else "runtime")))

;;; Boundary:
;;; - import-symbols composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Datum (List String) )
(def (import-symbols datum)
  (if (pair? datum)
    (unique
     (filter-map
      (lambda (item)
        (and (symbol? item)
             (not (import-control-symbol? item))
             (not (module-ref-symbol? item))
             (symbol->string item)))
      (flatten datum)))
    '()))

;; : (-> Symbol Boolean )
(def (import-control-symbol? symbol)
  (member (symbol->string symbol)
          '("for-syntax" "only-in" "except-in" "rename-in" "rename-out"
            "prefix-in" "prefix:" "rename:" "phi:" "import:" "except-out"
            "for-template" "group-in" "only-out" "prefix-out" "group-out"
            "+1" "-1" "0")))

;; : (-> Datum ImportAlias )
(def (import-alias datum)
  (and (pair? datum)
       (member (car datum) '(rename-in rename-out prefix-in))
       (let (symbols (import-symbols datum))
         (and (pair? symbols) (car symbols)))))
