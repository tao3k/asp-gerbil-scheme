;;; -*- Gerbil -*-
;;; Native-reader fast path for one exact owner; no project analysis/cache.

(import :gerbil/expander
        :gerbil/gambit
        (only-in :gslph/src/parser/definition-syntax
                 +definition-heads+
                 definitions-from-form))

(export parse-exact-owner-definitions)

(def (parse-exact-owner-definitions source-path owner-path)
  (parameterize ((current-output-port (open-output-string))
                 (current-error-port (open-output-string)))
    (let* ((body (read-syntax-from-file source-path))
           (forms (if (stx-list? body) (stx-map identity body) [body])))
      (let loop ((rest forms) (definitions '()))
        (if (null? rest)
          (reverse definitions)
          (let* ((form (car rest))
                 (datum (syntax->datum form))
                 (head (and (pair? datum) (car datum)))
                 (next-definitions
                  (if (member head +definition-heads+)
                    (prepend-definitions
                     (definitions-from-form owner-path form datum)
                     definitions)
                    definitions)))
            (loop (cdr rest) next-definitions)))))))

(def (prepend-definitions incoming out)
  (let loop ((rest incoming) (out out))
    (if (null? rest)
      out
      (loop (cdr rest) (cons (car rest) out)))))
