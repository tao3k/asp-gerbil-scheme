#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Real downstream fixture: the default PackageSpec slot is installed, while
;;; this empty BuildSpec measures native projection startup without policy work.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/building-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(asp-gerbil-scheme-package-spec!
 (build-api-startup-fixture @ asp-gerbil-scheme-library-package-prototype)
 (spec build-api-startup-spec)
 (modules '()))

(defbuild-script (build-api-startup-spec))
