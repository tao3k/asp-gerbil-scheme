#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import :std/make
        :clan/building
        (only-in :asp-gerbil-scheme/src/build-api/source-coverage
                 asp-gerbil-scheme-source-coverage))

(asp-gerbil-scheme-source-coverage
 roots: '("src" "t")
 explanation: "build.ss declares source coverage; acceleration and receipts stay in reusable harness APIs.")

(def (spec)
  (all-gerbil-modules))

(%set-build-environment!
 "build.ss"
 name: "sample"
 deps: '("asp-gerbil-scheme")
 spec: spec)

(def (compile-package! options)
  (apply make (spec) options))
