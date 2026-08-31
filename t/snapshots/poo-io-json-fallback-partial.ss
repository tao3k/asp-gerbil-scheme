(patternSearch
 (namespace "pattern")
 (authority "executable-pattern")
 (evidenceGrade "fact")
 (quality "partial")
 (query "poo json fallback")
 (pattern
  (pattern
   (id "poo-io-json-fallback")
   (extension "poo")
   (focus "json fallback")
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
   (sourceOwners ("io.ss" "mop.ss" "object.ss"))
   (agentScenario "agent-customizes-poo-serialization-without-json-or-print-fallbacks")
   (intent "query-poo-io-fallbacks-before-overriding-json-or-print-behavior")
   (selectors
    ((selector
      (role "print-fallback")
      (symbol "@method :pr")
      (selector "gerbil-poo://io.ss#@method:pr"))
     (selector
      (role "writeenv-fallback")
      (symbol "@method :wr")
      (selector "gerbil-poo://io.ss#@method:wr-object"))
     (selector
      (role "json-fallback")
      (symbol "@method :json")
      (selector "gerbil-poo://io.ss#@method:json"))
     (selector
      (role "json-writer")
      (symbol "@method :write-json")
      (selector "gerbil-poo://io.ss#@method:write-json"))
     (selector
      (role "typed-value-writer")
      (symbol "TV")
      (selector "gerbil-poo://io.ss#@method:wr-TV"))
     (selector
      (role "writeenv-runtime-boundary")
      (symbol "writeenv")
      (selector "gerbil-runtime://builtin#writeenv"))
     (selector
      (role "writeenv-method-dispatch-witness")
      (symbol "method-ref")
      (selector "gerbil-poo-witness://t/unit/poo/runtime-witness.ss#writeenv-method-dispatch"))
     (selector
      (role "object-value-mapping")
      (symbol "map-object-values")
      (selector "gerbil-poo://mop.ss#map-object-values"))))
   (minimalForms
    ((form
      (role "print-fallback")
      (symbol "@method :pr")
      (template
       (head "defmethod")
       (operands ("(@method :pr object)"
                  "(lambda (self port options) ...)"))
       (keywords ()))
     (selector "gerbil-poo://io.ss#@method:pr"))
     (form
      (role "writeenv-fallback")
      (symbol "@method :wr")
      (template
       (head "defmethod")
       (operands ("(@method :wr object)"
                  "(lambda (self writeenv) ...)"))
       (keywords ()))
      (selector "gerbil-poo://io.ss#@method:wr-object"))
     (form
      (role "json-fallback")
      (symbol "@method :json")
      (template
       (head "defmethod")
       (operands ("(@method :json object)"
                  "(lambda (self) ...)"))
       (keywords ()))
      (selector "gerbil-poo://io.ss#@method:json"))
     (form
      (role "json-writer")
      (symbol "@method :write-json")
      (template
       (head "defmethod")
       (operands ("(@method :write-json object)"
                  "(lambda (self port) ...)"))
       (keywords ()))
      (selector "gerbil-poo://io.ss#@method:write-json"))
     (form
      (role "typed-value-writer")
      (symbol "TV")
      (template
       (head "defmethod")
       (operands ("(@method :wr TV)"
                  "(lambda (self writeenv) ...)"))
       (keywords ("write-object" ".json<-" ".string<-" ".sexp<-")))
      (selector "gerbil-poo://io.ss#@method:wr-TV"))
     (form
      (role "writeenv-method-dispatch-witness")
      (symbol "method-ref")
      (template
       (head "method-ref")
       (operands ("<object-or-TV>" "`:wr"))
       (keywords ()))
      (selector "gerbil-poo-witness://t/unit/poo/runtime-witness.ss#writeenv-method-dispatch"))))
   (failureCases
    ((failureCase
      (id "json-fallback-bypass")
      (riskKind "serialization-contract")
      (correctiveAction "follow-json-fallback-order-before-overriding")
      (badPattern "manual-json-writer-that-skips-type-json<-and-sexp")
      (selectors ("gerbil-poo://io.ss#@method:json"
                  "gerbil-poo://io.ss#@method:write-json")))
     (failureCase
      (id "print-representation-bypass")
      (riskKind "display-contract")
      (correctiveAction "follow-pr-fallback-order-before-overriding")
      (badPattern "manual-printer-that-skips-print-representation-and-sexp")
      (selectors ("gerbil-poo://io.ss#@method:pr")))
     (failureCase
      (id "typed-value-writer-bypass")
      (riskKind "typed-value-serialization-contract")
      (correctiveAction "follow-TV-writeenv-fallback-order-before-specializing")
      (badPattern "manual-TV-printer-that-skips-write-object-json-string-sexp-precedence")
      (selectors ("gerbil-poo://io.ss#@method:wr-TV"
                  "gerbil-poo://io.ss#@method:wr-object")))
     (failureCase
      (id "direct-writeenv-construction")
      (riskKind "runtime-internal-boundary")
      (correctiveAction "use-write-json-pr-or-method-ref-dispatch-witness-until-writeenv-roundtrip-is-owned")
      (badPattern "agent-constructs-writeenv-or-calls-:wr-directly")
      (selectors ("gerbil-runtime://builtin#writeenv"
                  "gerbil-poo-witness://t/unit/poo/runtime-witness.ss#writeenv-method-dispatch")))
     (failureCase
      (id "write-printer-hook-assumption")
      (riskKind "printer-hook-contract")
      (correctiveAction "treat-writeenv-roundtrip-as-missing-until-a-runtime-owner-exposes-a-stable-writeenv-entrypoint")
      (badPattern "agent-assumes-write-output-roundtrips-through-poo-:wr")
      (selectors ("gerbil-poo://io.ss#@method:wr-object"
                  "gerbil-poo://io.ss#@method:wr-TV"
                  "gerbil-runtime://builtin#writeenv")))))
   (qualitySignals ("dependency-backed-mapping"
                    "json-fallback-source"
                    "print-fallback-source"
                    "writeenv-fallback-source"
                    "typed-value-writer-source"
                    "json-roundtrip-witness"
                    "print-fallback-witness"
                    "writeenv-method-dispatch-witness"
                    "writeenv-roundtrip-witness-required"))
   (witness "runtime-json-print-writeenv-method-source-backed-io-fallback")))
 (missing ("writeenv-roundtrip-witness"))
 (witness "runtime-json-print-writeenv-method-source-backed-io-fallback")
 (next "search runtime-source writeenv printer hook"))
