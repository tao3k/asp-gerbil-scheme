;;; -*- Gerbil -*-
;;; Shared helpers for agent-facing policy rule families.

(import :asp-gerbil-scheme/src/parser/facade
        (only-in :std/srfi/13 string-contains string-empty? string-prefix? string-suffix?)
        (only-in :std/sugar ormap))

(export +poo-declarative-heads+
        +poo-capability-dependencies+
        poo-source-file?
        poo-capability-active?
        poo-capability-dependency?
        source-runtime-file-path?
        index-source-runtime-file-path?
        configured-runtime-roots
        source-path-under-root?
        project-poo-forms
        poo-class-fact-exists?
        poo-protocol-fact-exists?
        blank-string?)
;; ConfigConstant
(def +poo-declarative-heads+
  '(".def" "define-type" "defclass" ".defclass" ".defgeneric" "defmethod" ".defmethod"))
;; Integer
(def +poo-capability-dependencies+
  '("gerbil-poo" "clan/poo"))
;;; Boundary:
;;; - poo-source-file? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile Boolean )
(def (poo-source-file? file)
  (ormap (lambda (import)
           (string-contains import "clan/poo"))
         (source-file-imports file)))
;;; Boundary:
;;; - poo-capability-active? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex Boolean )
(def (poo-capability-active? index)
  (or (ormap poo-source-file? (project-index-files index))
      (ormap (lambda (fact)
               (member (poo-form-fact-role fact)
                       '("class" "generic" "method")))
             (project-poo-forms index))
      (let (package (project-index-package index))
        (and package
             (ormap poo-capability-dependency?
                    (project-package-dependencies package))))))
;;; Boundary:
;;; - poo-capability-dependency? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> String Boolean )
(def (poo-capability-dependency? dependency)
  (ormap (lambda (needle)
           (string-contains dependency needle))
         +poo-capability-dependencies+))
;; : (-> String Boolean )
(def (source-runtime-file-path? path)
  (and (string-prefix? "src/" path)
       (string-suffix? ".ss" path)))
;;; Boundary:
;;; - index-source-runtime-file-path? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex String Boolean )
(def (index-source-runtime-file-path? index path)
  (and (string-suffix? ".ss" path)
       (let* ((package (project-index-package index))
              (policy (and package
                           (project-package-source-scope-policy package)))
              (roots (configured-runtime-roots policy)))
         (ormap (lambda (root)
                  (source-path-under-root? path root))
                roots))))
;; : (-> Policy (List String) )
(def (configured-runtime-roots policy)
  (cond
   ((and policy (pair? (source-scope-policy-runtime-roots policy)))
    (source-scope-policy-runtime-roots policy))
   ((and policy (pair? (source-scope-policy-roots policy)))
    (source-scope-policy-roots policy))
   (else ["src"])))
;; : (-> String String Boolean )
(def (source-path-under-root? path root)
  (or (equal? root ".")
      (equal? path root)
      (string-prefix? (string-append root "/") path)))
;;; Boundary:
;;; - project-poo-forms composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex Integer )
(def (project-poo-forms index)
  (apply append (map source-file-poo-forms (project-index-files index))))
;;; Boundary:
;;; - poo-class-fact-exists? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex ClassName Boolean )
(def (poo-class-fact-exists? index class-name)
  (ormap
   (lambda (fact)
     (and (equal? (poo-form-fact-role fact) "class")
          (equal? (poo-form-fact-name fact) class-name)))
   (project-poo-forms index)))
;;; Boundary:
;;; - poo-protocol-fact-exists? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex ProtocolName Boolean )
(def (poo-protocol-fact-exists? index protocol-name)
  (ormap
   (lambda (fact)
     (and (equal? (poo-form-fact-role fact) "protocol")
          (equal? (poo-form-fact-name fact) protocol-name)))
   (project-poo-forms index)))
;; : (-> MaybeString Boolean )
(def (blank-string? value)
  (or (not value)
      (and (string? value)
           (string-empty? value))))
