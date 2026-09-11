;;; -*- Gerbil -*-
;;; Pure paths for Gerbil module build artifacts.

(import (only-in :std/misc/path path-expand)
        (only-in :std/srfi/13 string-suffix?))

(export asp-gerbil-scheme-build-module-source-file
        asp-gerbil-scheme-build-module-output-file)

;; asp-gerbil-scheme-build-module-source-file
;; : (-> Path ModulePath Path)
(def (asp-gerbil-scheme-build-module-source-file source-root module)
  (path-expand module source-root))

;; asp-gerbil-scheme-module-path-stem
;; : (-> ModulePath ModulePath)
(def (asp-gerbil-scheme-module-path-stem module)
  (if (string-suffix? ".ss" module)
    (substring module 0 (- (string-length module) 3))
    module))

;; asp-gerbil-scheme-build-module-output-file
;; : (-> Path ModulePath Path)
(def (asp-gerbil-scheme-build-module-output-file output-root module)
  (path-expand
   (string-append (asp-gerbil-scheme-module-path-stem module) ".scm")
   output-root))
