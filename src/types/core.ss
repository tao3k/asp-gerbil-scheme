;;; -*- Gerbil -*-
;;; Type-check dispatch for Gerbil source projects.

(import :asp-gerbil-scheme/src/parser/model
        (only-in :std/sugar hash ormap)
        :asp-gerbil-scheme/src/types/env
        :asp-gerbil-scheme/src/types/findings
        :asp-gerbil-scheme/src/types/source-findings)

(export type-status
        run-type-checks
        run-type-checks/signatures
        run-type-checks/whitelist
        source-file-type-findings)
;;; Boundary:
;;; - type-status composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypeFinding) Status )
(def (type-status findings)
  (if (ormap non-info-finding? findings) "fail" "pass"))
;; : (-> TypeFinding Boolean )
(def (non-info-finding? finding)
  (not (equal? (type-finding-severity finding) "info")))
;; : (-> ProjectIndex (List TypeFinding) )
(def (run-type-checks index)
  (run-type-checks/signatures index '()))
;; : (-> ProjectIndex NativeSignatures (List TypeFinding) )
(def (run-type-checks/signatures index signatures)
  (run-type-checks/whitelist index signatures '()))
;;; Boundary:
;;; - run-type-checks/whitelist composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex NativeSignatures Whitelist (List TypeFinding) )
(def (run-type-checks/whitelist index signatures whitelist)
  (void whitelist)
  (append
   (apply append (map source-file-type-findings (project-index-files index)))
   (type-env-findings (build-type-env/signatures index signatures))))
;;; Boundary:
;;; - type-env-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypeFinding) (List TypeFinding) )
(def (type-env-findings bindings)
  (map duplicate-binding-finding (duplicate-type-bindings bindings)))
;; : (-> Duplicate TypeFinding )
(def (duplicate-binding-finding duplicate)
  (let ((binding (car duplicate))
        (prior (cadr duplicate)))
    (make-type-finding "GERBIL-SCHEME-TYPE-E001"
                       "error"
                       (type-binding-path binding)
                       (string-append "duplicate type binding for " (type-binding-name binding))
                       (type-binding-selector binding)
                       (hash (firstSelector (type-binding-selector prior))
                             (duplicateSelector (type-binding-selector binding))))))
