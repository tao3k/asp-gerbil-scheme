(import :std/test
        :clan/poo/object
        (only-in :asp-gerbil-scheme/src/build-api/source-coverage
                 asp-gerbil-scheme-source-coverage-roots
                 asp-gerbil-scheme-source-coverage-runtime-roots)
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/build-api/package-spec)

(export library-provider-boundary-test)

(asp-gerbil-scheme-package-spec! library-package-spec-fixture
  (role 'library)
  (profile 'production)
  (roots ["src"])
  (runtime-roots ["src"])
  (exclude-directories [])
  (native-spec '("src/parser/model")))

(def library-provider-boundary-test
  (test-suite "library-default and explicit-provider build boundary"
    (test-case "package macro declares a POO-native library spec"
      (check (.get library-package-spec-fixture role) => 'library)
      (check (asp-gerbil-scheme-package-native-spec
              library-package-spec-fixture)
             => '("src/parser/model"))
      (check (asp-gerbil-scheme-package-build-profile
              library-package-spec-fixture)
             => 'production)
      (check (asp-gerbil-scheme-package-source-roots
              library-package-spec-fixture)
             => ["src"])
      (check (asp-gerbil-scheme-package-runtime-roots
              library-package-spec-fixture)
             => ["src"])
      (check (asp-gerbil-scheme-source-coverage-roots) => ["src"])
      (check (asp-gerbil-scheme-source-coverage-runtime-roots) => ["src"])
      (check (asp-gerbil-scheme-package-build-profile
              asp-gerbil-scheme-library-package-prototype)
             => 'development))))
