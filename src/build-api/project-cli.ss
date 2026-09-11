;;; The project CLI only decodes user intent and delegates to Build API library
;;; operations.  Compilation policy stays in package/profile declarations so
;;; CLI invocation cannot create a second platform or concurrency authority.
(export #t)

(import :gerbil/tools/env
        (only-in :std/cli/getopt flag rest-arguments)
        (only-in :std/cli/multicall
                 define-entry-point
                 define-multicall-main)
  :asp-gerbil-scheme/src/build-api/project-build
  :asp-gerbil-scheme/src/testing/project-build)

;; : (List GetoptOption)
(def compile-getopt
  [(flag 'verbose "-V" "--verbose"
         help: "Make the library build verbose")
   (flag 'full "--full"
         help: "Compile every discovered library module")
   (flag 'force "--force"
         help: "Rebuild the declared package API stages")])

;; : (List GetoptOption)
(def test-file-getopt
  [(rest-arguments 'files
                   help: "Selected gxtest files")])

(define-entry-point (compile verbose: (verbose #f)
                             full: (full #f)
                             force: (force #f))
  (help: "Compile the package"
   getopt: compile-getopt)
  (project-compile-target verbose full force))

(define-entry-point (spec)
  (help: "Show the build specification"
   getopt: [])
  (displayln (project-compile-spec #t)))

(define-entry-point (clean)
  (help: "Clean package-local development build artifacts"
   getopt: [])
  (project-clean-target))

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
