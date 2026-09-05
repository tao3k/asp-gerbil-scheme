#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import :gerbil/gambit
        (only-in "./provider-package-spec"
                 asp-gerbil-scheme-provider-spec)
        (only-in "./src/building/build-script"
                 framework-build-main))

(framework-build-main
 (cddr (command-line))
 (asp-gerbil-scheme-provider-spec)
 '(profile: production)
 "build-provider.ss")
