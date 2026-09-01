(export asp-gerbil-scheme-provider-package-spec)

(import :clan/building
        (only-in :asp-gerbil-scheme/src/build-api/component-closure
                 asp-gerbil-scheme-source-dependency-order)
        (only-in "./src/build-api/package-spec"
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype)
        (only-in "./src/building/build-script"
                 framework-executable-build-spec)

)

(def (provider-runtime-modules)
  (remove-build-file
   (asp-gerbil-scheme-source-dependency-order
    "."
    '("src/provider-server.ss"))
   "src/provider-server.ss"))

(asp-gerbil-scheme-package-spec!
 (asp-gerbil-scheme-provider-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
 (role 'provider)
 (entry "src/provider-server")
 (native-spec
  (let (runtime-modules (provider-runtime-modules))
    (append
     '("provider-package-spec")
     (framework-executable-build-spec
      "src/provider-server"
      "asp-gerbil-scheme"
      runtime-modules
      []
      '(tls))))))
