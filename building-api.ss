;;; -*- Gerbil -*-
;;; Optional public Building Framework API. Package declarations that only need
;;; PackageSpec should import :asp-gerbil-scheme/build-api instead.

(import "./src/build-api/generated-artifact"
        "./src/build-api/framework"
        "./src/build-api/native-profile"
        "./src/build-api/package-spec"
        "./src/building/facade"
        "./src/building/declarative")

(export (import: "./src/build-api/generated-artifact")
        (import: "./src/build-api/framework")
        (import: "./src/build-api/native-profile")
        (import: "./src/build-api/package-spec")
        (import: "./src/building/facade")
        (import: "./src/building/declarative"))
