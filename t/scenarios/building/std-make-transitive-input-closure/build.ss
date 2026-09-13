#!/usr/bin/env gerbil
;;; -*- Gerbil -*-
(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(asp-gerbil-scheme-package-spec!
 (scenario @ asp-gerbil-scheme-library-package-prototype)
 (spec scenario-spec)
 (modules '("a" "b" "c")))

(defbuild-script (scenario-spec))
