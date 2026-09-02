(export #t)

(import :gerbil/tools/env
        :std/cli/getopt
 :std/cli/multicall
  :asp-gerbil-scheme/src/build-api/project-build
  :asp-gerbil-scheme/src/testing/project-build)

(def (native-build-getopt . options)
  (append
   [(flag 'verbose "-V" "--verbose"
          help: "Make the build verbose")
    (flag 'debug "-g" "--debug"
          help: "Include debug information")
    (flag 'no-optimize "--O" "--no-optimize"
          help: "Disable Gerbil optimization")
    (flag 'optimized "-O" "--optimized"
          help: "Accept gxpkg optimized build mode")
    (flag 'release "-R" "--release"
          help: "Build optimized release executables")]
   options))

(def compile-getopt
  (native-build-getopt
   (flag 'binary "--binary"
         help: "Build the package-local development CLI executable under .bin")
   (flag 'full "--full"
         help: "Compile every library module instead of the CLI launcher")))

(def install-getopt
  (native-build-getopt
   (option 'flag "--flag"
           help: "Installation profile; use asp for ASP State Home runtime"
           value: string->symbol)
   (flag 'full "--full"
         help: "Compile every library module before installing the CLI launcher")))

(def test-file-getopt
  [(rest-arguments 'files
                   help: "Selected gxtest files")])

(define-entry-point (compile verbose: (verbose #f)
                             debug: (debug #f)
                             no-optimize: (no-optimize #f)
                             optimized: (optimized #f)
                             release: (release #f)
                             binary: (binary #f)
                             full: (full #f))
  (help: "Compile the package"
   getopt: compile-getopt)
  (project-compile-target
   verbose debug no-optimize optimized release full binary))

(define-entry-point (spec)
  (help: "Show the build specification"
   getopt: [])
  (displayln (project-compile-spec #t #f #f)))

(define-entry-point (install (verbose #f)
                             (debug #f)
                             (no-optimize #f)
                             (optimized #f)
        (release #f)
        (flag #f)
        (full #f))
  (help: "Install standalone asp-gerbil-scheme; use --flag asp for ASP State Home runtime"
   getopt: install-getopt)
  (project-install-target
   verbose debug no-optimize optimized release full flag))

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
