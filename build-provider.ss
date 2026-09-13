#!/usr/bin/env gerbil
;;; -*- Gerbil -*-

(import (only-in :std/build-script defbuild-script)
        (only-in "./src/build-api/source-bootstrap"
                 asp-gerbil-scheme-package-native-profile
                 asp-gerbil-scheme-package-pkg-config-libs
                 asp-gerbil-scheme-native-profile-prepare!)
        (only-in "./provider-package-spec"
                 asp-gerbil-scheme-provider-package-spec
                 asp-gerbil-scheme-provider-spec))

((asp-gerbil-scheme-native-profile-prepare!
  (asp-gerbil-scheme-package-native-profile
   asp-gerbil-scheme-provider-package-spec))
 (asp-gerbil-scheme-package-pkg-config-libs
  asp-gerbil-scheme-provider-package-spec))

(defbuild-script (asp-gerbil-scheme-provider-spec))
