;;; -*- Gerbil -*-
;;; Stable package-level API for build.ss and downstream Gerbil packages.
;;; Implementation owners remain under src/; callers import only
;;; :asp-gerbil-scheme/build-api, so repository layout never becomes API.

(import (only-in :clan/testing init-test-environment!)
        "./src/build-api/generated-artifact"
        "./src/build-api/framework"
        "./src/build-api/native-profile"
        "./src/build-api/package-spec"
        "./src/building/facade"
        "./src/building/declarative"
        "./src/testing/extension"
        "./src/testing/performance"
        "./src/policy/gxtest"
        "./src/policy/modularity"
        "./src/benchmark/gate"
        "./src/benchmark/micro-kernel")

(export init-test-environment!
        (import: "./src/build-api/generated-artifact")
        (import: "./src/build-api/framework")
        (import: "./src/build-api/native-profile")
        (import: "./src/build-api/package-spec")
        (import: "./src/building/facade")
        (import: "./src/building/declarative")
        (import: "./src/testing/extension")
        (import: "./src/testing/performance")
        (import: "./src/policy/gxtest")
        (import: "./src/policy/modularity")
        (import: "./src/benchmark/gate")
        (import: "./src/benchmark/micro-kernel"))
