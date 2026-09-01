(import :std/test
        :clan/poo/object
        :asp-gerbil-scheme/src/building/provider-package-spec)

(export explicit-provider-boundary-test)

(def explicit-provider-boundary-test
  (test-suite "explicit provider build boundary"
    (test-case "provider object extends the package-spec contract"
      (check (.slot? asp-gerbil-scheme-provider-package-spec 'native-spec) => #t)
      (check (.get asp-gerbil-scheme-provider-package-spec role) => 'provider)
      (check (.get asp-gerbil-scheme-provider-package-spec entry)
             => "src/provider-server"))))
