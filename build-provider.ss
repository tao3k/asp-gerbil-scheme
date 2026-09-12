#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import (only-in :clan/building init-build-environment!)
        (only-in "./src/build-api/source-bootstrap"
                 asp-gerbil-scheme-package-native-profile
                 asp-gerbil-scheme-package-pkg-config-libs
                 asp-gerbil-scheme-package-nix-deps
                 asp-gerbil-scheme-native-profile-prepare!)
        (only-in "./provider-package-spec"
                 asp-gerbil-scheme-provider-package-spec
                 asp-gerbil-scheme-provider-spec))

((asp-gerbil-scheme-native-profile-prepare!
  (asp-gerbil-scheme-package-native-profile
   asp-gerbil-scheme-provider-package-spec))
 (asp-gerbil-scheme-package-pkg-config-libs
  asp-gerbil-scheme-provider-package-spec))

(init-build-environment!
 name: "asp-gerbil-scheme-provider"
 deps: '("clan" "clan/poo")
 spec: asp-gerbil-scheme-provider-spec
 pkg-config-libs:
 (asp-gerbil-scheme-package-pkg-config-libs
  asp-gerbil-scheme-provider-package-spec)
 nix-deps:
 (asp-gerbil-scheme-package-nix-deps
  asp-gerbil-scheme-provider-package-spec))
