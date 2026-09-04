;;; -*- Gerbil -*-
;;; Agent macro/protocol witness and facade export conflict checks.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-support
        :asp-gerbil-scheme/src/policy/gerbil-utils-source
        :asp-gerbil-scheme/src/policy/model
        :asp-gerbil-scheme/src/policy/modularity
        (only-in :std/misc/path path-directory path-expand path-simplify)
        (only-in :std/srfi/13 string-contains string-suffix?)
        (only-in :std/sugar filter-map hash hash-key? hash-put! ormap while)
        :asp-gerbil-scheme/src/types/findings)

(export macro-runtime-source-witness-findings
        macro-runtime-source-witness-finding
        protocol-evidence-findings
        protocol-evidence-finding
        facade-export-conflict-findings)

;; A witness is executable project evidence, not package metadata: an asserting
;; test either invokes the macro directly or loads/includes its exact case owner.
(def +macro-runtime-source-witness-assertions+
  '("check" "check-equal?" "check-exception" "check-output"))
(def +macro-runtime-source-witness-loaders+
  '("load" "load!"))
;;; Boundary:
;;; - The project index is traversed once to derive executable witness names.
;;; - A witness owner either contains its own assertion or is reached through
;;;   an exact load/include edge from an asserting test owner.
;; : (-> ProjectIndex (List TypeFinding) )
(def (macro-runtime-source-witness-findings index)
  (let (witnesses (macro-runtime-source-witness-index index))
    (apply append
           (map (lambda (file)
                  (if (index-source-runtime-file-path? index
                                                       (source-file-path file))
                    (filter-map
                     (lambda (fact)
                       (and (not (hash-key? witnesses (macro-fact-name fact)))
                            (macro-runtime-source-witness-finding file fact)))
                     (source-file-macros file))
                    '()))
                (project-index-files index)))))

;; : (-> ProjectIndex HashTable)
(def (macro-runtime-source-witness-index index)
  (let ((files (project-index-files index))
        (asserted-owner-paths (make-hash-table))
        (witnesses (make-hash-table)))
    (for-each
     (lambda (test-owner)
       (when (and (macro-runtime-source-test-owner? index test-owner)
                  (macro-runtime-source-assertion-owner? test-owner))
         (hash-put! asserted-owner-paths
                    (macro-runtime-source-owner-path index test-owner)
                    #t)
         (for-each (lambda (path)
                     (hash-put! asserted-owner-paths path #t))
                   (macro-runtime-source-linked-owner-paths
                    index test-owner))))
     files)
    (for-each
     (lambda (owner)
       (when (hash-key? asserted-owner-paths
                        (macro-runtime-source-owner-path index owner))
         (for-each (lambda (callee)
                     (hash-put! witnesses callee #t))
                   (macro-runtime-source-invocation-names owner))))
     files)
    witnesses))

;; : (-> ProjectIndex SourceFile Boolean)
(def (macro-runtime-source-test-owner? index owner)
  (let* ((package (project-index-package index))
         (policy (and package
                      (project-package-test-directory-policy package)))
         (roots (if policy
                  (or (test-directory-policy-allowed-directories policy) '())
                  ["t"])))
    (ormap (lambda (root)
             (source-path-under-root? (source-file-path owner) root))
           roots)))

;; : (-> SourceFile Boolean)
(def (macro-runtime-source-assertion-owner? owner)
  (ormap (lambda (assertion)
           (source-file-invokes? owner assertion))
         +macro-runtime-source-witness-assertions+))

;; : (-> ProjectIndex SourceFile Path)
(def (macro-runtime-source-owner-path index owner)
  (macro-runtime-source-canonical-path
   (path-expand (source-file-path owner) (project-index-root index))))

;; : (-> ProjectIndex SourceFile (List Path))
(def (macro-runtime-source-linked-owner-paths index owner)
  (let* ((owner-path (macro-runtime-source-owner-path index owner))
         (owner-directory (path-directory owner-path)))
    (apply append
           (map (lambda (path)
                  (map macro-runtime-source-canonical-path
                       (macro-runtime-source-linked-paths
                        index owner-directory path)))
                (append
                 (source-file-includes owner)
                 (filter-map macro-runtime-source-load-path
                             (source-file-calls owner)))))))

;; Catalog facts may retain either workspace-relative or owner-relative load
;; paths. Project both candidates into the in-memory owner index; the exact
;; collected owner match selects the valid identity without probing the
;; filesystem or embedding a test-directory convention in this policy.
;; : (-> ProjectIndex Path Path (List Path))
(def (macro-runtime-source-linked-paths index owner-directory path)
  (let ((workspace-path (path-expand path (project-index-root index)))
        (owner-path (path-expand path owner-directory)))
    (if (equal? workspace-path owner-path)
      [workspace-path]
      [workspace-path owner-path])))

;; Gerbil's native reader canonicalizes load targets to module stems while the
;; source catalog retains file extensions.  Compare both as source stems.
;; : (-> Path Path)
(def (macro-runtime-source-canonical-path path)
  (let (normalized (path-simplify path))
    (cond
     ((string-suffix? ".ss" normalized)
      (substring normalized 0 (- (string-length normalized) 3)))
     ((string-suffix? ".scm" normalized)
      (substring normalized 0 (- (string-length normalized) 4)))
     (else normalized))))

;; : (-> CallFact (Or Path False))
(def (macro-runtime-source-load-path call)
  (and (member (call-fact-callee call)
               +macro-runtime-source-witness-loaders+)
       (pair? (call-fact-arguments call))
       ;; Call facts already project literal string arguments as strings; the
       ;; exact collected-owner lookup below rejects dynamic or unrelated paths.
       (car (call-fact-arguments call))))

;; : (-> SourceFile (List String))
(def (macro-runtime-source-invocation-names owner)
  (append (map call-fact-callee (source-file-calls owner))
          (map top-form-head (source-file-forms owner))))
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
                  " needs an executable source witness before agent edits; add a collected test owner that invokes the macro directly or loads its exact case owner and asserts observable behaviour")
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
          "one collected test owner with an assertion and either a parser-visible macro call or an exact load/include edge to its case owner"))))
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
