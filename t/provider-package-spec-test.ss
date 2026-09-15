(import :gerbil/gambit
        :clan/poo/object
        :std/test
        (only-in "../provider-package-spec"
                 asp-gerbil-scheme-provider-package-spec
                 asp-gerbil-scheme-provider-spec)
        (only-in :asp-gerbil-scheme/src/build-api/native-profile
                 asp-gerbil-scheme-native-profile-name
                 asp-gerbil-scheme-native-profile-platform
                 asp-gerbil-scheme-native-profile-architecture))

(export provider-package-spec-test main)

(def provider-package-spec-test
  (test-suite "provider package spec"
    (test-case "declared runtime modules project through native BuildSpec forms"
      (let* ((runtime-modules
              (.get asp-gerbil-scheme-provider-package-spec runtime-modules))
             (native-spec (asp-gerbil-scheme-provider-spec))
             (entry (list-ref native-spec (length runtime-modules))))
        (check (map cadr (take native-spec (length runtime-modules)))
               => runtime-modules)
        (check (take entry 4)
               => '(exe: "src/provider-server"
                       bin: "asp-gerbil-scheme"))
        ;; PackageSpec declares capabilities; upstream clan/building owns
        ;; pkg-config resolution and the resulting compiler/linker flags.
        (check (member "-cc-options" entry) ? true)
        (check (member "-ld-options" entry) ? true)
        (check (and (member "-cc" entry)
                    (cadr (member "-cc" entry)))
               => (cond-expand
                   (darwin "gcc")
                   (else #f)))
        (check (asp-gerbil-scheme-native-profile-name
                (.get asp-gerbil-scheme-provider-package-spec native-profile))
               => (cond-expand
                   (darwin 'macos-native)
                   (linux 'linux-native)
                   (else 'portable)))
        (check (asp-gerbil-scheme-native-profile-platform
                (.get asp-gerbil-scheme-provider-package-spec native-profile))
               => (cond-expand
                   (darwin 'macos)
                   (linux 'linux)
                   (else 'portable)))
        (check (asp-gerbil-scheme-native-profile-architecture
                (.get asp-gerbil-scheme-provider-package-spec native-profile))
               => (car (system-type)))
        (check (.get asp-gerbil-scheme-provider-package-spec native-capabilities)
               => '(tls))
        (check (.get asp-gerbil-scheme-provider-package-spec pkg-config-libs)
               => '("openssl"))
        (check (.get asp-gerbil-scheme-provider-package-spec nix-deps)
               => '("openssl"))))
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
