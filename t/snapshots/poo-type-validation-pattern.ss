(patternSearch
 (namespace "pattern")
 (authority "executable-pattern")
 (evidenceGrade "fact")
 (quality "verified")
 (query "poo sealed validate")
 (pattern
  (pattern
   (id "poo-type-validation-sealed")
   (extension "poo")
   (focus "sealed validate")
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
   (agentScenario "agent-defines-poo-class-without-sealed-type-validation")
   (intent "query-sealed-class-and-validate-witness-before-writing-type-checked-poo-classes")
   (selectors
    ((selector
      (role "class-descriptor")
      (symbol "Class.")
      (selector "gerbil-poo://mop.ss#Class."))
     (selector
      (role "function-validator")
      (symbol "Function.")
      (selector "gerbil-poo://mop.ss#Function."))
     (selector
      (role "generic-slot-validator")
      (symbol "slot-checker")
      (selector "gerbil-poo://mop.ss#slot-checker"))
     (selector
      (role "real-project-validation-test")
      (symbol "mop-test")
      (selector "gerbil-poo-test://t/mop-test.ss#sealed-type-validation"))))
   (minimalForms
    ((form
      (role "sealed-class-definition")
      (symbol "define-type")
      (template
       (head "define-type")
       (operands ("(<Class> @ <Base>)"
                  "slots: =>.+ {<slot>: {type: <Type>} ...}"))
       (keywords ("sealed: #t")))
      (selector "gerbil-poo://mop.ss#Class."))
     (form
      (role "generic-slot-validator")
      (symbol ".defgeneric")
      (template
       (head ".defgeneric")
       (operands ("(<accessor> x)"))
       (keywords ("slot: <slot>" "default: <value>")))
      (selector "gerbil-poo://mop.ss#slot-checker"))
     (form
      (role "validation-regression-test")
      (symbol "validate")
      (template
       (head "validate")
       (operands ("<Type>" "<object>"))
       (keywords ()))
      (selector "gerbil-poo-test://t/mop-test.ss#sealed-type-validation"))))
   (failureCases
    ((failureCase
      (id "missing-required-typed-slot")
      (riskKind "type-validation-gap")
      (correctiveAction "validate-against-real-mop-test-required-slot-failures")
      (badPattern "class-instance-created-without-required-typed-slot")
      (selectors ("gerbil-poo-test://t/mop-test.ss#sealed-type-validation"
                  "gerbil-poo://mop.ss#Class.")))
     (failureCase
      (id "sealed-extra-slot-assumption")
      (riskKind "sealed-class-contract")
      (correctiveAction "respect-Class.-sealed-effective-slots-check")
      (badPattern "sealed-class-accepts-extra-slots")
      (selectors ("gerbil-poo://mop.ss#Class."
                  "gerbil-poo-test://t/mop-test.ss#sealed-type-validation")))
     (failureCase
      (id "unchecked-function-arity")
      (riskKind "function-validation-contract")
      (correctiveAction "use-Function.-validate-row-witness")
      (badPattern "function-slot-without-arity-or-type-validation")
      (selectors ("gerbil-poo://mop.ss#Function.")))))
   (qualitySignals ("dependency-backed-mapping"
                    "class-descriptor-source"
                    "function-validator-source"
                    "real-project-mop-test"
                    "sealed-type-witness"
                    "validation-negative-witness"))
   (witness "real-project-sealed-type-validation-witness")))
 (missing ())
 (witness "real-project-sealed-type-validation-witness")
 (next "search pattern poo sealed validate"))
