;;; -*- Gerbil -*-
;;; ASP product-native compilation plan.
;;; This owner is intentionally outside the downstream Package Spec facade:
;;; downstream projects load only the declarative Build API, while ASP's own
;;; CLI/provider/test product may consume this complete native plan.

(import (only-in "./source-coverage"
                 asp-gerbil-scheme-source-coverage-declared-files)
        (only-in :std/srfi/1 append-map find fold)
        (only-in :std/srfi/13 string-prefix? string-suffix?))

(export asp-gerbil-scheme-package-api-spec
        asp-gerbil-scheme-package-api-stage-specs)

;; Cold package builds retain an explicit stage order for owners whose imports
;; cannot safely be widened into one directory-parallel batch.
(def +package-api-prologue-stages+
  '(("build-api/package-build.ss")
    ("build-api/source-coverage-query.ss"
     "build-api/source-coverage.ss"
     "build-api/source-discovery.ss"
     "constants.ss")
    ("build-api/package-receipt.ss"
     "build-api/cli-gsc-options.ss"
     "build-api/launcher-receipt.ss"
     "build-api/release-modules.ss"
     "build-api/build-path-contract.ss"
     "build-api/builder-profile.ss"
     "support/time.ss")
    ("build-api/package-spec.ss"
     "build-api/package-native-plan.ss")
    ("benchmark/gate.ss")
    ("benchmark/framework.ss")
    ("testing/model.ss")
    ("testing/scope.ss")
    ("testing/scenario.ss" "testing/performance.ss" "testing/batch.ss")
    ("testing/selection.ss")
    ("utilities/functional.ss")
    ("utilities/contracts.ss")
    ("utilities/projection.ss")
    ("utilities/contract-syntax.ss")
    ("types/core.ss"
     "types/env.ss"
     "types/findings.ss"
     "types/source-findings.ss"
     "types/model.ss"
     "types/signatures.ss"
     "types/subtyping.ss"
     "types/validation.ss"
     "types/facade.ss"
     "parser/model.ss"
     "parser/support.ss"
     "parser/formals.ss"
     "parser/syntax-support.ss"
     "parser/definition-syntax.ss"
     "parser/exact-owner.ss"
     "parser/syntax-calls.ss"
     "parser/imports.ss"
     "parser/syntax.ss"
     "parser/comment-quality-classifier.ss"
     "parser/comment-quality.ss"
     "parser/control-flow.ss"
     "parser/dependency-adapter-quality.ss"
     "parser/exports.ss"
     "parser/higher-order.ss"
     "parser/function-quality.ss"
     "parser/package.ss"
     "parser/profile.ss"
     "parser/quality-shape.ss"
     "parser/selectors.ss"
     "parser/source-scope.ss"
     "parser/source-class.ss"
     "parser/source-file.ss"
     "parser/test-source-scope.ss"
     "parser/typed-contract-token.ss"
     "parser/typed-contract-scheme.ss"
     "parser/runtime-contract.ss"
     "parser/typed-comment-metadata.ss"
     "parser/typed-contract-diagnostics.ss"
     "parser/typed-contract.ss"
     "parser/poo.ss"
     "parser/parse-workers.ss"
     "parser/core.ss"
     "parser/facade.ss"
     "extensions/poo-pattern-support.ss"
     "extensions/poo-pattern-typeclass.ss"
     "extensions/poo-patterns.ss")
    ("exact-source-projection.ss")
    ("testing/commands.ss")
    ("testing/framework.ss")))

(def +package-api-policy-stages+
  '(("policy/model.ss"
     "policy/agent-support.ss"
     "policy/agent-import.ss"
     "policy/agent-style-steering.ss"
     "policy/agent-style-gerbil-signal-support.ss"
     "policy/agent-style-destructuring-signals.ss"
     "policy/agent-style-performance-signals.ss"
     "policy/agent-style-message.ss"
     "policy/prototype.ss"
     "policy/agent-poo-callees.ss")
    ("policy/agent-alist-access.ss"
     "policy/agent-anonymous-pair.ss"
     "policy/agent-comment.ss"
     "policy/dependency-adapter-profile.ss"
     "policy/agent-list-growth.ss"
     "policy/agent-list-random-access.ss"
     "policy/agent-macro-io.ss"
     "policy/agent-source-scope.ss"
     "policy/agent-string-growth.ss"
     "policy/agent-style-gerbil-boundary-signals.ss"
     "policy/agent-style-gerbil-macro-signals.ss"
     "policy/agent-style-docs.ss"
     "policy/detection.ss"
     "policy/agent-poo-object-literal.ss"
     "policy/agent-build.ss"
     "policy/modularity.ss"
     "policy/catalog.ss")
    ("policy/poo-source.ss"
     "policy/agent-dependency-adapter.ss"
     "policy/agent-style-gerbil-signals.ss"
     "policy/gerbil-utils-source.ss"
     "policy/agent-poo-loop-performance.ss"
     "policy/repair.ss")
    ("policy/agent-package-build-system.ss"
     "policy/agent-style-shape.ss"
     "policy/agent-style-quality.ss"
     "policy/agent-style-details.ss"
     "policy/agent-macro-protocol.ss"
     "policy/agent-poo.ss")
    ("policy/agent-basic.ss"
     "policy/agent-build-runtime.ss"
     "policy/agent-style.ss")
    ("policy/agent.ss")
    ("policy/core.ss")
    ("policy/facade.ss")
    ("policy/gxtest-report.ss")))

