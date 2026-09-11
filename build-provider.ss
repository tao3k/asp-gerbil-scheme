#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import (only-in :gerbil/gambit setenv)
        (only-in :std/misc/path path-expand)
        "./build-api"
        (only-in "./provider-package-spec"
                 asp-gerbil-scheme-provider-spec))

(def +provider-build-root+
  (path-expand "build/workspace-provider" (current-directory)))

;; One provider artifact root owns both native modules and the executable.
;; The BuildScript bridge resolves its libdir/bindir from GERBIL_PATH.
(setenv "GERBIL_PATH" +provider-build-root+)

(defbuild-script
 (asp-gerbil-scheme-provider-spec)
 profile: 'production)
