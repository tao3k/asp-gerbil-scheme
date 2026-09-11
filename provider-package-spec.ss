(export asp-gerbil-scheme-provider-package-spec
        asp-gerbil-scheme-provider-spec)

(import (only-in "./src/build-api/package-spec"
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype)
        (only-in :std/make cppflags ldflags))

;; Build entrypoints must be self-hosting: this native Gerbil module list is
;; package-spec data, while the heavier source-closure analyzer remains a
;; test/receipt oracle and is not imported by a fresh provider build.
(def +provider-runtime-modules+
  '("src/utilities/functional.ss"
    "src/parser/model.ss"
    "src/parser/selectors.ss"
    "src/parser/support.ss"
    "src/parser/package.ss"
    "src/parser/imports.ss"
    "src/parser/formals.ss"
    "src/parser/syntax-ast.ss"
    "src/parser/syntax-macro-family.ss"
    "src/parser/syntax-support.ss"
    "src/parser/syntax-calls.ss"
    "src/parser/syntax.ss"
    "src/parser/definition-syntax.ss"
    "src/parser/control-flow.ss"
    "src/constants.ss"
    "src/parser/exact-owner.ss"
    "src/exact-source-projection.ss"
    "src/commands/projection-batch.ss"
    "src/commands/project-resolution.ss"
    "src/object-family/syntax.ss"
    "src/runtime/provider/types.ss"
    "src/runtime/provider/objects.ss"
    "src/runtime/provider/interface.ss"
    "src/runtime/provider-operation.ss"
    "src/runtime/provider-http-json-server.ss"
    "src/commands/provider-runtime.ss"))

;; Every provider dependency is owned exactly once by the sibling native AOT
;; runtime closure. Re-declaring a runtime module after the executable gives
;; std/make two completion owners for the same normalized module identity.
(def +provider-library-modules+ '())

(def +provider-source-modules+
  (append +provider-runtime-modules+
          '("src/provider-server.ss")))

(asp-gerbil-scheme-package-spec!
 (asp-gerbil-scheme-provider-package-spec
 @ asp-gerbil-scheme-library-package-prototype)
 (spec asp-gerbil-scheme-provider-spec)
 (modules +provider-source-modules+)
 (role 'provider)
 (entry "src/provider-server")
 (runtime-modules +provider-runtime-modules+)
 (library-modules +provider-library-modules+)
 (native-spec
  (append
   (map (lambda (module) `(gxc: ,module)) +provider-runtime-modules+)
   `((exe: "src/provider-server"
           bin: "asp-gerbil-scheme"
           "-cc-options" ,(string-append (cppflags "openssl" "")
                                          " -include openssl/kdf.h")
           "-ld-options" ,(ldflags "openssl" "-lssl -lcrypto")))
   +provider-library-modules+)))
