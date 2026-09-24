#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/building-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

;;; ASP Building API owns declarative source projection; std/make owns the
;;; native graph and scheduling through std/build-script.
(asp-gerbil-scheme-package-spec!
 (sample-package-spec @ asp-gerbil-scheme-library-package-prototype)
 (spec spec)
 (modules '("src/main.ss" "t/unit/build-runtime.ss")))

(defbuild-script (spec))
