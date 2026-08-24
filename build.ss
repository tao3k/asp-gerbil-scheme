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
(def +provider-library-modules+
  '("src/support/time"
    "src/commands/guide"
    "src/commands/query"
    "src/commands/projection"))

(def +provider-runtime-build-spec+
  (framework-executable-build-spec
   "src/provider-server"
   "asp-gerbil-scheme"
   +provider-runtime-modules+
   +provider-library-modules+))

(defbuild-script
 +provider-runtime-build-spec+
 bindir: (framework-build-bindir))
