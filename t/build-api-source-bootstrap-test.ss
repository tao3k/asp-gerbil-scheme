;;; -*- Gerbil -*-
;;; Each public capability facade must work at its stable package address both
;;; during source bootstrap and after installation.

(import :gerbil/runtime/gambit
        :std/test
        (only-in :asp-gerbil-scheme/building-api
                 asp-gerbil-scheme-package-native-spec))

(export build-api-source-bootstrap-test)

(def build-api-source-bootstrap-test
  (test-suite "stable package-level Build API facade"
    (test-case "owns the PackageSpec downstream module address"
      (check (file-exists? "building-api.ss") => #t)
      (check (file-exists? "build-api.ss") => #f)
      (check (file-exists? "src/package-build-api.ss") => #f))
    (test-case "exports the compile-mode-neutral native-spec projection"
      (check (procedure? asp-gerbil-scheme-package-native-spec)
             => #t))))
