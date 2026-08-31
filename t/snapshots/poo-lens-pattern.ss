(patternSearch
 (namespace "pattern")
 (authority "executable-pattern")
 (evidenceGrade "fact")
 (quality "verified")
 (query "poo lens slot-lens")
 (pattern
  (pattern
   (id "poo-lens-slot")
   (extension "poo")
   (focus "lens slot-lens")
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
   (sourceOwners ("mop.ss" "t/mop-test.ss"))
   (agentScenario "agent-updates-poo-slots-without-lens-composition-semantics")
   (intent "query-slot-lens-and-lens-compose-before-writing-functional-slot-updates")
   (selectors
    ((selector
      (role "lens-class")
      (symbol "Lens")
      (selector "gerbil-poo://mop.ss#Lens"))
     (selector
      (role "lens-slot")
      (symbol "slot-lens")
      (selector "gerbil-poo://mop.ss#slot-lens"))
     (selector
      (role "lens-compose")
      (symbol ".compose")
      (selector "gerbil-poo://mop.ss#Lens.compose"))
     (selector
      (role "real-project-lens-test")
      (symbol "Lenses")
      (selector "gerbil-poo-test://t/mop-test.ss#Lenses"))))
   (minimalForms
    ((form
      (role "slot-lens")
      (symbol "slot-lens")
      (template
       (head "slot-lens")
       (operands ("'<slot-symbol>"))
       (keywords ()))
      (selector "gerbil-poo://mop.ss#slot-lens"))
     (form
      (role "lens-compose")
      (symbol ".compose")
      (template
       (head ".call")
       (operands ("<lens>" ".compose" "<nested-lens>"))
       (keywords ()))
      (selector "gerbil-poo://mop.ss#Lens.compose"))
     (form
      (role "lens-regression-test")
      (symbol "Lenses")
      (template
       (head "check-equal?")
       (operands ("(.alist (.call Lens .modify (slot-lens '<slot>) <fn> <object>))"
                  "'((<slot> . <value>) ...)"))
       (keywords ()))
      (selector "gerbil-poo-test://t/mop-test.ss#Lenses"))))
   (failureCases
    ((failureCase
      (id "imperative-slot-update")
      (riskKind "functional-update-contract")
      (correctiveAction "use-slot-lens-and-lens-compose")
      (badPattern "manual-slot-mutation-instead-of-slot-lens")
      (selectors ("gerbil-poo://mop.ss#slot-lens"
                  "gerbil-poo://mop.ss#Lens.compose")))))
   (qualitySignals ("dependency-backed-mapping"
                    "lens-source"
                    "slot-lens-source"
                    "real-project-lens-test"
                    "functional-update-witness"))
   (witness "real-project-lens-witness")))
 (missing ())
 (witness "real-project-lens-witness")
 (next "search pattern poo lens slot-lens"))
