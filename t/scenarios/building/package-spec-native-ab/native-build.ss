#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Native control: the literal BuildSpec reaches the official defbuild-script.

(import (only-in :std/build-script defbuild-script))

(def +shared-build-spec+ '("probe.ss"))

(when (getenv "GERBIL_BUILD_VERBOSE" #f)
  (displayln "[package-spec-native-ab] lane=native phase=spec-ready target-count=1 executor=std/make")
  (force-output))

(defbuild-script +shared-build-spec+)
