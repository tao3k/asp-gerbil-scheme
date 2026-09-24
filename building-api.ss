;;; -*- Gerbil -*-
;;; Public ASP Building API.
;;;
;;; PackageSpec supplies declarative build data and NativeProfile POO slots;
;;; std/make remains the only graph, currentness, scheduling, and execution
;;; owner. Optional extension modules are not part of this package-build
;;; startup closure.

(import "./src/build-api/native-profile"
        "./src/build-api/package-spec")

(export (import: "./src/build-api/native-profile")
        (import: "./src/build-api/package-spec"))
