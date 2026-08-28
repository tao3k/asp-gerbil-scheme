;;; -*- Gerbil -*-
;;; Native owner-local Gerbil syntax projection for one exact owner.

(import :gerbil/expander
        :gerbil/gambit
        (only-in :gslph/src/parser/definition-syntax
                 +definition-heads+
                 definitions-from-form)
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/13 string-prefix?))

(export parse-exact-owner-definitions
        read-exact-owner-forms)

(def (read-exact-owner-forms source-path)
  ;; SearchProjection owns syntax facts for this source owner only.  Import
  ;; expansion and library resolution belong to ProjectResolution and must not
  ;; make an ordinary exact-owner read depend on unrelated workspace files.
  ;; An explicit #lang declaration is different: its phase-1 reader is the
  ;; provider-owned syntax hook that turns an embedded DSL into Gerbil forms.
  (parameterize ((current-output-port (open-output-string))
                 (current-error-port (open-output-string)))
    (let (lines (read-file-lines source-path))
      (if (and (pair? lines) (string-prefix? "#lang" (car lines)))
        (read-exact-owner-lang-forms source-path)
        (let (body (read-syntax-from-file source-path))
          (if (stx-list? body) (stx-map identity body) [body]))))))

(def (read-exact-owner-lang-forms source-path)
  ;; Gerbil's normal runtime initializer installs :gerbil/core as the module
  ;; prelude.  A statically linked provider process does not inherit that
  ;; mutable expander parameter, so restore the same upstream invariant only
  ;; while invoking an explicit #lang reader.
  (let (default-prelude
        (or (current-expander-module-prelude)
            (make-prelude-context (core-import-module ':gerbil/core))))
    (parameterize ((current-expander-module-prelude default-prelude))
      (let* (((values _prelude _module-id _module-ns body)
              (core-read-module source-path)))
        (if (stx-list? body) (stx-map identity body) [body])))))

(def (parse-exact-owner-definitions source-path owner-path)
  (let (forms (read-exact-owner-forms source-path))
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
            (loop (cdr rest) next-definitions))))))

(def (prepend-definitions incoming out)
  (let loop ((rest incoming) (out out))
    (if (null? rest)
      out
      (loop (cdr rest) (cons (car rest) out)))))
