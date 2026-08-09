;;; -*- Gerbil -*-
;;; Lightweight package API build surface for downstream dependency installs.

(import (only-in :gerbil/gambit
                 directory-files
                 file-exists?)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 append-map)
        (only-in :std/srfi/13 string-suffix?))

(export gslph-package-api-spec
        gslph-package-api-stage-specs)

;; : (List (List Path))
;;; Package API prologue stages keep native parser, type, and policy
;;; owners materialized before report modules so cold CI cannot build a report
;;; facade without the transitive library graph it imports.
(def +gslph-package-api-prologue-stages+
  '(("build-api/package-build.ss")
    ("build-api/source-coverage.ss"
     "constants.ss")
    ("build-api/package-receipt.ss"
     "build-api/cli-gsc-options.ss"
     "build-api/launcher-receipt.ss"
     "build-api/release-modules.ss"
     "build-api/build-path-contract.ss"
     "build-api/package-spec.ss"
     "support/time.ss")
    ("benchmark/gate.ss")
    ("benchmark/framework.ss")
    ("testing/model.ss")
    ("testing/scope.ss")
    ("testing/scenario.ss"
     "testing/performance.ss"
     "testing/batch.ss")
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

;; Policy stages follow the internal import DAG. A facade must never expand
;; against a concurrently generated model SSI.
;; : (List (List Path))
(def +gslph-package-api-policy-stages+
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

;; : (List (List Path))
(def +gslph-package-api-epilogue-stages+
  '(("testing/build-paths.ss"
     "testing/gxtest-smoke.ss"
     "testing/gxtest-context.ss"
     "testing/gxtest-report.ss")
    ("testing/build-process.ss")
    ("testing/gxtest-syntax.ss")
    ("testing/memory-profile.ss"
     "testing/execution-profile.ss")
    ("testing/gxtest-imports.ss")
    ("testing/gxtest-sources.ss")
    ("testing/gxtest-discovery.ss")
    ("testing/build-support.ss"
     "testing/build.ss")
    ("testing/gxtest-delegate.ss")
    ("testing/gxtest-expression.ss")
    ("testing/gxtest-receipts.ss")
    ("testing/gxtest-policy.ss"
     "testing/gxtest-build.ss")
    ("testing/gxtest-execution.ss")
    ("testing/gxtest-run.ss")
    ("testing/build-runtime.ss")
    ("testing/build-runner.ss")
    ("testing/gxtest-runner.ss")
    ("testing/project-build.ss")
    ("build-api/project-build.ss")
    ("build-api/project-cli.ss")))

;; : (List (List Path))
(def +gslph-package-api-command-prologue-stages+
  '(("support/args.ss"
     "support/io.ss")))

;; : (List String)
(def +gslph-package-api-building-stages+
  '(("testing/building.ss")))

;; Native build interfaces must precede directory-wide parallel compilation.
;; : (List (List Path))
(def +gslph-package-api-build-api-stages+
  '(("build-api/artifact-cleanup.ss"
     "build-api/component-closure.ss")
    ("build-api/native-build.ss")
    ("build-api/framework.ss")))

(def +gslph-package-api-directories+
  '("utilities" "types" "parser" "policy" "protocol" "extensions" "language" "format" "commands"))

;; : (List (List Path))
(def +gslph-package-api-launcher-stages+
  '(("search-light-launcher.ss")
    ("cli-launcher.ss")))

;; : (-> String Boolean)
(def (gslph-ss-file? file)
  (and (string? file)
       (string-suffix? ".ss" file)))

;; : (-> String (List Path))
(def (gslph-package-api-directory-spec dir)
  (let (source-dir (string-append "src/" dir))
    (if (file-exists? source-dir)
      (map (lambda (file) (string-append dir "/" file))
           (sort (filter gslph-ss-file? (directory-files source-dir))
                 string<?))
      [])))

;; : (-> (List (List Path)) (List Path))
(def (gslph-package-api-flatten-stages stages)
  (append-map (lambda (stage) stage) stages))

(def gslph-package-api-stage-specs-cache #f)
(def gslph-package-api-spec-cache #f)

;; : (-> (List (List Path)))
(def (gslph-package-api-stage-specs/fresh)
  (append +gslph-package-api-prologue-stages+
          +gslph-package-api-policy-stages+
          +gslph-package-api-building-stages+
          +gslph-package-api-build-api-stages+
          +gslph-package-api-command-prologue-stages+
          (map gslph-package-api-directory-spec
                +gslph-package-api-directories+)
          +gslph-package-api-launcher-stages+
          +gslph-package-api-epilogue-stages+))

;; : (-> (List (List Path)))
(def (gslph-package-api-stage-specs)
  (or gslph-package-api-stage-specs-cache
      (let (stages (gslph-package-api-stage-specs/fresh))
        (set! gslph-package-api-stage-specs-cache stages)
        stages)))

;; : (-> (List Path))
(def (gslph-package-api-spec)
  (or gslph-package-api-spec-cache
      (let (spec (gslph-package-api-flatten-stages
                  (gslph-package-api-stage-specs)))
        (set! gslph-package-api-spec-cache spec)
        spec)))
