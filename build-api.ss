#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Source-bootstrap facade for build.ss.  The installed public facade is
;;; src/build-api.ss; both project the same owner modules.

(import "./src/build-api/package-spec"
        "./src/build-api/source-discovery"
        "./src/building/build-script")

(export (import: "./src/build-api/package-spec")
        (import: "./src/build-api/source-discovery")
        (import: "./src/building/build-script"))
