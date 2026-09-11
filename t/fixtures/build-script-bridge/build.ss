#!/usr/bin/env gxi
(import :asp-gerbil-scheme/build-api)

(defbuild-script
  []
  profile: 'development
  bindir: (framework-build-bindir))
