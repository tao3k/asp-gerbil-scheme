#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(export asp-gerbil-scheme-library-package-spec)

(import :clan/building
        (only-in :std/srfi/1 fold)
        (only-in :std/srfi/13 string-prefix?)
        (only-in "./src/building/build-script"
                 framework-apply-build-core-policy!)
        (only-in "./src/build-api/package-spec"
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
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

(def +project-discovery-exclude-directories+
  '("run" ".git" "_darcs" ".gerbil" "scenarios" "snapshots"))

(def (discover-project-modules)
  (all-gerbil-modules
   exclude-dirs: +project-discovery-exclude-directories+))

(def +project-modules+ (discover-project-modules))
(def +source-modules+
  (filter (cut string-prefix? "src/" <>) +project-modules+))

(asp-gerbil-scheme-package-spec!
 (asp-gerbil-scheme-library-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
  (modules +project-modules+)
  (source-catalog-authority 'project)
  (role 'library)
  (profile 'development)
  (roots ["src" "t"])
  (runtime-roots ["src"])
  (exclude-directories +project-discovery-exclude-directories+)
  (native-spec
   (fold (lambda (module spec)
           (remove-build-file spec module))
         +source-modules+
         +product-entry-modules+)))

(def (spec)
  (framework-apply-build-core-policy!)
  (asp-gerbil-scheme-package-native-spec
   asp-gerbil-scheme-library-package-spec))

;; gerbil.pkg owns physical acquisition.  These are the logical package names
;; used by the already-installed upstream libraries while clan/building owns
;; the ordinary library build lifecycle, freshness, and std/make scheduling.
(init-build-environment!
 name: "asp-gerbil-scheme"
 deps: '("clan" "clan/poo")
 spec: spec)
