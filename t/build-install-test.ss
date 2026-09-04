;;; -*- Gerbil -*-
;;; Build/install path contract tests.
;;; Boundary:
;;; - Package-local paths must remain independent of a developer's global Gerbil installation.
;;; - Closure checks reject linker and checker modules before a release can package them.

(import :gerbil/gambit
        (only-in :std/test test-suite test-case check)
        (only-in :std/misc/path path-expand)
        (only-in "../src/build-api/build-path-contract"
                 configure-build-root!
                 install-launcher-binpath
                 dev-launcher-binpath)
        (only-in "../src/build-api/native-build"
                 cli-binary-module-spec
                 package-api-build-output-files)
        (only-in "../src/build-api/package-native-plan"
                 asp-gerbil-scheme-package-api-stage-specs)
        (only-in "../src/commands/guide-sections" guide-section-lines-for)
        (only-in "../src/constants" +help+))
(export build-install-test)

;;; Boundary:
;;; - This suite keeps development and release module closures separate before artifacts are produced.
;;; - The long contract guards package boundaries where an omitted exclusion would ship non-runtime code.
;; : TestSuite
(def build-install-test
  (test-suite "asp gerbil-scheme build install path contract"
    (test-case "build root configures package-local Gerbil path"
      (configure-build-root! (current-directory))
      (check (getenv "GERBIL_PATH")
             => (path-expand ".gerbil" (current-directory))))
    (test-case "install path is ASP State Home runtime bin"
      (configure-build-root! (current-directory))
      (let* ((state-home
              (or (getenv "ASP_STATE_HOME")
                  (path-expand ".agent-semantic-protocols" (getenv "HOME"))))
             (bin-dir
              (or (getenv "SEMANTIC_AGENT_BIN_DIR")
                  (path-expand "runtime/bin" state-home))))
        (check (install-launcher-binpath)
               => (path-expand "asp-gerbil-scheme" bin-dir))))
    (test-case "development binary path is package-local .bin"
      (configure-build-root! (current-directory))
      (check (dev-launcher-binpath)
             => (path-expand ".bin/asp-gerbil-scheme" (current-directory))))
    (test-case "bootstrap and release module closures exclude linker roots"
      (let* ((development-modules (cli-binary-module-spec #f))
             (release-modules (cli-binary-module-spec #t)))
        (for-each
          (lambda (module)
            (check (member module development-modules) => #f)
            (check (member module release-modules) => #f))
          '("commands/bench.ss" "commands/bench-light.ss"))
        (check (member "cli-dev-linker.ss" development-modules)
               => #f)
        (check (member "cli-release-linker.ss" development-modules)
               => #f)
        (check (member "cli-release-linker.ss" release-modules)
               => #f)
        (for-each
         (lambda (module)
           (check (member module release-modules) => #f))
         '("checker/arity.ss"
           "checker/core.ss"
           "checker/facade.ss"
           "checker/forms.ss"
           "checker/model.ss"
           "checker/types.ss"
           "checker/whitelist.ss"))
        (check (not (not (ormap (lambda (path)
                                  (string-contains path "commands/guide-sections.ssi"))
                                (package-api-build-output-files))))
               => #t)
        (check (string-contains +help+ "bench") => #f)
        (check (ormap (lambda (line) (string-contains line "bench"))
                      (guide-section-lines-for '()))
               => #f))
    (test-case "package test driver dependencies remain materialized"
      (let (modules (apply append (asp-gerbil-scheme-package-api-stage-specs)))
        (check (not (not (member "testing/commands.ss" modules))) => #t)
        (check (not (not (member "testing/project-build.ss" modules))) => #t)
        (check (not (not (member "build-api/project-build.ss" modules))) => #t)))
    (test-case "package bootstrap compiles native-build dependencies first"
      (let loop ((stages (asp-gerbil-scheme-package-api-stage-specs))
                 (index 0)
                 (package-build-index #f)
                 (native-build-index #f))
        (if (null? stages)
          (begin
            (check package-build-index => 0)
            (check (< package-build-index native-build-index) => #t))
          (let (stage (car stages))
            (loop (cdr stages)
                  (+ index 1)
                  (or package-build-index
                      (and (member "build-api/package-build.ss" stage) index))
                  (or native-build-index
                      (and (member "build-api/native-build.ss" stage) index))))))))
    (test-case "package runtime stage does not rewrite bootstrap controls"
      (let (modules (apply append (asp-gerbil-scheme-package-api-stage-specs)))
        (for-each
         (lambda (module)
           (check (member module modules) => #f))
         '("building/native-toolchain.ss"
           "building/model.ss"
           "building/std-builder.ss"
           "building/facade.ss"
           "building/declarative.ss"))))
  ))
