#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import (only-in "./src/building/build-script"
                 defbuild-script
                 framework-build-bindir)
        (only-in "./src/build-api/package-spec"
                 asp-gerbil-scheme-package-build-profile)
        (only-in "./provider-package-spec"
                 asp-gerbil-scheme-provider-package-spec
                 asp-gerbil-scheme-provider-spec))

(defbuild-script
 (asp-gerbil-scheme-provider-spec)
 profile: (asp-gerbil-scheme-package-build-profile
           asp-gerbil-scheme-provider-package-spec)
 bindir: (framework-build-bindir))
