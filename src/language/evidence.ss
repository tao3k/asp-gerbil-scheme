;;; -*- Gerbil -*-
;;; Gerbil language/runtime/std evidence facts for agent-facing search.

(import (only-in :std/srfi/13 string-contains string-index)
        (only-in :std/sugar filter ormap))

(export runtime-bin
        evidence-fact
        active-runtime-facts
        runtime-source-facts
        compiler-evidence-facts
        language-rule-facts
        standard-library-facts
        project-contract-pattern-evidence
        project-contract-pattern-query?
        project-contract-pattern-minimal-forms
        project-contract-pattern-failure-cases
        hygienic-macro-pattern-evidence
        hygienic-macro-pattern-query?
        hygienic-macro-minimal-forms
        hygienic-macro-failure-cases)

;;; Hygienic macro search terms are a query vocabulary, not a parser fact.
;;; Keeping them data-shaped avoids widening the macro evidence predicate with
;;; every synonym we want the agent search path to understand.
;; (List SearchTerm)
(def +hygienic-macro-query-terms+
  '("hygienic-macro" "hygienic" "macro" "defsyntax" "syntax-case"))
;;; Contract projection terms are intentionally stricter than lexical search.
;;; A broad "schema" query is not enough to claim this executable pattern.
;; (List SearchTerm)
(def +project-contract-pattern-query-terms+
  '("poo-flow-json-schema-node->object-type-contract"
    "json-schema-node"
    "object-type-contract"
    "contract-projection"
    "defobject-contract"))
;; : (-> String RuntimeBin )
(def (runtime-bin name)
  (let ((default-bin (path-expand (string-append "bin/" name) (gerbil-home)))
        (sibling-bin (path-expand (string-append "../bin/" name) (gerbil-home))))
    (if (file-exists? default-bin) default-bin sibling-bin)))
;;; Boundary:
;;; - runtime-path-normalize composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> String String )
(def (runtime-path-normalize path)
  (with-catch
   (lambda (_) path)
   (lambda () (path-normalize path))))
;;; Boundary:
;;; - Runtime evidence must prove active tool identity without leaking checkout paths.
;;; - Public paths derive from the active runtime, not from a fixed checkout root.
;; : (-> RuntimePath PublicPath )
(def (runtime-public-path path)
  (if (not path)
    path
    (let* ((home (runtime-path-normalize (gerbil-home)))
           (bin-root (runtime-path-normalize (path-expand "../bin" home))))
      (if (or (string-contains path home)
              (string-contains path bin-root))
        (string-append "gerbil://runtime/" (path-strip-directory path))
        path))))
