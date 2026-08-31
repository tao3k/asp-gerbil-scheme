(patternSearch
 (namespace "pattern")
 (authority "executable-pattern")
 (evidenceGrade "fact")
 (quality "verified")
 (query "poo c3 mro slot order")
 (pattern
  (pattern
   (id "poo-c3-mro-regression")
   (extension "poo")
   (focus "c3 mro slot order")
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
   (sourceOwners ("object.ss"
                  "mop.ss"
                  "proto.ss"
                  ":gerbil/runtime/c3"
                  "src/gerbil/test/c3-test.ss"))
   (agentScenario "agent-writes-poo-inheritance-without-knowing-c3-linearization")
   (intent "force-agent-to-query-poo-and-runtime-c3-witnesses-before-editing-inheritance")
   (selectors
    ((selector
      (role "class-definition")
      (symbol "defclass")
      (selector "gerbil-poo://object.ss#defclass"))
     (selector
      (role "method-resolution-order")
      (symbol "class-precedence-list")
      (selector "gerbil-runtime://c3.ss#class-precedence-list"))
     (selector
      (role "real-project-semantic-test")
      (symbol "c3-test")
      (selector "gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test"))))
   (minimalForms
    ((form
      (role "class-definition")
      (symbol "defclass")
      (template
       (head "defclass")
       (operands ("(<Class> <Base>)" "(<slot> ...)"))
       (keywords ("transparent: #t")))
      (selector "gerbil-poo://object.ss#defclass"))
     (form
      (role "mro-regression-test")
      (symbol "class-precedence-list")
      (template
       (head "check")
       (operands ("(map ##type-name (class-precedence-list <Class>::t))"
                  "'(<Class> <Base> ... object t)"))
       (keywords ()))
      (selector "gerbil-runtime-test://src/gerbil/test/c3-test.ss#class-inheritance"))
     (form
      (role "slot-order-regression-test")
      (symbol "class-type-slot-vector")
      (template
       (head "check")
       (operands ("(class-type-slot-vector <Class>::t)"
                  "#(__class <base-slots> ... <class-slots> ...)"))
       (keywords ()))
      (selector "gerbil-runtime-test://src/gerbil/test/c3-test.ss#slot-computation-order"))))
   (failureCases
    ((failureCase
      (id "unchecked-mro-assumption")
      (riskKind "semantic-regression-gap")
      (correctiveAction "add-c3-linearization-and-slot-vector-witnesses")
      (badPattern "class-hierarchy-without-c3-or-slot-order-test")
      (selectors ("gerbil-runtime://c3.ss#class-precedence-list"
                  "gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test"
                  "gerbil-runtime-test://src/gerbil/test/c3-test.ss#slot-computation-order")))
     (failureCase
      (id "method-without-generic")
      (riskKind "incomplete-method-contract")
      (correctiveAction "follow-generic-and-method-mappings-together")
      (badPattern "defmethod-without-generic-slot-contract")
      (selectors ("gerbil-poo://mop.ss#.defgeneric"
                  "gerbil-poo://mop.ss#defmethod")))))
   (qualitySignals ("active-extension-fact"
                    "dependency-backed-mapping"
                    "real-project-c3-test"
                    "mro-linearization-witness"
                    "slot-order-witness"
                    "failure-cases"))
   (witness "real-project-c3-and-slot-order-witness")))
 (missing ())
 (witness "real-project-c3-and-slot-order-witness")
 (next "search extension poo pattern c3"))
