;;; -*- Gerbil -*-
;;; Policy snapshot projection facade.

(import :std/test
        :asp-gerbil-scheme/src/snapshot/facade
        (rename-in :unit/snapshot/policy-poo
          (downstream-poo-agent-policy-snapshot policy-poo-downstream-poo-agent-policy-snapshot)
          (poo-prototype-fixed-point-policy-snapshot policy-poo-poo-prototype-fixed-point-policy-snapshot)
          (poo-guidance-corpus-policy-snapshot policy-poo-poo-guidance-corpus-policy-snapshot))
        (rename-in :unit/snapshot/policy-flow
          (functional-idiom-policy-snapshot policy-flow-functional-idiom-policy-snapshot)
          (real-agent-basic-syntax-policy-snapshot policy-flow-real-agent-basic-syntax-policy-snapshot)
          (controlled-branch-shape-policy-snapshot policy-flow-controlled-branch-shape-policy-snapshot)
          (controlled-branch-conditional-dispatch-policy-snapshot policy-flow-controlled-branch-conditional-dispatch-policy-snapshot))
        (rename-in :unit/snapshot/policy-typed
          (typed-combinator-style-policy-snapshot policy-typed-typed-combinator-style-policy-snapshot)
          (case-lambda-function-factory-policy-snapshot policy-typed-case-lambda-function-factory-policy-snapshot)
          (generator-combinator-policy-snapshot policy-typed-generator-combinator-policy-snapshot)
          (controlled-macro-syntax-policy-snapshot policy-typed-controlled-macro-syntax-policy-snapshot)
          (typeclass-algebra-policy-snapshot policy-typed-typeclass-algebra-policy-snapshot)
          (destructuring-combinator-boundary-policy-snapshot policy-typed-destructuring-combinator-boundary-policy-snapshot))
        (rename-in :unit/snapshot/policy-comment-dependency
          (comment-quality-policy-snapshot policy-comment-dependency-comment-quality-policy-snapshot)
          (harness-dependency-policy-application-policy-snapshot policy-comment-dependency-harness-dependency-policy-application-policy-snapshot)
          (harness-dependency-policy-disable-requires-explanation-policy-snapshot policy-comment-dependency-harness-dependency-policy-disable-requires-explanation-policy-snapshot))
        (rename-in :unit/snapshot/policy-build
          (macro-controlled-helper-policy-snapshot policy-build-macro-controlled-helper-policy-snapshot)
          (predicate-family-combinator-policy-snapshot policy-build-predicate-family-combinator-policy-snapshot)
          (build-runtime-shell-template-policy-snapshot policy-build-build-runtime-shell-template-policy-snapshot)
          (package-build-shell-pipeline-policy-snapshot policy-build-package-build-shell-pipeline-policy-snapshot)
          (package-build-canonical-shape-policy-snapshot policy-build-package-build-canonical-shape-policy-snapshot)
          (package-build-std-build-script-policy-snapshot policy-build-package-build-std-build-script-policy-snapshot)
          (package-build-std-make-ssi-policy-snapshot policy-build-package-build-std-make-ssi-policy-snapshot)
          (dependency-manual-object-adapter-policy-snapshot policy-build-dependency-manual-object-adapter-policy-snapshot)
          (dependency-protocol-adapter-policy-snapshot policy-build-dependency-protocol-adapter-policy-snapshot)))

(export downstream-poo-agent-policy-snapshot
        poo-prototype-fixed-point-policy-snapshot
        poo-guidance-corpus-policy-snapshot
        functional-idiom-policy-snapshot
        real-agent-basic-syntax-policy-snapshot
        controlled-branch-shape-policy-snapshot
        controlled-branch-conditional-dispatch-policy-snapshot
        typed-combinator-style-policy-snapshot
        case-lambda-function-factory-policy-snapshot
        generator-combinator-policy-snapshot
        controlled-macro-syntax-policy-snapshot
        typeclass-algebra-policy-snapshot
        destructuring-combinator-boundary-policy-snapshot
        comment-quality-policy-snapshot
        harness-dependency-policy-application-policy-snapshot
        harness-dependency-policy-disable-requires-explanation-policy-snapshot
        macro-controlled-helper-policy-snapshot
        predicate-family-combinator-policy-snapshot
        build-runtime-shell-template-policy-snapshot
        package-build-shell-pipeline-policy-snapshot
        package-build-canonical-shape-policy-snapshot
        package-build-std-build-script-policy-snapshot
        package-build-std-make-ssi-policy-snapshot
        dependency-manual-object-adapter-policy-snapshot
        dependency-protocol-adapter-policy-snapshot
        check-policy-snapshot-fixtures)

;; Snapshot
(def (downstream-poo-agent-policy-snapshot)
  (policy-poo-downstream-poo-agent-policy-snapshot))

;; Snapshot
(def (poo-prototype-fixed-point-policy-snapshot)
  (policy-poo-poo-prototype-fixed-point-policy-snapshot))

;; Snapshot
(def (poo-guidance-corpus-policy-snapshot)
  (policy-poo-poo-guidance-corpus-policy-snapshot))

;; Snapshot
(def (functional-idiom-policy-snapshot)
  (policy-flow-functional-idiom-policy-snapshot))

;; Snapshot
(def (real-agent-basic-syntax-policy-snapshot)
  (policy-flow-real-agent-basic-syntax-policy-snapshot))

;; Snapshot
(def (controlled-branch-shape-policy-snapshot)
  (policy-flow-controlled-branch-shape-policy-snapshot))

