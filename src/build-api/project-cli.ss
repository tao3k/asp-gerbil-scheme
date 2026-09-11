;;; The project CLI only decodes user intent and delegates to Build API library
;;; operations. Native compile/spec/clean remain owned by root build.ss.
(export #t)

(import :gerbil/tools/env
        (only-in :std/cli/getopt rest-arguments)
        (only-in :std/cli/multicall
                 define-entry-point
                 define-multicall-main)
  :asp-gerbil-scheme/src/testing/project-build)

;; : (List GetoptOption)
(def test-file-getopt
  [(rest-arguments 'files
                   help: "Selected gxtest files")])

(define-entry-point (test)
  (help: "Run the default fast gxtest smoke gate"
   getopt: [])
  (project-test-target))

(define-entry-point (test-file . files)
  (help: "Run selected gxtest files"
   getopt: test-file-getopt)
  (project-test-file-target files))

(define-entry-point (test-full)
  (help: "Run every top-level gxtest file"
   getopt: [])
  (project-test-full-target))

(define-multicall-main)
