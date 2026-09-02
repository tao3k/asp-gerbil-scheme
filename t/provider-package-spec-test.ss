(import :clan/building
        :clan/poo/object
        :std/test
        (only-in "../provider-package-spec"
                 asp-gerbil-scheme-provider-package-spec)
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
    (test-case "declared native runtime modules match the closure oracle"
      (check (.get asp-gerbil-scheme-provider-package-spec runtime-modules)
             => (provider-closure-runtime-modules)))
    (test-case "integration support remains outside the provider runtime closure"
      (check (.get asp-gerbil-scheme-provider-package-spec library-modules)
             => '("src/support/time"))
      (check (member
              "src/support/time"
              (.get asp-gerbil-scheme-provider-package-spec runtime-modules))
             => #f))))

(def (main . _args)
  (run-tests! provider-package-spec-test))
