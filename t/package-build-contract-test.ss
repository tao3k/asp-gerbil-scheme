;;; -*- Gerbil -*-
;;; Package-library build ownership contracts.

(import :gerbil/gambit
        (only-in :std/test test-suite test-case check)
        (only-in :std/misc/path path-expand)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/source gerbil-home)
        (only-in "../src/build-api/package-build"
                 asp-gerbil-scheme-package-build-active-gerbil-path)
        (only-in "../src/build-api/native-build-spec"
                 configure-build-root!)
        (only-in "../src/build-api/package-native-plan"
                 asp-gerbil-scheme-package-api-stage-specs))

(export package-build-contract-test)

;; : TestSuite
(def package-build-contract-test
  (test-suite "asp gerbil-scheme package build contract"
    (test-case "build root preserves the caller Gerbil path"
      (let ((caller-gerbil-path (getenv "GERBIL_PATH" #f))
            (sentinel "/tmp/asp-gerbil-scheme-caller-path-sentinel"))
        (setenv "GERBIL_PATH" sentinel)
        (configure-build-root! (current-directory))
        (check (getenv "GERBIL_PATH" #f) => sentinel)
        (setenv "GERBIL_PATH" (or caller-gerbil-path ""))
        (configure-build-root! (current-directory))))
    (test-case "empty caller Gerbil path resolves to the Gerbil default"
      (let (caller-gerbil-path (getenv "GERBIL_PATH" #f))
        (setenv "GERBIL_PATH" "")
        (check (asp-gerbil-scheme-package-build-active-gerbil-path
                (current-directory))
               => (path-expand (gerbil-home)))
        (setenv "GERBIL_PATH" (or caller-gerbil-path ""))
        (configure-build-root! (current-directory))))
    (test-case "package test driver dependencies remain materialized"
      (let (modules (apply append (asp-gerbil-scheme-package-api-stage-specs)))
        (check (member "build-api/source-bootstrap.ss" modules) ? true)
        (check (member "testing/commands.ss" modules) ? true)
        (check (member "testing/project-build.ss" modules) ? true)
        (check (member "build-api/project-build.ss" modules) ? true)
        (check (member "build-api/generated-artifact.ss" modules) ? true)
        (check (member "runtime/provider/types.ss" modules) ? true)
        (check (member "runtime/provider/objects.ss" modules) ? true)))
    (test-case "package bootstrap compiles native-build dependencies first"
      (let loop ((stages (asp-gerbil-scheme-package-api-stage-specs))
                 (index 0)
                 (package-build-index #f)
                 (native-build-index #f))
        (if (null? stages)
          (begin
            (check (integer? package-build-index) => #t)
            (check (< package-build-index native-build-index) => #t))
          (let (stage (car stages))
            (loop (cdr stages)
                  (+ index 1)
                  (or package-build-index
                      (and (member "build-api/package-build.ss" stage) index))
                  (or native-build-index
                      (and (member "build-api/native-build.ss" stage) index)))))))
    (test-case "root build entries use the narrow internal source bootstrap"
      (let ((library-source
             (call-with-input-file "build.ss" read-all-as-string))
            (provider-source
             (call-with-input-file "build-provider.ss" read-all-as-string))
            (public-facade-source
             (call-with-input-file "build-api.ss" read-all-as-string)))
        (check (string-contains
                library-source
                "\"./src/build-api/source-bootstrap\"")
               ? true)
        (check (string-contains
                provider-source
                "\"./src/build-api/source-bootstrap\"")
               ? true)
        (check (string-contains library-source "\"./build-api\"") => #f)
        (check (string-contains provider-source "\"./build-api\"") => #f)
        (check (string-contains public-facade-source "source-bootstrap") => #f)))
    (test-case "package build API materializes native std/make owners only"
      (let (modules (apply append (asp-gerbil-scheme-package-api-stage-specs)))
        (for-each
         (lambda (module)
           (check (member module modules) ? true))
         '("building/native-toolchain.ss"
           "building/model.ss"
           "building/std-builder.ss"
           "building/facade.ss"
           "building/declarative.ss"))
        (check (member "build-api/source-coverage-query.ss" modules) => #f)))))
