;;; -*- Gerbil -*-
;;; Query-free parser projection command for ASP lifecycle import.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/parser/language-projection
        (only-in :asp-gerbil-scheme/src/protocol/json-output write-json-line)
        :asp-gerbil-scheme/src/protocol/structural-index
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
    ((flag? "--native-index" args)
     (let* ((workspace (path-normalize (or (option "--workspace" args) ".")))
             (index (collect-project-package-only workspace))
             (owner (option "--owner" args))
             (artifact? (flag? "--artifact" args)))
       (write-json-line
        (cond
         (owner
          (let (file (find-owner index owner))
            (unless file (error "owner not found" owner))
            (native-syntax-owner-facts-packet-json index file)))
         (artifact? (structural-index-artifact-packet-json index))
         (else (structural-index-packet-json index))))
       0))
    (else
    (let ((owners (positional-args args)))
      (if (and (pair? owners) (null? (cdr owners)))
        (let ((workspace (path-normalize (or (option "--workspace" args) "."))))
          (write-json-line
           (parse-owner-language-projection workspace (car owners)))
          0)
        (error "projection requires exactly one owner path"))))))
