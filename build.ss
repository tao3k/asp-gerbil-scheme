#!/usr/bin/env gxi

;;; -*- Gerbil -*-

(import (only-in :clan/building
                 all-gerbil-modules
                 init-build-environment!)
        (only-in "./src/build-api/source-bootstrap"
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(def +product-entry-modules+
  '("provider-package-spec"
    "build-provider"
    "src/provider-server"
    "src/commands/provider-runtime"
    ;; Executable provider state is a sibling product. Static protocol
    ;; discovery and command adapters remain in the reusable library graph.
    "src/runtime/provider/types"
    "src/runtime/provider/objects"
    "src/runtime/provider/interface"
    "src/runtime/provider-operation"
    "src/runtime/provider-http-json-server"))

(asp-gerbil-scheme-package-spec!
 (asp-gerbil-scheme-library-package-spec
 @ asp-gerbil-scheme-library-package-prototype)
 (spec asp-gerbil-scheme-library-spec)
 (modules (all-gerbil-modules))
 (product-entry-modules +product-entry-modules+))

;; gerbil.pkg owns physical acquisition. These logical dependency names and
;; the package BuildSpec remain native clan/building declarations; std/make
;; owns execution, scheduling, and freshness.
(init-build-environment!
 name: "asp-gerbil-scheme"
 deps: '("clan" "clan/poo")
 spec: asp-gerbil-scheme-library-spec)
