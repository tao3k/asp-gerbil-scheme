#!/usr/bin/env gerbil

;;; -*- Gerbil -*-

(import (only-in :std/build-script defbuild-script)
        (only-in "./src/build-api/source-bootstrap"
                 asp-gerbil-scheme-package-spec!
                 all-gerbil-modules
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-package-native-profile
                 asp-gerbil-scheme-package-pkg-config-libs
                 asp-gerbil-scheme-native-profile-prepare!))

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

((asp-gerbil-scheme-native-profile-prepare!
  (asp-gerbil-scheme-package-native-profile
   asp-gerbil-scheme-library-package-spec))
 (asp-gerbil-scheme-package-pkg-config-libs
  asp-gerbil-scheme-library-package-spec))

;; Native spec/compile/clean/meta dispatch; gxpkg owns package acquisition.
(defbuild-script (asp-gerbil-scheme-library-spec))
