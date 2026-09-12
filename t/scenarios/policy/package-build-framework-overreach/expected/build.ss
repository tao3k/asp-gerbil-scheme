#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import (only-in :std/build-script defbuild-script)
        (only-in :clan/building all-gerbil-modules)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(asp-gerbil-scheme-package-spec!
 (sample-package-spec @ asp-gerbil-scheme-library-package-prototype)
 (spec sample-package-build-spec)
 (modules (all-gerbil-modules)))

(defbuild-script (sample-package-build-spec))
