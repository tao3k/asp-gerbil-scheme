(patternSearch
 (namespace "pattern")
 (authority "executable-pattern")
 (evidenceGrade "fact")
 (quality "verified")
 (query "poo prototype compose-proto")
 (pattern
  (pattern
   (id "poo-prototype-composition")
   (extension "poo")
   (focus "prototype compose-proto")
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
   (sourceOwners ("proto.ss"))
   (agentScenario "agent-composes-poo-prototypes-without-knowing-proto-order")
   (intent "query-proto-composition-source-before-composing-object-prototypes")
   (selectors
    ((selector
      (role "prototype-instantiation")
      (symbol "instantiate-proto")
      (selector "gerbil-poo://proto.ss#instantiate-proto"))
     (selector
      (role "prototype-composition")
      (symbol "compose-proto")
      (selector "gerbil-poo://proto.ss#compose-proto"))
     (selector
      (role "prototype-composition-list")
      (symbol "compose-proto*")
      (selector "gerbil-poo://proto.ss#compose-proto*"))))
   (minimalForms
    ((form
      (role "prototype-instantiation")
      (symbol "instantiate-proto")
      (template
       (head "instantiate-proto")
       (operands ("<proto>" "<base-object>"))
       (keywords ()))
      (selector "gerbil-poo://proto.ss#instantiate-proto"))
     (form
      (role "prototype-composition")
      (symbol "compose-proto")
      (template
       (head "compose-proto")
       (operands ("<proto-a>" "<proto-b>"))
       (keywords ()))
      (selector "gerbil-poo://proto.ss#compose-proto"))
     (form
      (role "prototype-composition-list")
      (symbol "compose-proto*")
      (template
       (head "compose-proto*")
       (operands ("[<proto-a> <proto-b> ...]"))
       (keywords ()))
      (selector "gerbil-poo://proto.ss#compose-proto*"))))
   (failureCases
    ((failureCase
      (id "proto-order-confusion")
      (riskKind "composition-order")
      (correctiveAction "follow-compose-proto-source-order-before-editing")
      (badPattern "compose-proto-with-reversed-base-and-extension-order")
      (selectors ("gerbil-poo://proto.ss#compose-proto"
                  "gerbil-poo://proto.ss#compose-proto*")))
     (failureCase
      (id "missing-prototype-runtime-witness")
      (riskKind "untested-composition")
      (correctiveAction "add-instantiate-proto-behavior-snapshot")
      (badPattern "prototype-stack-without-instantiation-witness")
      (selectors ("gerbil-poo://proto.ss#instantiate-proto")))))
   (qualitySignals ("dependency-backed-mapping"
                    "proto-source"
                    "composition-order"
                    "runtime-prototype-composition-witness"
                    "poo-prototype-object-extension"))
   (witness "runtime-prototype-composition-witness")))
 (missing ())
 (witness "runtime-prototype-composition-witness")
 (next "search pattern poo prototype composition witness"))