(def +package-api-epilogue-stages+
  '(("testing/build-paths.ss"
     "testing/gxtest-smoke.ss"
     "testing/gxtest-context.ss"
     "testing/gxtest-report.ss")
    ("testing/build-process.ss")
    ("testing/gxtest-syntax.ss")
    ("testing/memory-profile.ss" "testing/execution-profile.ss")
    ("testing/gxtest-imports.ss")
    ("testing/gxtest-sources.ss")
    ("testing/gxtest-discovery.ss")
    ("testing/build-support.ss" "testing/build.ss")
    ("testing/gxtest-delegate.ss")
    ("testing/gxtest-expression.ss")
    ("testing/gxtest-receipts.ss")
    ("testing/gxtest-policy.ss" "testing/gxtest-build.ss")
    ("testing/gxtest-execution.ss")
    ("testing/gxtest-run.ss")
    ("testing/build-runtime.ss")
    ("testing/build-runner.ss")
    ("testing/gxtest-runner.ss")
    ("testing/project-build.ss")
    ("build-api/project-build.ss")
    ("build-api/project-cli.ss")))

(def +package-api-command-prologue-stages+
  '(("support/args.ss" "support/io.ss")))

(def +package-api-building-stages+
  '(("building/model.ss"
     "building/native-toolchain.ss"
     "building/memory-anomaly-guard.ss")
    ("building/build-script.ss")
    ("building/std-builder.ss")
    ("building/observability.ss")
    ("building/facade.ss")
    ("building/declarative.ss" "building/commands.ss")
    ("testing/building.ss")))

(def +package-api-build-api-stages+
  '(("build-api/artifact-cleanup.ss" "build-api/source-closure.ss")
    ("build-api/native-build.ss")
    ("build-api/profile-build-spec.ss")
    ("build-api/framework.ss")))

(def +package-api-directories+
  '("utilities" "types" "parser" "policy" "protocol" "extensions"
    "language" "format" "commands"))

(def +package-api-launcher-stages+
  '(("cli-launcher.ss")))

(def (ss-file? file)
  (and (string? file) (string-suffix? ".ss" file)))

(def (package-api-source-directory path)
  (and (ss-file? path)
       (find (lambda (dir)
               (string-prefix? (string-append "src/" dir "/") path))
             +package-api-directories+)))

(def (package-api-empty-directory-buckets)
  (map list +package-api-directories+))

(def (package-api-add-directory-source path buckets)
  (let (directory (package-api-source-directory path))
    (if directory
      (map (lambda (bucket)
             (if (string=? (car bucket) directory)
               (cons directory
                     (cons (substring path 4 (string-length path))
                           (cdr bucket)))
               bucket))
           buckets)
      buckets)))

(def (package-api-directory-specs)
  (let* ((source-files
          (or (asp-gerbil-scheme-source-coverage-declared-files)
              (error "package API requires the Build API module catalog")))
         (buckets
          (fold package-api-add-directory-source
                (package-api-empty-directory-buckets)
                source-files)))
    (map (lambda (bucket) (reverse (cdr bucket))) buckets)))

(def (flatten-stages stages)
  (append-map (lambda (stage) stage) stages))

(def package-api-stage-specs-cache #f)
(def package-api-spec-cache #f)

(def (package-api-stage-specs/fresh)
  (append +package-api-prologue-stages+
          +package-api-policy-stages+
          +package-api-building-stages+
          +package-api-build-api-stages+
          +package-api-command-prologue-stages+
          (package-api-directory-specs)
          +package-api-launcher-stages+
          +package-api-epilogue-stages+))

(def (asp-gerbil-scheme-package-api-stage-specs)
  (or package-api-stage-specs-cache
      (let (stages (package-api-stage-specs/fresh))
        (set! package-api-stage-specs-cache stages)
        stages)))

(def (asp-gerbil-scheme-package-api-spec)
  (or package-api-spec-cache
      (let (spec (flatten-stages
                  (asp-gerbil-scheme-package-api-stage-specs)))
        (set! package-api-spec-cache spec)
        spec)))
