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
    ;; The library graph must also omit every provider-only module reachable
    ;; from a retained command. std/make correctly follows imports, so leaving
    ;; registry/agent in the library catalog would pull this runtime back in.
    "src/runtime/provider/types"
    "src/runtime/provider/objects"
    "src/runtime/provider/interface"
    "src/runtime/provider-operation"
    "src/runtime/provider-http-json-server"
    "src/runtime/provider-semantic-evidence"
    "src/protocol/registry"
    "src/commands/agent"))

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
