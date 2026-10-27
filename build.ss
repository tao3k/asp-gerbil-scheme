#!/usr/bin/env -S gerbil -:max-heap=2G,debug=q

;;; -*- Gerbil -*-

(import (only-in :std/build-script defbuild-script)
        (only-in "./src/build-api/source-bootstrap"
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

;; Package compilation and its children own their heap budget. Do not export
;; this budget from the package manager to its later gxtags process.
(let (options (getenv "GAMBOPT" #f))
  (setenv "GAMBOPT"
    (string-append (if options (string-append options ",") "")
                   "max-heap=2G,debug=q")))

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
