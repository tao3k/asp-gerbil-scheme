;;; -*- Gerbil -*-
;;; Internal source bootstrap for this package's root build entrypoints.
;;; The public :asp-gerbil-scheme/build-api facade has the same narrow closure;
;;; this source-relative owner additionally bootstraps this package's own cold
;;; build before the public facade has been compiled.

(import (only-in "./package-spec"
                 asp-gerbil-scheme-package-spec!
                 all-gerbil-modules
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-package-modules
                 asp-gerbil-scheme-package-native-profile
                 asp-gerbil-scheme-package-pkg-config-libs
                 asp-gerbil-scheme-package-nix-deps)
        (only-in "./native-profile"
                 asp-gerbil-scheme-native-profile-prepare!))

(export asp-gerbil-scheme-package-spec!
        all-gerbil-modules
        asp-gerbil-scheme-library-package-prototype
        asp-gerbil-scheme-package-modules
        asp-gerbil-scheme-package-native-profile
        asp-gerbil-scheme-package-pkg-config-libs
        asp-gerbil-scheme-package-nix-deps
        asp-gerbil-scheme-native-profile-prepare!)
