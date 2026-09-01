(import :std/build-script
        (only-in "./src/building/build-script"
                 framework-build-bindir)
        (only-in "./src/building/package-spec"
                 asp-gerbil-scheme-package-native-spec)
        (only-in "./src/building/provider-package-spec"
                 asp-gerbil-scheme-provider-package-spec))

(defbuild-script
 (asp-gerbil-scheme-package-native-spec
  asp-gerbil-scheme-provider-package-spec)
 bindir: (framework-build-bindir))
