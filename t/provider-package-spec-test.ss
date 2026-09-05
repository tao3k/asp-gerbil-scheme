(import :clan/poo/object
        :std/test
        (only-in "../provider-package-spec"
                 asp-gerbil-scheme-provider-package-spec)
        (only-in "../src/build-api/package-spec"
                 asp-gerbil-scheme-package-build-profile))

(export provider-package-spec-test main)

(def provider-package-spec-test
  (test-suite "provider package spec"
    (test-case "the provider projects its Builder Profile to production"
      (check (asp-gerbil-scheme-package-build-profile
              asp-gerbil-scheme-provider-package-spec)
             => 'production))
    (test-case "declared runtime modules project to one separate AOT boundary"
      (let* ((runtime-modules
              (.get asp-gerbil-scheme-provider-package-spec runtime-modules))
             (native-spec
              (.get asp-gerbil-scheme-provider-package-spec native-spec))
             (entry (list-ref native-spec (length runtime-modules))))
        (check (map cadr (take native-spec (length runtime-modules)))
               => runtime-modules)
        (check (take entry 6)
               => '(exe: "src/provider-server"
                       bin: "asp-gerbil-scheme"
                       runtime-linkage: separate-aot))))
    (test-case "each provider module has one std make completion owner"
      (check (.get asp-gerbil-scheme-provider-package-spec library-modules)
             => '())
      (check (member
              "src/support/time.ss"
              (.get asp-gerbil-scheme-provider-package-spec runtime-modules))
             ? true))))

(def (main . _args)
  (run-tests! provider-package-spec-test))
