(import :clan/building
        :clan/poo/object
        :std/test
        (only-in "../provider-package-spec"
                 asp-gerbil-scheme-provider-package-spec)
        (only-in "../src/build-api/package-spec"
                 asp-gerbil-scheme-package-build-profile)
        (only-in "../src/build-api/source-closure"
                 asp-gerbil-scheme-source-dependency-order))

(export provider-package-spec-test main)

(def (provider-closure-runtime-modules)
  (remove-build-file
   (asp-gerbil-scheme-source-dependency-order
    "."
    '("src/provider-server.ss"))
   "src/provider-server.ss"))

(def provider-package-spec-test
  (test-suite "provider package spec"
    (test-case "the provider projects its Builder Profile to production"
      (check (asp-gerbil-scheme-package-build-profile
              asp-gerbil-scheme-provider-package-spec)
             => 'production))
    (test-case "declared native runtime modules match the closure oracle"
      (check (.get asp-gerbil-scheme-provider-package-spec runtime-modules)
             => (provider-closure-runtime-modules)))
    (test-case "each provider module has one std make completion owner"
      (check (.get asp-gerbil-scheme-provider-package-spec library-modules)
             => '())
      (check (member
              "src/support/time.ss"
              (.get asp-gerbil-scheme-provider-package-spec runtime-modules))
             ? true))))

(def (main . _args)
  (run-tests! provider-package-spec-test))