;; Snapshot
(def (controlled-branch-conditional-dispatch-policy-snapshot)
  (policy-flow-controlled-branch-conditional-dispatch-policy-snapshot))

;; Snapshot
(def (typed-combinator-style-policy-snapshot)
  (policy-typed-typed-combinator-style-policy-snapshot))

;; Snapshot
(def (case-lambda-function-factory-policy-snapshot)
  (policy-typed-case-lambda-function-factory-policy-snapshot))

;; Snapshot
(def (generator-combinator-policy-snapshot)
  (policy-typed-generator-combinator-policy-snapshot))

;; Snapshot
(def (controlled-macro-syntax-policy-snapshot)
  (policy-typed-controlled-macro-syntax-policy-snapshot))

;; Snapshot
(def (typeclass-algebra-policy-snapshot)
  (policy-typed-typeclass-algebra-policy-snapshot))

;; Snapshot
(def (destructuring-combinator-boundary-policy-snapshot)
  (policy-typed-destructuring-combinator-boundary-policy-snapshot))

;; Snapshot
(def (comment-quality-policy-snapshot)
  (policy-comment-dependency-comment-quality-policy-snapshot))

;; Snapshot
(def (harness-dependency-policy-application-policy-snapshot)
  (policy-comment-dependency-harness-dependency-policy-application-policy-snapshot))

;; Snapshot
(def (harness-dependency-policy-disable-requires-explanation-policy-snapshot)
  (policy-comment-dependency-harness-dependency-policy-disable-requires-explanation-policy-snapshot))

;; Snapshot
(def (macro-controlled-helper-policy-snapshot)
  (policy-build-macro-controlled-helper-policy-snapshot))

;; Snapshot
(def (predicate-family-combinator-policy-snapshot)
  (policy-build-predicate-family-combinator-policy-snapshot))

;; Snapshot
(def (build-runtime-shell-template-policy-snapshot)
  (policy-build-build-runtime-shell-template-policy-snapshot))

;; Snapshot
(def (package-build-shell-pipeline-policy-snapshot)
  (policy-build-package-build-shell-pipeline-policy-snapshot))

;; Snapshot
(def (package-build-canonical-shape-policy-snapshot)
  (policy-build-package-build-canonical-shape-policy-snapshot))

;; Snapshot
(def (package-build-std-build-script-policy-snapshot)
  (policy-build-package-build-std-build-script-policy-snapshot))

;; Snapshot
(def (package-build-std-make-ssi-policy-snapshot)
  (policy-build-package-build-std-make-ssi-policy-snapshot))

;; Snapshot
(def (dependency-manual-object-adapter-policy-snapshot)
  (policy-build-dependency-manual-object-adapter-policy-snapshot))

;; Snapshot
(def (dependency-protocol-adapter-policy-snapshot)
  (policy-build-dependency-protocol-adapter-policy-snapshot))

;; Snapshot
(def (check-policy-snapshot-fixtures)
  (check (downstream-poo-agent-policy-snapshot)
         => (snapshot-load "t/snapshots/policy-downstream-poo-agent.ss"))
  (check (functional-idiom-policy-snapshot)
         => (snapshot-load "t/snapshots/policy-functional-idiom.ss"))
  (check (real-agent-basic-syntax-policy-snapshot)
         => (snapshot-load "t/snapshots/policy-real-agent-basic-syntax.ss"))
  (check (controlled-branch-shape-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-controlled-branch-shape.ss"))
  (check (controlled-branch-conditional-dispatch-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-controlled-branch-conditional-dispatch.ss"))
  (check (typed-combinator-style-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-typed-combinator-style.ss"))
  (check (destructuring-combinator-boundary-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-destructuring-combinator-boundary.ss"))
  (check (case-lambda-function-factory-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-case-lambda-function-factory.ss"))
  (check (generator-combinator-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-generator-combinator.ss"))
  (check (controlled-macro-syntax-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-controlled-macro-syntax.ss"))
  (check (typeclass-algebra-policy-snapshot)
         => (snapshot-load "t/snapshots/policy-typeclass-algebra.ss"))
  (check (comment-quality-policy-snapshot)
         => (snapshot-load "t/snapshots/policy-comment-quality.ss"))
  (check (harness-dependency-policy-application-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-harness-dependency-policy-application.ss"))
  (check (harness-dependency-policy-disable-requires-explanation-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-harness-dependency-policy-disable-requires-explanation.ss"))
  (check (macro-controlled-helper-policy-snapshot)
         => (snapshot-load "t/snapshots/policy-macro-controlled-helper.ss"))
  (check (predicate-family-combinator-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-predicate-family-combinator.ss"))
  (check (build-runtime-shell-template-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-build-runtime-shell-template.ss"))
  (check (package-build-shell-pipeline-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-package-build-shell-pipeline.ss"))
  (check (package-build-canonical-shape-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-package-build-canonical-shape.ss"))
  (check (package-build-std-build-script-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-package-build-std-build-script.ss"))
  (check (package-build-std-make-ssi-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-package-build-std-make-ssi.ss"))
  (check (poo-prototype-fixed-point-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-poo-prototype-fixed-point.ss"))
  (check (poo-guidance-corpus-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-poo-guidance-corpus.ss"))
  (check (dependency-manual-object-adapter-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-dependency-manual-object-adapter.ss"))
  (check (dependency-protocol-adapter-policy-snapshot)
         => (snapshot-load
             "t/snapshots/policy-dependency-protocol-adapter.ss")))
