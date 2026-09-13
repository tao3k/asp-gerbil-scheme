;;; -*- Gerbil -*-
;;; Stable, latency-bounded package declaration API for downstream build.ss.
;;;
;;; Build scripts must not initialize the optional Building Framework, testing,
;;; Policy, or benchmark graphs merely to project a native PackageSpec.  Those
;;; capabilities have explicit public owners: building-api, testing-api,
;;; policy-api, and benchmark-api.

(import "./src/build-api/package-spec")

(export (import: "./src/build-api/package-spec"))
