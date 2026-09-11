;;; -*- Gerbil -*-
;;; Internal source bootstrap for this package's root build entrypoints.
;;; Downstream packages continue to import only :asp-gerbil-scheme/build-api;
;;; this narrow projection prevents a cold build from loading the ASP product,
;;; Testing, Policy, or benchmark graph before std/make owns compilation.

(import (only-in "./builder-profile"
                 asp-gerbil-scheme-development-builder-profile)
        (only-in "./package-spec"
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype)
        (only-in "../building/build-script"
                 defbuild-script))

(export asp-gerbil-scheme-development-builder-profile
        asp-gerbil-scheme-package-spec!
        asp-gerbil-scheme-library-package-prototype
        defbuild-script)
