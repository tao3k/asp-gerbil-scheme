(patternSearch
 (namespace "pattern")
 (authority "executable-pattern")
 (evidenceGrade "fact")
 (quality "verified")
 (query "poo trace debug")
 (pattern
  (pattern
   (id "poo-trace-debug")
   (extension "poo")
   (focus "trace debug")
   (sourceRef
    (kind "package-manager-source")
    (manager "gxpkg")
    (package "poo")
    (dependency "git.cons.io/mighty-gerbils/gerbil-poo")
    (repository "git.cons.io/mighty-gerbils/gerbil-poo")
    (localSource
     (kind "gerbil-package-source")
     (manager "gxpkg")
     (rootHint "~/.gerbil")
     (package "git.cons.io/mighty-gerbils/gerbil-poo")
     (status "probe-first")
     (owner "asp-server"))
    (repositorySource
     (kind "git-repository")
     (vcs "git")
     (repository "git.cons.io/mighty-gerbils/gerbil-poo")
     (url "https://git.cons.io/mighty-gerbils/gerbil-poo")
     (status "fallback")
     (owner "asp-server"))
    (indexHint
     (owner "asp-server")
     (backend "rust-sql")
     (mode "local-source-before-git"))
    (pathPolicy "runtime-resolved")
    (selectorScheme "gerbil-poo-logical-symbol"))
   (sourceOwners ("debug.ss" "object.ss"))
   (agentScenario "agent-traces-poo-methods-without-preserving-computed-slot-superfun")
   (intent "query-trace-poo-and-computed-slot-wrapper-before-adding-debug-tracing")
   (selectors
    ((selector
      (role "trace-function-wrapper")
      (symbol "traced-function")
      (selector "gerbil-poo://debug.ss#traced-function"))
     (selector
      (role "trace-inherited-slot")
      (symbol "trace-inherited-slot")
      (selector "gerbil-poo://debug.ss#trace-inherited-slot"))
     (selector
      (role "trace-poo-wrapper")
      (symbol "trace-poo")
      (selector "gerbil-poo://debug.ss#trace-poo"))
     (selector
      (role "computed-slot-wrapper")
      (symbol "$computed-slot-spec")
      (selector "gerbil-poo://debug.ss#trace-inherited-slot"))))
   (minimalForms
    ((form
      (role "trace-function-wrapper")
      (symbol "traced-function")
      (template
       (head "traced-function")
       (operands ("`(.@ ,name ,slot-name)" "<procedure>"))
       (keywords ()))
      (selector "gerbil-poo://debug.ss#traced-function"))
     (form
      (role "trace-inherited-slot")
      (symbol "trace-inherited-slot")
      (template
       (head "trace-inherited-slot")
       (operands ("<poo-name>" "'<slot-symbol>"))
       (keywords ()))
      (selector "gerbil-poo://debug.ss#trace-inherited-slot"))
     (form
      (role "computed-slot-trace")
      (symbol "$computed-slot-spec")
      (template
       (head "$computed-slot-spec")
       (operands ("(lambda (self superfun) ...)"))
       (keywords ("call-superfun-before-wrapping")))
      (selector "gerbil-poo://debug.ss#trace-inherited-slot"))
     (form
      (role "trace-poo-wrapper")
      (symbol "trace-poo")
      (template
       (head "trace-poo")
       (operands ("<poo>" "<name>"))
       (keywords ()))
      (selector "gerbil-poo://debug.ss#trace-poo"))))
   (failureCases
    ((failureCase
      (id "trace-without-superfun")
      (riskKind "computed-slot-contract")
      (correctiveAction "call-superfun-inside-trace-inherited-slot-before-wrapping")
      (badPattern "trace-wrapper-that-never-calls-inherited-superfun")
      (selectors ("gerbil-poo://debug.ss#trace-inherited-slot")))
     (failureCase
      (id "eager-trace-wrapper")
      (riskKind "debug-tracing-semantics")
      (correctiveAction "use-$computed-slot-spec-to-delay-inherited-slot-wrapper")
      (badPattern "wraps-slot-value-before-computed-slot-inheritance-runs")
      (selectors ("gerbil-poo://debug.ss#trace-inherited-slot"
                  "gerbil-poo://object.ss#apply-slot-spec")))
     (failureCase
      (id "trace-mutates-source-poo")
      (riskKind "debug-object-isolation")
      (correctiveAction "create-traced-variant-with-trace-poo-wrapper")
      (badPattern "mutates-original-poo-while-adding-trace-slots")
      (selectors ("gerbil-poo://debug.ss#trace-poo"
                  "gerbil-poo://debug.ss#trace-inherited-slot")))))
   (qualitySignals ("dependency-backed-mapping"
                    "debug-source"
                    "computed-slot-source"
                    "superfun-chain-source"
                    "trace-wrapper-source"
                    "runtime-trace-poo-witness"))
   (witness "runtime-trace-poo-witness")))
 (missing ())
 (witness "runtime-trace-poo-witness")
 (next "search pattern poo trace runtime witness"))
