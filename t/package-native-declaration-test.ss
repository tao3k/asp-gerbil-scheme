(import :std/test
        :asp-gerbil-scheme/build-api)
(export package-native-declaration-test)

(asp-gerbil-scheme-package-spec!
 (fixture @ asp-gerbil-scheme-library-package-prototype)
 (spec fixture-spec)
 (modules '("src/a.ss" "src/b.ss" "src/c.ss" "src/main.ss"))
 (exclude-modules '("src/b" "src/c.ss"))
 (product-entry-modules '("src/main.ss"))
 (native-prelude-spec
  '((gsc: "ffi/_native" "-cc-options" "-Iffi")
    (ssi: "ffi/_native")))
 (extra-spec '((ssi: "src/b.ss") (gsc: "foreign.c") "ui/init.ss")))

(asp-gerbil-scheme-package-spec!
 (explicit-fixture @ asp-gerbil-scheme-library-package-prototype)
 (spec explicit-spec)
 (modules '("src/a.ss"))
 (extra-spec '("ui/init.ss"))
 (native-spec '((ssi: "standalone.ss"))))

(def package-native-declaration-test
  (test-suite "declarative native package targets"
    (test-case "exclusions and native additions preserve target forms and order"
      (check (fixture-spec)
             => '((gsc: "ffi/_native" "-cc-options" "-Iffi")
                  (ssi: "ffi/_native")
                  "src/a.ss" (ssi: "src/b.ss")
                  (gsc: "foreign.c") "ui/init.ss")))
    (test-case "declarations do not mutate the catalog or accumulate targets"
      (check (asp-gerbil-scheme-package-modules fixture)
             => '("src/a.ss" "src/b.ss" "src/c.ss" "src/main.ss"))
      (check (fixture-spec) => (fixture-spec)))
    (test-case "explicit native spec still replaces the default declaration"
      (check (explicit-spec) => '((ssi: "standalone.ss"))))))
