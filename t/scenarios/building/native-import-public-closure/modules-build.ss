#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Direct-root control for PackageSpec root-mode A/B.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(asp-gerbil-scheme-package-spec!
 (native-import-direct-root-fixture
  @ asp-gerbil-scheme-library-package-prototype)
 (spec native-import-direct-root-spec)
 (modules '("c.ss")))

(defbuild-script (native-import-direct-root-spec))
