;;; -*- Gerbil -*-
;;; Executable expansion witnesses for declaration macros whose generated
;;; bindings remain ordinary runtime values and procedures.

(import (only-in :std/test test-suite test-case check)
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :asp-gerbil-scheme/src/building/commands
                 define-build-options
                 define-build-commands)
        (only-in :asp-gerbil-scheme/src/building/declarative
                 define-build-profile)
        (only-in :asp-gerbil-scheme/src/building/facade
                 default-std-builder
                 build-profile?)
        (only-in :asp-gerbil-scheme/src/build-api/package-spec
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-package-modules
                 asp-gerbil-scheme-package-source-roots)
        (only-in :asp-gerbil-scheme/src/build-api/source-coverage
                 asp-gerbil-scheme-source-coverage-declared-files
                 asp-gerbil-scheme-source-coverage-owner-root)
        (only-in :asp-gerbil-scheme/src/build-api/builder-profile
                 asp-gerbil-scheme-production-builder-profile)
        (only-in :asp-gerbil-scheme/src/testing/commands
                 define-project-test))

(export build-api-macro-expansion-witness-test)

(define-build-options witness-options!
  make: (lambda () (lambda arguments arguments)))

(define-build-commands (witness-spec! witness-compile! witness-clean!)
  spec: (lambda () (lambda (options) options))
  compile: (lambda () (lambda (options) options))
  clean: (lambda () (lambda () 'cleaned)))

(define-build-profile witness-profile
  builder: (default-std-builder #f [])
  label-of: car
  extra-options: []
  after: #f)

(define-project-test witness-project-test
  project: (lambda () 'witness-project)
  run: (lambda (_project files) files)
  ok?: pair?)

(asp-gerbil-scheme-package-spec!
  (witness-package-spec @ asp-gerbil-scheme-library-package-prototype)
  (spec witness-package-build-spec)
  (modules ["src/parser/model.ss"])
  (role 'library)
  (profile asp-gerbil-scheme-production-builder-profile)
  (exclude-directories [])
  (native-spec '("src/parser/model")))

;; : TestSuite
(def build-api-macro-expansion-witness-test
  (test-suite "declarative macro expansion witnesses"
    (test-case "build options lower to an ordinary procedure"
      (check (witness-options! 'alpha 'beta) => '(alpha beta)))
    (test-case "build profile lowers to a typed profile value"
      (check (build-profile? witness-profile) => #t))
    (test-case "build commands lower to ordinary procedures"
      (check (witness-spec! 'spec-options) => 'spec-options)
      (check (witness-compile! 'compile-options) => 'compile-options)
      (check (witness-clean!) => 'cleaned))
    (test-case "project test lowers to receipt-based exit status"
      (check (witness-project-test ["t/witness.ss"]) => 0))
    (test-case "package declaration lowers to a POO package spec"
      (check (asp-gerbil-scheme-package-modules witness-package-spec)
             => ["src/parser/model.ss"])
      (check (asp-gerbil-scheme-package-source-roots witness-package-spec)
             => ["."])
      (check (asp-gerbil-scheme-source-coverage-declared-files)
             => ["src/parser/model.ss"])
      (check (asp-gerbil-scheme-source-coverage-owner-root)
             => (path-normalize
                 (path-directory
                  (path-expand "t/package-spec-witness.ss"
                               (current-directory)))))
      (check (witness-package-build-spec)
             => '("src/parser/model")))))
