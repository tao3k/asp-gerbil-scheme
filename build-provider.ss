#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import (only-in :std/build-script defbuild-script)
        (only-in :std/misc/path path-expand)
        (only-in :std/source this-source-file)
        (only-in "./provider-package-spec"
                 asp-gerbil-scheme-provider-spec))

(def +provider-build-root+
  (path-expand "build/workspace-provider" (current-directory)))

(defbuild-script
 (asp-gerbil-scheme-provider-spec)
 optimize: #f
 bindir: (path-expand "bin" +provider-build-root+))
