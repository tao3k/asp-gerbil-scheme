(runtimeSourceSearch
 (namespace "runtime-source")
 (authority "runtime-version-source")
 (evidenceGrade "fact")
 (quality "version-matched-source-plan")
 (query "writeenv printer hook")
 (facts
  ((runtimeSourceFact
    (id "gerbil-runtime-writeenv-source")
    (summary "Gerbil writeenv and printer hook guidance must come from the active runtime source before POO :wr roundtrip claims.")
    (evidenceGrade "fact")
    (witness "active-runtime-version-to-writeenv-source-acquisition-plan")
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
       (id "runtime-writeenv-binding")
       (role "runtime-binding")
       (symbol "writeenv")
       (selector "gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv")
       (form
        (head "system:")
        (operands ("writeenv::t" "(t::t)"))
        (keywords ()))
       (commentMode "neighbor-comments-before-form"))
      (sourceExample
       (id "runtime-write-object-owner")
       (role "runtime-printer-owner")
       (symbol "write-object")
       (selector "gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object")
       (form
        (head "write-object")
        (operands ("<object>" "<port>" "<writeenv>"))
        (keywords ()))
       (commentMode "implementation-window-with-leading-comments"))))
    (sourceComments
     ((sourceComment
       (id "builtin-primitive-comment")
       (selector "gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv")
       (extractor "leading-and-neighbor-line-comments")
       (summary "include primitive-class comment context when resolving writeenv")
       (fallback "comment-missing-is-signal"))
      (sourceComment
       (id "write-object-comment-boundary")
       (selector "gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object")
       (extractor "leading-and-neighbor-line-comments")
       (summary "extract printer hook comments with the write-object owner window")
       (fallback "comment-missing-is-signal"))))
    (selectors
     ((selector
       (role "writeenv-builtin")
       (symbol "writeenv")
       (selector "gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv"))
      (selector
       (role "core-writeenv-binding")
       (symbol "writeenv")
       (selector "gerbil-runtime-source://src/bootstrap/gerbil/core.ssi#writeenv"))
      (selector
       (role "runtime-write-object-owner")
       (symbol "write-object")
       (selector "gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object"))))
    (agentScenario "agent-needs-runtime-printer-hook-facts-before-poo-writeenv-roundtrip-claims")
    (intent "query-versioned-runtime-writeenv-and-write-object-source-before-promoting-poo-io-to-verified")
    (failureCases
     ((failureCase
       (id "memory-writeenv-answer")
       (risk "agent-answers-writeenv-or-printer-hook-behavior-from-training-memory")
       (correction "acquire-active-runtime-source-and-query-writeenv-selectors"))
      (failureCase
       (id "poo-writeenv-roundtrip-assumption")
       (risk "agent-promotes-poo-io-pattern-to-verified-without-runtime-writeenv-roundtrip-witness")
       (correction "keep-poo-io-partial-until-runtime-source-backed-roundtrip-witness-exists"))
      (failureCase
       (id "raw-runtime-source-search")
       (risk "agent-clones-gerbil-source-but-searches-it-with-raw-grep")
       (correction "defer-runtime-source-index-lookup-to-asp-server-ipc"))))
    (qualitySignals ("no-memory"
                     "version-matched-source"
	                     "asp-state-managed-checkout"
	                     "writeenv-source-index-required"
	                     "printer-hook-source-required"
	                     "bootstrap-runtime-binding-labelled"
	                     "source-ranking-prefers-runtime-source")))))
 (missing ())
 (witness "active-runtime-version-to-writeenv-source-acquisition-plan")
 (next "search runtime-source writeenv printer hook"))
