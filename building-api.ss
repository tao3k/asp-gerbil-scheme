;;; -*- Gerbil -*-
;;; Public ASP Building API.
;;;
;;; PackageSpec supplies declarative build data and NativeProfile POO slots;
;;; std/make remains the only graph, currentness, scheduling, and execution
;;; owner. Its default PackageSpec slot admits policy on BuildSpec-selected
;;; sources before handing the same native spec to std/make.

(import "./src/build-api/native-profile"
        "./src/build-api/package-spec")

(export (import: "./src/build-api/native-profile")
        (import: "./src/build-api/package-spec"))
