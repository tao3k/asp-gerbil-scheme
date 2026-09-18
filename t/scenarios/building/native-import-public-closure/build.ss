#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Downstream fixture for root-only native Import Model projection.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/building-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(asp-gerbil-scheme-package-spec!
 (native-import-public-closure-fixture
  @ asp-gerbil-scheme-library-package-prototype)
 (spec native-import-public-closure-spec)
 (public-entry-modules '("c.ss")))

(defbuild-script (native-import-public-closure-spec))
