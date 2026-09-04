(import :std/test
        :clan/poo/object
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/build-api/package-spec
        (only-in :asp-gerbil-scheme/src/build-api/builder-profile
                 asp-gerbil-scheme-production-builder-profile)
        (only-in :std/srfi/13 string-contains))

(export library-provider-boundary-test)

(asp-gerbil-scheme-package-spec! library-package-spec-fixture
  (spec library-build-spec-fixture)
  (modules ["src/parser/model.ss"])
  (role 'library)
  (profile asp-gerbil-scheme-production-builder-profile)
  (roots ["."])
  (exclude-directories [])
  (native-spec '("src/parser/model")))

(asp-gerbil-scheme-package-spec! conventional-root-package-spec-fixture
  (spec conventional-root-build-spec-fixture)
  (modules ["src/library.ss" "t/library-test.ss"])
  (role 'library)
  (profile asp-gerbil-scheme-production-builder-profile)
  (roots ["."]))

(def (fixture-native-spec-projector package-spec)
  (filter (lambda (module) (not (string-contains module "test")))
          (asp-gerbil-scheme-package-modules package-spec)))

(asp-gerbil-scheme-package-spec! projected-native-package-spec-fixture
  (spec projected-native-build-spec-fixture)
  (modules ["src/library.ss" "src/library-test-support.ss"])
  (role 'library)
  (profile asp-gerbil-scheme-production-builder-profile)
  (roots ["."])
  (native-spec-projector fixture-native-spec-projector))

;; : (-> (List ModuleReference))
(def (downstream-build-api-imports)
  (map module-import-fact-module
       (source-file-module-imports
        (parse-source-file "." "src/package-build-api.ss"))))

;; : (-> ModuleReference Boolean)
(def (asp-product-module-reference? reference)
  (ormap (lambda (fragment) (string-contains reference fragment))
         '("cli" "provider" "testing" "package-native-plan")))

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
      (check (asp-gerbil-scheme-package-modules
              library-package-spec-fixture)
             => ["src/parser/model.ss"])
      (check (.get library-package-spec-fixture source-catalog-authority)
             => #f)
      (check (asp-gerbil-scheme-package-source-roots
              library-package-spec-fixture)
             => ["."])
      (check (asp-gerbil-scheme-package-build-profile
              asp-gerbil-scheme-library-package-prototype)
             => 'development))
    (test-case "project root discovery excludes the profile test root natively"
      (check (asp-gerbil-scheme-package-native-spec
             conventional-root-package-spec-fixture)
             => ["src/library.ss"]))
    (test-case "named projectors receive the resolved package catalog"
      (check (asp-gerbil-scheme-package-native-spec
              projected-native-package-spec-fixture)
             => ["src/library.ss"])
      (check (projected-native-build-spec-fixture)
             => ["src/library.ss"]))
    (test-case "downstream Build API excludes ASP product entry modules"
      (let (imports (downstream-build-api-imports))
        (check (ormap asp-product-module-reference? imports) => #f)
        (check (member "./build-api/package-spec" imports) ? pair?)
        (check (member "./build-api/profile-build-spec" imports) ? pair?)
        (check (member "./building/build-script" imports) ? pair?)))))
