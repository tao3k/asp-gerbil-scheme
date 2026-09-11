(import :std/test
        :clan/poo/object
        "../../../../src/parser/facade"
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-package-native-spec
                 asp-gerbil-scheme-package-modules)
        (only-in :std/srfi/13 string-contains))

(export library-provider-boundary-test)

(asp-gerbil-scheme-package-spec!
 (library-package-spec-fixture
  @ asp-gerbil-scheme-library-package-prototype)
  (spec library-build-spec-fixture)
  (modules ["src/parser/model.ss"])
  (role 'library)
  (native-spec '("src/parser/model")))

(asp-gerbil-scheme-package-spec!
 (conventional-root-package-spec-fixture
  @ asp-gerbil-scheme-library-package-prototype)
  (spec conventional-root-build-spec-fixture)
  (modules ["src/library.ss" "t/library-test.ss"])
  (role 'library))

(def (fixture-native-spec-projector package-spec)
  (filter (lambda (module) (not (string-contains module "test")))
          (asp-gerbil-scheme-package-modules package-spec)))

(asp-gerbil-scheme-package-spec!
 (projected-native-package-spec-fixture
  @ asp-gerbil-scheme-library-package-prototype)
  (spec projected-native-build-spec-fixture)
  (modules ["src/library.ss" "src/library-test-support.ss"])
  (role 'library)
 (native-spec-projector fixture-native-spec-projector))

(asp-gerbil-scheme-package-spec!
 (extended-exclude-package-spec-fixture
  @ asp-gerbil-scheme-library-package-prototype)
 (spec extended-exclude-build-spec-fixture)
 (modules [])
 (exclude-dirs => append '("generated")))

;; : (-> (List ModuleReference))
(def (downstream-build-api-imports)
  (map module-import-fact-module
       (source-file-module-imports
        (parse-source-file "." "build-api.ss"))))

;; : (-> ModuleReference Boolean)
(def (asp-product-entry-module-reference? reference)
  (ormap (lambda (fragment) (string-contains reference fragment))
         '("cli" "provider")))

(def library-provider-boundary-test
  (test-suite "library-default and explicit-provider build boundary"
    (test-case "package macro declares a POO-native library spec"
      (check (.get library-package-spec-fixture role) => 'library)
      (check (asp-gerbil-scheme-package-native-spec
              library-package-spec-fixture)
             => '("src/parser/model"))
      (check (asp-gerbil-scheme-package-modules
              library-package-spec-fixture)
             => ["src/parser/model.ss"]))
    (test-case "an explicit native catalog remains caller-owned"
      (check (asp-gerbil-scheme-package-native-spec
             conventional-root-package-spec-fixture)
             => ["src/library.ss" "t/library-test.ss"]))
    (test-case "named projectors receive the resolved package catalog"
      (check (asp-gerbil-scheme-package-native-spec
              projected-native-package-spec-fixture)
             => ["src/library.ss"])
      (check (projected-native-build-spec-fixture)
             => ["src/library.ss"]))
    (test-case "exclude dirs composition extends clan native defaults"
      (let (exclude-dirs (.get extended-exclude-package-spec-fixture
                               exclude-dirs))
        (check (member "t" exclude-dirs) ? pair?)
        (check (member ".gerbil" exclude-dirs) ? pair?)
        (check (member "generated" exclude-dirs) ? pair?)))
    (test-case "downstream Build API excludes ASP product entry modules"
      (let (imports (downstream-build-api-imports))
        (check (ormap asp-product-entry-module-reference? imports) => #f)
        (check (member "./src/build-api/package-spec" imports) ? pair?)
        (check (member "./src/build-api/profile-build-spec" imports) => #f)
        (check (member "./src/build-api/builder-profile" imports) => #f)))))
