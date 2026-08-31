;;; -*- Gerbil -*-
;;; Agent-facing macro expansion IO boundary policy.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/sugar filter-map hash ormap)
        :asp-gerbil-scheme/src/types/findings)

(export macro-expansion-io-boundary-findings
        macro-expansion-io-boundary-finding)

;; (List Callee)
(def +macro-expansion-io-callees+
  ["call-with-input-file"
   "open-input-file"
   "with-input-from-file"
   "read-file-lines"])

;; (List Callee)
(def +macro-expansion-path-callees+
  ["path-expand"
   "current-directory"
   "stx-source"
   "current-expander-context"
   "expander-context-id"])

;;; Boundary:
;;; - Parser macro facts own syntax ownership evidence.
;;; - Parser call facts own file IO/path evidence.
;;; - The policy never searches rendered source strings.
;; : (-> ProjectIndex (List TypeFinding) )
(def (macro-expansion-io-boundary-findings index)
  (apply append
         (map (lambda (file)
                (if (pair? (source-file-macros file))
                  (filter-map
                   (lambda (call)
                     (and (member (call-fact-callee call)
                                  +macro-expansion-io-callees+)
                          (macro-expansion-io-boundary-finding
                           file call)))
                   (source-file-calls file))
                  '()))
              (project-index-files index))))

;; : (-> SourceFile (List String) )
(def (macro-expansion-io-boundary-macro-names file)
  (map macro-fact-name (source-file-macros file)))

;; : (-> SourceFile (List String) )
(def (macro-expansion-io-boundary-path-calls file)
  (map call-fact-callee
       (filter (lambda (call)
                 (member (call-fact-callee call)
                         +macro-expansion-path-callees+))
               (source-file-calls file))))

;; : (-> SourceFile CallFact TypeFinding )
(def (macro-expansion-io-boundary-finding file call)
  (make-type-finding
   (policy-rule-id +agent-macro-expansion-io-boundary-rule+)
   (policy-rule-severity +agent-macro-expansion-io-boundary-rule+)
   (source-file-path file)
   (string-append
    "macro owner performs expansion-time file IO with "
    (call-fact-callee call)
    "; keep macro expansion thin and move fragment loading/path resolution behind an explicit source-backed helper or build artifact boundary")
   (call-fact-selector call)
   (hash (kind "macro-expansion-io-boundary")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (macros (macro-expansion-io-boundary-macro-names file))
         (pathCalls (macro-expansion-io-boundary-path-calls file))
         (guidanceMode "quality-warning")
         (trigger "file IO call in a parser-owned macro source file")
         (allowedMacroShape "thin syntax-case/syntax-rules transformer over visible syntax payloads or precomputed artifacts")
         (risk "AI-generated macro code often hides filesystem reads, path derivation, syntax conversion, and runtime behavior inside one transformer")
         (sourceEvidence "gerbil://core/expander.ss exposes syntax/phase APIs; poo-flow/src/module-system/init-syntax.ss demonstrates a real compile-time fragment loading boundary")
         (repairStrategies ["syntax-payload-instead-of-file-read"
                            "separate-expansion-path-resolution-helper"
                            "precompute-fragment-build-artifact"
                            "document-runtime-source-witness"])
         (next "split expansion-time IO from transformer generation or replace the macro file read with explicit syntax payloads"))))
