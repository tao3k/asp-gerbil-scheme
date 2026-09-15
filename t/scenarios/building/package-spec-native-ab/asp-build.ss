#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Candidate: PackageSpec projects the same one-element native BuildSpec.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(asp-gerbil-scheme-package-spec!
 (package-spec-native-ab @ asp-gerbil-scheme-library-package-prototype)
 (spec package-spec-native-ab-spec)
 (modules '("probe.ss")))

(defbuild-script (package-spec-native-ab-spec))
