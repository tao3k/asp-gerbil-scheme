#!/usr/bin/env gxi
(import :asp-gerbil-scheme/src/building/build-script)

(defbuild-script
  (framework-executable-build-spec
   "main"
   "downstream-build-script-probe"
   '("support.ss"))
  bindir: (framework-build-bindir))
