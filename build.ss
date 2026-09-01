#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(include "src/build-api/source-coverage.ss")
(include "src/building/build-script-body.inc")

(asp-gerbil-scheme-source-coverage
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
    "src/commands/search-prime-light-list"
    "src/commands/search-prime-light"
    "src/search-light-launcher"
    "src/commands/project-resolution"
    "src/runtime/provider-operation"
    "src/runtime/provider-http-json-server"
    "src/commands/provider-runtime"))

;; The package library is built from the Owner's complete Scheme source tree.
;; It remains separate from the resident provider executable closure: downstream
;; packages import these modules normally through gerbil.pkg package identity.
(def +public-library-source-roots+
  '("src"))

(def (provider-source-file->module path)
  (substring path 0 (- (string-length path) 3)))

(def (scheme-source-file? path)
  (let (length (string-length path))
    (and (>= length 3)
         (string=? (substring path (- length 3) length) ".ss"))))

(def +public-library-modules+
  (filter
   (lambda (module)
     (and (not (equal? module "src/provider-server"))
          (not (member module +provider-runtime-modules+))))
   (map provider-source-file->module
        (filter scheme-source-file?
                (asp-gerbil-scheme-source-coverage-files-for-roots
                 "." +public-library-source-roots+)))))

(def +provider-runtime-build-spec+
  (framework-executable-build-spec
   "src/provider-server"
   "asp-gerbil-scheme"
   +provider-runtime-modules+
   +public-library-modules+
   '(tls)))

(defbuild-script
 +provider-runtime-build-spec+
 bindir: (framework-build-bindir))
