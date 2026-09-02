(export asp-gerbil-scheme-provider-package-spec)

(import (only-in "./src/build-api/package-spec"
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype)
        (only-in "./src/building/build-script"
                 framework-executable-build-spec))

;; Build entrypoints must be self-hosting: this native Gerbil module list is
;; package-spec data, while the heavier source-closure analyzer remains a
;; test/receipt oracle and is not imported by a fresh provider build.
(def +provider-runtime-modules+
  '("src/parser/support.ss"
    "src/parser/model.ss"
    "src/parser/imports.ss"
    "src/parser/formals.ss"
    "src/parser/syntax-support.ss"
    "src/parser/syntax-calls.ss"
    "src/parser/syntax.ss"
    "src/parser/definition-syntax.ss"
    "src/parser/exact-owner.ss"
    "src/parser/control-flow.ss"
    "src/exact-source-projection.ss"
    "src/parser/selectors.ss"
    "src/commands/projection-batch.ss"
    "src/parser/package.ss"
    "src/protocol/command-catalog.ss"
    "src/constants.ss"
    "src/commands/project-resolution.ss"
    "src/runtime/provider-operation.ss"
    "src/runtime/provider-http-json-server.ss"
    "src/commands/provider-runtime.ss"))

;; Ordinary library modules follow the executable target in std/make's build
;; spec.  They are available to integration tests without entering the static
;; provider runtime closure or changing the executable's embedded module set.
(def +provider-library-modules+
  '("src/support/time"))

(asp-gerbil-scheme-package-spec!
 (asp-gerbil-scheme-provider-package-spec
 @ asp-gerbil-scheme-library-package-prototype)
 (role 'provider)
 (profile 'production)
 (entry "src/provider-server")
 (runtime-modules +provider-runtime-modules+)
 (library-modules +provider-library-modules+)
 (native-spec
  (framework-executable-build-spec
   "src/provider-server"
   "asp-gerbil-scheme"
   +provider-runtime-modules+
   +provider-library-modules+
   '(tls))))
