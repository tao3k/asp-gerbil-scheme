#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/building-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(asp-gerbil-scheme-package-spec!
 (sample-package-spec @ asp-gerbil-scheme-library-package-prototype)
 (spec sample-package-build-spec)
 (modules '("src/main.ss")))

(defbuild-script (sample-package-build-spec))
