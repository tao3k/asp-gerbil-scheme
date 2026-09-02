(import (only-in "./src/building/build-script"
                 defbuild-script
                 framework-build-bindir)
        (only-in "./src/build-api/package-spec"
                 asp-gerbil-scheme-package-build-profile
                 asp-gerbil-scheme-package-native-spec)
        (only-in "./provider-package-spec"
                 asp-gerbil-scheme-provider-package-spec))

(defbuild-script
 (asp-gerbil-scheme-package-native-spec
  asp-gerbil-scheme-provider-package-spec)
 profile: (asp-gerbil-scheme-package-build-profile
           asp-gerbil-scheme-provider-package-spec)
 bindir: (framework-build-bindir))
