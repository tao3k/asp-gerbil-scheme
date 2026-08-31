#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(include "src/build-api/source-coverage.ss")
(include "src/building/build-script-body.inc")

(gslph-source-coverage
 roots: ["src"]
 runtime-roots: ["src"])

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
    "src/commands/project-resolution"
    "src/runtime/provider-operation"
    "src/runtime/provider-http-json-server"
    "src/commands/provider-runtime"))

;; Package modules required by provider contract and acceptance tests are built
;; after the executable target. They share the same std/make graph without
;; becoming part of the resident executable closure.
(def +provider-library-source-roots+
  '("src/parser" "src/types" "src/utilities"))

(def (provider-source-file->module path)
  (substring path 0 (- (string-length path) 3)))

(def +provider-library-modules+
  (filter
   (lambda (module) (not (member module +provider-runtime-modules+)))
   (append
    '("src/support/time"
      "src/support/args"
      "src/protocol/json-output"
      "src/testing/gxtest-context"
      "src/testing/gxtest-syntax"
      "src/testing/execution-profile")
    (map provider-source-file->module
         (gslph-source-coverage-files-for-roots
          "." +provider-library-source-roots+))
    '("src/commands/query"
      "src/commands/projection"))))

;; The resident HTTP runtime pulls in Gerbil's TLS bindings.  Release builds
;; link a static executable, so retain the transitive OpenSSL closure here
;; instead of relying on a dynamically loaded host library.  Keep the native
;; libraries platform-owned, following the Standard Library's OS split.
(def +provider-native-link-modules+
  (cond-expand
    (darwin
     '((gxc: ":std/net/ssl/libssl"
             "-ld-options" "-lssl"
             "-ld-options" "-lcrypto")))
    (linux
     '((gxc: ":std/net/ssl/libssl"
             "-ld-options" "-lssl"
             "-ld-options" "-lcrypto")))
    (else
     (error "unsupported native TLS linker platform"))))

(def +provider-runtime-build-spec+
  (append
   +provider-runtime-modules+
   +provider-native-link-modules+
   `((exe: "src/provider-server" bin: "asp-gerbil-scheme"))
   +provider-library-modules+))

(defbuild-script
 +provider-runtime-build-spec+
 bindir: (framework-build-bindir))
