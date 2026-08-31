;;; -*- Gerbil -*-
;;; Query-free parser projection command for ASP lifecycle import.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/language-projection
        (only-in :asp-gerbil-scheme/src/protocol/json-output write-json-line)
        (only-in :std/misc/path path-normalize)
        :asp-gerbil-scheme/src/support/args)

(export projection-main)

;;; This command is a native parser capability, not a search or index command.
;;; It owns neither cache nor lifecycle state and requires machine JSON output.
;; : (-> (List ProjectionCommandArgument) Integer)
(def (projection-main args)
  (cond
   ((not (flag? "--json" args))
    (error "projection requires --json"))
   (else
    (let ((owners (positional-args args)))
      (if (and (pair? owners) (null? (cdr owners)))
        (let ((workspace (path-normalize (or (option "--workspace" args) "."))))
          (write-json-line
           (parse-owner-language-projection workspace (car owners)))
          0)
        (error "projection requires exactly one owner path"))))))
