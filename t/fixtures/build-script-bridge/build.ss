#!/usr/bin/env gxi
(import :asp-gerbil-scheme/src/building/build-script)

(defbuild-script
  []
  profile: 'development
  bindir: (framework-build-bindir))
