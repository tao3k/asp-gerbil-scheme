;;; -*- Gerbil -*-
;;; Default gxtest smoke suite for the Gerbil language harness.

(import (only-in "./model" gxtest-suite))

(export asp-gerbil-scheme-default-gxtest-smoke-suite
        asp-gerbil-scheme-default-gxtest-smoke-files)

(def +asp-gerbil-scheme-default-gxtest-smoke-files+
  '("t/agent-poo-scenario-contract-test.ss"
    "t/build-install-test.ss"
    "t/source-closure-test.ss"
    "t/poo-object-validation-test.ss"
    "t/parser-memory-stability-test.ss"
    "t/support-test.ss"
    "t/testing-memory-profile-test.ss"
    "t/testing-framework-smoke-test.ss"))

(def (asp-gerbil-scheme-default-gxtest-smoke-files)
  +asp-gerbil-scheme-default-gxtest-smoke-files+)

(def (asp-gerbil-scheme-default-gxtest-smoke-suite)
  (gxtest-suite
   name: "default-smoke"
   roots: ["t"]
   files: +asp-gerbil-scheme-default-gxtest-smoke-files+
   batch-size: 1
   max-selected-files: 6
   max-selected-sources: 15
   max-selected-outputs: 15))
