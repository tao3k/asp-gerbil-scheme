;;; -*- Gerbil -*-
;;; Executable expansion witnesses for declaration macros whose generated
;;; bindings remain ordinary runtime values and procedures.

(import (only-in :std/test test-suite test-case check)
        (only-in :asp-gerbil-scheme/src/building/commands
                 define-build-options
                 define-build-commands)
        (only-in :asp-gerbil-scheme/build-api
                 define-build-profile
                 define-build-request
                 std-build
                 define-std-build
                 default-std-builder
                 build-profile?
                 build-request?
                 build-request-label)
        (only-in :asp-gerbil-scheme/src/build-api/package-spec
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 asp-gerbil-scheme-package-modules))

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

(define-build-request witness-build-request
  label: "witness-build-request"
  profile: witness-profile
  stage-specs: []
  current?: (lambda (_stage _context) #t)
  context: 'witness-context)

(define-std-build witness-std-build-request
  label: "witness-std-build-request"
  source: #f
  make-options: []
  label-of: car
  after: #f
  stage-specs: []
  current?: (lambda (_stage _context) #t)
  context: 'witness-std-context)

(asp-gerbil-scheme-package-spec!
  (witness-package-spec @ asp-gerbil-scheme-library-package-prototype)
  (spec witness-package-build-spec)
  (modules ["src/parser/model.ss"])
  (role 'library)
  (native-spec '("src/parser/model")))

;; : TestSuite
(def build-api-macro-expansion-witness-test
  (test-suite "declarative macro expansion witnesses"
    (test-case "build options lower to an ordinary procedure"
      (check (witness-options! 'alpha 'beta) => '(alpha beta)))
    (test-case "build profile lowers to a typed profile value"
      (check (build-profile? witness-profile) => #t))
    (test-case "request declarations lower through the stable facade"
      (check (build-request? witness-build-request) => #t)
      (check (build-request-label witness-build-request)
             => "witness-build-request")
      (check (build-request? witness-std-build-request) => #t)
      (check (build-request-label witness-std-build-request)
             => "witness-std-build-request")
      (let (request
            (std-build
             label: "witness-expression-build-request"
             source: #f
             make-options: []
             label-of: car
             after: #f
             stage-specs: []
             current?: (lambda (_stage _context) #t)
             context: 'witness-expression-context))
        (check (build-request? request) => #t)
        (check (build-request-label request)
               => "witness-expression-build-request")))
    (test-case "build commands lower to ordinary procedures"
      (check (witness-spec! 'spec-options) => 'spec-options)
      (check (witness-compile! 'compile-options) => 'compile-options)
      (check (witness-clean!) => 'cleaned))
    (test-case "package declaration lowers to a POO package spec"
      (check (asp-gerbil-scheme-package-modules witness-package-spec)
             => ["src/parser/model.ss"])
      (check (witness-package-build-spec)
             => '("src/parser/model")))))
