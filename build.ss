#!/usr/bin/env gxi

;;; -*- Gerbil -*-

(export asp-gerbil-scheme-library-package-spec)

(import (only-in :clan/building init-build-environment!)
        "./build-api")

(def +product-entry-modules+
  '("build-provider"
    "provider-package-spec"
    "src/provider-server"
    "src/commands/provider-runtime"))

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
