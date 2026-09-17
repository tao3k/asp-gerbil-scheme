#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Native control: clan/building catalogs the package and hands the resulting
;;; BuildSpec to the official defbuild-script/std/make executor.

(import (only-in :std/build-script defbuild-script)
        (only-in :clan/building all-gerbil-modules))

(def +native-build-spec+
  (all-gerbil-modules
   exclude: '("asp-build.ss" "native-build.ss" "run-ab.ss"
              "benchmark.ss" "scenario-contract.ss")))

(when (getenv "GERBIL_BUILD_VERBOSE" #f)
  (displayln "[package-spec-native-ab] lane=native phase=spec-ready target-count="
             (length +native-build-spec+) " executor=std/make")
  (force-output))

(defbuild-script +native-build-spec+)
