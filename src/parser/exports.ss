;;; -*- Gerbil -*-
;;; Parser-owned export DSL fact extraction.

(import :gerbil/expander
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/support
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-prefix?))

(export module-export-facts-from-form)

;;; Boundary:
;;; - Export facts mirror import facts so agent search can reason about public API shape.
;;; - Keep the retired flat export symbol list separate from this item-scoped DSL evidence.
;; : (-> Relpath Form (List ModuleExportFact) )
(def (module-export-facts-from-form relpath form)
  (filter-map (cut module-export-fact-from-stx relpath <>)
              (cdr (stx-list-items form))))

;;; Boundary:
;;; - Item parsing keeps wrapper syntax, source spans, and public names on one export fact.
;;; - Preserve this join so query/search can explain re-exports without reading the whole module.
;; : (-> Relpath Item (Maybe ModuleExportFact) )
(def (module-export-fact-from-stx relpath item)
  (let* ((datum (syntax->datum item))
         (loc (stx-source item))
         (module (export-module-ref datum))
         (symbols (export-symbol-list datum))
         (name (export-fact-name datum module symbols)))
    (and name
         (make-module-export-fact name
                                  (export-modifier datum)
                                  (export-alias datum symbols)
                                  module
                                  symbols
                                  relpath
                                  (source-start-line loc)
                                  (source-end-line loc)))))

;;; Boundary:
;;; - Export names prefer the public alias, then the explicit module re-export, then the first symbol.
;;; - This keeps search names stable without pretending wrapper forms are simple direct exports.
;; : (-> Datum MaybeModule (List SymbolName) (Maybe String) )
(def (export-fact-name datum module symbols)
  (or (export-alias datum symbols)
      module
      (and (pair? symbols) (car symbols))))

;; : (-> Datum ExportModifier )
(def (export-modifier datum)
  (if (pair? datum)
    (datum->string (car datum))
    "direct"))

;;; Boundary:
;;; - Rename wrappers conventionally expose the last symbol as the public alias.
;;; - Direct exports and module re-exports have no separate alias field.
;; : (-> Datum (List SymbolName) (Maybe String) )
(def (export-alias datum symbols)
  (and (pair? datum)
       (eq? (car datum) 'rename:)
       (pair? symbols)
       (last symbols)))

;;; Module reference scan is wrapper-only.
;;; Direct exports such as :render are public symbols, not module re-exports.
;; : (-> Datum (Maybe ModuleRef) )
(def (export-module-ref datum)
  (and (pair? datum)
       (member (car datum) '(import: only-in except-out phi:))
       (let (found
             (find (lambda (item)
                     (and (symbol? item)
                          (string-prefix? ":" (symbol->string item))))
                   (flatten datum)))
         (and found (symbol->string found)))))

;;; Symbol projection: filter-map keeps only public names and leaves modifier
;;; tokens behind, preserving deterministic export facts for search packets.
;; : (-> Datum (List SymbolName) )
(def (export-symbol-list datum)
  (if (symbol? datum)
    [(symbol->string datum)]
    (unique
     (filter-map
      (lambda (item)
        (and (symbol? item)
             (let (text (symbol->string item))
               (and (export-symbol-name? text) text))))
      (flatten datum)))))

;;; Boundary:
;;; - Export symbol filtering removes DSL control tokens but keeps public API names searchable.
;;; - Keep module references out of symbol facts so runtime/module selectors remain distinct.
;; : (-> String Boolean )
(def (export-symbol-name? text)
  (and (not (member text ["export" "import:" "except-out" "rename:" "phi:" "only-in"]))
       (not (string-prefix? ":" text))))
