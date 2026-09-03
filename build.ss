#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(export asp-gerbil-scheme-library-package-spec)

(import (except-in :clan/building all-gerbil-modules)
        :std/srfi/1
        :std/srfi/13
        "./build-api")

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
  '("scenarios" "snapshots"))

(def +source-exclude-directories+
  (append
   (asp-gerbil-scheme-package-exclude-directories
    asp-gerbil-scheme-library-package-prototype)
   +project-discovery-exclude-directories+))

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
  (profile asp-gerbil-scheme-development-builder-profile)
  (roots ["src" "t"])
  (runtime-roots ["src"])
  (exclude-directories +source-exclude-directories+)
  (native-spec
   (fold (lambda (module spec)
           (remove-build-file spec module))
         +source-modules+
         +product-entry-modules+)))

(def (spec)
  (framework-apply-build-core-policy!)
  (asp-gerbil-scheme-package-profiled-build-spec
   asp-gerbil-scheme-library-package-spec))

;; gerbil.pkg owns physical acquisition.  These are the logical package names
;; used by the already-installed upstream libraries while clan/building owns
;; the ordinary library build lifecycle, freshness, and std/make scheduling.
(init-build-environment!
 name: "asp-gerbil-scheme"
 deps: '("clan" "clan/poo")
 spec: spec)
