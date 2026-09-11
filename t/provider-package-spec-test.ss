(import :clan/poo/object
        :std/test
        (only-in "../provider-package-spec"
                 asp-gerbil-scheme-provider-package-spec))

(export provider-package-spec-test main)

(def provider-package-spec-test
  (test-suite "provider package spec"
    (test-case "declared runtime modules project through native BuildSpec forms"
      (let* ((runtime-modules
              (.get asp-gerbil-scheme-provider-package-spec runtime-modules))
             (native-spec
              (.get asp-gerbil-scheme-provider-package-spec native-spec))
             (entry (list-ref native-spec (length runtime-modules))))
        (check (map cadr (take native-spec (length runtime-modules)))
               => runtime-modules)
        (check (take entry 4)
               => '(exe: "src/provider-server"
                       bin: "asp-gerbil-scheme"))
        (check (member "-cc-options" entry) ? true)
        (check (member "-ld-options" entry) ? true)))
    (test-case "each provider module has one std make completion owner"
      (check (.get asp-gerbil-scheme-provider-package-spec library-modules)
             => '())
      (check (member
              "src/parser/syntax-ast.ss"
              (.get asp-gerbil-scheme-provider-package-spec runtime-modules))
             ? true)
      (check (member
              "src/parser/syntax-macro-family.ss"
              (.get asp-gerbil-scheme-provider-package-spec runtime-modules))
             ? true)
      (check (member
              "src/protocol/provider-operation-catalog.ss"
              (.get asp-gerbil-scheme-provider-package-spec runtime-modules))
             ? true)
      (check (member "src/protocol/registry.ss"
                     (.get asp-gerbil-scheme-provider-package-spec
                           runtime-modules))
             => #f)
      (check (member "src/commands/agent.ss"
                     (.get asp-gerbil-scheme-provider-package-spec
                           runtime-modules))
             => #f))))

(def (main . _args)
  (run-tests! provider-package-spec-test))
