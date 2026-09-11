;;; -*- Gerbil -*-
;;; Stable package-level API for build.ss and downstream Gerbil packages.
;;; Implementation owners remain under src/; callers import only
;;; :asp-gerbil-scheme/build-api, so repository layout never becomes API.

(import "./src/build-api/generated-artifact"
        "./src/build-api/framework"
        "./src/build-api/package-spec"
        "./src/build-api/source-closure"
        "./src/build-api/source-coverage"
        "./src/building/facade"
        "./src/building/declarative"
        "./src/testing/build-runner"
        "./src/testing/build"
        "./src/testing/building"
        "./src/testing/framework"
        "./src/testing/memory-profile"
        "./src/testing/model"
        "./src/testing/performance"
        "./src/policy/gxtest"
        "./src/policy/modularity"
        "./src/benchmark/gate")

(export (import: "./src/build-api/generated-artifact")
        (import: "./src/build-api/framework")
        (import: "./src/build-api/package-spec")
        (import: "./src/build-api/source-closure")
        (import: "./src/build-api/source-coverage")
        (import: "./src/building/facade")
        (import: "./src/building/declarative")
        (import: "./src/testing/build-runner")
        (import: "./src/testing/build")
        (import: "./src/testing/building")
        (import: "./src/testing/framework")
        (import: "./src/testing/memory-profile")
        (import: "./src/testing/model")
        (import: "./src/testing/performance")
        (import: "./src/policy/gxtest")
        (import: "./src/policy/modularity")
        (import: "./src/benchmark/gate"))
