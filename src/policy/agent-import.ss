;;; -*- Gerbil -*-
;;; Agent-facing import precision policy.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-support
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/srfi/13 string-prefix?)
        :asp-gerbil-scheme/src/types/findings)

(export explicit-precise-import-findings
        explicit-precise-import-finding)

;; Command
(def +explicit-precise-import-guide-command+
  "asp gerbil-scheme guide --code --topic explicit-precise-import --intent repair")

;;; Entry boundary: policy consumes parser-owned module import facts.
;;; It does not infer imported names from raw source text.
;; : (-> ProjectIndex (List TypeFinding) )
(def (explicit-precise-import-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (cut explicit-precise-import-finding index file <>)
                 (source-file-module-imports file)))
              (project-index-files index))))

;; : (-> ProjectIndex SourceFile ModuleImportFact TypeFinding )
(def (explicit-precise-import-finding index file fact)
  (and (index-source-runtime-file-path? index (source-file-path file))
       (imprecise-runtime-import? fact)
       (not (reexported-import? file fact))
       (make-type-finding
        (policy-rule-id +agent-explicit-precise-import-rule+)
        (policy-rule-severity +agent-explicit-precise-import-rule+)
        (source-file-path file)
        (explicit-precise-import-message fact)
        (module-import-fact-selector fact)
        (explicit-precise-import-details fact))))

;; : (-> ModuleImportFact Boolean )
(def (imprecise-runtime-import? fact)
  (and (equal? (module-import-fact-phase fact) "runtime")
       (governed-import-module? (module-import-fact-module fact))
       (or (equal? (module-import-fact-modifier fact) "direct")
           (and (equal? (module-import-fact-modifier fact) "only-in")
                (null? (module-import-fact-symbols fact))))))

;;; Boundary:
;;; - A direct import that is immediately re-exported with `(export (import: ...))`
;;;   is a public interface surface, not a private runtime dependency.
;;; - Parser-owned export facts make the exception explicit without scanning text.
;; : (-> SourceFile ModuleImportFact Boolean )
(def (reexported-import? file fact)
  (let ((module (module-import-fact-module fact))
        (phase (module-import-fact-phase fact)))
    (and (equal? phase "runtime")
         (let loop ((exports (source-file-module-exports file)))
           (cond
            ((null? exports) #f)
            ((and (equal? (module-export-fact-modifier (car exports)) "import:")
                  (equal? (module-export-fact-module (car exports)) module))
             #t)
            (else
             (loop (cdr exports))))))))

;; : (-> ModuleName Boolean )
(def (governed-import-module? module)
  (or (string-prefix? ":std/" module)
      (string-prefix? ":clan/" module)
      (string-prefix? "./" module)
      (string-prefix? "../" module)))

;; : (-> ModuleImportFact Selector )
(def (module-import-fact-selector fact)
  (string-append (module-import-fact-path fact)
                 ":"
                 (number->string (module-import-fact-start fact))
                 "-"
                 (number->string (module-import-fact-end fact))))

;; : (-> ModuleImportFact String )
(def (explicit-precise-import-message fact)
  (string-append
   "runtime import " (module-import-fact-module fact)
   " is not explicit enough; use (only-in "
   (module-import-fact-module fact)
   " <symbols...>) after checking owner usage"))

;;; Boundary: repair details carry exact parser evidence so agents do not guess symbols.
;; : (-> ModuleImportFact Json )
(def (explicit-precise-import-details fact)
  (hash (styleGuide "explicit-precise-import")
        (styleCommand +explicit-precise-import-guide-command+)
        (repairAction "replace-broad-import-with-only-in")
        (module (module-import-fact-module fact))
        (phase (module-import-fact-phase fact))
        (modifier (module-import-fact-modifier fact))
        (importedSymbols (module-import-fact-symbols fact))
        (missingEvidence (explicit-precise-import-missing-evidence fact))
        (agentRepairStandard
         "Prefer explicit (only-in <module> <symbols...>) imports for runtime libraries, dependency packages, and owner-local helper modules. Use parser/query evidence to identify the actual symbols; do not guess from broad module names.")
        (allowedMoves
         ["replace direct runtime import with only-in"
          "add the exact imported symbols used by this owner"
          "keep phase-specific imports explicit when the import is for syntax or template use"
          "leave runtime substrate modules alone unless parser evidence identifies a narrower stable surface"])
        (disallowedMoves
         ["do not satisfy the rule with (only-in <module>) and no symbols"
          "do not replace the import with a different dependency"
          "do not infer symbol usage from raw text heuristics"])
        (nativeFactSource
         "parser-owned moduleImportFacts: module, phase, modifier, imported symbols, and selector")
        (exampleShape
         (string-append "(import (only-in "
                        (module-import-fact-module fact)
                        " <symbols...>))"))
        (next +explicit-precise-import-guide-command+)))

;; : (-> ModuleImportFact (List MissingEvidence) )
(def (explicit-precise-import-missing-evidence fact)
  (cond
   ((equal? (module-import-fact-modifier fact) "direct")
    ["only-in-import-surface" "imported-symbol-list"])
   ((null? (module-import-fact-symbols fact))
    ["imported-symbol-list"])
   (else [])))
