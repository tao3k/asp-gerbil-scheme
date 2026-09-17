#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Candidate: PackageSpec projects only the declared product closure, then
;;; hands that ordinary BuildSpec to the same defbuild-script/std/make executor.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(asp-gerbil-scheme-package-spec!
 (package-spec-native-ab @ asp-gerbil-scheme-library-package-prototype)
 (spec package-spec-native-ab-spec)
 (public-entry-modules '("probe.ss")))

(defbuild-script (package-spec-native-ab-spec))
