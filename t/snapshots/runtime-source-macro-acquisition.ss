(runtimeSourceSearch
 (namespace "runtime-source")
 (authority "runtime-version-source")
 (evidenceGrade "fact")
 (quality "version-matched-source-plan")
 (query "macro")
 (facts
  ((runtimeSourceFact
    (id "gerbil-runtime-source")
    (summary "Gerbil language facts must come from a source checkout matched to the active runtime version.")
    (evidenceGrade "fact")
    (witness "active-runtime-version-to-source-acquisition-plan")
    (sourceRef
     (kind "runtime-version-source")
     (manager "git")
     (repository "https://git.cons.io/mighty-gerbils/gerbil")
     (checkoutPolicy "exact-tag-from-active-runtime")
     (statePathPolicy "asp-state-managed")
     (selectorScheme "runtime-source-owner-selector"))
    (acquisition
     (owner "asp-server")
     (operation "clone-or-fetch-checkout")
     (stateNamespace "runtime-source/gerbil-scheme")
     (indexOwner "asp-server"))
    (selectorResolver
     (scheme "gerbil-runtime-source")
     (owner "gerbil-scheme")
     (stateNamespace "runtime-source/gerbil-scheme")
     (selectorFormat "gerbil-runtime-source://<source-path>#<symbol>")
     (output "code-with-comments")
     (indexOwner "asp-server"))
    (sourceExamples
     ((sourceExample
       (id "std-sugar-defrule")
       (role "macro-rule")
       (symbol "defrule")
       (selector "gerbil-runtime-source://src/std/sugar.ss#defrule")
       (form
        (head "defrule")
        (operands ("(<name> arg ...)" "body ..."))
        (keywords ()))
       (commentMode "neighbor-comments-before-form"))
      (sourceExample
       (id "std-sugar-defsyntax-call")
       (role "procedural-macro-call")
       (symbol "defsyntax-call")
       (selector "gerbil-runtime-source://src/std/sugar.ss#defsyntax-call")
       (form
        (head "defsyntax-call")
        (operands ("<macro-name>" "<context>" "<formal> ..." "body ..."))
        (keywords ()))
       (commentMode "neighbor-comments-before-form"))
      (sourceExample
       (id "module-sugar-only-in")
       (role "import-filter")
       (symbol "only-in")
       (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in")
       (form
        (head "only-in")
        (operands ("<module>" "<identifier> ..."))
        (keywords ()))
       (commentMode "neighbor-comments-before-form"))))
    (sourceComments
     ((sourceComment
       (id "std-sugar-comment-boundary")
       (selector "gerbil-runtime-source://src/std/sugar.ss#defsyntax-call")
       (extractor "leading-and-neighbor-line-comments")
       (summary "extract source comments near macro forms when present; absence is reported as comment-missing evidence")
       (fallback "comment-missing-is-signal"))
      (sourceComment
       (id "module-sugar-comment-boundary")
       (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in")
       (extractor "leading-and-neighbor-line-comments")
       (summary "extract import/export transformer comments together with the selected source window")
       (fallback "comment-missing-is-signal"))))
    (selectors
     ((selector
       (role "std-sugar-source")
       (symbol "defrule")
       (selector "gerbil-runtime-source://src/std/sugar.ss#defrule"))
      (selector
       (role "std-sugar-source")
       (symbol "defsyntax-call")
       (selector "gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"))
      (selector
       (role "std-sugar-phase-import")
       (symbol "for-syntax")
       (selector "gerbil-runtime-source://src/std/sugar.ss#import-for-syntax"))
      (selector
       (role "module-sugar-import-filter")
       (symbol "only-in")
       (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in"))
      (selector
       (role "module-sugar-import-filter")
       (symbol "except-in")
       (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#except-in"))
      (selector
       (role "module-sugar-import-rename")
       (symbol "rename-in")
       (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-in"))
      (selector
       (role "module-sugar-export-rename")
       (symbol "rename-out")
       (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-out"))))
    (agentScenario "agent-needs-gerbil-macro-facts-from-versioned-source")
    (intent "clone-active-runtime-source-before-answering-language-or-macro-usage")
    (failureCases
     ((failureCase
       (id "memory-language-answer")
       (risk "agent-answers-gerbil-language-usage-from-training-memory")
       (correction "acquire-runtime-source-and-search-source-facts"))
      (failureCase
       (id "wrong-runtime-version")
       (risk "agent-uses-source-from-a-different-gerbil-version")
       (correction "checkout-source-tag-derived-from-active-runtime"))
      (failureCase
       (id "unindexed-source-checkout")
       (risk "agent-clones-source-but-searches-it-with-raw-grep")
       (correction "defer-runtime-source-index-lookup-to-asp-server-ipc"))))
    (qualitySignals ("no-memory"
                     "version-matched-source"
                     "asp-state-managed-checkout"
                     "source-index-required"
                     "source-index-owned-by-asp-server"
	                     "code-with-comments-output"
                     "selector-resolver-owned-by-gerbil-scheme"
	                     "source-ranking-prefers-runtime-source"
	                     "bootstrap-stubs-labelled")))))
 (missing ())
 (witness "active-runtime-version-to-source-acquisition-plan")
 (next "search runtime-source macro sugar module-sugar"))
