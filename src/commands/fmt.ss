;;; -*- Gerbil -*-
;;; Gerbil Scheme source formatter.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/format/facade
        :asp-gerbil-scheme/src/protocol/json
        (only-in :std/misc/path path-normalize)
        :asp-gerbil-scheme/src/support/args
        :asp-gerbil-scheme/src/support/io)

(export fmt-main)

(def +fmt-schema-id+
  "agent.semantic-protocols.gerbil-scheme-fmt-report")

;; : (-> (List String) Integer)
(def (fmt-main args)
  (let* ((root (path-normalize (or (option "--workspace" args) ".")))
         (json? (flag? "--json" args))
         (check? (flag? "--check" args))
         (targets (positional-args args))
         (files (fmt-target-files root targets))
         (results (map (lambda (path) (fmt-file root path check?)) files))
         (changed (filter fmt-result-changed? results))
         (status (fmt-status check? changed)))
    (if json?
      (write-json-line (fmt-report-json root check? files changed status))
      (display-fmt-report check? files changed status))
    (if (equal? status "diff") 1 0)))

;; : (-> Boolean (List FmtResult) String)
(def (fmt-status check? changed)
  (cond
   ((and check? (pair? changed)) "diff")
   ((pair? changed) "formatted")
   (else "ok")))

;; : (-> String Boolean (List Path) (List FmtResult) String Json)
(def (fmt-report-json root check? files changed status)
  (hash (schemaId +fmt-schema-id+)
        (schemaVersion "1")
        (languageId "gerbil-scheme")
        (projectRoot root)
        (mode (if check? "check" "write"))
        (status status)
        (files (length files))
        (changed (length changed))
        (changedPaths (map car changed))))

;; : (-> Boolean (List Path) (List FmtResult) String Void)
(def (display-fmt-report check? files changed status)
  (emit-field-line
   "[gerbil-fmt]"
   [(line-field "status" status)
    (line-field "mode" (if check? "check" "write"))
    (line-field "files" (length files))
    (line-field "changed" (length changed))])
  (for-each
   (lambda (result)
     (emit-field-line
      "|formatted"
      [(line-field "path" (car result))
       (line-field "changed" (cdr result))]))
   changed))
