;;; -*- Gerbil -*-
;;; Agent macro/protocol witness and facade export conflict checks.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-support
        :asp-gerbil-scheme/src/policy/gerbil-utils-source
        :asp-gerbil-scheme/src/policy/model
        :asp-gerbil-scheme/src/policy/modularity
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar filter-map hash ormap while)
        :asp-gerbil-scheme/src/types/findings)

(export macro-runtime-source-witness-findings
        macro-runtime-source-witness-finding
        protocol-evidence-findings
        protocol-evidence-finding
        facade-export-conflict-findings)

;; A witness is executable project evidence, not package metadata: the same
;; collected owner must invoke the macro and assert observable behaviour.
(def +macro-runtime-source-witness-assertions+
  '("check" "check-equal?" "check-exception" "check-output"))
;;; Boundary:
;;; - Every runtime macro is checked independently against parser-owned call
;;;   evidence in its declared witness owner.
;; : (-> ProjectIndex (List TypeFinding) )
(def (macro-runtime-source-witness-findings index)
  (apply append
         (map (lambda (file)
                (if (index-source-runtime-file-path? index
                                                     (source-file-path file))
                  (filter-map
                   (lambda (fact)
                     (and (not (macro-runtime-source-policy-allows?
                                index fact))
                          (macro-runtime-source-witness-finding file fact)))
                   (source-file-macros file))
                  '()))
              (project-index-files index))))
;; : (-> ProjectIndex MacroFact Boolean )
(def (macro-runtime-source-policy-allows? index fact)
  (ormap (lambda (owner)
           (macro-runtime-source-witness-valid? owner fact))
         (project-index-files index)))
;;; A source owner is evidence only when parser facts prove both sides of the
;;; executable contract: it invokes the named macro and contains an assertion.
;; : (-> SourceFile MacroFact Boolean )
(def (macro-runtime-source-witness-valid? owner fact)
  (and (source-file-invokes? owner (macro-fact-name fact))
       (ormap (lambda (assertion)
                (source-file-invokes? owner assertion))
              +macro-runtime-source-witness-assertions+)))
;; : (-> SourceFile String Boolean )
(def (source-file-invokes? owner callee)
  (or (ormap (lambda (call)
               (equal? (call-fact-callee call) callee))
             (source-file-calls owner))
      (ormap (lambda (form)
               (equal? (top-form-head form) callee))
             (source-file-forms owner))))
;;; Finding boundary:
;;; - The macro fact supplies selector and syntax evidence.
;;; - Details tell agents to fetch runtime-source witnesses before editing macros.
;; : (-> SourceFile MacroFact TypeFinding )
(def (macro-runtime-source-witness-finding file fact)
  (make-type-finding
   (policy-rule-id +agent-macro-runtime-source-witness-rule+)
   (policy-rule-severity +agent-macro-runtime-source-witness-rule+)
   (source-file-path file)
   (string-append "macro " (macro-fact-name fact)
                  " needs an executable source witness before agent edits; add a collected test owner that invokes the macro and asserts observable behaviour")
   (macro-fact-selector fact)
   (hash (macro (macro-fact-name fact))
         (transformer (macro-fact-transformer fact))
         (phase (macro-fact-phase fact))
         (patternCount (macro-fact-pattern-count fact))
         (hygienic (macro-fact-hygienic fact))
         (qualityFacets (macro-fact-quality-facets fact))
         (selector (macro-fact-selector fact))
         (macroFactSource "parser-owned macroFacts from native Gerbil syntax extraction")
         (policyBoundary "macros are allowed when they stay controlled, source-backed, and explainable")
         (runtimeSourceRequirement
          (hash (authority "runtime-version-source")
                (selectorScheme "gerbil-runtime-source")
                (selectorFormat "gerbil-runtime-source://<source-path>#<symbol>")
                (output "code-with-comments")
                (indexOwner "asp-server")))
         (qualityReference
          (gerbil-utils-source-details 'macro-helper))
         (allowedMacroShape
          ["thin syntax bridge"
           "syntax-case transformer with local parsing helpers"
           "defrule/defrules wrapper over visible runtime behavior"
           "for-syntax helper with precise imports"])
         (agentEscapeConstraint
          "do not weaken macro-governance or replace executable evidence with package metadata")
         (next "search runtime-source macro sugar module-sugar")
         (requiredWitness
          "one collected source owner with a parser-visible macro call and test assertion"))))
;;; Boundary:
;;; - protocol-evidence-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex String )
(def (protocol-evidence-findings index)
  (apply append
         (map (lambda (file)
                (if (protocol-context-file? file)
                  (filter-map
                   (lambda (fact)
                     (and (equal? (poo-form-fact-role fact) "method")
                          (not (blank-string? (poo-form-fact-receiver-type fact)))
                          (not (poo-protocol-fact-exists?
                                index
                                (poo-form-fact-receiver-type fact)))
                          (not (poo-class-fact-exists?
                                index
                                (poo-form-fact-receiver-type fact)))
                          (protocol-evidence-finding file fact)))
                   (source-file-poo-forms file))
                  '()))
              (project-index-files index))))
;;; Boundary:
;;; - protocol-context-file? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile Boolean )
(def (protocol-context-file? file)
  (or (ormap protocol-import? (source-file-imports file))
      (ormap (lambda (fact)
               (equal? (poo-form-fact-role fact) "protocol"))
             (source-file-poo-forms file))))
;; : (-> String Boolean )
(def (protocol-import? import)
  (and import (string-contains import "protocol")))
;; : (-> SourceFile Fact String )
(def (protocol-evidence-finding file fact)
  (make-type-finding
   (policy-rule-id +agent-protocol-evidence-rule+)
   (policy-rule-severity +agent-protocol-evidence-rule+)
   (source-file-path file)
   (string-append "protocol method " (poo-form-fact-name fact)
                  " specializes " (poo-form-fact-receiver-type fact)
                  " without parser-owned defprotocol/defclass evidence; declare protocol evidence before implementing methods")
   (poo-form-fact-selector fact)
   (hash (method (poo-form-fact-name fact))
         (receiverType (poo-form-fact-receiver-type fact))
         (generic (or (poo-form-fact-generic fact) ""))
         (next "search pattern poo protocol"))))
;;; Invariant:
;;; - facade-export-conflict-findings owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; : (-> ProjectIndex (List TypeFinding) )
(def (facade-export-conflict-findings index)
  (let ((rest (facade-export-bindings index))
        (seen '())
        (out '()))
    (while (pair? rest)
      (let* ((binding (car rest))
             (name (car binding))
             (file (cdr binding))
             (prior (assoc name seen)))
        (if (and prior
                 (not (equal? (source-file-path file)
                              (source-file-path (cdr prior)))))
          (set! out (cons (export-conflict-finding name file (cdr prior)) out))
          (set! seen (cons binding seen)))
        (set! rest (cdr rest))))
    (reverse out)))
;;; Boundary:
;;; - facade-export-bindings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex (List BindingFact) )
(def (facade-export-bindings index)
  (apply append
         (map (lambda (file)
                (if (facade-source-file? index file)
                  (map (lambda (name) (cons name file))
                       (source-file-exports file))
                  '()))
              (project-index-files index))))
;; : (-> String SourceFile ControlFlowGroup TypeFinding )
(def (export-conflict-finding name file prior)
  (make-type-finding
   (policy-rule-id +agent-export-conflict-rule+)
   (policy-rule-severity +agent-export-conflict-rule+)
   (source-file-path file)
   (string-append "facade export " name
                  " conflicts with another facade export")
   (source-file-path file)
   (hash (export name)
         (firstPath (source-file-path prior))
         (duplicatePath (source-file-path file)))))
