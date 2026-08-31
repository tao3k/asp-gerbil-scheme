(patternSearch
 (namespace "pattern")
 (authority "executable-pattern")
 (evidenceGrade "fact")
 (quality "verified")
 (query "poo slot cache computed")
 (pattern
  (pattern
   (id "poo-slot-cache-computed")
   (extension "poo")
   (focus "slot cache computed")
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
   (sourceOwners ("object.ss" "mop.ss"))
   (agentScenario "agent-adds-computed-poo-slot-without-cache-or-superfun-semantics")
   (intent "query-slot-cache-and-apply-slot-spec-before-adding-computed-slots")
   (selectors
    ((selector
      (role "slot-spec-application")
      (symbol "apply-slot-spec")
      (selector "gerbil-poo://object.ss#apply-slot-spec"))
     (selector
      (role "object-materialization")
      (symbol "instantiate-object!")
      (selector "gerbil-poo://object.ss#instantiate-object!"))
     (selector
      (role "precedence-materialization")
      (symbol "compute-precedence-list!")
      (selector "gerbil-poo://object.ss#compute-precedence-list!"))
     (selector
      (role "slot-function-materialization")
      (symbol "compute-slot-funs!")
      (selector "gerbil-poo://object.ss#compute-slot-funs!"))
     (selector
      (role "slot-cache-read")
      (symbol ".ref")
      (selector "gerbil-poo://object.ss#.ref"))
     (selector
      (role "slot-cache-read-existing")
      (symbol ".ref/cached")
      (selector "gerbil-poo://object.ss#.ref/cached"))
     (selector
      (role "slot-lens")
      (symbol "slot-lens")
      (selector "gerbil-poo://mop.ss#slot-lens"))
     (selector
      (role "real-project-slot-cache-test")
      (symbol "putslot-test")
      (selector "gerbil-poo-test://t/object-test.ss#testing-putslot"))))
   (minimalForms
    ((form
      (role "computed-slot")
      (symbol "computed-slot-spec")
      (template
       (head "computed-slot-spec")
       (operands ("(lambda (self superfun) ...)"))
       (keywords ()))
      (selector "gerbil-poo://object.ss#apply-slot-spec"))
     (form
      (role "slot-cache-read")
      (symbol ".ref")
      (template
       (head ".ref")
       (operands ("<object>" "<slot-symbol>"))
       (keywords ()))
      (selector "gerbil-poo://object.ss#.ref"))
     (form
      (role "slot-cache-read-existing")
      (symbol ".ref/cached")
      (template
       (head ".ref/cached")
       (operands ("<object>" "<slot-symbol>" "<default>"))
       (keywords ()))
      (selector "gerbil-poo://object.ss#.ref/cached"))
     (form
      (role "slot-cache-regression-test")
      (symbol "putslot-test")
      (template
       (head "check")
       (operands ("(.@ <object> <computed-slot>)"
                  "'<expected-cached-value>"))
       (keywords ()))
      (selector "gerbil-poo-test://t/object-test.ss#testing-putslot"))))
   (failureCases
    ((failureCase
      (id "uncached-slot-side-effect")
      (riskKind "slot-cache-semantics")
      (correctiveAction "use-ref-cache-and-ref-cached-selectors")
      (badPattern "computed-slot-with-side-effects-assumed-to-run-every-ref")
      (selectors ("gerbil-poo://object.ss#.ref"
                  "gerbil-poo://object.ss#.ref/cached")))
     (failureCase
      (id "missing-superfun-chain")
      (riskKind "computed-slot-contract")
      (correctiveAction "follow-apply-slot-spec-superfun-form")
      (badPattern "computed-slot-ignores-superfun")
      (selectors ("gerbil-poo://object.ss#apply-slot-spec")))))
   (qualitySignals ("dependency-backed-mapping"
                    "apply-slot-spec-source"
                    "object-materialization-source"
                    "precedence-materialization-source"
                    "slot-function-materialization-source"
                    "ref-cache-source"
                    "real-project-slot-cache-test"
                    "superfun-witness"))
   (witness "real-project-slot-cache-witness")))
 (missing ())
 (witness "real-project-slot-cache-witness")
 (next "search pattern poo slot cache computed"))
