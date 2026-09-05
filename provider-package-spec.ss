(export asp-gerbil-scheme-provider-package-spec
        asp-gerbil-scheme-provider-spec)

(import (only-in "./src/build-api/package-spec"
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype)
        (only-in "./src/build-api/builder-profile"
                 asp-gerbil-scheme-production-builder-profile)
        (only-in "./src/building/build-script"
                 framework-executable-build-spec))

;; Build entrypoints must be self-hosting: this native Gerbil module list is
;; package-spec data, while the heavier source-closure analyzer remains a
;; test/receipt oracle and is not imported by a fresh provider build.
(def +provider-runtime-modules+
  '("src/utilities/contract-syntax.ss"
    "src/types/model-syntax.ss"
    "src/utilities/contracts.ss"
    "src/utilities/projection.ss"
    "src/utilities/functional.ss"
    "src/types/model.ss"
    "src/types/subtyping.ss"
    "src/types/validation-union.ss"
    "src/types/validation.ss"
    "src/types/signatures.ss"
    "src/types/findings.ss"
    "src/parser/model.ss"
    "src/parser/selectors.ss"
    "src/types/env.ss"
    "src/types/source-findings.ss"
    "src/types/core.ss"
    "src/types/facade.ss"
    "src/protocol/support.ss"
    "src/parser/support.ss"
    "src/parser/package.ss"
    "src/parser/source-scope.ss"
    "src/parser/source-class.ss"
    "src/support/time.ss"
    "src/parser/typed-contract-token.ss"
    "src/parser/typed-contract-scheme-expression.ss"
    "src/parser/typed-contract-scheme.ss"
    "src/parser/runtime-contract.ss"
    "src/parser/typed-comment-metadata.ss"
    "src/parser/typed-contract-diagnostics.ss"
    "src/parser/typed-contract-comment-index.ss"
    "src/parser/typed-contract.ss"
    "src/parser/imports.ss"
    "src/parser/formals.ss"
    "src/parser/syntax-support.ss"
    "src/parser/syntax-calls.ss"
    "src/parser/syntax.ss"
    "src/parser/quality-shape-loop-driver.ss"
    "src/parser/quality-shape.ss"
    "src/parser/profile.ss"
    "src/parser/poo.ss"
    "src/parser/higher-order.ss"
    "src/parser/function-quality-signals.ss"
    "src/parser/function-quality.ss"
    "src/parser/exports.ss"
    "src/parser/definition-syntax.ss"
    "src/parser/dependency-adapter-quality.ss"
    "src/parser/control-flow.ss"
    "src/parser/comment-quality-classifier.ss"
    "src/parser/comment-quality.ss"
    "src/parser/source-file.ss"
    "src/parser/parse-workers.ss"
    "src/parser/test-source-scope.ss"
    "src/parser/reader.ss"
    "src/parser/core.ss"
    "src/parser/facade.ss"
    "src/protocol/quality-shape-facts.ss"
    "src/protocol/function-quality-facts.ss"
    "src/protocol/structural-facts.ss"
    "src/protocol/command-catalog.ss"
    "src/constants.ss"
    "src/protocol/structural-index.ss"
    "src/protocol/json-output.ss"
    "src/policy/model.ss"
    "src/policy/catalog.ss"
    "src/policy/repair-diagnostic.ss"
    "src/policy/repair-report.ss"
    "src/policy/repair.ss"
    "src/parser/query.ss"
    "src/extensions/poo-source-ref-validation.ss"
    "src/extensions/poo-object-validation.ss"
    "src/package-manager/core.ss"
    "src/package-manager/facade.ss"
    "src/extensions/poo-pattern-support.ss"
    "src/extensions/poo-pattern-typeclass.ss"
    "src/extensions/poo-patterns.ss"
    "src/extensions/poo-validation.ss"
    "src/extensions/poo-inheritance.ss"
    "src/extensions/model.ss"
    "src/extensions/poo.ss"
    "src/extensions/core.ss"
    "src/extensions/facade.ss"
    "src/protocol/json.ss"
    "src/language/evidence.ss"
    "src/language/compare.ss"
    "src/language/capability.ss"
    "src/language/facade.ss"
    "src/runtime/provider-semantic-search.ss"
    "src/parser/exact-owner.ss"
    "src/exact-source-projection.ss"
    "src/commands/projection-batch.ss"
    "src/commands/project-resolution.ss"
    "src/runtime/provider-operation.ss"
    "src/runtime/provider-http-json-server.ss"
    "src/commands/provider-runtime.ss"))

;; Ordinary library modules follow the executable target in std/make's build
;; spec.  They are available to integration tests without entering the static
;; provider runtime closure or changing the executable's embedded module set.
(def +provider-library-modules+
  '("src/support/time"))

(def +provider-source-modules+
  (append +provider-runtime-modules+
          '("src/support/time.ss"
            "src/provider-server.ss")))

(asp-gerbil-scheme-package-spec!
 (asp-gerbil-scheme-provider-package-spec
 @ asp-gerbil-scheme-library-package-prototype)
 (spec asp-gerbil-scheme-provider-spec)
 (modules +provider-source-modules+)
 (role 'provider)
 (profile asp-gerbil-scheme-production-builder-profile)
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
