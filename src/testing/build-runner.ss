;;; -*- Gerbil -*-
;;; Execution layer for downstream testing-build declarations.

(import :asp-gerbil-scheme/src/testing/build
        :asp-gerbil-scheme/src/testing/framework
        :asp-gerbil-scheme/src/testing/build-support
        (only-in :asp-gerbil-scheme/src/testing/build-runtime
                 testing-build-dry-gxtest-runner
                 testing-build-gxtest-runner))

(export (import: :asp-gerbil-scheme/src/testing/build)
        testing-build-select
        testing-build-main
        testing-build-dry-gxtest-runner
        testing-build-gxtest-runner
        testing-build-compile-selection-support!)

;; : (-> TestingBuild List TestingSelection)
(def (testing-build-select build args)
  (testing-select-project (testing-build-project build) args))

;; : (-> TestingBuild List (OrFalse Procedure) TestingReceipt)
(def (testing-build-main build args (run-files #f))
  (let (selection (testing-build-select build args))
    (testing-build-compile-selection-support! build selection)
    (testing-run-selection
     selection
     (or run-files
         (testing-build-gxtest-runner build)))))
