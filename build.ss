#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import :std/build-script
        :std/make
        :clan/building
        (only-in :std/srfi/1 fold)
        (only-in "./src/building/build-script"
                 framework-build-bindir
                 framework-executable-build-spec))

;; std/make owns compiler scheduling.  Homebrew Gerbil 0.18.2 requires the
;; provider's compiler-derived runtime closure to be materialized before the
;; executable link; this target manifest is verified against the emitted
;; executable stub rather than widened to every module under src/.
(def +provider-runtime-modules+
  '("src/parser/model"
    "src/parser/selectors"
    "src/parser/support"
    "src/parser/formals"
    "src/parser/syntax-support"
    "src/parser/imports"
    "src/parser/syntax-calls"
    "src/parser/syntax"
    "src/parser/control-flow"
    "src/parser/definition-syntax"
    "src/parser/exact-owner"
    "src/commands/projection-batch"
    "src/exact-source-projection"
    "src/parser/package"
    "src/protocol/command-catalog"
    "src/constants"
    "src/commands/search-prime-light-list"
    "src/commands/search-prime-light"
    "src/search-light-launcher"
    "src/commands/project-resolution"
    "src/runtime/provider-operation"
    "src/runtime/provider-http-json-server"
    "src/commands/provider-runtime"))

;; gerbil.pkg owns package identity and dependencies.  clan/building owns
;; canonical src/ discovery.  This build.ss only declares the package's build
;; spec; std/build-script and std/make retain execution and scheduling authority.
(def (public-library-modules)
  (fold (lambda (module specs)
          (remove-build-file specs module))
        (all-gerbil-modules)
        (cons "src/provider-server" +provider-runtime-modules+)))

(def (spec)
  (framework-executable-build-spec
   "src/provider-server"
   "asp-gerbil-scheme"
   +provider-runtime-modules+
   (public-library-modules)
   '(tls)))

(defbuild-script
 (spec)
 bindir: (framework-build-bindir))
