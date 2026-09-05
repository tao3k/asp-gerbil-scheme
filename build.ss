#!/usr/bin/env gxi

;;; -*- Gerbil -*-

(export asp-gerbil-scheme-library-package-spec)

(import (only-in :clan/building init-build-environment!)
        "./build-api")

(def +product-entry-modules+
  '("src/provider-server"
    "src/cli"
    "src/cli-dev-linker"
    "src/cli-install-linker"
    "src/cli-query"
    "src/cli-release-linker"
    "src/commands/provider-runtime"
    "src/cli-launcher"))

(asp-gerbil-scheme-package-spec!
 (asp-gerbil-scheme-library-package-spec
  @ asp-gerbil-scheme-library-package-prototype)
  (spec spec)
  (role 'library)
  (profile asp-gerbil-scheme-development-builder-profile)
  (exclude-modules +product-entry-modules+))

;; gerbil.pkg owns physical acquisition.  These are the logical package names
;; used by the already-installed upstream libraries while clan/building owns
;; the ordinary library build lifecycle, freshness, and std/make scheduling.
(init-build-environment!
 name: "asp-gerbil-scheme"
 deps: '("clan" "clan/poo")
 spec: spec)
