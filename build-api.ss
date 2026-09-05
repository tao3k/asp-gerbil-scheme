#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Source-bootstrap facade for build.ss.  The installed public facade is
;;; src/package-build-api.ss; both project the same owner modules.

(import "./src/build-api/builder-profile"
        "./src/build-api/package-spec"
        "./src/build-api/profile-build-spec"
        "./src/build-api/source-discovery")

(export (import: "./src/build-api/builder-profile")
        (import: "./src/build-api/package-spec")
        (import: "./src/build-api/profile-build-spec")
        (import: "./src/build-api/source-discovery"))
