(import :std/test
        :clan/poo/object
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/build-api/package-spec)

(export library-provider-boundary-test)

(asp-gerbil-scheme-package-spec! library-package-spec-fixture
  (role 'library)
  (profile 'production)
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
      (check (asp-gerbil-scheme-package-build-profile
              asp-gerbil-scheme-library-package-prototype)
             => 'development))))
