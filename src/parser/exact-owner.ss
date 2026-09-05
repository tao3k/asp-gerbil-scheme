;;; -*- Gerbil -*-
;;; Native-reader fast path for one exact owner; no project analysis/cache.
;;; The reader preserves native syntax objects and suppresses incidental output
;;; only while reading; definition projection stays parser-owned and pure.

(import :gerbil/expander
        :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/parser/definition-syntax
                 +definition-heads+
                 definitions-from-form)
        (only-in :std/srfi/1 fold))

(export parse-exact-owner-definitions
        read-exact-owner-forms)

;; : (-> Path (List Syntax))
(def (read-exact-owner-forms source-path)
  (parameterize ((current-output-port (open-output-string))
                 (current-error-port (open-output-string)))
    (let (body (read-syntax-from-file source-path))
      (if (stx-list? body) (stx-map identity body) [body]))))

;; : (-> Path Relpath (List Definition))
(def (parse-exact-owner-definitions source-path owner-path)
  (let (forms (read-exact-owner-forms source-path))
    (reverse
     (fold
      (lambda (form definitions)
        (let* ((datum (syntax->datum form))
               (head (and (pair? datum) (car datum))))
          (if (member head +definition-heads+)
            (fold cons
                  definitions
                  (definitions-from-form owner-path form datum))
            definitions)))
      '()
      forms))))
