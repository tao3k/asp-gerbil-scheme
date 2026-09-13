#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Real downstream fixture: PackageSpec projection must not load optional ASP
;;; Policy, testing, benchmark, or Building Framework graphs.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(asp-gerbil-scheme-package-spec!
 (build-api-startup-fixture @ asp-gerbil-scheme-library-package-prototype)
 (spec build-api-startup-spec)
 (modules '()))

(defbuild-script (build-api-startup-spec))