;; : (-> VersionString GerbilRuntimeTag )
(def (gerbil-runtime-tag version-string)
  (let (start (string-index version-string #\v))
    (and start
         (let* ((tail (substring version-string start (string-length version-string)))
                (end (string-index tail #\space)))
           (if end (substring tail 0 end) tail)))))
;; : (-> String Summary EvidenceGrade Witness Next (List String) Details (List String) AgentScenario String QualitySignals FailureCases String )
(def (evidence-fact id summary evidence-grade witness next terms details selectors
                    agent-scenario intent quality-signals failure-cases)
  (hash (id id)
        (summary summary)
        (evidenceGrade evidence-grade)
        (witness witness)
        (next next)
        (terms terms)
        (details details)
        (selectors selectors)
        (agentScenario agent-scenario)
        (intent intent)
        (qualitySignals quality-signals)
        (failureCases failure-cases)))
;;; Boundary:
;;; - active-runtime-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List Fact)
(def (active-runtime-facts)
  (let* ((home (path-normalize (gerbil-home)))
         (gxi (path-normalize (runtime-bin "gxi")))
         (gsc (path-normalize (runtime-bin "gsc")))
         (paths (map runtime-path-normalize (load-path)))
         (public-home (runtime-public-path home))
         (public-gxi (runtime-public-path gxi))
         (public-gsc (runtime-public-path gsc))
         (public-paths (map runtime-public-path paths))
         (missing-paths (filter (lambda (path)
                                  (not (file-exists? path)))
                                paths))
         (public-missing-paths (map runtime-public-path missing-paths))
         (witness (if (and (file-exists? gxi) (file-exists? gsc))
                    "gerbil-home-gxi-gsc-load-path-resolved"
                    "gerbil-home-load-path-resolved")))
    [(evidence-fact
      "active-gerbil-runtime"
      "Active Gerbil runtime discovered from the executing provider process."
      "fact"
      witness
      "search env load-path"
      ["env" "runtime" "gxi" "gsc" "gerbil-home" "load-path"
       public-home public-gxi public-gsc]
      (hash (gerbilHome public-home)
            (gxi public-gxi)
            (gsc public-gsc)
            (gxiExists (file-exists? gxi))
            (gscExists (file-exists? gsc))
            (loadPath public-paths)
            (loadPathMissing public-missing-paths))
      []
      "agent-needs-active-gerbil-runtime-before-import-or-macro-claims"
      "discover-active-gxi-gsc-and-load-path-before-writing-gerbil-code"
      ["active-gxi" "active-gsc" "runtime-load-path"]
      [(hash (id "stale-doc-runtime")
             (risk "agent-trusts-online-gerbil-version-instead-of-active-gxi")
             (correction "query-search-env-before-version-or-import-guidance"))
       (hash (id "global-path-hardcoding")
             (risk "agent-copies-user-machine-path-into-project-docs-or-code")
             (correction "treat-runtime-path-as-evidence-not-project-config"))])]))
;;; Boundary:
;;; - runtime-source-facts coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; (List Fact)
(def (runtime-source-facts)
  (let* ((home (path-normalize (gerbil-home)))
         (gxi (path-normalize (runtime-bin "gxi")))
         (public-home (runtime-public-path home))
         (public-gxi (runtime-public-path gxi))
         (version-string (gerbil-system-version-string))
         (tag (or (gerbil-runtime-tag version-string) "unknown-runtime-tag"))
         (runtime-resolver
          (hash (scheme "gerbil-runtime-source")
                (owner "gerbil-scheme")
                (stateNamespace "runtime-source/gerbil-scheme")
                (versionKey tag)
                (selectorFormat "gerbil-runtime-source://<source-path>#<symbol>")
                (output "code-with-comments")
                (indexOwner "asp-server"))))
    [(evidence-fact
      "gerbil-runtime-source"
      "Gerbil language facts must come from a source checkout matched to the active runtime version."
      "fact"
      "active-runtime-version-to-source-acquisition-plan"
      "search runtime-source macro sugar module-sugar"
      ["runtime-source" "source" "source-facts" "runtime" "version" "clone" "checkout" "macro" "gerbil" "std" "sugar" "std/sugar" "defrule" "defsyntax-call" "module-sugar" "module" "import" "export" "only-in" "except-in" "rename-in" "rename-out" "for-syntax" "ranking" "source-ranking" "bootstrap" "stub" "bootstrap-stub" tag version-string]
      (hash (runtime (hash (gerbilHome public-home)
                           (gxi public-gxi)
                           (systemVersion version-string)
                           (tag tag)))
            (sourceRef (hash (kind "runtime-version-source")
                             (manager "git")
                             (repository "https://git.cons.io/mighty-gerbils/gerbil")
                             (checkout tag)
                             (checkoutPolicy "exact-tag-from-active-runtime")
                             (statePathPolicy "asp-state-managed")
                             (selectorScheme "runtime-source-owner-selector")))
            (acquisition (hash (owner "asp-server")
                               (operation "clone-or-fetch-checkout")
                               (stateNamespace "runtime-source/gerbil-scheme")
                               (versionKey tag)
                               (indexOwner "asp-server")))
            (selectorResolver runtime-resolver)
            (sourceExamples
             [(hash (id "std-sugar-defrule")
                    (role "macro-rule")
                    (symbol "defrule")
                    (selector "gerbil-runtime-source://src/std/sugar.ss#defrule")
                    (form (hash (head "defrule")
                                (operands ["(<name> arg ...)" "body ..."])
                                (keywords [])))
                    (commentMode "neighbor-comments-before-form"))
              (hash (id "std-sugar-defsyntax-call")
                    (role "procedural-macro-call")
                    (symbol "defsyntax-call")
                    (selector "gerbil-runtime-source://src/std/sugar.ss#defsyntax-call")
                    (form (hash (head "defsyntax-call")
                                (operands ["<macro-name>" "<context>" "<formal> ..." "body ..."])
                                (keywords [])))
                    (commentMode "neighbor-comments-before-form"))
              (hash (id "module-sugar-only-in")
                    (role "import-filter")
                    (symbol "only-in")
                    (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in")
                    (form (hash (head "only-in")
                                (operands ["<module>" "<identifier> ..."])
                                (keywords [])))
                    (commentMode "neighbor-comments-before-form"))])
            (sourceComments
             [(hash (id "std-sugar-comment-boundary")
                    (selector "gerbil-runtime-source://src/std/sugar.ss#defsyntax-call")
                    (extractor "leading-and-neighbor-line-comments")
                    (summary "extract source comments near macro forms when present; absence is reported as comment-missing evidence")
                    (fallback "comment-missing-is-signal"))
              (hash (id "module-sugar-comment-boundary")
                    (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in")
                    (extractor "leading-and-neighbor-line-comments")
                    (summary "extract import/export transformer comments together with the selected source window")
                    (fallback "comment-missing-is-signal"))])
            (nextSearch "search runtime-source macro sugar module-sugar"))
      [(hash (role "std-sugar-source")
             (symbol "defrule")
             (selector "gerbil-runtime-source://src/std/sugar.ss#defrule"))
       (hash (role "std-sugar-source")
             (symbol "defsyntax-call")
             (selector "gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"))
       (hash (role "std-sugar-phase-import")
             (symbol "for-syntax")
             (selector "gerbil-runtime-source://src/std/sugar.ss#import-for-syntax"))
       (hash (role "module-sugar-import-filter")
             (symbol "only-in")
             (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in"))
       (hash (role "module-sugar-import-filter")
             (symbol "except-in")
             (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#except-in"))
       (hash (role "module-sugar-import-rename")
             (symbol "rename-in")
             (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-in"))
       (hash (role "module-sugar-export-rename")
             (symbol "rename-out")
             (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-out"))]
      "agent-needs-gerbil-macro-facts-from-versioned-source"
      "clone-active-runtime-source-before-answering-language-or-macro-usage"
      ["no-memory" "version-matched-source" "asp-state-managed-checkout" "source-index-required" "source-index-owned-by-asp-server" "code-with-comments-output" "selector-resolver-owned-by-gerbil-scheme" "source-ranking-prefers-runtime-source" "bootstrap-stubs-labelled"]
      [(hash (id "memory-language-answer")
             (risk "agent-answers-gerbil-language-usage-from-training-memory")
             (correction "acquire-runtime-source-and-search-source-facts"))
       (hash (id "wrong-runtime-version")
             (risk "agent-uses-source-from-a-different-gerbil-version")
             (correction "checkout-source-tag-derived-from-active-runtime"))
       (hash (id "unindexed-source-checkout")
             (risk "agent-clones-source-but-searches-it-with-raw-grep")
             (correction "defer-runtime-source-index-lookup-to-asp-server-ipc"))])
     (evidence-fact
      "gerbil-runtime-writeenv-source"
      "Gerbil writeenv and printer hook guidance must come from the active runtime source before POO :wr roundtrip claims."
      "fact"
      "active-runtime-version-to-writeenv-source-acquisition-plan"
      "search runtime-source writeenv printer hook"
      ["runtime-source" "source" "runtime" "version" "writeenv" "printer" "printer-hook" "hook" "write" "write-object" ":wr" "wr" "poo" "io" "serialization" "ranking" "source-ranking" "bootstrap" "stub" "bootstrap-stub" tag version-string]
      (hash (runtime (hash (gerbilHome public-home)
                           (gxi public-gxi)
                           (systemVersion version-string)
                           (tag tag)))
            (sourceRef (hash (kind "runtime-version-source")
                             (manager "git")
                             (repository "https://git.cons.io/mighty-gerbils/gerbil")
                             (checkout tag)
                             (checkoutPolicy "exact-tag-from-active-runtime")
                             (statePathPolicy "asp-state-managed")
                             (selectorScheme "runtime-source-owner-selector")))
            (acquisition (hash (owner "asp-server")
                               (operation "clone-or-fetch-checkout")
                               (stateNamespace "runtime-source/gerbil-scheme")
                               (versionKey tag)
                               (indexOwner "asp-server")))
            (selectorResolver runtime-resolver)
            (sourceExamples
             [(hash (id "runtime-writeenv-binding")
                    (role "runtime-binding")
                    (symbol "writeenv")
                    (selector "gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv")
                    (form (hash (head "system:")
                                (operands ["writeenv::t" "(t::t)"])
                                (keywords [])))
                    (commentMode "neighbor-comments-before-form"))
              (hash (id "runtime-write-object-owner")
                    (role "runtime-printer-owner")
                    (symbol "write-object")
                    (selector "gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object")
                    (form (hash (head "write-object")
                                (operands ["<object>" "<port>" "<writeenv>"])
                                (keywords [])))
                    (commentMode "implementation-window-with-leading-comments"))])
            (sourceComments
             [(hash (id "builtin-primitive-comment")
                    (selector "gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv")
                    (extractor "leading-and-neighbor-line-comments")
                    (summary "include primitive-class comment context when resolving writeenv")
                    (fallback "comment-missing-is-signal"))
              (hash (id "write-object-comment-boundary")
                    (selector "gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object")
                    (extractor "leading-and-neighbor-line-comments")
                    (summary "extract printer hook comments with the write-object owner window")
                    (fallback "comment-missing-is-signal"))])
            (nextSearch "search runtime-source writeenv printer hook"))
      [(hash (role "writeenv-builtin")
             (symbol "writeenv")
             (selector "gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv"))
       (hash (role "core-writeenv-binding")
             (symbol "writeenv")
             (selector "gerbil-runtime-source://src/bootstrap/gerbil/core.ssi#writeenv"))
       (hash (role "runtime-write-object-owner")
             (symbol "write-object")
             (selector "gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object"))]
      "agent-needs-runtime-printer-hook-facts-before-poo-writeenv-roundtrip-claims"
      "query-versioned-runtime-writeenv-and-write-object-source-before-promoting-poo-io-to-verified"
      ["no-memory" "version-matched-source" "asp-state-managed-checkout" "writeenv-source-index-required" "printer-hook-source-required" "bootstrap-runtime-binding-labelled" "source-ranking-prefers-runtime-source"]
      [(hash (id "memory-writeenv-answer")
             (risk "agent-answers-writeenv-or-printer-hook-behavior-from-training-memory")
             (correction "acquire-active-runtime-source-and-query-writeenv-selectors"))
       (hash (id "poo-writeenv-roundtrip-assumption")
             (risk "agent-promotes-poo-io-pattern-to-verified-without-runtime-writeenv-roundtrip-witness")
             (correction "keep-poo-io-partial-until-runtime-source-backed-roundtrip-witness-exists"))
       (hash (id "raw-runtime-source-search")
             (risk "agent-clones-gerbil-source-but-searches-it-with-raw-grep")
             (correction "defer-runtime-source-index-lookup-to-asp-server-ipc"))])]))
;;; Boundary:
;;; - compiler-evidence-facts records upstream optimizer facts as medium-weight evidence.
;;; - It must not promote optimizer metadata into a complete type theory or proof system.
;; (List Fact)
(def (compiler-evidence-facts)
  (let* ((version-string (gerbil-system-version-string))
         (tag (or (gerbil-runtime-tag version-string) "unknown-runtime-tag"))
         (compiler-resolver
          (hash (scheme "gerbil-runtime-source")
                (owner "gerbil-scheme")
                (stateNamespace "runtime-source/gerbil-scheme")
                (versionKey tag)
                (selectorFormat "gerbil-runtime-source://<source-path>#<symbol>")
                (output "code-with-comments")
                (indexOwner "asp-server"))))
    [(evidence-fact
      "gerbil-compiler-medium-weight-evidence"
      "Gerbil compiler optimizer metadata supports medium-weight derivation witnesses, not a complete proof system."
      "fact"
      "runtime-source-compiler-optimizer-metadata-and-local-assertion-env"
      "search compiler-evidence optimizer subtype assertion"
      ["compiler-evidence" "compiler" "medium-weight" "proof" "proof-boundary"
       "optimizer" "metadata" "!signature" "!class" "!predicate"
       "!type-subtype?" "subtype" "!class-subclass?" "assertion" "assert-type"
       "fold-assert-type" "env-type" "predicate-type" "module-context"
       "import-module" "local-assertion" "type-derivation" "type-proof"
       "runtime-source" tag version-string]
      (hash (proofBoundary "medium-weight-compiler-evidence")
            (runtime (hash (systemVersion version-string)
                           (tag tag)))
            (sourceRef (hash (kind "runtime-version-source")
                             (manager "git")
                             (repository "https://git.cons.io/mighty-gerbils/gerbil")
                             (checkout tag)
                             (checkoutPolicy "exact-tag-from-active-runtime")
                             (statePathPolicy "asp-state-managed")
                             (selectorScheme "runtime-source-owner-selector")))
            (acquisition (hash (owner "asp-server")
                               (operation "clone-or-fetch-checkout")
                               (stateNamespace "runtime-source/gerbil-scheme")
                               (versionKey tag)
                               (indexOwner "asp-server")))
            (selectorResolver compiler-resolver)
            (sourceExamples
             [(hash (id "compiler-signature-metadata")
                    (role "optimizer-metadata")
                    (symbol "!signature")
                    (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-base.ss#!signature")
                    (form (hash (head "defclass")
                                (operands ["!signature" "(return effect arguments unchecked origin)"])
                                (keywords ["final:" "equal:" "print:"])))
                    (commentMode "owner-window-with-neighbor-comments"))
              (hash (id "compiler-subtype-relation")
                    (role "subtype-relation")
                    (symbol "!type-subtype?")
                    (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-base.ss#!type-subtype?")
                    (form (hash (head "def")
                                (operands ["(!type-subtype? type-a type-b)" "metadata-level-relation"])
                                (keywords [])))
                    (commentMode "owner-window-with-neighbor-comments"))
              (hash (id "compiler-local-assertion-env")
                    (role "local-assertion-env")
                    (symbol "fold-assert-type")
                    (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-ann.ss#fold-assert-type")
                    (form (hash (head "def")
                                (operands ["(fold-assert-type expr val env)" "env-type"])
                                (keywords [])))
                    (commentMode "owner-window-with-neighbor-comments"))
              (hash (id "compiler-assert-type")
                    (role "assertion-check")
                    (symbol "assert-type")
                    (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-ann.ss#assert-type")
                    (form (hash (head "def")
                                (operands ["(assert-type id t)" "local-env-type"])
                                (keywords [])))
                    (commentMode "owner-window-with-neighbor-comments"))])
            (sourceComments
             [(hash (id "compiler-subtype-boundary")
                    (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-base.ss#!type-subtype?")
                    (extractor "owner-window-with-neighbor-line-comments")
                    (summary "subtype evidence is equality, top type, procedure shape, and class precedence checks")
                    (fallback "comment-missing-is-signal"))
              (hash (id "compiler-assert-type-boundary")
                    (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-ann.ss#assert-type")
                    (extractor "owner-window-with-neighbor-line-comments")
                    (summary "positive assertions are accepted only when class metadata proves a subtype relation")
                    (fallback "comment-missing-is-signal"))])
            (model (hash (acceptedEvidence ["optimizer-type-metadata"
                                            "class-precedence-subtype"
                                            "local-assertion-env"
                                            "runtime-source-selector"])
                         (rejectedClaims ["general-constraint-solver"
                                          "quantifier-reasoning"
                                          "principal-type-inference"
                                          "proof-term-calculus"
                                          "cross-module-theorem-prover"])))
            (agentContract
             (hash (claim "emit-derived-type-witnesses-only-when-source-backed")
                   (repairLoop "parser-contract-annotation-to-normalized-typespec-to-compiler-evidence-witness")
                   (qualityGate "no-full-proof-claim-without-dedicated-typed-core")))
            (nextSearch "search compiler-evidence optimizer subtype assertion"))
      [(hash (role "optimizer-signature")
             (symbol "!signature")
             (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-base.ss#!signature"))
       (hash (role "optimizer-class")
             (symbol "!class")
             (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-base.ss#!class"))
       (hash (role "optimizer-predicate")
             (symbol "!predicate")
             (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-base.ss#!predicate"))
       (hash (role "subtype-relation")
             (symbol "!type-subtype?")
             (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-base.ss#!type-subtype?"))
       (hash (role "class-subtype-relation")
             (symbol "!class-subclass?")
             (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-base.ss#!class-subclass?"))
       (hash (role "local-assertion-fold")
             (symbol "fold-assert-type")
             (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-ann.ss#fold-assert-type"))
       (hash (role "local-assertion-check")
             (symbol "assert-type")
             (selector "gerbil-runtime-source://src/gerbil/compiler/optimize-ann.ss#assert-type"))]
      "agent-needs-versioned-compiler-evidence-before-type-proof-claims"
      "use-medium-weight-compiler-evidence-and-source-selectors-before-agent-type-repair"
      ["medium-weight-only" "runtime-source-backed-compiler-selectors"
       "optimizer-metadata-boundary" "local-assertion-env"
       "no-full-proof-claim" "agent-repair-contract"]
      [(hash (id "full-proof-system-claim")
             (risk "agent-claims-complete-type-theory-soundness-from-optimizer-metadata")
             (correction "limit-claims-to-source-backed-medium-weight-derivation-witnesses"))
       (hash (id "training-memory-compiler-rule")
             (risk "agent-generates-type-contract-repair-from-memory-without-versioned-compiler-source")
             (correction "query-compiler-evidence-and-runtime-source-selectors-before-repair"))
       (hash (id "pseudo-type-comment")
             (risk "agent-keeps-invalid-comment-contracts-as-if-they-were-verified-types")
             (correction "normalize-comment-contracts-and-reject-unsupported-forms-before-claiming-evidence"))
       (hash (id "cross-module-theorem-prover-assumption")
             (risk "agent-assumes-import-module-or-module-context-provides-global-proof-search")
             (correction "treat-module-context-as-acquisition-context-not-a-theorem-prover"))])]))
;;; Boundary:
;;; - language-rule-facts coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; (List Fact)
(def (language-rule-facts)
  [(evidence-fact
    "hygienic-macro"
    "Gerbil macros are syntax objects expanded by the active Gerbil expander; macro guidance must route through parser/runtime witnesses."
    "fact"
    "provider-loads-macro-forms-and-parser-witnesses"
    "search pattern hygienic-macro"
    ["lang" "macro" "hygienic" "hygienic-macro" "defsyntax" "syntax-case" "syntax-rules"]
    (hash (rule "hygienic-macro")
          (authority "language-rules"))
    [(hash (role "macro-form-parser")
           (symbol "defsyntax")
           (selector "src/checker/forms.ss:13"))]
    "agent-does-not-know-gerbil-macro-phase-rules"
    "route-macro-questions-through-parser-and-generated-code-policy"
    ["parser-owned-macro-heads" "forbidden-form-policy" "pattern-route"]
    [(hash (id "generated-code-forbidden-form")
           (risk "agent-blindly-emits-defsyntax-or-syntax-case-in-generated-code")
           (correction "use-parser-witness-and-policy-check-before-writing-macro-forms"))
     (hash (id "racket-macro-assumption")
           (risk "agent-mixes-racket-macro-examples-with-gerbil-code")
           (correction "query-gerbil-pattern-and-owner-selectors-first"))])
   (evidence-fact
    "module-import"
    "Gerbil module imports are resolved through the active load path and module-sugar import/export sets; project guidance must include runtime source when import set syntax matters."
    "fact"
    "runtime-source-module-sugar-import-export-sets"
    "search runtime-source module-sugar"
    ["lang" "module" "import" "export" "load-path" "package" "module-sugar" "only-in" "except-in" "rename-in" "prefix-in" "rename-out" "for-syntax" "for-template"]
    (hash (rule "module-import")
          (authority "language-rules")
          (runtimeSourceSelector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss"))
    [(hash (role "import-filter")
           (symbol "only-in")
           (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in"))
     (hash (role "import-filter")
           (symbol "except-in")
           (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#except-in"))
     (hash (role "import-rename")
           (symbol "rename-in")
           (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-in"))
     (hash (role "phase-import")
           (symbol "for-syntax")
           (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#for-syntax"))
     (hash (role "export-rename")
           (symbol "rename-out")
           (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-out"))]
    "agent-does-not-know-gerbil-module-load-path-resolution"
    "query-active-load-path-and-module-sugar-source-before-adding-imports-or-exports"
    ["load-path-policy" "runtime-route" "module-sugar-source" "import-set-witness" "export-set-witness"]
    [(hash (id "missing-load-path")
           (risk "agent-adds-import-that-current-gxi-cannot-resolve")
           (correction "query-search-env-load-path-before-editing-imports"))
     (hash (id "racket-require-assumption")
           (risk "agent-uses-racket-require-forms-in-gerbil-imports")
           (correction "use-gerbil-module-sugar-selectors-for-only-in-except-in-rename-in"))
     (hash (id "unchecked-rename-in")
           (risk "agent-renames-an-identifier-that-is-not-in-the-import-set")
           (correction "use-rename-in-witness-that-checks-identifier-membership"))
     (hash (id "rename-out-confusion")
           (risk "agent-confuses-import-renaming-with-export-renaming")
           (correction "use-rename-in-for-imports-and-rename-out-for-exports"))])
   (evidence-fact
    "scheme-style"
    "Gerbil code quality guidance should follow domain owners, t/ test owners, directional data-flow names, and named control-flow helpers."
    "fact"
    "gerbil-utils-style-audit-and-harness-policy"
    "search lang style"
    ["lang" "style" "quality" "tests" "t" "owner" "domain" "data-flow" "control-flow" "gerbil-utils"]
    (hash (rule "scheme-style")
          (authority "language-rules")
          (reference "https://git.cons.io/mighty-gerbils/gerbil-utils")
          (testDirectory "t")
          (policyRules ["GERBIL-SCHEME-MOD-R006"
                        "GERBIL-SCHEME-AGENT-POLICY-004"
                        "GERBIL-SCHEME-AGENT-POLICY-005"])
          (styleDoc "languages/gerbil-scheme-language-project-harness/docs/50-59-policy/51.05-current-project-programming-style.org"))
    [(hash (role "style-reference")
           (symbol "generating<-list")
           (selector "gerbil-utils://generator.ss#generating<-list"))
     (hash (role "test-layout-reference")
           (symbol "assq-test")
           (selector "gerbil-utils://pure/dict/t/assq-test.ss#assq-test"))
     (hash (role "root-test-layout-reference")
           (symbol "base-test")
           (selector "gerbil-utils://t/base-test.ss#base-test"))]
    "agent-needs-high-quality-gerbil-code-conventions"
    "prefer-domain-owners-t-tests-directional-data-flow-and-named-control-flow"
    ["domain-owner-names" "t-test-layout" "real-project-t-tests" "directional-data-flow-names" "named-control-flow-helpers" "vague-definition-policy" "top-level-executable-policy"]
    [(hash (id "retired-test-directory")
           (risk "agent-creates-top-level-test-directory-for-gerbil-unit-tests")
           (correction "use-t-directory-and-native-std-test-suites"))
     (hash (id "generic-owner-name")
           (risk "agent-creates-utils-or-helpers-owner-instead-of-domain-owner")
           (correction "name-the-domain-owner-and-keep-facades-thin"))
     (hash (id "vague-definition-name")
           (risk "agent-writes-helper-process-handle-or-convert-without-domain-semantics")
           (correction "name-the-domain-action-or-use-directional-data-flow-naming"))
     (hash (id "top-level-executable-call")
           (risk "agent-puts-runtime-effects-at-src-top-level-instead-of-a-named-entrypoint")
           (correction "move-executable-call-behind-a-named-definition-or-bin-entrypoint"))
     (hash (id "inline-control-flow")
           (risk "agent-writes-large-inline-continuation-thread-or-generator-block")
           (correction "extract-named-helper-and-cover-it-with-a-native-unit-test"))])])
;;; Boundary:
;;; - standard-library-facts coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; (List Fact)
(def (standard-library-facts)
  [(evidence-fact
    "std/srfi/13"
    "SRFI-13 string procedures are available to the harness and used by search rendering."
    "fact"
    "provider-imports-:std/srfi/13"
    "search std string"
    ["std" "standard-library" "srfi" "srfi-13" "std/srfi/13" "string" "string-contains" "string-prefix"]
    (hash (module ":std/srfi/13")
          (capabilities ["string-contains" "string-prefix?" "string-suffix?"]))
    []
    "agent-does-not-know-gerbil-standard-string-module"
    "use-active-provider-standard-library-fact-instead-of-dialect-memory"
    ["provider-imports-std-module" "string-prefix-capability" "string-contains-capability"]
    [(hash (id "guessed-racket-string-api")
           (risk "agent-imports-or-calls-a-similar-api-from-another-scheme")
           (correction "use-std-srfi-13-fact-and-selector-backed-provider-import"))])
   (evidence-fact
    "std/misc/ports"
    "Port helpers are available to the harness and used for guide/test output capture."
    "fact"
    "provider-imports-:std/misc/ports"
    "search std ports"
    ["std" "standard-library" "ports" "std/misc/ports" "call-with-output-string"]
    (hash (module ":std/misc/ports")
          (capabilities ["call-with-output-string" "read-all-as-string"]))
    []
    "agent-needs-test-output-capture-without-shelling-out"
    "use-gerbil-port-helper-facts-for-unit-test-output-capture"
    ["provider-imports-std-module" "port-capture-capability"]
    [(hash (id "shell-output-capture")
           (risk "agent-spawns-shell-or-temp-files-for-unit-output")
           (correction "use-call-with-output-string-from-std-misc-ports"))])
   (evidence-fact
    "std/text/json"
    "Gerbil JSON parsing is available through :std/text/json; import read-json with only-in when the harness needs machine packet validation."
    "fact"
    "provider-imports-:std/text/json"
    "search std json"
    ["std" "standard-library" "json" "std/text/json" ":std/text/json" "read-json" "only-in"]
    (hash (module ":std/text/json")
          (capabilities ["read-json"])
          (minimalImport "(import (only-in :std/text/json read-json))"))
    []
    "agent-needs-json-packet-validation-without-python-parser"
    "use-gerbil-std-text-json-read-json-with-only-in"
    ["provider-imports-std-module" "read-json-capability" "only-in-minimal-import"]
    [(hash (id "foreign-json-parser")
           (risk "agent-adds-python-or-shell-json-parser-for-gerbil-tests")
           (correction "use-read-json-from-std-text-json"))
     (hash (id "broad-json-import")
           (risk "agent-imports-more-json-surface-than-the-test-needs")
           (correction "use-only-in-std-text-json-read-json"))])
   (evidence-fact
    "std/sugar"
    "Gerbil sugar macros are available through :std/sugar and must be treated as runtime-source-backed macro evidence, not generic Scheme memory."
    "fact"
    "runtime-source-std-sugar-defrule-and-defsyntax"
    "search pattern hygienic-macro"
    ["std" "standard-library" "sugar" "std/sugar" ":std/sugar" "defrule" "defsyntax" "syntax-call" "defsyntax-call" "for-syntax"]
    (hash (module ":std/sugar")
          (capabilities ["defrule" "defsyntax" "syntax-call" "defsyntax-call"])
          (runtimeSourceSelector "gerbil-runtime-source://src/std/sugar.ss"))
    [(hash (role "std-sugar-source")
           (symbol "defrule")
           (selector "gerbil-runtime-source://src/std/sugar.ss#defrule"))
     (hash (role "std-sugar-source")
           (symbol "defsyntax-call")
           (selector "gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"))
     (hash (role "std-sugar-import")
           (symbol "for-syntax")
           (selector "gerbil-runtime-source://src/std/sugar.ss#import-for-syntax"))]
    "agent-needs-gerbil-sugar-macro-facts-from-versioned-source"
    "search-runtime-source-std-sugar-before-writing-defrule-or-defsyntax-call"
    ["runtime-source-backed-std-module" "macro-sugar-capability" "for-syntax-import-witness"]
    [(hash (id "generic-scheme-rule-macro")
           (risk "agent-assumes-defrule-or-syntax-call-shape-from-another-scheme")
           (correction "query-std-sugar-and-runtime-source-before-writing-sugar-macros"))
     (hash (id "missing-for-syntax-import")
           (risk "agent-writes-macro-helper-without-phase-specific-import-evidence")
           (correction "use-std-sugar-for-syntax-import-witness"))])
   (evidence-fact
    "std/test"
    "Gerbil test support is the harness unit-test surface."
    "fact"
    "test-suite-loads-:std/test"
    "search std test"
    ["std" "standard-library" "test" "std/test" "test-suite" "check"]
    (hash (module ":std/test")
          (capabilities ["test-suite" "test-case" "check"]))
    []
    "agent-needs-native-gerbil-unit-test-interface"
    "use-std-test-suite-and-check-for-harness-tests"
    ["provider-imports-std-module" "native-test-capability"]
    [(hash (id "foreign-test-framework")
           (risk "agent-adds-python-or-non-gerbil-test-wrapper")
           (correction "use-std-test-native-gerbil-test-suite"))])])
;;; Boundary:
;;; - Project contract patterns are provider-owned registry facts.
;;; - They do not require a gerbil-poo dependency activation.
;; : (-> (List SearchTerm) MaybePattern )
(def (project-contract-pattern-evidence terms)
  (and (project-contract-pattern-query? terms)
       (hash (id "project-json-schema-object-type-contract")
             (extension "gerbil-scheme")
             (focus "json schema node to object type contract")
             (origin "provider-registry")
             (sourceRef
              (hash (kind "provider-pattern-registry")
                    (manager "native-provider")
                    (package "gerbil-scheme-language-project-harness")
                    (dependency "project-contract-patterns")
                    (repository "agent-semantic-protocols/languages/gerbil-scheme-language-project-harness")
                    (pathPolicy "workspace-logical-selector")
                    (selectorScheme "project-contract-logical-symbol")))
             (sourceOwners ["src/utilities/contracts.ss"
                            "src/utilities/contract-syntax.ss"
                            "src/utilities/projection.ss"])
             (selectors
              [(hash (role "json-schema-node-projection")
                     (symbol "poo-flow-json-schema-node->object-type-contract")
                     (selector "src/utilities/contracts.ss#poo-flow-json-schema-node->object-type-contract"))
               (hash (role "declarative-contract-macro")
                     (symbol "defobject-contract")
                     (selector "src/utilities/contract-syntax.ss#defobject-contract"))
               (hash (role "object-type-contract")
                     (symbol "object-type-contract")
                     (selector "src/utilities/contracts.ss#object-type-contract"))
               (hash (role "slot-contract")
                     (symbol "slot-contract")
                     (selector "src/utilities/contracts.ss#slot-contract"))
               (hash (role "contract-report-projection")
                     (symbol "object-type-contract->alist")
                     (selector "src/utilities/projection.ss#object-type-contract->alist"))])
             (agentScenario "agent-projects-json-schema-objects-without-a-contract-boundary")
             (agentSteering "use a declarative object contract projection before writing schema-to-object code; avoid ad hoc POJO/alist decoding without slot predicates and report projection")
             (intent "query-json-schema-object-contract-projection-before-writing-schema-to-contract-code")
             (minimalForms (project-contract-pattern-minimal-forms))
             (failureCases (project-contract-pattern-failure-cases))
             (qualitySignals ["registered-pattern-query"
                              "json-schema-node-mapping"
                              "object-type-contract-boundary"
                              "slot-contract-predicates"
                              "declarative-contract-macro"
                              "projection-report"])
             (witness "project-json-schema-object-type-contract-pattern-registry")
             (missing [])
             (next "search pattern json-schema-node object-type-contract"))))
;; : (-> (List SearchTerm) Boolean )
(def (project-contract-pattern-query? terms)
  (and (pair? terms)
       (or (project-contract-term-any?
            terms
            +project-contract-pattern-query-terms+)
           (and (project-contract-json-schema-query? terms)
                (project-contract-object-contract-query? terms)))))
;; : (-> (List SearchTerm) Boolean )
(def (project-contract-json-schema-query? terms)
  (or (project-contract-term-any? terms ["json-schema" "json-schema-node"
                                         "schema-node"])
      (and (member "json" terms) (member "schema" terms))))
;; : (-> (List SearchTerm) Boolean )
(def (project-contract-object-contract-query? terms)
  (or (project-contract-term-any? terms ["object-type-contract"
                                         "contract-projection"
                                         "defobject-contract"])
      (and (member "object" terms)
           (member "type" terms)
           (member "contract" terms))))
;; : (-> (List SearchTerm) Needles Boolean )
(def (project-contract-term-any? terms needles)
  (ormap (lambda (needle) (member needle terms)) needles))
;; (List FormMapping)
(def (project-contract-pattern-minimal-forms)
  [(hash (role "json-schema-node-projection")
         (symbol "poo-flow-json-schema-node->object-type-contract")
         (template (hash (head "poo-flow-json-schema-node->object-type-contract")
                         (operands ["<json-schema-node>"])
                         (keywords ["owner:" "object-kind:" "slots:"])))
         (selector "src/utilities/contracts.ss#poo-flow-json-schema-node->object-type-contract"))
   (hash (role "declarative-contract-macro")
         (symbol "defobject-contract")
         (template (hash (head "defobject-contract")
                         (operands ["<contract-id>"])
                         (keywords ["owner:" "object-kind:" "slots:"])))
         (selector "src/utilities/contract-syntax.ss#defobject-contract"))
   (hash (role "contract-report-projection")
         (symbol "object-type-contract->alist")
         (template (hash (head "object-type-contract->alist")
                         (operands ["<object-type-contract>"])
                         (keywords [])))
         (selector "src/utilities/projection.ss#object-type-contract->alist"))])
;; (List FailureCase)
(def (project-contract-pattern-failure-cases)
  [(hash (id "pojo-json-schema-projection")
         (risk "contract-boundary-bypass")
         (badPattern "parse-json-schema-into-ad-hoc-alists-without-object-type-contract")
         (correction "project-json-schema-through-object-type-contract-and-slot-contracts")
         (selectors ["src/utilities/contracts.ss#poo-flow-json-schema-node->object-type-contract"
                     "src/utilities/contracts.ss#object-type-contract"]))
   (hash (id "missing-slot-predicate")
         (risk "typed-contract-gap")
         (badPattern "schema-property-without-required-slot-predicate-or-type-contract")
         (correction "materialize-slot-contract-predicates-before-object-projection")
         (selectors ["src/utilities/contracts.ss#slot-contract"]))
   (hash (id "manual-contract-report")
         (risk "projection-drift")
         (badPattern "hand-written-report-rows-that-do-not-come-from-contract-data")
         (correction "derive-report-rows-from-object-type-contract->alist")
         (selectors ["src/utilities/projection.ss#object-type-contract->alist"]))])
;;; Boundary:
;;; - hygienic-macro-pattern-evidence coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> (List MacroFact) Boolean )
(def (hygienic-macro-pattern-evidence terms)
  (and (hygienic-macro-pattern-query? terms)
       (hash (id "hygienic-macro")
             (extension "gerbil-scheme")
             (focus "syntax-case/defsyntax")
             (origin "provider")
             (sourceRef (hash (kind "provider-source")
                              (manager "native-provider")
                              (package "gerbil-scheme-language-project-harness")
                              (dependency "gerbil-scheme-language-project-harness")
                              (repository "agent-semantic-protocols/languages/gerbil-scheme-language-project-harness")
                              (pathPolicy "repository-relative")
                              (selectorScheme "provider-owner-selector")))
             (sourceOwners ["src/checker/forms.ss"
                            "gerbil-runtime-source://src/std/sugar.ss"])
             (selectors
              [(hash (role "macro-form")
                     (symbol "defsyntax")
                     (selector "src/checker/forms.ss:13"))
               (hash (role "std-sugar-rule-macro")
                     (symbol "defrule")
                     (selector "gerbil-runtime-source://src/std/sugar.ss#defrule"))
               (hash (role "std-sugar-procedural-macro")
                     (symbol "defsyntax-call")
                     (selector "gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"))
               (hash (role "std-sugar-phase-import")
                     (symbol "for-syntax")
                     (selector "gerbil-runtime-source://src/std/sugar.ss#import-for-syntax"))])
             (agentScenario "agent-does-not-know-gerbil-macro-syntax-or-generated-code-policy")
             (intent "recognize-gerbil-macro-surfaces-and-avoid-forbidden-generated-forms")
             (minimalForms (hygienic-macro-minimal-forms))
             (failureCases (hygienic-macro-failure-cases))
             (qualitySignals ["parser-owned-macro-heads"
                              "runtime-source-std-sugar"
                              "for-syntax-import-witness"
                              "generated-code-policy"
                              "test-backed-query"])
             (witness "parser-and-test-backed-hygienic-macro-pattern")
             (next "search lang hygienic-macro"))))
;;; Boundary:
;;; - hygienic-macro-minimal-forms coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; Boolean
(def (hygienic-macro-minimal-forms)
  [(hash (role "macro-definition")
         (symbol "defsyntax")
         (template (hash (head "defsyntax")
                         (operands ["(<name> stx)" "..."])
                         (keywords [])))
         (selector "src/checker/forms.ss:13"))
   (hash (role "macro-policy")
         (symbol "syntax-case")
         (template (hash (head "policy")
                         (operands ["generated-code"
                                    "must-not-emit-defsyntax-or-syntax-case-without-policy-witness"])
                         (keywords [])))
         (selector "src/checker/forms.ss:13"))
   (hash (role "std-sugar-rule-macro")
         (symbol "defrule")
         (template (hash (head "defrule")
                         (operands ["(<name> arg ...)" "body ..."])
                         (keywords [])))
         (selector "gerbil-runtime-source://src/std/sugar.ss#defrule"))
   (hash (role "std-sugar-procedural-macro")
         (symbol "defsyntax-call")
         (template (hash (head "defsyntax-call")
                         (operands ["<macro-name>" "<syntax-argument> ..."])
                         (keywords [])))
         (selector "gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"))])
;; Boolean
(def (hygienic-macro-failure-cases)
  [(hash (id "generated-code-forbidden-form")
         (risk "agent-blindly-emits-defsyntax-syntax-case-or-defrules")
         (correction "run-policy-check-or-route-through-parser-owned-macro-witness"))
   (hash (id "racket-macro-assumption")
         (risk "agent-copies-racket-syntax-case-shape-into-gerbil-code")
         (correction "query-gerbil-lang-and-pattern-before-editing-macro-code"))])
;;; Query classification is intentionally vocabulary-only: macro facts remain
;;; parser-owned, while this helper decides whether search terms should request
;;; hygienic macro guidance.
;;; Macro-pattern lookup is an existential tag match over a fixed query table.
;;; Keeping this as `ormap` preserves the no-ranking invariant for search
;;; evidence and avoids a second parser path for macro guidance.
;; : (-> (List MacroFact) Boolean )
(def (hygienic-macro-pattern-query? terms)
  (and (pair? terms)
       (ormap (lambda (term)
                (member term terms))
              +hygienic-macro-query-terms+)))
