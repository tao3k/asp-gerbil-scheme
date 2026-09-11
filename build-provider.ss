#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import (only-in :std/build-script defbuild-script)
        (only-in "./provider-package-spec"
                 asp-gerbil-scheme-provider-spec))

(defbuild-script
 (asp-gerbil-scheme-provider-spec))
