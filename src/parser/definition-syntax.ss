;;; -*- Gerbil -*-
;;; Lightweight top-level definition facts shared by full and exact parsing.

(import :gerbil/expander
        (only-in :asp-gerbil-scheme/src/parser/formals
                 definition-name-datums
                 definition-formal-names
                 definition-formal-arity)
        (only-in :asp-gerbil-scheme/src/parser/model make-definition)
        (only-in :asp-gerbil-scheme/src/parser/support
                 datum->string
                 source-start-line
                 source-end-line)
        (only-in :asp-gerbil-scheme/src/parser/syntax-support
                 +definition-heads+
                 +macro-definition-heads+))

(export +definition-heads+
        +macro-definition-heads+
        definitions-from-form)

;; This is the common parser-owned definition projection.  Keep the full
;; source parser and the exact-owner fast path on the same fact constructor.
;; : (-> Relpath Syntax Datum (List Definition))
(def (definitions-from-form relpath form datum)
  (let ((head (car datum))
        (name-datums (definition-name-datums datum)))
    (map (lambda (name)
           (let* ((loc (stx-source form))
                  (start (source-start-line loc))
                  (end (source-end-line loc)))
             (make-definition (datum->string name) (symbol->string head)
                              relpath start end
                              (definition-formal-names datum name)
                              (definition-formal-arity datum name))))
         name-datums)))
