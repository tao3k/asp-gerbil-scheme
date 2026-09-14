(import :std/test
        :asp-gerbil-scheme/build-api)
(export package-native-declaration-test)

;; Direct defbuild-script controls.  PackageSpec must return these ordinary
;; std/make values exactly; its additional value is reusable POO composition
;; of module scope, exclusions, generated modules, and native profiles.
(def +managed-ffi-native-control+
  '((gxc: "ffi/managed"
          "-cc-options" "-Iffi"
          "-ld-options" "-ldl")
    "src/managed.ss"))

(def +raw-ffi-native-control+
  '((gsc: "ffi/_native" "-cc-options" "-Iffi")
    (ssi: "ffi/_native")
    "src/a.ss" (ssi: "src/b.ss")
    (gsc: "foreign.c") "ui/init.ss"))

(asp-gerbil-scheme-package-spec!
 (managed-ffi-fixture @ asp-gerbil-scheme-library-package-prototype)
 (spec managed-ffi-spec)
 (modules '("src/managed.ss"))
 (native-prelude-spec
  '((gxc: "ffi/managed"
          "-cc-options" "-Iffi"
          "-ld-options" "-ldl"))))

(asp-gerbil-scheme-package-spec!
 (raw-ffi-fixture @ asp-gerbil-scheme-library-package-prototype)
 (spec raw-ffi-spec)
 (modules '("src/a.ss" "src/b.ss" "src/c.ss" "src/main.ss"))
 (exclude-modules '("src/b" "src/c.ss"))
 (product-entry-modules '("src/main.ss"))
 (native-prelude-spec
  '((gsc: "ffi/_native" "-cc-options" "-Iffi")
    (ssi: "ffi/_native")))
 (extra-spec '((ssi: "src/b.ss") (gsc: "foreign.c") "ui/init.ss")))

(def +platform-ffi-target+
  (cond-expand
   (darwin
    '(gsc: "ffi/platform" "-ld-options" "-framework Security"))
   (else
    '(gsc: "ffi/platform" "-ld-options" "-ldl"))))

(asp-gerbil-scheme-package-spec!
 (platform-ffi-fixture @ asp-gerbil-scheme-library-package-prototype)
 (spec platform-ffi-spec)
 (modules '())
 (native-prelude-spec
  (list +platform-ffi-target+ '(ssi: "ffi/platform"))))

(asp-gerbil-scheme-package-spec!
 (explicit-fixture @ asp-gerbil-scheme-library-package-prototype)
 (spec explicit-spec)
 (modules '("src/a.ss"))
 (extra-spec '("ui/init.ss"))
 (native-spec '((ssi: "standalone.ss"))))

(def package-native-declaration-test
  (test-suite "declarative native package targets"
    (test-case "Gerbil begin-ffi modules remain ordinary native gxc targets"
      (check (managed-ffi-spec)
             => +managed-ffi-native-control+))
    (test-case "raw Gambit FFI preserves paired gsc and ssi targets"
      (check (raw-ffi-spec)
             => +raw-ffi-native-control+))
    (test-case "platform-selected external-library flags remain native data"
      (check (platform-ffi-spec)
             => (list +platform-ffi-target+ '(ssi: "ffi/platform"))))
    (test-case "declarations do not mutate the catalog or accumulate targets"
      (check (asp-gerbil-scheme-package-modules raw-ffi-fixture)
             => '("src/a.ss" "src/b.ss" "src/c.ss" "src/main.ss"))
      (check (raw-ffi-spec) => (raw-ffi-spec)))
    (test-case "explicit native spec still replaces the default declaration"
      (check (explicit-spec) => '((ssi: "standalone.ss"))))))
