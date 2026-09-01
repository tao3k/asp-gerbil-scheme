(export asp-gerbil-scheme-provider-package-spec)

(import :clan/building
        (only-in :std/srfi/1 fold)
        (only-in :asp-gerbil-scheme/src/build-api/component-closure
                 asp-gerbil-scheme-source-dependency-order)
        (only-in :asp-gerbil-scheme/src/building/build-script
                 framework-executable-build-spec)
        (only-in :asp-gerbil-scheme/src/building/package-spec
                 asp-gerbil-scheme-package-spec!)
        (only-in :asp-gerbil-scheme/src/building/project-package-spec
                 asp-gerbil-scheme-library-package-spec))

(def (provider-runtime-modules)
  (remove-build-file
   (asp-gerbil-scheme-source-dependency-order
    "."
    '("src/provider-server.ss"))
   "src/provider-server.ss"))

(asp-gerbil-scheme-package-spec!
 (asp-gerbil-scheme-provider-package-spec
  @ asp-gerbil-scheme-library-package-spec)
 (role 'provider)
 (entry "src/provider-server")
 (native-spec
  (previous)
  (let* ((runtime-modules (provider-runtime-modules))
         (library-modules
          (fold (lambda (module spec)
                  (remove-build-file spec module))
                (previous)
                runtime-modules)))
    (append
     library-modules
     '("src/building/provider-package-spec")
     (framework-executable-build-spec
      "src/provider-server"
      "asp-gerbil-scheme"
      runtime-modules
      []
      '(tls))))))
