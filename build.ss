#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(export asp-gerbil-scheme-library-package-spec)

(import :clan/building
        (only-in :std/srfi/1 fold)
        (only-in :std/srfi/13 string-prefix?)
        (only-in "./src/building/build-script"
                 defbuild-script
                 framework-build-bindir)
        (only-in "./src/build-api/package-spec"
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-package-build-profile
                 asp-gerbil-scheme-package-native-spec))

(def +product-entry-modules+
  '("src/provider-server"
    "src/cli"
    "src/cli-dev-linker"
    "src/cli-install-linker"
    "src/cli-query"
    "src/cli-release-linker"
    "src/runtime/provider-operation"
    "src/runtime/provider-http-json-server"
    "src/commands/provider-runtime"
    "src/cli-launcher"))

(def (source-modules)
  (filter (cut string-prefix? "src/" <>) (all-gerbil-modules)))

(asp-gerbil-scheme-package-spec!
 (asp-gerbil-scheme-library-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
  (role 'library)
  (profile 'development)
  (native-spec
   (fold (lambda (module spec)
           (remove-build-file spec module))
         (source-modules)
         +product-entry-modules+)))

(defbuild-script
 (asp-gerbil-scheme-package-native-spec
  asp-gerbil-scheme-library-package-spec)
 profile: (asp-gerbil-scheme-package-build-profile
           asp-gerbil-scheme-library-package-spec)
 bindir: (framework-build-bindir))
