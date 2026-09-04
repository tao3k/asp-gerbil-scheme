;;; -*- Gerbil -*-
;;; Static module surface for the installed asp-gerbil-scheme binary.

(export cli-install-static-modules)

(import :asp-gerbil-scheme/src/build-api/release-modules
        (only-in :std/misc/list unique))

;; : (List Path)
(def cli-install-static-modules
  (unique (cons "cli-launcher.ss" cli-release-modules)))
