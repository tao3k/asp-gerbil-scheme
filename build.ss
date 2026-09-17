#!/usr/bin/env gerbil

;;; -*- Gerbil -*-

(import (only-in :std/build-script defbuild-script)
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
 (product-entry-modules +product-entry-modules+))

;; Native spec/compile/clean/meta dispatch; gxpkg owns package acquisition.
(defbuild-script (asp-gerbil-scheme-library-spec))
